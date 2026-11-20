-- ============================================
-- Krishnasamy Institution - Supabase Schema Migration
-- Run this script on Supabase to update schema
-- ============================================

-- First, create the email domain if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'email') THEN
        CREATE DOMAIN email AS character varying(254)
        CHECK (VALUE ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');
    END IF;
END $$;

-- ============================================
-- CURRENCY TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.currency
(
    cur_id integer NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
    curname character varying(30) NOT NULL,
    curshort character varying(10) NOT NULL,
    cursymbol character(1) NOT NULL,
    curdecpoints integer NOT NULL,
    curdecname character varying(10) NOT NULL,
    createdon date NOT NULL DEFAULT CURRENT_DATE,
    activestatus smallint NOT NULL DEFAULT 1,
    CONSTRAINT currency_pkey PRIMARY KEY (cur_id),
    CONSTRAINT currency_activestatus_check CHECK (activestatus = ANY (ARRAY[0, 1]))
);

-- ============================================
-- INSTITUTIONTYPE TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.institutiontype
(
    it_id integer NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
    ittype character varying(20) NOT NULL,
    activestatus smallint NOT NULL DEFAULT 1,
    CONSTRAINT institutiontype_pkey PRIMARY KEY (it_id),
    CONSTRAINT institutiontype_ittype_key UNIQUE (ittype),
    CONSTRAINT institutiontype_activestatus_check CHECK (activestatus = ANY (ARRAY[1, 2, 9]))
);

-- ============================================
-- YEAR TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.year
(
    yr_id integer NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
    ins_id integer NOT NULL,
    yrlabel character varying(9) NOT NULL,
    yrstadate date NOT NULL,
    yrenddate date NOT NULL,
    createdon timestamp without time zone NOT NULL DEFAULT now(),
    activestatus smallint NOT NULL DEFAULT 1,
    CONSTRAINT year_pkey PRIMARY KEY (yr_id),
    CONSTRAINT chk_year_dates CHECK (yrstadate <= yrenddate),
    CONSTRAINT year_activestatus_check CHECK (activestatus = ANY (ARRAY[0, 1]))
);

-- ============================================
-- CONCESSIONCATEGORY TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.concessioncategory
(
    con_id integer NOT NULL,
    condesc character varying(20) NOT NULL,
    ins_id integer NOT NULL,
    ordid integer,
    activestatus smallint NOT NULL DEFAULT 1,
    CONSTRAINT concessioncategory_pkey PRIMARY KEY (con_id),
    CONSTRAINT concessioncategory_activiestatus_check CHECK (activestatus = ANY (ARRAY[0, 1]))
);

-- ============================================
-- PAYMENTGATEWAY TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.paymentgateway
(
    gw_id integer NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
    gwname character varying(100) NOT NULL,
    gwapikey character varying(255),
    gwapisecret character varying(255),
    activestatus smallint NOT NULL DEFAULT 1,
    CONSTRAINT paymentgateway_pkey PRIMARY KEY (gw_id),
    CONSTRAINT paymentgateway_activestatus_check CHECK (activestatus = ANY (ARRAY[0, 1]))
);

-- ============================================
-- PAYMENT TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.payment
(
    pay_id integer NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
    yr_id integer NOT NULL,
    yrlabel character varying(9),
    ins_id integer NOT NULL,
    inscode character varying(10),
    car_id integer,
    paydate timestamp without time zone,
    paystatus character(1),
    paymethod character varying(60),
    payreference character varying(100),
    paygwresponse numeric(15,0),
    createdat timestamp without time zone NOT NULL DEFAULT now(),
    activestatus smallint NOT NULL DEFAULT 1,
    CONSTRAINT payment_pkey PRIMARY KEY (pay_id),
    CONSTRAINT payment_yr_id_fkey FOREIGN KEY (yr_id) REFERENCES public.year (yr_id),
    CONSTRAINT payment_activestatus_check CHECK (activestatus = ANY (ARRAY[0, 1])),
    CONSTRAINT payment_paystatus_check CHECK (paystatus = ANY (ARRAY['I'::bpchar, 'C'::bpchar, 'F'::bpchar, 'R'::bpchar]))
);

-- ============================================
-- SHOPPINGCART TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.shoppingcart
(
    car_id integer NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
    yr_id integer NOT NULL,
    yrlabel character varying(9),
    ins_id integer NOT NULL,
    transtype character varying(10) NOT NULL,
    transdate date NOT NULL,
    transcurrency character varying(20) NOT NULL,
    transtotalamount numeric(12,2) NOT NULL,
    carinitiated character(1) NOT NULL,
    pay_id integer,
    createdby character varying(50) NOT NULL,
    createdon timestamp without time zone NOT NULL DEFAULT now(),
    activestatus smallint NOT NULL DEFAULT 1,
    CONSTRAINT shoppingcart_pkey PRIMARY KEY (car_id),
    CONSTRAINT shoppingcart_yr_id_fkey FOREIGN KEY (yr_id) REFERENCES public.year (yr_id),
    CONSTRAINT shoppingcart_activestatus_check CHECK (activestatus = ANY (ARRAY[0, 1])),
    CONSTRAINT shoppingcart_carinitiated_check CHECK (carinitiated = ANY (ARRAY['N'::bpchar, 'I'::bpchar, 'F'::bpchar]))
);

-- ============================================
-- MODULES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.modules
(
    mod_id integer NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
    ins_id integer NOT NULL,
    modtype character(1) NOT NULL,
    modname character varying(30) NOT NULL,
    modshort character varying(11) NOT NULL,
    createdon date NOT NULL DEFAULT CURRENT_DATE,
    activestatus smallint NOT NULL DEFAULT 1,
    CONSTRAINT modules_pkey PRIMARY KEY (mod_id),
    CONSTRAINT modules_activestatus_check CHECK (activestatus = ANY (ARRAY[0, 1])),
    CONSTRAINT modules_modtype_check CHECK (modtype = ANY (ARRAY['A'::bpchar, 'C'::bpchar]))
);

-- ============================================
-- INSTITUTIONYEAR TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.institutionyear
(
    iyr_id integer NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
    ins_id integer NOT NULL,
    inscode character varying(10) NOT NULL,
    yrlabel character varying(9) NOT NULL,
    iyrstadate date NOT NULL,
    iyrenddate date NOT NULL,
    iyearsubstatus smallint NOT NULL DEFAULT 1,
    iyearsubsdate date,
    sub_id integer,
    iyrschema character varying(20),
    iyearlicencekey text,
    terminatedby character varying(50),
    terminatedon date,
    iyrnotes character varying(100),
    createdon timestamp without time zone NOT NULL DEFAULT now(),
    activestatus smallint NOT NULL DEFAULT 1,
    CONSTRAINT institution_year_pkey PRIMARY KEY (iyr_id),
    CONSTRAINT chk_instyear_dates CHECK (iyrstadate <= iyrenddate),
    CONSTRAINT institution_year_activestatus_check CHECK (activestatus = ANY (ARRAY[0, 1])),
    CONSTRAINT institution_year_iyearsubstatus_check CHECK (iyearsubstatus = ANY (ARRAY[0, 1]))
);

-- ============================================
-- COUNTRY TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.country
(
    cou_id integer NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
    cou_name character varying(35) NOT NULL,
    cur_id integer NOT NULL,
    coutimezone timestamp with time zone NOT NULL DEFAULT now(),
    createdon date NOT NULL DEFAULT CURRENT_DATE,
    activestatus smallint NOT NULL DEFAULT 1,
    CONSTRAINT country_pkey PRIMARY KEY (cou_id),
    CONSTRAINT country_activestatus_check CHECK (activestatus = ANY (ARRAY[0, 1]))
);

-- ============================================
-- STATE TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.state
(
    sta_id integer NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
    staname character varying(35) NOT NULL,
    cou_id integer NOT NULL,
    createdon date NOT NULL DEFAULT CURRENT_DATE,
    activestatus smallint NOT NULL DEFAULT 1,
    CONSTRAINT state_pkey PRIMARY KEY (sta_id),
    CONSTRAINT state_cou_id_fkey FOREIGN KEY (cou_id) REFERENCES public.country (cou_id),
    CONSTRAINT state_activestatus_check CHECK (activestatus = ANY (ARRAY[0, 1]))
);

-- ============================================
-- CITY TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.city
(
    cit_id integer NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
    citname character varying(50) NOT NULL,
    sta_id integer NOT NULL,
    cou_id integer NOT NULL,
    createdon date NOT NULL DEFAULT CURRENT_DATE,
    activestatus smallint NOT NULL DEFAULT 1,
    CONSTRAINT city_pkey PRIMARY KEY (cit_id),
    CONSTRAINT city_cou_id_fkey FOREIGN KEY (cou_id) REFERENCES public.country (cou_id),
    CONSTRAINT city_sta_id_fkey FOREIGN KEY (sta_id) REFERENCES public.state (sta_id),
    CONSTRAINT city_activestatus_check CHECK (activestatus = ANY (ARRAY[0, 1]))
);

-- ============================================
-- INSTITUTION TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.institution
(
    ins_id integer NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
    insname character varying(80) NOT NULL,
    inscode character varying(10),
    insstadate date NOT NULL DEFAULT CURRENT_DATE,
    insautusername character varying(50) NOT NULL,
    insdesignation character varying(30) NOT NULL,
    insmobno character varying(25) NOT NULL,
    insmail email NOT NULL,
    insmailotp numeric(8,0),
    insmobotp numeric(6,0),
    insotpstatus smallint NOT NULL DEFAULT 0,
    it_id integer NOT NULL,
    insrecognised character(1) NOT NULL,
    insaffliation character varying(70),
    insaffno character varying(25),
    insaffdate date,
    insaffstayear character varying(9),
    insaddress1 character varying(60) NOT NULL,
    insaddress2 character varying(60),
    insaddress3 character varying(60),
    cit_id integer NOT NULL,
    sta_id integer NOT NULL,
    cou_id integer NOT NULL,
    inspincode character varying(6) NOT NULL,
    insipaddress character varying(20) NOT NULL,
    inssername character varying(30) NOT NULL,
    insserurl character varying(80) NOT NULL,
    insapproved smallint NOT NULL DEFAULT 0,
    insactby character varying(30),
    insactdate date,
    insactcode character varying(50),
    activestatus smallint NOT NULL DEFAULT 1,
    suspendeddate date,
    suspendedby character varying(50),
    suspendedreason character varying(200),
    terminateddate date,
    terminatedby character varying(50),
    terminatedreason character varying(200),
    updatedby character varying(50) NOT NULL,
    updateddate date NOT NULL DEFAULT CURRENT_DATE,
    CONSTRAINT institution_pkey PRIMARY KEY (ins_id),
    CONSTRAINT institution_cit_id_fkey FOREIGN KEY (cit_id) REFERENCES public.city (cit_id),
    CONSTRAINT institution_cou_id_fkey FOREIGN KEY (cou_id) REFERENCES public.country (cou_id),
    CONSTRAINT institution_it_id_fkey FOREIGN KEY (it_id) REFERENCES public.institutiontype (it_id),
    CONSTRAINT institution_activestatus_check CHECK (activestatus = ANY (ARRAY[1, 2, 9])),
    CONSTRAINT institution_insapproved_check CHECK (insapproved = ANY (ARRAY[0, 1])),
    CONSTRAINT institution_insotpstatus_check CHECK (insotpstatus = ANY (ARRAY[0, 1, 2])),
    CONSTRAINT institution_insrecognised_check CHECK (insrecognised = ANY (ARRAY['Y'::bpchar, 'N'::bpchar]))
);

CREATE UNIQUE INDEX IF NOT EXISTS unique_inscode ON public.institution USING btree (lower(inscode::text));

-- ============================================
-- CUSTUSERROLES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.custuserroles
(
    ur_id integer NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
    ins_id integer NOT NULL,
    inscode character varying(10) NOT NULL,
    urname character varying(50) NOT NULL,
    activestatus smallint NOT NULL DEFAULT 1,
    CONSTRAINT custuserroles_pkey PRIMARY KEY (ur_id),
    CONSTRAINT custuserroles_unique_role UNIQUE (ins_id, urname),
    CONSTRAINT custuserroles_activestatus_check CHECK (activestatus = ANY (ARRAY[1, 2, 9]))
);

-- ============================================
-- STAFFDESIGNATION TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.staffdesignation
(
    des_id integer NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
    ins_id integer NOT NULL,
    desname character varying(50) NOT NULL,
    desrepto integer,
    activestatus smallint NOT NULL DEFAULT 1,
    CONSTRAINT staffdesignation_pkey PRIMARY KEY (des_id),
    CONSTRAINT uniq_staffdesignation UNIQUE (ins_id, desname),
    CONSTRAINT fk_staffdesignation_repto FOREIGN KEY (desrepto) REFERENCES public.staffdesignation (des_id),
    CONSTRAINT staffdesignation_activestatus_check CHECK (activestatus = ANY (ARRAY[1, 2, 9]))
);

-- ============================================
-- INSTITUTIONUSERS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.institutionusers
(
    use_id integer NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
    ins_id integer,
    inscode character varying(10) NOT NULL,
    usename character varying(50) NOT NULL,
    usemail email NOT NULL,
    usephone character varying(30) NOT NULL,
    usepassword character varying(250),
    usestadate date NOT NULL DEFAULT CURRENT_DATE,
    usemaiotp numeric(8,0),
    usemobotp numeric(6,0),
    useotpstatus smallint NOT NULL DEFAULT 0,
    usedob date NOT NULL,
    usecategory character varying(30),
    ur_id integer NOT NULL,
    urname character varying(50) NOT NULL,
    des_id integer NOT NULL,
    desname character varying(50) NOT NULL,
    userepto integer NOT NULL,
    approvedby character varying(50),
    approveddate timestamp without time zone DEFAULT now(),
    suspendeddate date,
    suspendedby character varying(50),
    terminateddate date,
    terminatedby character varying(50),
    activestatus smallint NOT NULL DEFAULT 1,
    CONSTRAINT institutionusers_pkey PRIMARY KEY (use_id),
    CONSTRAINT institutionusers_des_id_fkey FOREIGN KEY (des_id) REFERENCES public.staffdesignation (des_id),
    CONSTRAINT institutionusers_ur_id_fkey FOREIGN KEY (ur_id) REFERENCES public.custuserroles (ur_id),
    CONSTRAINT institutionusers_useactstatus_check CHECK (activestatus = ANY (ARRAY[1, 2, 9])),
    CONSTRAINT institutionusers_useotpstatus_check CHECK (useotpstatus = ANY (ARRAY[0, 1, 2]))
);

-- ============================================
-- ACTIVITYTYPE TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.activitytype
(
    act_id integer NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
    ins_id integer NOT NULL,
    mod_id integer NOT NULL,
    actname character varying(30) NOT NULL,
    actshort character varying(10) NOT NULL,
    seqapplicable character(1) NOT NULL,
    createdon timestamp without time zone NOT NULL DEFAULT now(),
    activestatus smallint NOT NULL DEFAULT 1,
    CONSTRAINT activitytype_pkey PRIMARY KEY (act_id),
    CONSTRAINT fk_activitytype_module FOREIGN KEY (mod_id) REFERENCES public.modules (mod_id),
    CONSTRAINT activitytype_activestatus_check CHECK (activestatus = ANY (ARRAY[0, 1])),
    CONSTRAINT activitytype_seqapplicable_check CHECK (seqapplicable = ANY (ARRAY['Y'::bpchar, 'N'::bpchar]))
);

-- ============================================
-- SEQUENCE TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.sequence
(
    seq_id integer NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
    ins_id integer NOT NULL,
    mod_id integer NOT NULL,
    yr_id integer NOT NULL,
    yrlabel character varying(9) NOT NULL,
    actname character varying(30) NOT NULL,
    seqname character varying(10) NOT NULL,
    isprefix character(1) NOT NULL,
    seqprefix character varying(8) NOT NULL,
    seqstart numeric(9,0) NOT NULL,
    seqwidth numeric(1,0) NOT NULL,
    sequid character varying(18) NOT NULL,
    seqcurno numeric(9,0) NOT NULL,
    createdon timestamp without time zone NOT NULL DEFAULT now(),
    activestatus smallint NOT NULL DEFAULT 1,
    CONSTRAINT sequence_pkey PRIMARY KEY (seq_id),
    CONSTRAINT fk_sequence_year FOREIGN KEY (yr_id) REFERENCES public.year (yr_id),
    CONSTRAINT sequence_activestatus_check CHECK (activestatus = ANY (ARRAY[0, 1])),
    CONSTRAINT sequence_isprefix_check CHECK (isprefix = ANY (ARRAY['Y'::bpchar, 'N'::bpchar]))
);

-- ============================================
-- PARENTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.parents
(
    par_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    yr_id integer NOT NULL,
    yrlabel character varying(9),
    partype character(1) NOT NULL,
    paremail email,
    fathername character varying(50),
    mothername character varying(50),
    guardianname character varying(50),
    fathermobile character varying(20),
    mothermobile character varying(20),
    guardianmobile character varying(20),
    fatheroccupation character varying(60),
    motheroccupation character varying(60),
    guardianoccupation character varying(60),
    payincharge character varying(50) NOT NULL,
    payinchargemob character varying(20) NOT NULL,
    parpassword character varying(255),
    parmobotp numeric(6,0),
    parotpstatus smallint NOT NULL DEFAULT 0,
    approvedby character varying(50),
    approveddate timestamp without time zone DEFAULT now(),
    terminateddate date,
    terminatedby character varying(50),
    activestatus smallint NOT NULL DEFAULT 1,
    CONSTRAINT parents_pkey PRIMARY KEY (par_id),
    CONSTRAINT parents_paremail_key UNIQUE (paremail),
    CONSTRAINT parents_yr_id_fkey FOREIGN KEY (yr_id) REFERENCES public.year (yr_id),
    CONSTRAINT parents_activestatus_check CHECK (activestatus = ANY (ARRAY[1, 2, 9])),
    CONSTRAINT parents_parotpstatus_check CHECK (parotpstatus = ANY (ARRAY[0, 1])),
    CONSTRAINT parents_partype_check CHECK (partype = ANY (ARRAY['P'::bpchar, 'G'::bpchar]))
);

-- ============================================
-- STUDENTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.students
(
    stu_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    ins_id integer NOT NULL,
    inscode character varying(10) NOT NULL,
    yr_id integer NOT NULL,
    yrlabel character varying(9) NOT NULL,
    stuadmno character varying(25) NOT NULL,
    stuadmdate date NOT NULL,
    stuname character varying(50) NOT NULL,
    stugender character(1) NOT NULL,
    studob date NOT NULL,
    stumobile character varying(30) NOT NULL,
    stuemail email,
    stuaddress text,
    stucity character varying(50),
    stustate character varying(50),
    stucountry character varying(50),
    stupin character varying(6),
    stugeocoordinates character varying(40),
    stubloodgrp character varying(20),
    stuphoto text,
    stuclass character varying(20) NOT NULL,
    con_id integer,
    stucondesc character varying(20),
    stuser_id character varying(25) NOT NULL,
    stupassword character varying(255),
    stumobotp numeric(6,0),
    stuotpstatus smallint NOT NULL DEFAULT 0,
    approvedby character varying(50),
    approveddate timestamp without time zone NOT NULL DEFAULT now(),
    suspendeddate date,
    suspendedby character varying(50),
    terminateddate date,
    terminatedby character varying(50),
    activestatus smallint NOT NULL DEFAULT 1,
    createdon timestamp without time zone NOT NULL DEFAULT now(),
    CONSTRAINT students_pkey PRIMARY KEY (stu_id),
    CONSTRAINT students_stuemail_key UNIQUE (stuemail),
    CONSTRAINT uq_students_admission UNIQUE (ins_id, stuadmno),
    CONSTRAINT students_yr_id_fkey FOREIGN KEY (yr_id) REFERENCES public.year (yr_id),
    CONSTRAINT students_activestatus_check CHECK (activestatus = ANY (ARRAY[1, 2, 9])),
    CONSTRAINT students_stu_id_check CHECK (stu_id > 0),
    CONSTRAINT students_stugender_check CHECK (stugender = ANY (ARRAY['M'::bpchar, 'F'::bpchar, 'T'::bpchar])),
    CONSTRAINT students_stuotpstatus_check CHECK (stuotpstatus = ANY (ARRAY[0, 1, 2]))
);

-- ============================================
-- PARENTDETAIL TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.parentdetail
(
    pd_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    yr_id integer NOT NULL,
    yrlabel character varying(9),
    par_id bigint NOT NULL,
    stu_id bigint NOT NULL,
    ins_id integer NOT NULL,
    inscode character varying(10) NOT NULL,
    stuadmno character varying(20) NOT NULL,
    stuname character varying(50) NOT NULL,
    stuclass character varying(20) NOT NULL,
    CONSTRAINT parentdetail_pkey PRIMARY KEY (pd_id),
    CONSTRAINT parentdetail_stuadmno_key UNIQUE (stuadmno),
    CONSTRAINT parentdetail_yr_id_fkey FOREIGN KEY (yr_id) REFERENCES public.year (yr_id)
);

-- ============================================
-- CHALLAN TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.challan
(
    cha_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    ins_id integer,
    inscode character varying(10) NOT NULL,
    yr_id integer,
    yrlabel character varying(9),
    stu_id bigint NOT NULL,
    stuadmno character varying(20) NOT NULL,
    stuname character varying(50) NOT NULL,
    chano character varying(25) NOT NULL,
    fcseqtype character varying(20) NOT NULL,
    stuclass character varying(20) NOT NULL,
    feeamount numeric(15,2) NOT NULL,
    fcduedate date NOT NULL,
    partialpayment character(1) NOT NULL,
    paidamount numeric(15,2) DEFAULT 0,
    balancedue numeric(15,2),
    paidstatus character(1) NOT NULL DEFAULT 'U'::bpchar,
    createdby character varying(50) NOT NULL,
    createdat timestamp without time zone NOT NULL DEFAULT now(),
    activestatus smallint NOT NULL DEFAULT 1,
    CONSTRAINT fk_challan_institution FOREIGN KEY (ins_id) REFERENCES public.institution (ins_id),
    CONSTRAINT fk_challan_year FOREIGN KEY (yr_id) REFERENCES public.year (yr_id),
    CONSTRAINT challan_activestatus_check CHECK (activestatus = ANY (ARRAY[0, 1])),
    CONSTRAINT challan_paidstatus_check CHECK (paidstatus = ANY (ARRAY['P'::bpchar, 'U'::bpchar])),
    CONSTRAINT challan_partialpayment_check CHECK (partialpayment = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])),
    CONSTRAINT chk_challan_amounts CHECK (feeamount >= 0::numeric AND paidamount >= 0::numeric),
    CONSTRAINT chk_challan_balance CHECK (balancedue IS NULL OR balancedue = (feeamount - paidamount))
);

-- ============================================
-- FEEDEMAND TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.feedemand
(
    dem_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1 ),
    demno character varying(30) NOT NULL,
    demseqtype character varying(20) NOT NULL,
    ins_id integer NOT NULL,
    inscode character varying(10) NOT NULL,
    yr_id integer NOT NULL,
    stu_id bigint,
    stuadmno character varying(25) NOT NULL,
    stuclass character varying(20) NOT NULL,
    demfeeyear character varying(9) NOT NULL,
    demfeeterm character varying(20) NOT NULL,
    demfeetype character varying(30) NOT NULL,
    demfeecategory character varying(20),
    feeamount numeric(12,2) NOT NULL,
    con_id integer,
    conamount numeric(12,2) DEFAULT 0,
    paidamount numeric(12,2) DEFAULT 0,
    balancedue numeric(12,2),
    duedate date NOT NULL,
    pay_id integer,
    paidstatus character(1) NOT NULL DEFAULT 'U'::bpchar,
    createdby character varying(50) NOT NULL,
    createdat timestamp without time zone NOT NULL DEFAULT now(),
    activestatus smallint NOT NULL DEFAULT 1,
    inactivedate timestamp without time zone,
    remarks character varying(50),
    CONSTRAINT feedemand_pkey PRIMARY KEY (dem_id),
    CONSTRAINT fk_feedemand_year FOREIGN KEY (yr_id) REFERENCES public.year (yr_id),
    CONSTRAINT feedemand_activestatus_check CHECK (activestatus = ANY (ARRAY[0, 1])),
    CONSTRAINT feedemand_paidstatus_check CHECK (paidstatus = ANY (ARRAY['P'::bpchar, 'U'::bpchar]))
);

-- ============================================
-- SHOPPINGCARTDETAILS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.shoppingcartdetails
(
    cd_id integer NOT NULL GENERATED ALWAYS AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
    yr_id integer NOT NULL,
    yrlabel character varying(9),
    car_id integer NOT NULL,
    ins_id integer NOT NULL,
    transdetail_id integer,
    transcurrency character varying(20) NOT NULL,
    transtotalamount numeric(12,2) NOT NULL,
    activestatus smallint NOT NULL DEFAULT 1,
    CONSTRAINT shoppingcartdetails_pkey PRIMARY KEY (cd_id),
    CONSTRAINT shoppingcartdetails_yr_id_fkey FOREIGN KEY (yr_id) REFERENCES public.year (yr_id),
    CONSTRAINT shoppingcartdetails_activestatus_check CHECK (activestatus = ANY (ARRAY[0, 1]))
);

-- ============================================
-- USERLOGIN TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.userlogin
(
    ul_id bigint NOT NULL,
    ins_id integer NOT NULL,
    inscode character varying(10) NOT NULL,
    yr_id integer NOT NULL,
    yrlabel character varying(9),
    uluser character varying(50),
    ulusetype smallint,
    ultime timestamp without time zone,
    ulattempt smallint DEFAULT 0,
    ulip character varying(40),
    ullocation character varying(50),
    ulsuccess character(1) NOT NULL DEFAULT 'N'::bpchar,
    ulsesid numeric,
    ulsesstart timestamp without time zone NOT NULL DEFAULT now(),
    ulsesend timestamp without time zone,
    ulsestime timestamp without time zone,
    CONSTRAINT userlogin_pkey PRIMARY KEY (ul_id),
    CONSTRAINT fk_userlogin_year FOREIGN KEY (yr_id) REFERENCES public.year (yr_id),
    CONSTRAINT userlogin_ulattempt_check CHECK (ulattempt >= 0 AND ulattempt <= 3),
    CONSTRAINT userlogin_ulsuccess_check CHECK (ulsuccess = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])),
    CONSTRAINT userlogin_ulusetype_check CHECK (ulusetype = ANY (ARRAY[1, 2]))
);

-- ============================================
-- DONE!
-- ============================================
SELECT 'Schema migration completed successfully!' as status;
