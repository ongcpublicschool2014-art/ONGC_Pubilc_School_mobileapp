-- Parent app OTP: 5-minute validity.
--
-- 1) add parmobotp_at to every parents table (records when the OTP was sent),
-- 2) stamp it on request_parent_otp,
-- 3) reject OTPs older than 5 minutes in verify_parent_otp.
-- Idempotent; safe to re-run.

DO $$
DECLARE r record;
BEGIN
  FOR r IN SELECT table_schema FROM information_schema.tables WHERE table_name = 'parents'
  LOOP
    EXECUTE format('ALTER TABLE %I.parents ADD COLUMN IF NOT EXISTS parmobotp_at timestamp', r.table_schema);
  END LOOP;
END $$;

CREATE OR REPLACE FUNCTION public.request_parent_otp(p_mobile text, p_ins_id integer, p_otp integer)
RETURNS TABLE(is_found boolean, has_password boolean)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions AS $$
DECLARE v_schema text; v_par integer; v_has boolean;
BEGIN
  is_found := false; has_password := false;
  v_schema := get_institution_schema(p_ins_id);
  IF v_schema IS NULL THEN RETURN NEXT; RETURN; END IF;
  EXECUTE format(
    'SELECT par_id, (COALESCE(length(parpassword),0)>0) FROM %I.parents '
    'WHERE payinchargemob=$1 AND activestatus=1 ORDER BY par_id LIMIT 1', v_schema)
  INTO v_par, v_has USING p_mobile;
  IF v_par IS NULL THEN RETURN NEXT; RETURN; END IF;
  EXECUTE format('UPDATE %I.parents SET parmobotp=$1, parmobotp_at=now(), parotpstatus=0 WHERE par_id=$2', v_schema)
    USING p_otp, v_par;
  is_found := true; has_password := COALESCE(v_has,false); RETURN NEXT;
END; $$;
GRANT EXECUTE ON FUNCTION public.request_parent_otp(text, integer, integer) TO anon, authenticated;

CREATE OR REPLACE FUNCTION public.verify_parent_otp(p_mobile text, p_ins_id integer, p_otp integer)
RETURNS boolean
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions AS $$
DECLARE v_schema text; v_par integer;
BEGIN
  v_schema := get_institution_schema(p_ins_id);
  IF v_schema IS NULL THEN RETURN false; END IF;
  -- OTP is valid only for 5 minutes after it was requested.
  EXECUTE format(
    'SELECT par_id FROM %I.parents WHERE payinchargemob=$1 AND parmobotp=$2 AND activestatus=1 '
    'AND parmobotp_at IS NOT NULL AND parmobotp_at >= now() - interval ''5 minutes'' '
    'ORDER BY par_id LIMIT 1', v_schema)
  INTO v_par USING p_mobile, p_otp;
  IF v_par IS NULL THEN RETURN false; END IF;
  EXECUTE format('UPDATE %I.parents SET parotpstatus=1, parmobotp=NULL, parmobotp_at=NULL WHERE par_id=$1', v_schema)
    USING v_par;
  RETURN true;
END; $$;
GRANT EXECUTE ON FUNCTION public.verify_parent_otp(text, integer, integer) TO anon, authenticated;
