-- ============================================
-- Krishnasamy Institution - Drop All Tables
-- Run this FIRST, then run migrate_supabase_schema.sql
-- ============================================

-- Drop tables in reverse dependency order (child tables first)
DROP TABLE IF EXISTS public.userlogin CASCADE;
DROP TABLE IF EXISTS public.shoppingcartdetails CASCADE;
DROP TABLE IF EXISTS public.feedemand CASCADE;
DROP TABLE IF EXISTS public.challan CASCADE;
DROP TABLE IF EXISTS public.parentdetail CASCADE;
DROP TABLE IF EXISTS public.students CASCADE;
DROP TABLE IF EXISTS public.parents CASCADE;
DROP TABLE IF EXISTS public.sequence CASCADE;
DROP TABLE IF EXISTS public.activitytype CASCADE;
DROP TABLE IF EXISTS public.institutionusers CASCADE;
DROP TABLE IF EXISTS public.staffdesignation CASCADE;
DROP TABLE IF EXISTS public.custuserroles CASCADE;
DROP TABLE IF EXISTS public.institution CASCADE;
DROP TABLE IF EXISTS public.city CASCADE;
DROP TABLE IF EXISTS public.state CASCADE;
DROP TABLE IF EXISTS public.country CASCADE;
DROP TABLE IF EXISTS public.institutionyear CASCADE;
DROP TABLE IF EXISTS public.modules CASCADE;
DROP TABLE IF EXISTS public.shoppingcart CASCADE;
DROP TABLE IF EXISTS public.payment CASCADE;
DROP TABLE IF EXISTS public.paymentgateway CASCADE;
DROP TABLE IF EXISTS public.concessioncategory CASCADE;
DROP TABLE IF EXISTS public.year CASCADE;
DROP TABLE IF EXISTS public.institutiontype CASCADE;
DROP TABLE IF EXISTS public.currency CASCADE;

-- Drop the email domain if exists
DROP DOMAIN IF EXISTS public.email CASCADE;

-- Drop helper function if exists
DROP FUNCTION IF EXISTS add_column_if_not_exists CASCADE;

SELECT 'All tables dropped successfully!' as status;
