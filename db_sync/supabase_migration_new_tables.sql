-- Migration: Add new tables (bank, feegroup, feetype) and update feedemand
-- Run this in Supabase SQL Editor

-- ============================================
-- 1. Create bank table
-- ============================================
CREATE TABLE IF NOT EXISTS public.bank
(
    ban_id integer NOT NULL,
    banname character varying(45) NOT NULL,
    banbranch character varying(80) NOT NULL,
    ifsccode character varying(15) NOT NULL,
    banaddress1 character varying(50) NOT NULL,
    banaddress2 character varying(50),
    banaddress3 character varying(50),
    banmobile character varying(15),
    banemail character varying(60),
    banaccno character varying(20) NOT NULL,
    banaccholder character varying(50) NOT NULL,
    activestatus smallint NOT NULL DEFAULT 1,
    CONSTRAINT bank_pkey PRIMARY KEY (ban_id),
    CONSTRAINT bank_activestatus_check CHECK (activestatus = ANY (ARRAY[0, 1, 9]))
);

ALTER TABLE IF EXISTS public.bank OWNER TO postgres;

-- ============================================
-- 2. Create feegroup table
-- ============================================
CREATE TABLE IF NOT EXISTS public.feegroup
(
    fg_id integer NOT NULL,
    fgdesc character varying(30) NOT NULL,
    ban_id integer,
    ins_id integer NOT NULL,
    yr_id integer NOT NULL,
    yrlabel character varying(9) NOT NULL,
    activestatus smallint NOT NULL DEFAULT 1,
    CONSTRAINT feegroup_pkey PRIMARY KEY (fg_id),
    CONSTRAINT fk_feegroup_institution FOREIGN KEY (ins_id)
        REFERENCES public.institution (ins_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT fk_feegroup_year FOREIGN KEY (yr_id)
        REFERENCES public.year (yr_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT feegroup_activestatus_check CHECK (activestatus = ANY (ARRAY[0, 1, 9]))
);

ALTER TABLE IF EXISTS public.feegroup OWNER TO postgres;

-- ============================================
-- 3. Create feetype table
-- ============================================
CREATE TABLE IF NOT EXISTS public.feetype
(
    fee_id integer NOT NULL,
    feedesc character varying(30) NOT NULL,
    feeshort character varying(10) NOT NULL,
    feeoptional smallint,
    feecategory smallint,
    fg_id integer NOT NULL,
    yr_id integer NOT NULL,
    yrlabel character varying(9) NOT NULL,
    activestatus smallint NOT NULL DEFAULT 1,
    CONSTRAINT feetype_pkey PRIMARY KEY (fee_id),
    CONSTRAINT fk_feetype_year FOREIGN KEY (yr_id)
        REFERENCES public.year (yr_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT feetype_activestatus_check CHECK (activestatus = ANY (ARRAY[0, 1, 9]))
);

ALTER TABLE IF EXISTS public.feetype OWNER TO postgres;

-- ============================================
-- 4. Update parentdetail table - Add missing column
-- ============================================
ALTER TABLE public.parentdetail
ADD COLUMN IF NOT EXISTS activestatus smallint NOT NULL DEFAULT 1;

-- ============================================
-- 5. Update feedemand table - Add new columns
-- ============================================
-- Add fee_id column (references feetype)
ALTER TABLE public.feedemand
ADD COLUMN IF NOT EXISTS fee_id integer;

-- Add foreign key constraint from feedemand to feetype
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints
                   WHERE constraint_name = 'fk_feedemand_feetype'
                   AND table_name = 'feedemand') THEN
        ALTER TABLE public.feedemand
        ADD CONSTRAINT fk_feedemand_feetype FOREIGN KEY (fee_id)
            REFERENCES public.feetype (fee_id) MATCH SIMPLE
            ON UPDATE NO ACTION
            ON DELETE NO ACTION;
    END IF;
END $$;

-- Add foreign key from feetype to feegroup (if not exists)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints
                   WHERE constraint_name = 'fk_feetype_feegroup'
                   AND table_name = 'feetype') THEN
        ALTER TABLE public.feetype
        ADD CONSTRAINT fk_feetype_feegroup FOREIGN KEY (fg_id)
            REFERENCES public.feegroup (fg_id) MATCH SIMPLE
            ON UPDATE NO ACTION
            ON DELETE NO ACTION;
    END IF;
END $$;

-- Rename demfeecategory to demconcategory if it exists, or add new column
DO $$
BEGIN
    -- Check if demfeecategory exists and rename it
    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_schema = 'public'
               AND table_name = 'feedemand'
               AND column_name = 'demfeecategory') THEN
        ALTER TABLE public.feedemand RENAME COLUMN demfeecategory TO demconcategory;
    -- If demconcategory doesn't exist, add it
    ELSIF NOT EXISTS (SELECT 1 FROM information_schema.columns
                      WHERE table_schema = 'public'
                      AND table_name = 'feedemand'
                      AND column_name = 'demconcategory') THEN
        ALTER TABLE public.feedemand ADD COLUMN demconcategory character varying(20);
    END IF;
END $$;

-- ============================================
-- 6. Enable RLS on new tables (recommended)
-- ============================================
ALTER TABLE public.bank ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.feegroup ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.feetype ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 7. Create basic RLS policies (allow all for now)
-- ============================================
-- Bank policies
DROP POLICY IF EXISTS "Allow all access to bank" ON public.bank;
CREATE POLICY "Allow all access to bank" ON public.bank FOR ALL USING (true) WITH CHECK (true);

-- Feegroup policies
DROP POLICY IF EXISTS "Allow all access to feegroup" ON public.feegroup;
CREATE POLICY "Allow all access to feegroup" ON public.feegroup FOR ALL USING (true) WITH CHECK (true);

-- Feetype policies
DROP POLICY IF EXISTS "Allow all access to feetype" ON public.feetype;
CREATE POLICY "Allow all access to feetype" ON public.feetype FOR ALL USING (true) WITH CHECK (true);

-- ============================================
-- Done!
-- ============================================
SELECT 'Migration completed successfully!' as status;
