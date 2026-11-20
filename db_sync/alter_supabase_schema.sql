-- ============================================
-- Krishnasamy Institution - Supabase Schema ALTER Migration
-- Use this if tables ALREADY EXIST but need new columns
-- ============================================

-- Helper function to add column if not exists
CREATE OR REPLACE FUNCTION add_column_if_not_exists(
    _table TEXT,
    _column TEXT,
    _type TEXT,
    _default TEXT DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = _table
        AND column_name = _column
    ) THEN
        IF _default IS NOT NULL THEN
            EXECUTE format('ALTER TABLE public.%I ADD COLUMN %I %s DEFAULT %s', _table, _column, _type, _default);
        ELSE
            EXECUTE format('ALTER TABLE public.%I ADD COLUMN %I %s', _table, _column, _type);
        END IF;
        RAISE NOTICE 'Added column %.% (%)', _table, _column, _type;
    ELSE
        RAISE NOTICE 'Column %.% already exists, skipping', _table, _column;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- Create email domain if not exists
-- ============================================
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'email') THEN
        CREATE DOMAIN email AS character varying(254)
        CHECK (VALUE ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');
        RAISE NOTICE 'Created email domain';
    END IF;
END $$;

-- ============================================
-- CURRENCY TABLE - Add missing columns
-- ============================================
SELECT add_column_if_not_exists('currency', 'curname', 'character varying(30) NOT NULL', '''Unknown''');
SELECT add_column_if_not_exists('currency', 'curshort', 'character varying(10) NOT NULL', '''UNK''');
SELECT add_column_if_not_exists('currency', 'cursymbol', 'character(1) NOT NULL', '''$''');
SELECT add_column_if_not_exists('currency', 'curdecpoints', 'integer NOT NULL', '2');
SELECT add_column_if_not_exists('currency', 'curdecname', 'character varying(10) NOT NULL', '''cents''');
SELECT add_column_if_not_exists('currency', 'createdon', 'date NOT NULL', 'CURRENT_DATE');
SELECT add_column_if_not_exists('currency', 'activestatus', 'smallint NOT NULL', '1');

-- ============================================
-- YEAR TABLE - Add missing columns
-- ============================================
SELECT add_column_if_not_exists('year', 'ins_id', 'integer NOT NULL', '1');
SELECT add_column_if_not_exists('year', 'yrlabel', 'character varying(9) NOT NULL', '''2024-25''');
SELECT add_column_if_not_exists('year', 'yrstadate', 'date NOT NULL', 'CURRENT_DATE');
SELECT add_column_if_not_exists('year', 'yrenddate', 'date NOT NULL', 'CURRENT_DATE');
SELECT add_column_if_not_exists('year', 'createdon', 'timestamp without time zone NOT NULL', 'now()');
SELECT add_column_if_not_exists('year', 'activestatus', 'smallint NOT NULL', '1');

-- ============================================
-- PARENTS TABLE - Add missing columns
-- ============================================
SELECT add_column_if_not_exists('parents', 'yr_id', 'integer NOT NULL', '1');
SELECT add_column_if_not_exists('parents', 'yrlabel', 'character varying(9)');
SELECT add_column_if_not_exists('parents', 'partype', 'character(1) NOT NULL', '''P''');
SELECT add_column_if_not_exists('parents', 'paremail', 'character varying(254)');
SELECT add_column_if_not_exists('parents', 'fathername', 'character varying(50)');
SELECT add_column_if_not_exists('parents', 'mothername', 'character varying(50)');
SELECT add_column_if_not_exists('parents', 'guardianname', 'character varying(50)');
SELECT add_column_if_not_exists('parents', 'fathermobile', 'character varying(20)');
SELECT add_column_if_not_exists('parents', 'mothermobile', 'character varying(20)');
SELECT add_column_if_not_exists('parents', 'guardianmobile', 'character varying(20)');
SELECT add_column_if_not_exists('parents', 'fatheroccupation', 'character varying(60)');
SELECT add_column_if_not_exists('parents', 'motheroccupation', 'character varying(60)');
SELECT add_column_if_not_exists('parents', 'guardianoccupation', 'character varying(60)');
SELECT add_column_if_not_exists('parents', 'payincharge', 'character varying(50) NOT NULL', '''Unknown''');
SELECT add_column_if_not_exists('parents', 'payinchargemob', 'character varying(20) NOT NULL', '''0000000000''');
SELECT add_column_if_not_exists('parents', 'parpassword', 'character varying(255)');
SELECT add_column_if_not_exists('parents', 'parmobotp', 'numeric(6,0)');
SELECT add_column_if_not_exists('parents', 'parotpstatus', 'smallint NOT NULL', '0');
SELECT add_column_if_not_exists('parents', 'approvedby', 'character varying(50)');
SELECT add_column_if_not_exists('parents', 'approveddate', 'timestamp without time zone', 'now()');
SELECT add_column_if_not_exists('parents', 'terminateddate', 'date');
SELECT add_column_if_not_exists('parents', 'terminatedby', 'character varying(50)');
SELECT add_column_if_not_exists('parents', 'activestatus', 'smallint NOT NULL', '1');

-- ============================================
-- STUDENTS TABLE - Add missing columns
-- ============================================
SELECT add_column_if_not_exists('students', 'ins_id', 'integer NOT NULL', '1');
SELECT add_column_if_not_exists('students', 'inscode', 'character varying(10) NOT NULL', '''INS001''');
SELECT add_column_if_not_exists('students', 'yr_id', 'integer NOT NULL', '1');
SELECT add_column_if_not_exists('students', 'yrlabel', 'character varying(9) NOT NULL', '''2024-25''');
SELECT add_column_if_not_exists('students', 'stuadmno', 'character varying(25) NOT NULL', '''ADM0001''');
SELECT add_column_if_not_exists('students', 'stuadmdate', 'date NOT NULL', 'CURRENT_DATE');
SELECT add_column_if_not_exists('students', 'stuname', 'character varying(50) NOT NULL', '''Unknown''');
SELECT add_column_if_not_exists('students', 'stugender', 'character(1) NOT NULL', '''M''');
SELECT add_column_if_not_exists('students', 'studob', 'date NOT NULL', 'CURRENT_DATE');
SELECT add_column_if_not_exists('students', 'stumobile', 'character varying(30) NOT NULL', '''0000000000''');
SELECT add_column_if_not_exists('students', 'stuemail', 'character varying(254)');
SELECT add_column_if_not_exists('students', 'stuaddress', 'text');
SELECT add_column_if_not_exists('students', 'stucity', 'character varying(50)');
SELECT add_column_if_not_exists('students', 'stustate', 'character varying(50)');
SELECT add_column_if_not_exists('students', 'stucountry', 'character varying(50)');
SELECT add_column_if_not_exists('students', 'stupin', 'character varying(6)');
SELECT add_column_if_not_exists('students', 'stugeocoordinates', 'character varying(40)');
SELECT add_column_if_not_exists('students', 'stubloodgrp', 'character varying(20)');
SELECT add_column_if_not_exists('students', 'stuphoto', 'text');
SELECT add_column_if_not_exists('students', 'stuclass', 'character varying(20) NOT NULL', '''Class 1''');
SELECT add_column_if_not_exists('students', 'con_id', 'integer');
SELECT add_column_if_not_exists('students', 'stucondesc', 'character varying(20)');
SELECT add_column_if_not_exists('students', 'stuser_id', 'character varying(25) NOT NULL', '''USR001''');
SELECT add_column_if_not_exists('students', 'stupassword', 'character varying(255)');
SELECT add_column_if_not_exists('students', 'stumobotp', 'numeric(6,0)');
SELECT add_column_if_not_exists('students', 'stuotpstatus', 'smallint NOT NULL', '0');
SELECT add_column_if_not_exists('students', 'approvedby', 'character varying(50)');
SELECT add_column_if_not_exists('students', 'approveddate', 'timestamp without time zone NOT NULL', 'now()');
SELECT add_column_if_not_exists('students', 'suspendeddate', 'date');
SELECT add_column_if_not_exists('students', 'suspendedby', 'character varying(50)');
SELECT add_column_if_not_exists('students', 'terminateddate', 'date');
SELECT add_column_if_not_exists('students', 'terminatedby', 'character varying(50)');
SELECT add_column_if_not_exists('students', 'activestatus', 'smallint NOT NULL', '1');
SELECT add_column_if_not_exists('students', 'createdon', 'timestamp without time zone NOT NULL', 'now()');

-- ============================================
-- PARENTDETAIL TABLE - Add missing columns
-- ============================================
SELECT add_column_if_not_exists('parentdetail', 'yr_id', 'integer NOT NULL', '1');
SELECT add_column_if_not_exists('parentdetail', 'yrlabel', 'character varying(9)');
SELECT add_column_if_not_exists('parentdetail', 'par_id', 'bigint NOT NULL', '1');
SELECT add_column_if_not_exists('parentdetail', 'stu_id', 'bigint NOT NULL', '1');
SELECT add_column_if_not_exists('parentdetail', 'ins_id', 'integer NOT NULL', '1');
SELECT add_column_if_not_exists('parentdetail', 'inscode', 'character varying(10) NOT NULL', '''INS001''');
SELECT add_column_if_not_exists('parentdetail', 'stuadmno', 'character varying(20) NOT NULL', '''ADM001''');
SELECT add_column_if_not_exists('parentdetail', 'stuname', 'character varying(50) NOT NULL', '''Unknown''');
SELECT add_column_if_not_exists('parentdetail', 'stuclass', 'character varying(20) NOT NULL', '''Class 1''');

-- ============================================
-- INSTITUTION TABLE - Add missing columns
-- ============================================
SELECT add_column_if_not_exists('institution', 'insname', 'character varying(80) NOT NULL', '''Unknown Institution''');
SELECT add_column_if_not_exists('institution', 'inscode', 'character varying(10)');
SELECT add_column_if_not_exists('institution', 'insstadate', 'date NOT NULL', 'CURRENT_DATE');
SELECT add_column_if_not_exists('institution', 'insautusername', 'character varying(50) NOT NULL', '''admin''');
SELECT add_column_if_not_exists('institution', 'insdesignation', 'character varying(30) NOT NULL', '''Principal''');
SELECT add_column_if_not_exists('institution', 'insmobno', 'character varying(25) NOT NULL', '''0000000000''');
SELECT add_column_if_not_exists('institution', 'insmail', 'character varying(254) NOT NULL', '''admin@school.com''');
SELECT add_column_if_not_exists('institution', 'insmailotp', 'numeric(8,0)');
SELECT add_column_if_not_exists('institution', 'insmobotp', 'numeric(6,0)');
SELECT add_column_if_not_exists('institution', 'insotpstatus', 'smallint NOT NULL', '0');
SELECT add_column_if_not_exists('institution', 'it_id', 'integer NOT NULL', '1');
SELECT add_column_if_not_exists('institution', 'insrecognised', 'character(1) NOT NULL', '''Y''');
SELECT add_column_if_not_exists('institution', 'insaffliation', 'character varying(70)');
SELECT add_column_if_not_exists('institution', 'insaffno', 'character varying(25)');
SELECT add_column_if_not_exists('institution', 'insaffdate', 'date');
SELECT add_column_if_not_exists('institution', 'insaffstayear', 'character varying(9)');
SELECT add_column_if_not_exists('institution', 'insaddress1', 'character varying(60) NOT NULL', '''Address Line 1''');
SELECT add_column_if_not_exists('institution', 'insaddress2', 'character varying(60)');
SELECT add_column_if_not_exists('institution', 'insaddress3', 'character varying(60)');
SELECT add_column_if_not_exists('institution', 'cit_id', 'integer NOT NULL', '1');
SELECT add_column_if_not_exists('institution', 'sta_id', 'integer NOT NULL', '1');
SELECT add_column_if_not_exists('institution', 'cou_id', 'integer NOT NULL', '1');
SELECT add_column_if_not_exists('institution', 'inspincode', 'character varying(6) NOT NULL', '''000000''');
SELECT add_column_if_not_exists('institution', 'insipaddress', 'character varying(20) NOT NULL', '''0.0.0.0''');
SELECT add_column_if_not_exists('institution', 'inssername', 'character varying(30) NOT NULL', '''server''');
SELECT add_column_if_not_exists('institution', 'insserurl', 'character varying(80) NOT NULL', '''http://localhost''');
SELECT add_column_if_not_exists('institution', 'insapproved', 'smallint NOT NULL', '0');
SELECT add_column_if_not_exists('institution', 'insactby', 'character varying(30)');
SELECT add_column_if_not_exists('institution', 'insactdate', 'date');
SELECT add_column_if_not_exists('institution', 'insactcode', 'character varying(50)');
SELECT add_column_if_not_exists('institution', 'activestatus', 'smallint NOT NULL', '1');
SELECT add_column_if_not_exists('institution', 'suspendeddate', 'date');
SELECT add_column_if_not_exists('institution', 'suspendedby', 'character varying(50)');
SELECT add_column_if_not_exists('institution', 'suspendedreason', 'character varying(200)');
SELECT add_column_if_not_exists('institution', 'terminateddate', 'date');
SELECT add_column_if_not_exists('institution', 'terminatedby', 'character varying(50)');
SELECT add_column_if_not_exists('institution', 'terminatedreason', 'character varying(200)');
SELECT add_column_if_not_exists('institution', 'updatedby', 'character varying(50) NOT NULL', '''system''');
SELECT add_column_if_not_exists('institution', 'updateddate', 'date NOT NULL', 'CURRENT_DATE');

-- ============================================
-- INSTITUTIONUSERS TABLE - Add missing columns
-- ============================================
SELECT add_column_if_not_exists('institutionusers', 'ins_id', 'integer');
SELECT add_column_if_not_exists('institutionusers', 'inscode', 'character varying(10) NOT NULL', '''INS001''');
SELECT add_column_if_not_exists('institutionusers', 'usename', 'character varying(50) NOT NULL', '''Unknown''');
SELECT add_column_if_not_exists('institutionusers', 'usemail', 'character varying(254) NOT NULL', '''user@school.com''');
SELECT add_column_if_not_exists('institutionusers', 'usephone', 'character varying(30) NOT NULL', '''0000000000''');
SELECT add_column_if_not_exists('institutionusers', 'usepassword', 'character varying(250)');
SELECT add_column_if_not_exists('institutionusers', 'usestadate', 'date NOT NULL', 'CURRENT_DATE');
SELECT add_column_if_not_exists('institutionusers', 'usemaiotp', 'numeric(8,0)');
SELECT add_column_if_not_exists('institutionusers', 'usemobotp', 'numeric(6,0)');
SELECT add_column_if_not_exists('institutionusers', 'useotpstatus', 'smallint NOT NULL', '0');
SELECT add_column_if_not_exists('institutionusers', 'usedob', 'date NOT NULL', 'CURRENT_DATE');
SELECT add_column_if_not_exists('institutionusers', 'usecategory', 'character varying(30)');
SELECT add_column_if_not_exists('institutionusers', 'ur_id', 'integer NOT NULL', '1');
SELECT add_column_if_not_exists('institutionusers', 'urname', 'character varying(50) NOT NULL', '''User''');
SELECT add_column_if_not_exists('institutionusers', 'des_id', 'integer NOT NULL', '1');
SELECT add_column_if_not_exists('institutionusers', 'desname', 'character varying(50) NOT NULL', '''Staff''');
SELECT add_column_if_not_exists('institutionusers', 'userepto', 'integer NOT NULL', '0');
SELECT add_column_if_not_exists('institutionusers', 'approvedby', 'character varying(50)');
SELECT add_column_if_not_exists('institutionusers', 'approveddate', 'timestamp without time zone', 'now()');
SELECT add_column_if_not_exists('institutionusers', 'suspendeddate', 'date');
SELECT add_column_if_not_exists('institutionusers', 'suspendedby', 'character varying(50)');
SELECT add_column_if_not_exists('institutionusers', 'terminateddate', 'date');
SELECT add_column_if_not_exists('institutionusers', 'terminatedby', 'character varying(50)');
SELECT add_column_if_not_exists('institutionusers', 'activestatus', 'smallint NOT NULL', '1');

-- ============================================
-- CHALLAN TABLE - Add missing columns
-- ============================================
SELECT add_column_if_not_exists('challan', 'ins_id', 'integer');
SELECT add_column_if_not_exists('challan', 'inscode', 'character varying(10) NOT NULL', '''INS001''');
SELECT add_column_if_not_exists('challan', 'yr_id', 'integer');
SELECT add_column_if_not_exists('challan', 'yrlabel', 'character varying(9)');
SELECT add_column_if_not_exists('challan', 'stu_id', 'bigint NOT NULL', '1');
SELECT add_column_if_not_exists('challan', 'stuadmno', 'character varying(20) NOT NULL', '''ADM001''');
SELECT add_column_if_not_exists('challan', 'stuname', 'character varying(50) NOT NULL', '''Unknown''');
SELECT add_column_if_not_exists('challan', 'chano', 'character varying(25) NOT NULL', '''CHA001''');
SELECT add_column_if_not_exists('challan', 'fcseqtype', 'character varying(20) NOT NULL', '''FEE''');
SELECT add_column_if_not_exists('challan', 'stuclass', 'character varying(20) NOT NULL', '''Class 1''');
SELECT add_column_if_not_exists('challan', 'feeamount', 'numeric(15,2) NOT NULL', '0');
SELECT add_column_if_not_exists('challan', 'fcduedate', 'date NOT NULL', 'CURRENT_DATE');
SELECT add_column_if_not_exists('challan', 'partialpayment', 'character(1) NOT NULL', '''N''');
SELECT add_column_if_not_exists('challan', 'paidamount', 'numeric(15,2)', '0');
SELECT add_column_if_not_exists('challan', 'balancedue', 'numeric(15,2)');
SELECT add_column_if_not_exists('challan', 'paidstatus', 'character(1) NOT NULL', '''U''');
SELECT add_column_if_not_exists('challan', 'createdby', 'character varying(50) NOT NULL', '''system''');
SELECT add_column_if_not_exists('challan', 'createdat', 'timestamp without time zone NOT NULL', 'now()');
SELECT add_column_if_not_exists('challan', 'activestatus', 'smallint NOT NULL', '1');

-- ============================================
-- FEEDEMAND TABLE - Add missing columns
-- ============================================
SELECT add_column_if_not_exists('feedemand', 'demno', 'character varying(30) NOT NULL', '''DEM001''');
SELECT add_column_if_not_exists('feedemand', 'demseqtype', 'character varying(20) NOT NULL', '''FEE''');
SELECT add_column_if_not_exists('feedemand', 'ins_id', 'integer NOT NULL', '1');
SELECT add_column_if_not_exists('feedemand', 'inscode', 'character varying(10) NOT NULL', '''INS001''');
SELECT add_column_if_not_exists('feedemand', 'yr_id', 'integer NOT NULL', '1');
SELECT add_column_if_not_exists('feedemand', 'stu_id', 'bigint');
SELECT add_column_if_not_exists('feedemand', 'stuadmno', 'character varying(25) NOT NULL', '''ADM001''');
SELECT add_column_if_not_exists('feedemand', 'stuclass', 'character varying(20) NOT NULL', '''Class 1''');
SELECT add_column_if_not_exists('feedemand', 'demfeeyear', 'character varying(9) NOT NULL', '''2024-25''');
SELECT add_column_if_not_exists('feedemand', 'demfeeterm', 'character varying(20) NOT NULL', '''Term 1''');
SELECT add_column_if_not_exists('feedemand', 'demfeetype', 'character varying(30) NOT NULL', '''Tuition''');
SELECT add_column_if_not_exists('feedemand', 'demfeecategory', 'character varying(20)');
SELECT add_column_if_not_exists('feedemand', 'feeamount', 'numeric(12,2) NOT NULL', '0');
SELECT add_column_if_not_exists('feedemand', 'con_id', 'integer');
SELECT add_column_if_not_exists('feedemand', 'conamount', 'numeric(12,2)', '0');
SELECT add_column_if_not_exists('feedemand', 'paidamount', 'numeric(12,2)', '0');
SELECT add_column_if_not_exists('feedemand', 'balancedue', 'numeric(12,2)');
SELECT add_column_if_not_exists('feedemand', 'duedate', 'date NOT NULL', 'CURRENT_DATE');
SELECT add_column_if_not_exists('feedemand', 'pay_id', 'integer');
SELECT add_column_if_not_exists('feedemand', 'paidstatus', 'character(1) NOT NULL', '''U''');
SELECT add_column_if_not_exists('feedemand', 'createdby', 'character varying(50) NOT NULL', '''system''');
SELECT add_column_if_not_exists('feedemand', 'createdat', 'timestamp without time zone NOT NULL', 'now()');
SELECT add_column_if_not_exists('feedemand', 'activestatus', 'smallint NOT NULL', '1');
SELECT add_column_if_not_exists('feedemand', 'inactivedate', 'timestamp without time zone');
SELECT add_column_if_not_exists('feedemand', 'remarks', 'character varying(50)');

-- ============================================
-- MODULES TABLE - Add missing columns
-- ============================================
SELECT add_column_if_not_exists('modules', 'ins_id', 'integer NOT NULL', '1');
SELECT add_column_if_not_exists('modules', 'modtype', 'character(1) NOT NULL', '''A''');
SELECT add_column_if_not_exists('modules', 'modname', 'character varying(30) NOT NULL', '''Module''');
SELECT add_column_if_not_exists('modules', 'modshort', 'character varying(11) NOT NULL', '''MOD''');
SELECT add_column_if_not_exists('modules', 'createdon', 'date NOT NULL', 'CURRENT_DATE');
SELECT add_column_if_not_exists('modules', 'activestatus', 'smallint NOT NULL', '1');

-- ============================================
-- ACTIVITYTYPE TABLE - Add missing columns
-- ============================================
SELECT add_column_if_not_exists('activitytype', 'ins_id', 'integer NOT NULL', '1');
SELECT add_column_if_not_exists('activitytype', 'mod_id', 'integer NOT NULL', '1');
SELECT add_column_if_not_exists('activitytype', 'actname', 'character varying(30) NOT NULL', '''Activity''');
SELECT add_column_if_not_exists('activitytype', 'actshort', 'character varying(10) NOT NULL', '''ACT''');
SELECT add_column_if_not_exists('activitytype', 'seqapplicable', 'character(1) NOT NULL', '''N''');
SELECT add_column_if_not_exists('activitytype', 'createdon', 'timestamp without time zone NOT NULL', 'now()');
SELECT add_column_if_not_exists('activitytype', 'activestatus', 'smallint NOT NULL', '1');

-- ============================================
-- SEQUENCE TABLE - Add missing columns
-- ============================================
SELECT add_column_if_not_exists('sequence', 'ins_id', 'integer NOT NULL', '1');
SELECT add_column_if_not_exists('sequence', 'mod_id', 'integer NOT NULL', '1');
SELECT add_column_if_not_exists('sequence', 'yr_id', 'integer NOT NULL', '1');
SELECT add_column_if_not_exists('sequence', 'yrlabel', 'character varying(9) NOT NULL', '''2024-25''');
SELECT add_column_if_not_exists('sequence', 'actname', 'character varying(30) NOT NULL', '''Activity''');
SELECT add_column_if_not_exists('sequence', 'seqname', 'character varying(10) NOT NULL', '''SEQ''');
SELECT add_column_if_not_exists('sequence', 'isprefix', 'character(1) NOT NULL', '''Y''');
SELECT add_column_if_not_exists('sequence', 'seqprefix', 'character varying(8) NOT NULL', '''PRE''');
SELECT add_column_if_not_exists('sequence', 'seqstart', 'numeric(9,0) NOT NULL', '1');
SELECT add_column_if_not_exists('sequence', 'seqwidth', 'numeric(1,0) NOT NULL', '5');
SELECT add_column_if_not_exists('sequence', 'sequid', 'character varying(18) NOT NULL', '''SEQ001''');
SELECT add_column_if_not_exists('sequence', 'seqcurno', 'numeric(9,0) NOT NULL', '1');
SELECT add_column_if_not_exists('sequence', 'createdon', 'timestamp without time zone NOT NULL', 'now()');
SELECT add_column_if_not_exists('sequence', 'activestatus', 'smallint NOT NULL', '1');

-- ============================================
-- Other tables - Add columns as needed
-- ============================================

-- INSTITUTIONYEAR
SELECT add_column_if_not_exists('institutionyear', 'ins_id', 'integer NOT NULL', '1');
SELECT add_column_if_not_exists('institutionyear', 'inscode', 'character varying(10) NOT NULL', '''INS001''');
SELECT add_column_if_not_exists('institutionyear', 'yrlabel', 'character varying(9) NOT NULL', '''2024-25''');
SELECT add_column_if_not_exists('institutionyear', 'iyrstadate', 'date NOT NULL', 'CURRENT_DATE');
SELECT add_column_if_not_exists('institutionyear', 'iyrenddate', 'date NOT NULL', 'CURRENT_DATE');
SELECT add_column_if_not_exists('institutionyear', 'iyearsubstatus', 'smallint NOT NULL', '1');
SELECT add_column_if_not_exists('institutionyear', 'iyearsubsdate', 'date');
SELECT add_column_if_not_exists('institutionyear', 'sub_id', 'integer');
SELECT add_column_if_not_exists('institutionyear', 'iyrschema', 'character varying(20)');
SELECT add_column_if_not_exists('institutionyear', 'iyearlicencekey', 'text');
SELECT add_column_if_not_exists('institutionyear', 'terminatedby', 'character varying(50)');
SELECT add_column_if_not_exists('institutionyear', 'terminatedon', 'date');
SELECT add_column_if_not_exists('institutionyear', 'iyrnotes', 'character varying(100)');
SELECT add_column_if_not_exists('institutionyear', 'createdon', 'timestamp without time zone NOT NULL', 'now()');
SELECT add_column_if_not_exists('institutionyear', 'activestatus', 'smallint NOT NULL', '1');

-- CUSTUSERROLES
SELECT add_column_if_not_exists('custuserroles', 'ins_id', 'integer NOT NULL', '1');
SELECT add_column_if_not_exists('custuserroles', 'inscode', 'character varying(10) NOT NULL', '''INS001''');
SELECT add_column_if_not_exists('custuserroles', 'urname', 'character varying(50) NOT NULL', '''Role''');
SELECT add_column_if_not_exists('custuserroles', 'activestatus', 'smallint NOT NULL', '1');

-- STAFFDESIGNATION
SELECT add_column_if_not_exists('staffdesignation', 'ins_id', 'integer NOT NULL', '1');
SELECT add_column_if_not_exists('staffdesignation', 'desname', 'character varying(50) NOT NULL', '''Designation''');
SELECT add_column_if_not_exists('staffdesignation', 'desrepto', 'integer');
SELECT add_column_if_not_exists('staffdesignation', 'activestatus', 'smallint NOT NULL', '1');

-- PAYMENT
SELECT add_column_if_not_exists('payment', 'yr_id', 'integer NOT NULL', '1');
SELECT add_column_if_not_exists('payment', 'yrlabel', 'character varying(9)');
SELECT add_column_if_not_exists('payment', 'ins_id', 'integer NOT NULL', '1');
SELECT add_column_if_not_exists('payment', 'inscode', 'character varying(10)');
SELECT add_column_if_not_exists('payment', 'car_id', 'integer');
SELECT add_column_if_not_exists('payment', 'paydate', 'timestamp without time zone');
SELECT add_column_if_not_exists('payment', 'paystatus', 'character(1)');
SELECT add_column_if_not_exists('payment', 'paymethod', 'character varying(60)');
SELECT add_column_if_not_exists('payment', 'payreference', 'character varying(100)');
SELECT add_column_if_not_exists('payment', 'paygwresponse', 'numeric(15,0)');
SELECT add_column_if_not_exists('payment', 'createdat', 'timestamp without time zone NOT NULL', 'now()');
SELECT add_column_if_not_exists('payment', 'activestatus', 'smallint NOT NULL', '1');

-- SHOPPINGCART
SELECT add_column_if_not_exists('shoppingcart', 'yr_id', 'integer NOT NULL', '1');
SELECT add_column_if_not_exists('shoppingcart', 'yrlabel', 'character varying(9)');
SELECT add_column_if_not_exists('shoppingcart', 'ins_id', 'integer NOT NULL', '1');
SELECT add_column_if_not_exists('shoppingcart', 'transtype', 'character varying(10) NOT NULL', '''FEE''');
SELECT add_column_if_not_exists('shoppingcart', 'transdate', 'date NOT NULL', 'CURRENT_DATE');
SELECT add_column_if_not_exists('shoppingcart', 'transcurrency', 'character varying(20) NOT NULL', '''INR''');
SELECT add_column_if_not_exists('shoppingcart', 'transtotalamount', 'numeric(12,2) NOT NULL', '0');
SELECT add_column_if_not_exists('shoppingcart', 'carinitiated', 'character(1) NOT NULL', '''N''');
SELECT add_column_if_not_exists('shoppingcart', 'pay_id', 'integer');
SELECT add_column_if_not_exists('shoppingcart', 'createdby', 'character varying(50) NOT NULL', '''system''');
SELECT add_column_if_not_exists('shoppingcart', 'createdon', 'timestamp without time zone NOT NULL', 'now()');
SELECT add_column_if_not_exists('shoppingcart', 'activestatus', 'smallint NOT NULL', '1');

-- SHOPPINGCARTDETAILS
SELECT add_column_if_not_exists('shoppingcartdetails', 'yr_id', 'integer NOT NULL', '1');
SELECT add_column_if_not_exists('shoppingcartdetails', 'yrlabel', 'character varying(9)');
SELECT add_column_if_not_exists('shoppingcartdetails', 'car_id', 'integer NOT NULL', '1');
SELECT add_column_if_not_exists('shoppingcartdetails', 'ins_id', 'integer NOT NULL', '1');
SELECT add_column_if_not_exists('shoppingcartdetails', 'transdetail_id', 'integer');
SELECT add_column_if_not_exists('shoppingcartdetails', 'transcurrency', 'character varying(20) NOT NULL', '''INR''');
SELECT add_column_if_not_exists('shoppingcartdetails', 'transtotalamount', 'numeric(12,2) NOT NULL', '0');
SELECT add_column_if_not_exists('shoppingcartdetails', 'activestatus', 'smallint NOT NULL', '1');

-- USERLOGIN
SELECT add_column_if_not_exists('userlogin', 'ins_id', 'integer NOT NULL', '1');
SELECT add_column_if_not_exists('userlogin', 'inscode', 'character varying(10) NOT NULL', '''INS001''');
SELECT add_column_if_not_exists('userlogin', 'yr_id', 'integer NOT NULL', '1');
SELECT add_column_if_not_exists('userlogin', 'yrlabel', 'character varying(9)');
SELECT add_column_if_not_exists('userlogin', 'uluser', 'character varying(50)');
SELECT add_column_if_not_exists('userlogin', 'ulusetype', 'smallint');
SELECT add_column_if_not_exists('userlogin', 'ultime', 'timestamp without time zone');
SELECT add_column_if_not_exists('userlogin', 'ulattempt', 'smallint', '0');
SELECT add_column_if_not_exists('userlogin', 'ulip', 'character varying(40)');
SELECT add_column_if_not_exists('userlogin', 'ullocation', 'character varying(50)');
SELECT add_column_if_not_exists('userlogin', 'ulsuccess', 'character(1) NOT NULL', '''N''');
SELECT add_column_if_not_exists('userlogin', 'ulsesid', 'numeric');
SELECT add_column_if_not_exists('userlogin', 'ulsesstart', 'timestamp without time zone NOT NULL', 'now()');
SELECT add_column_if_not_exists('userlogin', 'ulsesend', 'timestamp without time zone');
SELECT add_column_if_not_exists('userlogin', 'ulsestime', 'timestamp without time zone');

-- ============================================
-- Cleanup helper function (optional)
-- ============================================
-- DROP FUNCTION IF EXISTS add_column_if_not_exists;

-- ============================================
-- DONE!
-- ============================================
SELECT 'Schema ALTER migration completed!' as status;
