-- ================================================
-- SQL helper: drop riding and region roles, policies, and grants
-- ================================================
SET client_min_messages TO WARNING;

DO $$
DECLARE
  policy_rec RECORD;
  grant_rec RECORD;
  membership_rec RECORD;
  role_rec RECORD;
BEGIN
  -- Drop policies generated for riding_*/region_* roles
  FOR policy_rec IN
    SELECT schemaname, tablename, policyname
    FROM pg_policies
    WHERE policyname LIKE 'riding\_%' ESCAPE '\' OR policyname LIKE 'region\_%' ESCAPE '\'
  LOOP
    EXECUTE FORMAT(
      'DROP POLICY IF EXISTS %I ON %I.%I',
      policy_rec.policyname,
      policy_rec.schemaname,
      policy_rec.tablename
    );
  END LOOP;

  -- Revoke table privileges from riding_*/region_* grantees
  FOR grant_rec IN
    SELECT DISTINCT grantee, table_schema, table_name
    FROM information_schema.role_table_grants
    WHERE grantee LIKE 'riding\_%' ESCAPE '\' OR grantee LIKE 'region\_%' ESCAPE '\'
  LOOP
    EXECUTE FORMAT(
      'REVOKE ALL PRIVILEGES ON TABLE %I.%I FROM %I',
      grant_rec.table_schema,
      grant_rec.table_name,
      grant_rec.grantee
    );
  END LOOP;

  -- Revoke usage on sequences (if any) granted to these roles
  FOR grant_rec IN
    SELECT DISTINCT grantee, object_schema, object_name
    FROM information_schema.role_usage_grants
    WHERE object_type = 'SEQUENCE'
      AND (grantee LIKE 'riding\_%' ESCAPE '\' OR grantee LIKE 'region\_%' ESCAPE '\')
  LOOP
    EXECUTE FORMAT(
      'REVOKE ALL PRIVILEGES ON SEQUENCE %I.%I FROM %I',
      grant_rec.object_schema,
      grant_rec.object_name,
      grant_rec.grantee
    );
  END LOOP;

  -- Revoke memberships between riding/region roles
  FOR membership_rec IN
    SELECT DISTINCT granted_role.rolname AS role_name, member_role.rolname AS member_name
    FROM pg_auth_members pam
    JOIN pg_roles granted_role ON granted_role.oid = pam.roleid
    JOIN pg_roles member_role ON member_role.oid = pam.member
    WHERE granted_role.rolname LIKE 'riding\_%' ESCAPE '\'
       OR granted_role.rolname LIKE 'region\_%' ESCAPE '\'
       OR member_role.rolname LIKE 'riding\_%' ESCAPE '\'
       OR member_role.rolname LIKE 'region\_%' ESCAPE '\'
  LOOP
    EXECUTE FORMAT(
      'REVOKE %I FROM %I',
      membership_rec.role_name,
      membership_rec.member_name
    );
  END LOOP;

  -- Drop owned objects then drop the roles themselves
  FOR role_rec IN
    SELECT rolname
    FROM pg_roles
    WHERE rolname LIKE 'riding\_%' ESCAPE '\' OR rolname LIKE 'region\_%' ESCAPE '\'
    ORDER BY rolname DESC
  LOOP
    BEGIN
      EXECUTE FORMAT('DROP OWNED BY %I', role_rec.rolname);
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'DROP OWNED BY % failed: %', role_rec.rolname, SQLERRM;
    END;

    BEGIN
      EXECUTE FORMAT('DROP ROLE IF EXISTS %I', role_rec.rolname);
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'DROP ROLE % failed: %', role_rec.rolname, SQLERRM;
    END;
  END LOOP;
END
$$;
