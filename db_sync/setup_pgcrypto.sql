-- ============================================
-- Krishnasamy Institution - Password Encryption Setup
-- Using pgcrypto for secure password hashing
-- ============================================

-- 1. Enable pgcrypto extension
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ============================================
-- 2. Function to HASH a password (for registration/password change)
-- ============================================
CREATE OR REPLACE FUNCTION hash_password(plain_password TEXT)
RETURNS TEXT AS $$
BEGIN
    -- Uses bcrypt with automatically generated salt (bf = blowfish/bcrypt)
    RETURN crypt(plain_password, gen_salt('bf', 10));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 3. Function to VERIFY a password (for login)
-- ============================================
CREATE OR REPLACE FUNCTION verify_password(plain_password TEXT, hashed_password TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    -- Compare the plain password with the stored hash
    RETURN hashed_password = crypt(plain_password, hashed_password);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 4. Function to hash password for PARENTS table
-- ============================================
CREATE OR REPLACE FUNCTION hash_parent_password(
    p_par_id BIGINT,
    p_plain_password TEXT
)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE public.parents
    SET parpassword = crypt(p_plain_password, gen_salt('bf', 10))
    WHERE par_id = p_par_id;

    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 5. Function to verify PARENT login
-- ============================================
CREATE OR REPLACE FUNCTION verify_parent_login(
    p_email TEXT,
    p_plain_password TEXT
)
RETURNS TABLE(
    par_id BIGINT,
    paremail TEXT,
    payincharge TEXT,
    is_valid BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.par_id,
        p.paremail::TEXT,
        p.payincharge,
        (p.parpassword = crypt(p_plain_password, p.parpassword)) as is_valid
    FROM public.parents p
    WHERE p.paremail = p_email
    AND p.activestatus = 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 6. Function to hash password for STUDENTS table
-- ============================================
CREATE OR REPLACE FUNCTION hash_student_password(
    p_stu_id BIGINT,
    p_plain_password TEXT
)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE public.students
    SET stupassword = crypt(p_plain_password, gen_salt('bf', 10))
    WHERE stu_id = p_stu_id;

    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 7. Function to verify STUDENT login
-- ============================================
CREATE OR REPLACE FUNCTION verify_student_login(
    p_user_id TEXT,
    p_plain_password TEXT
)
RETURNS TABLE(
    stu_id BIGINT,
    stuadmno TEXT,
    stuname TEXT,
    stuclass TEXT,
    is_valid BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        s.stu_id,
        s.stuadmno::TEXT,
        s.stuname,
        s.stuclass,
        (s.stupassword = crypt(p_plain_password, s.stupassword)) as is_valid
    FROM public.students s
    WHERE s.stuser_id = p_user_id
    AND s.activestatus = 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 8. Function to hash password for INSTITUTIONUSERS table
-- ============================================
CREATE OR REPLACE FUNCTION hash_user_password(
    p_use_id INTEGER,
    p_plain_password TEXT
)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE public.institutionusers
    SET usepassword = crypt(p_plain_password, gen_salt('bf', 10))
    WHERE use_id = p_use_id;

    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 9. Function to verify INSTITUTION USER login
-- ============================================
CREATE OR REPLACE FUNCTION verify_user_login(
    p_email TEXT,
    p_plain_password TEXT
)
RETURNS TABLE(
    use_id INTEGER,
    usename TEXT,
    usemail TEXT,
    urname TEXT,
    desname TEXT,
    is_valid BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        u.use_id,
        u.usename,
        u.usemail::TEXT,
        u.urname,
        u.desname,
        (u.usepassword = crypt(p_plain_password, u.usepassword)) as is_valid
    FROM public.institutionusers u
    WHERE u.usemail = p_email
    AND u.activestatus = 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 10. Trigger to auto-hash passwords on INSERT/UPDATE
-- ============================================

-- Trigger function for parents
CREATE OR REPLACE FUNCTION trigger_hash_parent_password()
RETURNS TRIGGER AS $$
BEGIN
    -- Only hash if password is being set and doesn't look already hashed
    IF NEW.parpassword IS NOT NULL
       AND NEW.parpassword != ''
       AND LEFT(NEW.parpassword, 4) != '$2a$'
       AND LEFT(NEW.parpassword, 4) != '$2b$' THEN
        NEW.parpassword := crypt(NEW.parpassword, gen_salt('bf', 10));
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger function for students
CREATE OR REPLACE FUNCTION trigger_hash_student_password()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.stupassword IS NOT NULL
       AND NEW.stupassword != ''
       AND LEFT(NEW.stupassword, 4) != '$2a$'
       AND LEFT(NEW.stupassword, 4) != '$2b$' THEN
        NEW.stupassword := crypt(NEW.stupassword, gen_salt('bf', 10));
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger function for institution users
CREATE OR REPLACE FUNCTION trigger_hash_user_password()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.usepassword IS NOT NULL
       AND NEW.usepassword != ''
       AND LEFT(NEW.usepassword, 4) != '$2a$'
       AND LEFT(NEW.usepassword, 4) != '$2b$' THEN
        NEW.usepassword := crypt(NEW.usepassword, gen_salt('bf', 10));
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing triggers if any
DROP TRIGGER IF EXISTS hash_parent_password_trigger ON public.parents;
DROP TRIGGER IF EXISTS hash_student_password_trigger ON public.students;
DROP TRIGGER IF EXISTS hash_user_password_trigger ON public.institutionusers;

-- Create triggers
CREATE TRIGGER hash_parent_password_trigger
    BEFORE INSERT OR UPDATE OF parpassword ON public.parents
    FOR EACH ROW
    EXECUTE FUNCTION trigger_hash_parent_password();

CREATE TRIGGER hash_student_password_trigger
    BEFORE INSERT OR UPDATE OF stupassword ON public.students
    FOR EACH ROW
    EXECUTE FUNCTION trigger_hash_student_password();

CREATE TRIGGER hash_user_password_trigger
    BEFORE INSERT OR UPDATE OF usepassword ON public.institutionusers
    FOR EACH ROW
    EXECUTE FUNCTION trigger_hash_user_password();

-- ============================================
-- USAGE EXAMPLES
-- ============================================

-- Hash a password manually:
-- SELECT hash_password('mypassword123');
-- Result: $2a$10$xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

-- Verify a password:
-- SELECT verify_password('mypassword123', '$2a$10$xxxxx...');
-- Result: true or false

-- Set parent password:
-- SELECT hash_parent_password(1, 'newpassword');

-- Verify parent login:
-- SELECT * FROM verify_parent_login('parent@email.com', 'password123');

-- With triggers, just INSERT/UPDATE with plain password:
-- UPDATE parents SET parpassword = 'newpassword' WHERE par_id = 1;
-- The trigger will automatically hash it!

SELECT 'pgcrypto setup completed successfully!' as status;
