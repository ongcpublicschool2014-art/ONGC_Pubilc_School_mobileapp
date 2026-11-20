-- ============================================
-- Payment Safety: Atomic sequence + concurrency protection
-- Run this in Supabase SQL Editor.
-- ============================================

-- 1. Atomic payment number generation
-- Uses FOR UPDATE row lock to prevent two devices reading the same sequence number.
-- Returns the new payment number string (e.g., 'FC25/00008').
CREATE OR REPLACE FUNCTION generate_payment_number()
RETURNS TEXT AS $$
DECLARE
  v_seq RECORD;
  v_new_no INTEGER;
  v_pay_number TEXT;
BEGIN
  -- Lock the sequence row so no other transaction can read it simultaneously
  SELECT seq_id, sequid, seqwidth, seqcurno
  INTO v_seq
  FROM sequence
  LIMIT 1
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'No sequence record found';
  END IF;

  -- Increment
  v_new_no := v_seq.seqcurno + 1;

  -- Build payment number: extract prefix (e.g., 'FC25/') and pad the number
  v_pay_number := regexp_replace(v_seq.sequid, '\d+$', '') ||
                  lpad(v_new_no::TEXT, v_seq.seqwidth, '0');

  -- Update the sequence atomically
  UPDATE sequence SET seqcurno = v_new_no WHERE seq_id = v_seq.seq_id;

  RETURN v_pay_number;
END;
$$ LANGUAGE plpgsql;


-- 2. Add UNIQUE constraint on paynumber to prevent duplicates (if not exists)
-- This is a safety net - even if the app somehow generates a duplicate, the DB will reject it.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'payment_paynumber_unique'
  ) THEN
    ALTER TABLE payment ADD CONSTRAINT payment_paynumber_unique UNIQUE (paynumber);
  END IF;
END $$;


-- 3. Check if fees are already being paid (concurrent payment lock)
-- Returns dem_ids that are currently locked (have an active 'I' initiated payment).
-- Used before initiating payment to prevent the same fees being paid on two devices.
CREATE OR REPLACE FUNCTION check_fees_locked(p_dem_ids BIGINT[])
RETURNS TABLE(dem_id BIGINT) AS $$
BEGIN
  RETURN QUERY
  SELECT pd.dem_id
  FROM paymentdetails pd
  INNER JOIN payment p ON p.pay_id = pd.pay_id
  WHERE pd.dem_id = ANY(p_dem_ids)
    AND p.paystatus = 'I';
END;
$$ LANGUAGE plpgsql;


-- 4. Unique active cart per student
-- Prevents a student from having multiple active, non-initiated carts.
-- Step A: Clean up existing duplicates (keep the latest car_id, deactivate older ones)
UPDATE shoppingcart
SET activestatus = 0
WHERE car_id NOT IN (
  SELECT MAX(car_id)
  FROM shoppingcart
  WHERE activestatus = 1 AND carinitiated = 'N'
  GROUP BY stu_id
)
AND activestatus = 1
AND carinitiated = 'N';

-- Step B: Create partial unique index (only enforced on active, non-initiated carts)
CREATE UNIQUE INDEX IF NOT EXISTS unique_active_cart_per_student
  ON shoppingcart (stu_id)
  WHERE activestatus = 1 AND carinitiated = 'N';
