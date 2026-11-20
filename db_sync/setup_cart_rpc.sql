-- ============================================
-- RPC: get_active_cart_fees
-- Fetches feedemand rows for a student's active (non-initiated) shopping cart
-- in a single query instead of 3 sequential queries.
-- Run this in Supabase SQL Editor.
-- ============================================

CREATE OR REPLACE FUNCTION get_active_cart_fees(p_stu_id bigint)
RETURNS SETOF feedemand AS $$
BEGIN
  RETURN QUERY
  SELECT f.*
  FROM feedemand f
  INNER JOIN shoppingcartdetails cd ON cd.dem_id = f.dem_id AND cd.activestatus = 1
  INNER JOIN shoppingcart c ON c.car_id = cd.car_id
  WHERE c.stu_id = p_stu_id
    AND c.carinitiated = 'N'
    AND c.activestatus = 1
    AND f.activestatus = 1;
END;
$$ LANGUAGE plpgsql;
