-- ============================================
-- Supabase Row Level Security (RLS) Policies
-- Run this in Supabase SQL Editor to fix permission errors
-- ============================================

-- ============================================
-- Option 1: Disable RLS (Quick fix for development)
-- NOT recommended for production
-- ============================================

-- ALTER TABLE public.parents DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.students DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.feedemand DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.payment DISABLE ROW LEVEL SECURITY;

-- ============================================
-- Option 2: Enable RLS with proper policies (Recommended)
-- ============================================

-- Enable RLS on tables
ALTER TABLE public.parents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.feedemand ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment ENABLE ROW LEVEL SECURITY;

-- ============================================
-- Parents table policies
-- ============================================

-- Allow anonymous users to read parents (for login)
CREATE POLICY "Allow anonymous read access to parents"
ON public.parents
FOR SELECT
TO anon
USING (true);

-- Allow authenticated users to read parents
CREATE POLICY "Allow authenticated read access to parents"
ON public.parents
FOR SELECT
TO authenticated
USING (true);

-- Allow authenticated users to update their own record
CREATE POLICY "Allow authenticated update own parent record"
ON public.parents
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- Allow insert for registration
CREATE POLICY "Allow insert to parents"
ON public.parents
FOR INSERT
TO anon, authenticated
WITH CHECK (true);

-- ============================================
-- Students table policies
-- ============================================

-- Allow anonymous read access to students (for login verification)
CREATE POLICY "Allow anonymous read access to students"
ON public.students
FOR SELECT
TO anon
USING (true);

-- Allow authenticated users to read students
CREATE POLICY "Allow authenticated read access to students"
ON public.students
FOR SELECT
TO authenticated
USING (true);

-- ============================================
-- Feedemand table policies
-- ============================================

-- Allow authenticated users to read fee demands
CREATE POLICY "Allow authenticated read access to feedemand"
ON public.feedemand
FOR SELECT
TO authenticated
USING (true);

-- Allow anonymous read for fee checking
CREATE POLICY "Allow anonymous read access to feedemand"
ON public.feedemand
FOR SELECT
TO anon
USING (true);

-- ============================================
-- Payment table policies
-- ============================================

-- Allow authenticated users to read payments
CREATE POLICY "Allow authenticated read access to payment"
ON public.payment
FOR SELECT
TO authenticated
USING (true);

-- Allow anonymous read access to payment
CREATE POLICY "Allow anonymous read access to payment"
ON public.payment
FOR SELECT
TO anon
USING (true);

-- Allow insert for creating payments
CREATE POLICY "Allow insert to payment"
ON public.payment
FOR INSERT
TO anon, authenticated
WITH CHECK (true);

-- Allow update for payment status
CREATE POLICY "Allow update to payment"
ON public.payment
FOR UPDATE
TO anon, authenticated
USING (true)
WITH CHECK (true);

-- ============================================
-- Institution table policies
-- ============================================

-- Enable RLS on institution table
ALTER TABLE public.institution ENABLE ROW LEVEL SECURITY;

-- Allow anonymous read access to institution
CREATE POLICY "Allow anonymous read access to institution"
ON public.institution
FOR SELECT
TO anon
USING (true);

-- Allow authenticated read access to institution
CREATE POLICY "Allow authenticated read access to institution"
ON public.institution
FOR SELECT
TO authenticated
USING (true);

-- ============================================
-- City table policies (needed for joins)
-- ============================================

-- Enable RLS on city table
ALTER TABLE public.city ENABLE ROW LEVEL SECURITY;

-- Allow anonymous read access to city
CREATE POLICY "Allow anonymous read access to city"
ON public.city
FOR SELECT
TO anon
USING (true);

-- Allow authenticated read access to city
CREATE POLICY "Allow authenticated read access to city"
ON public.city
FOR SELECT
TO authenticated
USING (true);

-- ============================================
-- DONE! RLS policies created successfully
-- ============================================
