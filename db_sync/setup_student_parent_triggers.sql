-- ================================================================
-- setup_student_parent_triggers.sql
--
-- Trigger-based auto-increment for:
--   • stu_id  (students table)
--   • par_id  (parents table)
--   • dem_id  (feedemand table)
--
-- Uses MAX(id)+1 pattern (same as payment table trigger).
-- Student trigger also auto-sets stuphoto from stuadmno.
-- Feedemand trigger also auto-generates demno and demseqtype.
--
-- Run this once in Supabase SQL Editor.
-- ================================================================


-- ---------------------------------------------------------------
-- STEP 1: Drop GENERATED ALWAYS AS IDENTITY from all three columns
--         (required so the trigger can set the value freely)
-- ---------------------------------------------------------------

ALTER TABLE public.students
    ALTER COLUMN stu_id DROP IDENTITY IF EXISTS;

ALTER TABLE public.parents
    ALTER COLUMN par_id DROP IDENTITY IF EXISTS;

ALTER TABLE public.feedemand
    ALTER COLUMN dem_id DROP IDENTITY IF EXISTS;


-- ================================================================
-- STUDENTS TRIGGER
-- ================================================================

-- ---------------------------------------------------------------
-- Trigger function — STUDENTS
--   • Auto-sets stu_id  using MAX(stu_id) + 1
--   • Auto-sets stuphoto URL from stuadmno
--
--   ⚠️  Change 'StudentPhotos' to your actual storage bucket name
-- ---------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.trg_fn_students_before_insert()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_bucket  TEXT := 'StudentPhotos';
    v_base    TEXT := 'https://sjplfnqwlsomcuqoogxz.supabase.co/storage/v1/object/public/';
BEGIN
    IF NEW.stu_id IS NULL OR NEW.stu_id = 0 THEN
        SELECT COALESCE(MAX(stu_id), 0) + 1 INTO NEW.stu_id FROM public.students;
    END IF;

    IF NEW.stuphoto IS NULL AND NEW.stuadmno IS NOT NULL THEN
        NEW.stuphoto := v_base || v_bucket || '/' || TRIM(NEW.stuadmno) || '.jpg';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_students_before_insert ON public.students;

CREATE TRIGGER trg_students_before_insert
    BEFORE INSERT ON public.students
    FOR EACH ROW
    EXECUTE FUNCTION public.trg_fn_students_before_insert();


-- ================================================================
-- PARENTS TRIGGER
-- ================================================================

-- ---------------------------------------------------------------
-- Trigger function — PARENTS
--   • Auto-sets par_id using MAX(par_id) + 1
-- ---------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.trg_fn_parents_before_insert()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.par_id IS NULL OR NEW.par_id = 0 THEN
        SELECT COALESCE(MAX(par_id), 0) + 1 INTO NEW.par_id FROM public.parents;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_parents_before_insert ON public.parents;

CREATE TRIGGER trg_parents_before_insert
    BEFORE INSERT ON public.parents
    FOR EACH ROW
    EXECUTE FUNCTION public.trg_fn_parents_before_insert();


-- ================================================================
-- FEEDEMAND TRIGGER
-- ================================================================

-- ---------------------------------------------------------------
-- Trigger function — FEEDEMAND
--   • Auto-sets dem_id  using MAX(dem_id) + 1
--   • Auto-generates demno  → DE25/00083
--       format: 'DE' + 2-digit year + '/' + 5-digit padded dem_id
--   • Auto-sets demseqtype → 'DEMAND' if not provided
-- ---------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.trg_fn_feedemand_before_insert()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Auto-increment dem_id
    IF NEW.dem_id IS NULL OR NEW.dem_id = 0 THEN
        SELECT COALESCE(MAX(dem_id), 0) + 1 INTO NEW.dem_id FROM public.feedemand;
    END IF;

    -- Auto-generate demno: DE25/00083
    -- Year part taken from demfeeyear start year (e.g. '2025-2026' → '25')
    IF NEW.demno IS NULL OR TRIM(NEW.demno) = '' THEN
        NEW.demno := 'DE' ||
                     RIGHT(SPLIT_PART(COALESCE(NEW.demfeeyear, ''), '-', 1), 2) ||
                     '/' ||
                     LPAD(NEW.dem_id::TEXT, 5, '0');
    END IF;

    -- Auto-set demseqtype if not provided
    IF NEW.demseqtype IS NULL OR TRIM(NEW.demseqtype) = '' THEN
        NEW.demseqtype := 'DEMAND';
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_feedemand_before_insert ON public.feedemand;

CREATE TRIGGER trg_feedemand_before_insert
    BEFORE INSERT ON public.feedemand
    FOR EACH ROW
    EXECUTE FUNCTION public.trg_fn_feedemand_before_insert();


-- ================================================================
-- VERIFY — confirm all three triggers are active
-- ================================================================

SELECT
    t.tgname        AS trigger_name,
    c.relname       AS table_name,
    CASE t.tgenabled
        WHEN 'O' THEN 'ENABLED'
        WHEN 'D' THEN 'DISABLED'
        ELSE t.tgenabled::text
    END             AS status,
    p.proname       AS function_name
FROM pg_trigger     t
JOIN pg_class       c ON c.oid = t.tgrelid
JOIN pg_proc        p ON p.oid = t.tgfoid
WHERE t.tgname IN (
    'trg_students_before_insert',
    'trg_parents_before_insert',
    'trg_feedemand_before_insert'
)
ORDER BY c.relname;
