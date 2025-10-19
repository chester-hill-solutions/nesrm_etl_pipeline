
SET default_transaction_read_only = off;

SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;

CREATE ROLE "campaign_manager";
ALTER ROLE "campaign_manager" WITH INHERIT NOCREATEROLE NOCREATEDB LOGIN NOBYPASSRLS;
CREATE ROLE "cli_login_postgres";
ALTER ROLE "cli_login_postgres" WITH NOINHERIT NOCREATEROLE NOCREATEDB LOGIN NOBYPASSRLS VALID UNTIL '2025-10-19 00:08:21.842121+00';
CREATE ROLE "my_pgadmin_user";
ALTER ROLE "my_pgadmin_user" WITH INHERIT NOCREATEROLE NOCREATEDB LOGIN NOBYPASSRLS;
CREATE ROLE "riding_captain_scarboroughsouthwest";
ALTER ROLE "riding_captain_scarboroughsouthwest" WITH INHERIT NOCREATEROLE NOCREATEDB LOGIN NOBYPASSRLS;
CREATE ROLE "sai2@chsolutions.ca";
ALTER ROLE "sai2@chsolutions.ca" WITH INHERIT NOCREATEROLE NOCREATEDB LOGIN NOBYPASSRLS;
CREATE ROLE "sys_admin";
ALTER ROLE "sys_admin" WITH INHERIT NOCREATEROLE NOCREATEDB LOGIN NOBYPASSRLS;
CREATE ROLE "toronto_yns_reader";
ALTER ROLE "toronto_yns_reader" WITH INHERIT NOCREATEROLE NOCREATEDB NOLOGIN NOBYPASSRLS;
CREATE ROLE "toronto_yns_writer";
ALTER ROLE "toronto_yns_writer" WITH INHERIT NOCREATEROLE NOCREATEDB NOLOGIN NOBYPASSRLS;

ALTER ROLE "anon" SET "statement_timeout" TO '3s';

ALTER ROLE "authenticated" SET "statement_timeout" TO '8s';

ALTER ROLE "authenticator" SET "statement_timeout" TO '8s';

GRANT "postgres" TO "cli_login_postgres" WITH INHERIT FALSE GRANTED BY "supabase_admin";
GRANT "toronto_yns_reader" TO "sai2@chsolutions.ca" WITH INHERIT TRUE GRANTED BY "postgres";
GRANT "toronto_yns_reader" TO "toronto_yns_writer" WITH INHERIT TRUE GRANTED BY "postgres";
GRANT "toronto_yns_writer" TO "sai2@chsolutions.ca" WITH INHERIT TRUE GRANTED BY "postgres";

RESET ALL;
