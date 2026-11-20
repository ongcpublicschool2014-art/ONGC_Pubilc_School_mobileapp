-- Mobile payment: create the pending ('I') payment via a SECURITY DEFINER RPC,
-- like the admin app collects through complete_payment_grouped. This removes the
-- mobile's DIRECT insert into payment/paymentdetails, so it no longer needs anon
-- write grants on those (money) tables (fixes 42501 permission-denied) and it
-- falls back to the current active year for arrear demands whose year isn't in
-- the year master.
--
-- Params:
--   p_total    = payment.transtotalamount (sum of balancedue)
--   p_yr_id    = representative year (client resolves arrear -> current year;
--                RPC also falls back if it's null/0)
--   p_payitems = JSON string stored on payment.payitems (for the admin's orphan
--                recovery sweep) — [{dem_id,yr_id,yrlabel,ins_id,amount,demfeetype}]
--   p_details  = [{dem_id, yr_id, yrlabel, amount}] -> one paymentdetails row each

CREATE OR REPLACE FUNCTION public.create_pending_payment(
  p_ins_id integer, p_stu_id bigint, p_total numeric,
  p_yr_id integer, p_yrlabel text, p_created_by text,
  p_payitems text, p_details jsonb, p_ban_id integer DEFAULT NULL
) RETURNS bigint
LANGUAGE plpgsql SECURITY DEFINER SET statement_timeout = '30s'
AS $$
DECLARE
  v text; v_inscode text; v_pay_id bigint; v_fallback_yr int; v_yr int; it jsonb;
BEGIN
  v := get_institution_schema(p_ins_id);
  IF v IS NULL THEN RAISE EXCEPTION 'No schema for ins_id %', p_ins_id; END IF;

  EXECUTE format('SELECT inscode FROM %I.students WHERE stu_id=$1', v)
    INTO v_inscode USING p_stu_id;
  EXECUTE format('SELECT yr_id FROM %I.year WHERE activestatus=1 ORDER BY yr_id DESC LIMIT 1', v)
    INTO v_fallback_yr;
  v_yr := COALESCE(NULLIF(p_yr_id, 0), v_fallback_yr);

  -- Drop any stale 'I' (initiated-but-abandoned) payments for this student.
  EXECUTE format('DELETE FROM %I.paymentdetails WHERE pay_id IN '
                 '(SELECT pay_id FROM %I.payment WHERE stu_id=$1 AND paystatus=''I'')', v, v)
    USING p_stu_id;
  EXECUTE format('DELETE FROM %I.payment WHERE stu_id=$1 AND paystatus=''I''', v)
    USING p_stu_id;

  EXECUTE format(
    'INSERT INTO %I.payment(ins_id,inscode,stu_id,yr_id,yrlabel,transtotalamount,transcurrency,'
    'paydate,paystatus,recon_status,createdby,payitems,activestatus,ban_id) '
    'VALUES($1,$2,$3,$4,$5,$6,''INR'',now(),''I'',''P'',$7,$8,1,$9) RETURNING pay_id', v)
  INTO v_pay_id
  USING p_ins_id, v_inscode, p_stu_id, v_yr, p_yrlabel, p_total, p_created_by, p_payitems, p_ban_id;

  FOR it IN SELECT jsonb_array_elements(p_details) LOOP
    EXECUTE format(
      'INSERT INTO %I.paymentdetails(pay_id,dem_id,yr_id,yrlabel,ins_id,transcurrency,transtotalamount,activestatus) '
      'VALUES($1,$2,$3,$4,$5,''INR'',$6,1)', v)
    USING v_pay_id, (it->>'dem_id')::bigint,
          COALESCE(NULLIF((it->>'yr_id')::int, 0), v_fallback_yr),
          (it->>'yrlabel'), p_ins_id, (it->>'amount')::numeric;
  END LOOP;

  RETURN v_pay_id;
END; $$;

GRANT EXECUTE ON FUNCTION public.create_pending_payment(integer, bigint, numeric, integer, text, text, text, jsonb, integer)
  TO anon, authenticated;

-- Persist the gateway order id on the pending payment (SECURITY DEFINER so the
-- app doesn't need a direct UPDATE grant on payment).
CREATE OR REPLACE FUNCTION public.set_payment_order(p_ins_id integer, p_pay_id bigint, p_order_id text)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET statement_timeout = '15s'
AS $$
DECLARE v text;
BEGIN
  v := get_institution_schema(p_ins_id);
  IF v IS NULL THEN RETURN; END IF;
  EXECUTE format('UPDATE %I.payment SET payorderid=$1 WHERE pay_id=$2', v) USING p_order_id, p_pay_id;
END; $$;
GRANT EXECUTE ON FUNCTION public.set_payment_order(integer, bigint, text) TO anon, authenticated;

-- Update payment status/method/reference on the failure & recovery fallback
-- paths (widget-disposed cleanup, race-detected refund-needed mark, RPC-missing
-- fallbacks, gateway-poll reference sync). SECURITY DEFINER + COALESCE partial
-- update so the app never needs a direct UPDATE grant on payment. Any arg left
-- NULL is untouched; p_touch_date=false leaves paydate as-is (reference-only).
CREATE OR REPLACE FUNCTION public.set_payment_status(
  p_ins_id integer, p_pay_id bigint,
  p_status text DEFAULT NULL, p_method text DEFAULT NULL,
  p_reference text DEFAULT NULL, p_touch_date boolean DEFAULT true
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET statement_timeout = '15s'
AS $$
DECLARE v text;
BEGIN
  v := get_institution_schema(p_ins_id);
  IF v IS NULL THEN RETURN; END IF;
  EXECUTE format(
    'UPDATE %I.payment SET '
    'paystatus = COALESCE($1, paystatus), '
    'paymethod = COALESCE($2, paymethod), '
    'payreference = COALESCE($3, payreference), '
    'paydate = CASE WHEN $4 THEN now() ELSE paydate END '
    'WHERE pay_id = $5', v)
  USING p_status, p_method, p_reference, p_touch_date, p_pay_id;
END; $$;
GRANT EXECUTE ON FUNCTION public.set_payment_status(integer, bigint, text, text, text, boolean) TO anon, authenticated;

-- Remove a student's stale ('I' = initiated-but-abandoned) payments on cart
-- restore, so they don't linger in history. SECURITY DEFINER (grant-free);
-- same cleanup create_pending_payment runs before a fresh initiate.
CREATE OR REPLACE FUNCTION public.delete_stale_initiated_payments(p_ins_id integer, p_stu_id bigint)
RETURNS integer LANGUAGE plpgsql SECURITY DEFINER SET statement_timeout = '15s'
AS $$
DECLARE v text; n integer;
BEGIN
  v := get_institution_schema(p_ins_id);
  IF v IS NULL THEN RETURN 0; END IF;
  EXECUTE format('DELETE FROM %I.paymentdetails WHERE pay_id IN '
                 '(SELECT pay_id FROM %I.payment WHERE stu_id=$1 AND paystatus=''I'')', v, v)
    USING p_stu_id;
  EXECUTE format('WITH d AS (DELETE FROM %I.payment WHERE stu_id=$1 AND paystatus=''I'' RETURNING 1) '
                 'SELECT count(*) FROM d', v)
    INTO n USING p_stu_id;
  RETURN n;
END; $$;
GRANT EXECUTE ON FUNCTION public.delete_stale_initiated_payments(integer, bigint) TO anon, authenticated;
