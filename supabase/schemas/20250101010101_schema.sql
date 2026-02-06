

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE SCHEMA IF NOT EXISTS "__msar";


ALTER SCHEMA "__msar" OWNER TO "postgres";


CREATE EXTENSION IF NOT EXISTS "pg_cron" WITH SCHEMA "pg_catalog";






CREATE SCHEMA IF NOT EXISTS "mathesar_types";


ALTER SCHEMA "mathesar_types" OWNER TO "postgres";


CREATE SCHEMA IF NOT EXISTS "msar";


ALTER SCHEMA "msar" OWNER TO "postgres";


CREATE EXTENSION IF NOT EXISTS "pg_net" WITH SCHEMA "extensions";






COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "hypopg" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "index_advisor" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "postgis" WITH SCHEMA "public";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE TYPE "msar"."pkey_kind" AS ENUM (
    'UUIDv4',
    'IDENTITY'
);


ALTER TYPE "msar"."pkey_kind" OWNER TO "postgres";


CREATE TYPE "__msar"."col_def" AS (
	"name_" "text",
	"type_" "text",
	"not_null" boolean,
	"default_" "text",
	"pkey_type" "msar"."pkey_kind",
	"description" "text"
);


ALTER TYPE "__msar"."col_def" OWNER TO "postgres";


CREATE TYPE "__msar"."con_def" AS (
	"name_" "text",
	"type_" "char",
	"col_names" "text"[],
	"deferrable_" boolean,
	"fk_rel_name" "text",
	"fk_col_names" "text"[],
	"fk_upd_action" "char",
	"fk_del_action" "char",
	"fk_match_type" "char",
	"expression" "text"
);


ALTER TYPE "__msar"."con_def" OWNER TO "postgres";


CREATE TYPE "__msar"."not_null_def" AS (
	"col_name" "text",
	"not_null" boolean
);


ALTER TYPE "__msar"."not_null_def" OWNER TO "postgres";


CREATE DOMAIN "mathesar_types"."email" AS "text"
	CONSTRAINT "email_check" CHECK ((VALUE ~ '^[a-zA-Z0-9.!#$%&''*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$'::"text"));


ALTER DOMAIN "mathesar_types"."email" OWNER TO "postgres";


CREATE DOMAIN "mathesar_types"."mathesar_json_array" AS "jsonb"
	CONSTRAINT "mathesar_json_array_check" CHECK (("jsonb_typeof"(VALUE) = 'array'::"text"));


ALTER DOMAIN "mathesar_types"."mathesar_json_array" OWNER TO "postgres";


CREATE DOMAIN "mathesar_types"."mathesar_json_object" AS "jsonb"
	CONSTRAINT "mathesar_json_object_check" CHECK (("jsonb_typeof"(VALUE) = 'object'::"text"));


ALTER DOMAIN "mathesar_types"."mathesar_json_object" OWNER TO "postgres";


CREATE DOMAIN "mathesar_types"."mathesar_money" AS numeric;


ALTER DOMAIN "mathesar_types"."mathesar_money" OWNER TO "postgres";


CREATE TYPE "mathesar_types"."multicurrency_money" AS (
	"value" numeric,
	"currency" character(3)
);


ALTER TYPE "mathesar_types"."multicurrency_money" OWNER TO "postgres";


CREATE DOMAIN "mathesar_types"."uri" AS "text";


ALTER DOMAIN "mathesar_types"."uri" OWNER TO "postgres";


CREATE TYPE "msar"."joinable_tables" AS (
	"base" bigint,
	"target" bigint,
	"join_path" "jsonb",
	"fkey_path" "jsonb",
	"depth" integer,
	"multiple_results" boolean
);


ALTER TYPE "msar"."joinable_tables" OWNER TO "postgres";


CREATE TYPE "msar"."type_compat_details" AS (
	"type_compatible" boolean,
	"mathesar_casting" boolean,
	"group_sep" "char",
	"decimal_p" "char",
	"curr_pref" "text",
	"curr_suff" "text"
);


ALTER TYPE "msar"."type_compat_details" OWNER TO "postgres";


CREATE TYPE "public"."filter_visibility" AS ENUM (
    'private',
    'team'
);


ALTER TYPE "public"."filter_visibility" OWNER TO "postgres";


CREATE TYPE "public"."role_type" AS ENUM (
    'super_admin',
    'admin',
    'member',
    'locked',
    'developer'
);


ALTER TYPE "public"."role_type" OWNER TO "postgres";


CREATE TYPE "public"."status" AS ENUM (
    'new',
    'in-progress',
    'complete',
    'archived',
    'requires-follow-up'
);


ALTER TYPE "public"."status" OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "__msar"."add_columns"("tab_name" "text", VARIADIC "col_defs" "__msar"."col_def"[]) RETURNS "text"
    LANGUAGE "sql" STRICT
    AS $$/*
Add the given columns to the given table.

Args:
  tab_name: Fully-qualified, quoted table name.
  col_defs: The columns to be added.
*/
WITH ca_cte AS (
  SELECT string_agg(
    'ADD COLUMN ' || __msar.build_col_def_text(col),
      ', '
    ) AS col_additions
  FROM unnest(col_defs) AS col
)
SELECT __msar.exec_ddl('ALTER TABLE %s %s', tab_name, col_additions) FROM ca_cte;
$$;


ALTER FUNCTION "__msar"."add_columns"("tab_name" "text", VARIADIC "col_defs" "__msar"."col_def"[]) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "__msar"."add_constraints"("tab_name" "text", VARIADIC "con_defs" "__msar"."con_def"[]) RETURNS "text"
    LANGUAGE "sql" STRICT
    AS $$/*
Add the given constraints to the given table.

Args:
  tab_name: Fully-qualified, quoted table name.
  con_defs: The constraints to be added.
*/
WITH con_cte AS (
  SELECT string_agg('ADD ' || __msar.build_con_def_text(con), ', ') as con_additions
  FROM unnest(con_defs) as con
)
SELECT __msar.exec_ddl('ALTER TABLE %s %s', tab_name, con_additions) FROM con_cte;
$$;


ALTER FUNCTION "__msar"."add_constraints"("tab_name" "text", VARIADIC "con_defs" "__msar"."con_def"[]) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "__msar"."add_table"("tab_name" "text", "col_defs" "__msar"."col_def"[], "con_defs" "__msar"."con_def"[]) RETURNS "text"
    LANGUAGE "sql"
    AS $$/*
Add a table, returning the command executed.

Args:
  tab_name: A qualified & quoted name for the table to be added.
  col_defs: An array of __msar.col_def defining the column set of the new table.
  con_defs (optional): An array of __msar.con_def defining the constraints for the new table.

Note: Even if con_defs is null, there can be some column-level constraints set in col_defs.
*/
WITH col_cte AS (
  SELECT string_agg(__msar.build_col_def_text(col), ', ') AS table_columns
  FROM unnest(col_defs) AS col
), con_cte AS (
  SELECT string_agg(__msar.build_con_def_text(con), ', ') AS table_constraints
  FROM unnest(con_defs) as con
)
SELECT __msar.exec_ddl(
  'CREATE TABLE %s (%s)',
  tab_name,
  concat_ws(', ', table_columns, table_constraints)
)
FROM col_cte, con_cte;
$$;


ALTER FUNCTION "__msar"."add_table"("tab_name" "text", "col_defs" "__msar"."col_def"[], "con_defs" "__msar"."con_def"[]) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "__msar"."build_cast_expr"("val" "text", "type_" "text") RETURNS "text"
    LANGUAGE "sql" STRICT
    AS $$/*
Build an expression for casting a column in Mathesar, returning the text of that expression.

Args:
  val: This is quite general, and isn't sanitized in any way. It can be either a literal or a column
       identifier, since we want to be able to produce a casting expression in either case.
  type_: This type name string must cast properly to a regtype.
*/
SELECT msar.get_cast_function_name(type_::regtype) || '(' || val || ')'
$$;


ALTER FUNCTION "__msar"."build_cast_expr"("val" "text", "type_" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "__msar"."build_col_def_text"("col" "__msar"."col_def") RETURNS "text"
    LANGUAGE "sql"
    AS $$/*
Build appropriate text defining the given column for table creation or alteration.
*/
SELECT format(
  '%s %s %s %s %s',
  col.name_,
  col.type_,
  CASE WHEN col.not_null THEN 'NOT NULL' END,
  'DEFAULT ' || col.default_,
  -- This can be used to define our default Mathesar primary key column.
  -- TODO: We should really consider doing GENERATED *ALWAYS* (rather than BY DEFAULT), but this
  -- breaks some other assumptions.
  CASE col.pkey_type
    WHEN 'IDENTITY' THEN 'GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY'
    WHEN 'UUIDv4' THEN 'PRIMARY KEY DEFAULT gen_random_uuid()'
  END
);
$$;


ALTER FUNCTION "__msar"."build_col_def_text"("col" "__msar"."col_def") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "__msar"."build_col_default_expr"("tab_id" "oid", "col_id" integer, "old_default" "text", "new_default" "jsonb", "new_type" "text") RETURNS "text"
    LANGUAGE "plpgsql"
    AS $$/*
Build an expression to set a column's default value, returning the text of that expression.

This function is private, and not general. The expression it builds is in the context of the calling
msar.process_col_alter_jsonb function. In particular, this function can also reset the original
default after a column type alteration, but cast to the new type of the column. We also avoid
setting a new default in cases where the new default argument is (sql) NULL, or a JSONB null.

Args:
  tab_id: The OID of the table containing the column whose default we'll alter.
  col_id: The attnum of the column whose default we'll alter.
  old_default: The current default. In some cases in the context of the caller, we want to reset the
               original default, but cast to a new type.
  new_default: The new desired default. It's left as JSONB since we are using JSONB 'null' values to
               represent 'drop the column default'.
  new_type: The target type to which we'll cast the new default.
*/
DECLARE
  default_expr text;
  raw_default_expr text;
BEGIN
  -- In this case, we assume the intent is to clear out the original default.
  IF jsonb_typeof(new_default)='null' THEN
    default_expr := null;
  -- We get the root JSONB value as text if it exists.
  ELSEIF new_default #>> '{}' IS NOT NULL THEN
    default_expr := format('%L', new_default #>> '{}');  -- sanitize since this could be user input.
  -- At this point, we know we're not setting a new default, or dropping the old one.
  -- So, we check whether the original default is potentially dynamic, and whether we need to cast
  -- it to a new type.
  ELSEIF msar.is_default_possibly_dynamic(tab_id, col_id) AND new_type IS NOT NULL THEN
    -- We add casting the possibly dynamic expression to the new type as part of the default
    -- expression in this case.
    default_expr := format('%s::%s', old_default, new_type);
  ELSEIF old_default IS NOT NULL AND new_type IS NOT NULL THEN
    -- If we arrive here, then we know the old_default is a constant value, and we want to cast the
    -- old default value to the new type *before* setting it as the new default. This avoids
    -- building up nested cast functions in the default expression.
    -- The first step is to execute the cast expression, putting the result into a new variable.
    EXECUTE format('SELECT %s', __msar.build_cast_expr(old_default, new_type))
      INTO raw_default_expr;
    -- Then we format that new variable's value as a literal.
    default_expr := format('%L', raw_default_expr);
  END IF;
  RETURN
    format('ALTER COLUMN %I SET DEFAULT ', msar.get_column_name(tab_id, col_id)) || default_expr;
END;
$$;


ALTER FUNCTION "__msar"."build_col_default_expr"("tab_id" "oid", "col_id" integer, "old_default" "text", "new_default" "jsonb", "new_type" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "__msar"."build_col_drop_default_expr"("tab_id" "oid", "col_id" integer, "new_type" "text", "new_default" "jsonb") RETURNS "text"
    LANGUAGE "sql"
    AS $$/*
Build an expression for dropping a column's default, returning the text of that expression.

This function is private, and not general: It builds an expression in the context of the
msar.process_col_alter_jsonb function and should not otherwise be called independently, since it has
logic specific to that context. In that setting, we drop the default for the specified column if the
caller specifies that we're setting a new_default of NULL, or if we're changing the type of the
column.

Args:
  tab_id: The OID of the table where the column with the default to be dropped lives.
  col_id: The attnum of the column with the undesired default.
  new_type: This gives the function context letting it know whether to drop the default or not. If
            we are setting a new type for the column, we will always drop the default first.
  new_default: This also gives us context letting us know whether to drop the default. By setting
               the 'new_default' to (jsonb) null, the caller specifies that we should drop the
               column's default.
*/
SELECT CASE WHEN new_type IS NOT NULL OR jsonb_typeof(new_default)='null' THEN
  'ALTER COLUMN ' || quote_ident(msar.get_column_name(tab_id, col_id)) || ' DROP DEFAULT'
 END;
$$;


ALTER FUNCTION "__msar"."build_col_drop_default_expr"("tab_id" "oid", "col_id" integer, "new_type" "text", "new_default" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "__msar"."build_col_drop_text"("tab_id" "oid", "col_id" integer, "col_delete" boolean) RETURNS "text"
    LANGUAGE "sql" STRICT
    AS $$/*
Build an expression to drop a column from a table, returning the text of that expression.

Args:
  tab_id: The OID of the table containing the column whose nullability we'll alter.
  col_id: The attnum of the column whose nullability we'll alter.
  col_delete: If true, we drop the column. If false or null, we do nothing.
*/
SELECT CASE WHEN col_delete THEN 'DROP COLUMN ' || quote_ident(msar.get_column_name(tab_id, col_id)) END;
$$;


ALTER FUNCTION "__msar"."build_col_drop_text"("tab_id" "oid", "col_id" integer, "col_delete" boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "__msar"."build_col_not_null_expr"("tab_id" "oid", "col_id" integer, "not_null" boolean) RETURNS "text"
    LANGUAGE "sql" STRICT
    AS $$/*
Build an expression to alter a column's NOT NULL setting, returning the text of that expression.

Args:
  tab_id: The OID of the table containing the column whose nullability we'll alter.
  col_id: The attnum of the column whose nullability we'll alter.
  not_null: If true, we 'SET NOT NULL'. If false, we 'DROP NOT NULL' if null, we do nothing.
*/
SELECT 'ALTER COLUMN '
  || quote_ident(msar.get_column_name(tab_id, col_id))
  || CASE WHEN not_null THEN ' SET ' ELSE ' DROP ' END
  || 'NOT NULL';
$$;


ALTER FUNCTION "__msar"."build_col_not_null_expr"("tab_id" "oid", "col_id" integer, "not_null" boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "__msar"."build_col_retype_expr"("tab_id" "oid", "col_id" integer, "new_type" "text") RETURNS "text"
    LANGUAGE "sql" STRICT
    AS $$/*
Build an expression to change a column's type, returning the text of that expression.

Note that this function wraps the type alteration in a cast expression. If we have the custom
cast functions available, we prefer those to the default PostgreSQL casting behavior.

Args:
  tab_id: The OID of the table containing the column whose type we'll alter.
  col_id: The attnum of the column whose type we'll alter.
  new_type: The target type to which we'll alter the column.
*/
SELECT 'ALTER COLUMN '
  || quote_ident(msar.get_column_name(tab_id, col_id))
  || ' TYPE '
  || new_type
  || ' USING '
  || __msar.build_cast_expr(quote_ident(msar.get_column_name(tab_id, col_id)), new_type);
$$;


ALTER FUNCTION "__msar"."build_col_retype_expr"("tab_id" "oid", "col_id" integer, "new_type" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "__msar"."build_con_def_text"("con" "__msar"."con_def") RETURNS "text"
    LANGUAGE "sql" STRICT
    AS $$/*
Build appropriate text defining the given constraint for table creation or alteration.

If the given con.name_ is null, the syntax changes slightly (we don't add 'CONSTRAINT'). The FOREIGN
KEY constraint has a number of extra strings that may or may not be appended.  The best
documentation for this is the FOREIGN KEY section of the CREATE TABLE docs:
https://www.postgresql.org/docs/current/sql-createtable.html

One helpful note is that this function makes use heavy of the || operator. This operator returns
null if either side is null, and thus

  'CONSTRAINT ' || con.name_ || ' '

is 'CONSTRAINT <name> ' when con.name_ is not null, and simply null if con.name_ is null.
*/
SELECT CASE
    WHEN con.type_ = 'u' THEN  -- It's a UNIQUE constraint
      format(
        '%sUNIQUE %s',
        'CONSTRAINT ' || con.name_ || ' ',
        __msar.build_text_tuple(con.col_names)
      )
    WHEN con.type_ = 'p' THEN  -- It's a PRIMARY KEY constraint
      format(
        '%sPRIMARY KEY %s',
        'CONSTRAINT ' || con.name_ || ' ',
        __msar.build_text_tuple(con.col_names)
      )
    WHEN con.type_ = 'f' THEN  -- It's a FOREIGN KEY constraint
      format(
        '%sFOREIGN KEY %s REFERENCES %s%s%s%s%s',
        'CONSTRAINT ' || con.name_ || ' ',
        __msar.build_text_tuple(con.col_names),
        con.fk_rel_name,
        __msar.build_text_tuple(con.fk_col_names),
        ' MATCH ' || msar.get_fkey_match_type_from_char(con.fk_match_type),
        ' ON DELETE ' || msar.get_fkey_action_from_char(con.fk_del_action),
        ' ON UPDATE ' || msar.get_fkey_action_from_char(con.fk_upd_action)
      )
    ELSE
      NULL
  END
  || CASE WHEN con.deferrable_ THEN 'DEFERRABLE' ELSE '' END;
$$;


ALTER FUNCTION "__msar"."build_con_def_text"("con" "__msar"."con_def") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "__msar"."build_qualified_name_sql"("sch_name" "text", "obj_name" "text") RETURNS "text"
    LANGUAGE "plpgsql" STRICT
    AS $$/*
Return the fully-qualified, properly quoted, name for a given database object (e.g., table).

Args:
  sch_name: The schema of the object, unquoted.
  obj_name: The name of the object, unqualified and unquoted.
*/
BEGIN
  RETURN  format('%I.%I', sch_name, obj_name);
END;
$$;


ALTER FUNCTION "__msar"."build_qualified_name_sql"("sch_name" "text", "obj_name" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "__msar"."build_text_tuple"("text"[]) RETURNS "text"
    LANGUAGE "sql" STRICT
    AS $_$
SELECT '(' || string_agg(col, ', ') || ')' FROM unnest($1) x(col);
$_$;


ALTER FUNCTION "__msar"."build_text_tuple"("text"[]) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "__msar"."build_typmodin_arg"("typ_options" "jsonb", "timespan_flag" boolean) RETURNS "cstring"[]
    LANGUAGE "sql" STRICT
    AS $$/*
Build an array to be used as the argument for a typmodin function.

Timespans have to be handled slightly differently since they have a tricky `fields` argument that
requires special processing. See __msar.prepare_fields_arg for more details.

Args:
  typ_options: JSONB giving options fields as per the description in msar.build_type_text.
  timespan_flag: true if the associated type is a timespan, false otherwise.
*/
SELECT array_remove(
  ARRAY[
    typ_options ->> 'length',
    CASE WHEN timespan_flag THEN __msar.prepare_fields_arg(typ_options ->> 'fields') END,
    typ_options ->> 'precision',
    typ_options ->> 'scale'
  ],
  null
)::cstring[]
$$;


ALTER FUNCTION "__msar"."build_typmodin_arg"("typ_options" "jsonb", "timespan_flag" boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "__msar"."comment_on_column"("tab_id" "oid", "col_id" integer, "comment_" "text") RETURNS "text"
    LANGUAGE "sql"
    AS $$/*
Change the description of a column, returning command executed.

Args:
  tab_id: The OID of the table containg the column whose comment we will change.
  col_id: The ATTNUM of the column whose comment we will change.
  comment_: The new comment.
*/
SELECT __msar.comment_on_column(
  __msar.get_qualified_relation_name(tab_id),
  quote_ident(msar.get_column_name(tab_id, col_id)),
  comment_
);
$$;


ALTER FUNCTION "__msar"."comment_on_column"("tab_id" "oid", "col_id" integer, "comment_" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "__msar"."comment_on_column"("tab_name" "text", "col_name" "text", "comment_" "text") RETURNS "text"
    LANGUAGE "plpgsql"
    AS $$/*
Change the description of a column, returning command executed. If comment_ is NULL, column's
comment is removed.

Args:
  tab_name: The name of the table containg the column whose comment we will change.
  col_name: The name of the column whose comment we'll change
  comment_: The new comment. Any quotes or special characters must be escaped.
*/
DECLARE
  comment_or_null text := COALESCE(comment_, 'NULL');
BEGIN
RETURN __msar.exec_ddl(
  'COMMENT ON COLUMN %s.%s IS %s',
  tab_name,
  col_name,
  comment_or_null
);
END;
$$;


ALTER FUNCTION "__msar"."comment_on_column"("tab_name" "text", "col_name" "text", "comment_" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "__msar"."drop_table"("tab_name" "text", "cascade_" boolean, "if_exists" boolean) RETURNS "text"
    LANGUAGE "plpgsql" STRICT
    AS $$/*
Drop a table, returning the command executed.

Args:
  tab_name: The qualified, quoted name of the table we will drop.
  cascade_: Whether to add CASCADE.
  if_exists_: Whether to ignore an error if the table doesn't exist
*/
DECLARE
  cmd_template TEXT;
BEGIN
  IF if_exists
  THEN
    cmd_template := 'DROP TABLE IF EXISTS %s';
  ELSE
    cmd_template := 'DROP TABLE %s';
  END IF;
  IF cascade_
  THEN
    cmd_template = cmd_template || ' CASCADE';
  END IF;
  RETURN __msar.exec_ddl(cmd_template, tab_name);
END;
$$;


ALTER FUNCTION "__msar"."drop_table"("tab_name" "text", "cascade_" boolean, "if_exists" boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "__msar"."exec_ddl"("command" "text") RETURNS "text"
    LANGUAGE "plpgsql" STRICT
    AS $$/*
Execute the given command, returning the command executed.

Not useful for SELECTing from tables. Most useful when you're performing DDL.

Args:
  command: Raw string that will be executed as a command.
*/
BEGIN
  EXECUTE command;
  RETURN command;
END;
$$;


ALTER FUNCTION "__msar"."exec_ddl"("command" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "__msar"."exec_ddl"("command_template" "text", VARIADIC "arguments" "anyarray") RETURNS "text"
    LANGUAGE "plpgsql" STRICT
    AS $$/*
Execute a templated command, returning the command executed.

The template is given in the first argument, and all further arguments are used to fill in the
template. Not useful for SELECTing from tables. Most useful when you're performing DDL.

Args:
  command_template: Raw string that will be executed as a command.
  arguments: arguments that will be used to fill in the template.
*/
DECLARE formatted_command TEXT;
BEGIN
  formatted_command := format(command_template, VARIADIC arguments);
  RETURN __msar.exec_ddl(formatted_command);
END;
$$;


ALTER FUNCTION "__msar"."exec_ddl"("command_template" "text", VARIADIC "arguments" "anyarray") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "__msar"."exec_dql"("command" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql" STRICT
    AS $$/*
Execute the given command, returning a JSON object describing the records in the following form:
[
  {"id": 1, "col1_name": "value1", "col2_name": "value2"},
  {"id": 2, "col1_name": "value1", "col2_name": "value2"},
  {"id": 3, "col1_name": "value1", "col2_name": "value2"},
  ...
]

Useful for SELECTing from tables. Most useful when you're performing DQL.

Note that you must include the primary key column(`id` in case of a Mathesar table) in the
command_template if you want the returned records to be uniquely identifiable.

Args:
  command: Raw string that will be executed as a command.
*/
DECLARE
  records jsonb;
BEGIN
  EXECUTE 'WITH cte AS (' || command || ')
  SELECT jsonb_agg(row_to_json(cte.*)) FROM cte' INTO records;
  RETURN records;
END;
$$;


ALTER FUNCTION "__msar"."exec_dql"("command" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "__msar"."exec_dql"("command_template" "text", VARIADIC "arguments" "anyarray") RETURNS "jsonb"
    LANGUAGE "plpgsql" STRICT
    AS $$/*
Execute a templated command, returning a JSON object describing the records in the following form:
[
  {"id": 1, "col1_name": "value1", "col2_name": "value2"},
  {"id": 2, "col1_name": "value1", "col2_name": "value2"},
  {"id": 3, "col1_name": "value1", "col2_name": "value2"},
  ...
]

The template is given in the first argument, and all further arguments are used to fill in the
template. Useful for SELECTing from tables. Most useful when you're performing DQL.

Note that you must include the primary key column(`id` in case of a Mathesar table) in the
command_template if you want the returned records to be uniquely identifiable.

Args:
  command_template: Raw string that will be executed as a command.
  arguments: arguments that will be used to fill in the template.
*/
DECLARE formatted_command TEXT;
BEGIN
  formatted_command := format(command_template, VARIADIC arguments);
  RETURN __msar.exec_dql(formatted_command);
END;
$$;


ALTER FUNCTION "__msar"."exec_dql"("command_template" "text", VARIADIC "arguments" "anyarray") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "__msar"."get_duplicate_col_defs"("tab_id" "oid", "col_ids" smallint[], "new_names" "text"[], "copy_defaults" boolean) RETURNS "__msar"."col_def"[]
    LANGUAGE "sql" STRICT
    AS $$/*
Get an array of __msar.col_def from given columns in a table.

Args:
  tab_id: The OID of the table containing the column whose definition we want.
  col_ids: The attnums of the columns whose definitions we want.
  new_names: The desired names of the column defs. Must be in same order as col_ids, and same
    length.
  copy_defaults: Whether or not we should copy the defaults
*/
SELECT array_agg(
  (
    -- build a name for the duplicate column
    quote_ident(COALESCE(new_name, msar.get_fresh_copy_name(tab_id, pg_columns.attnum))),
    -- build text specifying the type of the duplicate column
    format_type(atttypid, atttypmod),
    -- set the duplicate column to be nullable, since it will initially be empty
    false,
    -- set the default value for the duplicate column if specified
    CASE WHEN copy_defaults THEN pg_get_expr(adbin, tab_id) END,
    -- We don't set a duplicate column as a primary key, since that would cause an error.
    null,
    msar.col_description(tab_id, pg_columns.attnum)
  )::__msar.col_def
)
FROM pg_attribute AS pg_columns
  JOIN unnest(col_ids, new_names) AS columns_to_copy(col_id, new_name)
    ON pg_columns.attnum=columns_to_copy.col_id
  LEFT JOIN pg_attrdef AS pg_column_defaults
    ON pg_column_defaults.adnum=pg_columns.attnum AND pg_columns.attrelid=pg_column_defaults.adrelid
WHERE pg_columns.attrelid=tab_id;
$$;


ALTER FUNCTION "__msar"."get_duplicate_col_defs"("tab_id" "oid", "col_ids" smallint[], "new_names" "text"[], "copy_defaults" boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "__msar"."get_formatted_base_type"("typ_name" "text", "typ_options" "jsonb") RETURNS "text"
    LANGUAGE "plpgsql"
    AS $$ /*
Build the appropriate type definition string, without Array brackets.

This function uses some PostgreSQL internal functions to do its work. In particular, for any type
that takes options, This function uses the typmodin (read "type modification input") system
functions to convert the given options into a typmod integer. The typ_name given is converted into
the OID of the named type. These two pieces let us call `format_type` to get a canonical string
representation of the definition of the type, with its options.

Args:
  typ_name: This should be qualified and quoted as needed.
  typ_options: These should be in the form described in msar.build_type_text.
*/
DECLARE
  typ_id oid;
  timespan_flag boolean;
  typmodin_func text;
  typmod integer;
BEGIN
  -- Here we just get the OID of the type.
  typ_id := typ_name::regtype::oid;
  -- This is a lookup of the function name for the typmodin function associated with the type, if
  -- one exists.
  typmodin_func := typmodin::text FROM pg_type WHERE oid=typ_id AND typmodin<>0;
  -- This flag is needed since timespan types need special handling when converting the options into
  -- the form needed to call the typmodin function.
  timespan_flag := typcategory='T' FROM pg_type WHERE oid=typ_id;
  IF (
    jsonb_typeof(typ_options) = 'null'  -- The caller passed no type options
    OR typ_options IS NULL -- The caller didn't even pass the type options key
    OR typ_options='{}'::jsonb  -- The caller passed an empty type options object
    OR typmodin_func IS NULL  -- The type doesn't actually accept type options
  ) THEN
    typmod := NULL;
  ELSE
    -- Here, we actually run the typmod function to get the output for use in the format_type call.
    EXECUTE format(
      'SELECT %I(%L)',
      typmodin_func,
      __msar.build_typmodin_arg(typ_options, timespan_flag)
    ) INTO typmod;
  END IF;
  RETURN format_type(typ_id::integer, typmod::integer);
END;
$$;


ALTER FUNCTION "__msar"."get_formatted_base_type"("typ_name" "text", "typ_options" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "__msar"."get_qualified_relation_name"("rel_id" "oid") RETURNS "text"
    LANGUAGE "plpgsql" STRICT
    AS $$/*
Return the name for a given relation (e.g., table), qualified or quoted as appropriate.

In cases where the relation is already included in the search path, the returned name will not be
fully-qualified.

The relation *must* be in the pg_class table to use this function.

Args:
  rel_id: The OID of the relation.
*/
BEGIN
  RETURN rel_id::regclass::text;
END;
$$;


ALTER FUNCTION "__msar"."get_qualified_relation_name"("rel_id" "oid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "__msar"."get_qualified_relation_name_or_null"("rel_id" "oid") RETURNS "text"
    LANGUAGE "sql" STRICT
    AS $$/*
Return the name for a given relation (e.g., table), qualified or quoted as appropriate.

In cases where the relation is already included in the search path, the returned name will not be
fully-qualified.

The relation *must* be in the pg_class table to use this function. This function will return NULL if
no corresponding relation can be found.

Args:
  rel_id: The OID of the relation.
*/
SELECT CASE
  WHEN EXISTS (SELECT oid FROM pg_catalog.pg_class WHERE oid=rel_id) THEN rel_id::regclass::text
END
$$;


ALTER FUNCTION "__msar"."get_qualified_relation_name_or_null"("rel_id" "oid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "__msar"."jsonb_key_exists"("data" "jsonb", "key" "text") RETURNS boolean
    LANGUAGE "plpgsql"
    AS $$/*
Wraps the `?` jsonb operator for improved readability.
*/
  BEGIN
    RETURN data ? key;
  END;
$$;


ALTER FUNCTION "__msar"."jsonb_key_exists"("data" "jsonb", "key" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "__msar"."prepare_fields_arg"("fields" "text") RETURNS "text"
    LANGUAGE "sql"
    AS $$/*
Convert the `fields` argument into an integer for use with the integertypmodin system function.

Args:
  fields: A string corresponding to the documented options from the doumentation at
          https://www.postgresql.org/docs/13/datatype-datetime.html

In order to construct the argument for intervaltypmodin, needed for constructing the typmod value
for INTERVAL types with arguments, we need to apply a transformation to the correct integer. This
transformation is quite arcane, and is lifted straight from the PostgreSQL C code. Given a non-null
fields argument, the steps are:
- Assign each substring of valid `fields` arguments the correct integer (from the Postgres src).
- Apply a bitshift mapping each integer to the according power of 2.
- Sum the results to get an integer signifying the fields argument.
*/
SELECT COALESCE(
  sum(1<<code)::text,
  '32767'  -- 0x7FFF in decimal; This represents no field argument.
)
FROM (
  VALUES
    ('MONTH', 1),
    ('YEAR', 2),
    ('DAY', 3),
    ('HOUR', 10),
    ('MINUTE', 11),
    ('SECOND', 12)
) AS field_map(field, code)
WHERE fields ILIKE '%' || field || '%';
$$;


ALTER FUNCTION "__msar"."prepare_fields_arg"("fields" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "__msar"."process_col_def_jsonb"("tab_id" "oid", "col_defs" "jsonb", "raw_default" boolean) RETURNS "__msar"."col_def"[]
    LANGUAGE "sql"
    AS $$/*
Create an __msar.col_def from a JSON array of column creation defining JSON blobs.

Args:
  tab_id: The OID of the table where we'll create the columns
  col_defs: A jsonb array defining a column creation (must have "type" key; "name",
                  "not_null", and "default" keys optional).
  raw_default: This boolean tells us whether we chould reproduce the default with or without quoting
               and escaping. True means we don't quote or escape, but just use the raw value.
  create_id: This boolean defines whether or not we should automatically add a default Mathesar 'id'
             column to the input.

The col_defs should have the form:
[
  {
    "name": <str> (optional),
    "type": {
      "name": <str> (optional),
      "options": <obj> (optional),
    },
    "not_null": <bool> (optional; default false),
    "default": <any> (optional),
    "description": <str> (optional)
  },
  {
    ...
  }
]

For more info on the type.options object, see the msar.build_type_text function. All pieces are
optional. If an empty object {} is given, the resulting column will have a default name like
'Column <n>' and type TEXT. It will allow nulls and have a null default value.
*/
WITH attnum_cte AS (
  SELECT MAX(attnum) AS m_attnum FROM pg_attribute WHERE attrelid=tab_id
), col_create_cte AS (
  SELECT (
    -- build a name for the column
    COALESCE(
      quote_ident(col_def_obj ->> 'name'),
      quote_ident('Column ' || (attnum_cte.m_attnum + ROW_NUMBER() OVER ())),
      quote_ident('Column ' || (ROW_NUMBER() OVER ()))
    ),
    -- build the column type
    msar.build_type_text(col_def_obj -> 'type'),
    -- set the not_null value for the column
    col_def_obj ->> 'not_null',
    -- set the default value for the column
    CASE
      WHEN col_def_obj ->> 'default' IS NULL THEN
        NULL
      WHEN raw_default THEN
        col_def_obj ->> 'default'
      ELSE
        format('%L', col_def_obj ->> 'default')
    END,
    -- We don't allow setting the primary key column manually
    null,
    -- Set the description for the column
    quote_literal(col_def_obj ->> 'description')
  )::__msar.col_def AS col_defs
  FROM attnum_cte, jsonb_array_elements(col_defs) AS col_def_obj
  WHERE (col_def_obj ->> 'name' IS NULL OR col_def_obj ->> 'name' <> 'id')
)
SELECT array_agg(col_defs)
FROM col_create_cte;
$$;


ALTER FUNCTION "__msar"."process_col_def_jsonb"("tab_id" "oid", "col_defs" "jsonb", "raw_default" boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "__msar"."process_con_def_jsonb"("tab_id" "oid", "con_create_arr" "jsonb") RETURNS "__msar"."con_def"[]
    LANGUAGE "sql"
    AS $$/*
Create an array of  __msar.con_def from a JSON array of constraint creation defining JSON.

Args:
  tab_id: The OID of the table where we'll create the constraints.
  con_create_arr: A jsonb array defining a constraint creation (must have "type" key; "name",
                  "not_null", and "default" keys optional).


The con_create_arr should have the form:
[
  {
    "name": <str> (optional),
    "type": <str>,
    "columns": [<int:str>, <int:str>, ...],
    "deferrable": <bool> (optional),
    "fkey_relation_id": <int> (optional),
    "fkey_columns": [<int>, <int>, ...] (optional),
    "fkey_update_action": <str> (optional),
    "fkey_delete_action": <str> (optional),
    "fkey_match_type": <str> (optional),
  },
  {
    ...
  }
]
If the constraint type is "f", then we require fkey_relation_id.

Numeric IDs are preferred over textual ones where both are accepted.
*/
SELECT array_agg(
  (
    -- build the name for the constraint, properly quoted.
    quote_ident(con_create_obj ->> 'name'),
    -- set the constraint type as a single char. See __msar.build_con_def_text for details.
    con_create_obj ->> 'type',
    -- Set the column names associated with the constraint.
    msar.get_column_names(tab_id, con_create_obj -> 'columns'),
    -- Set whether the constraint is deferrable or not (boolean).
    con_create_obj ->> 'deferrable',
    __msar.get_qualified_relation_name((con_create_obj -> 'fkey_relation_id')::integer::oid),
    -- Build the array of foreign columns for an fkey constraint.
    msar.get_column_names(
      -- We validate that the given OID (if any) is correct.
      (con_create_obj -> 'fkey_relation_id')::bigint::oid,
      con_create_obj -> 'fkey_columns'
    ),
    -- The below are passed directly. They define some parameters for FOREIGN KEY constraints.
    con_create_obj ->> 'fkey_update_action',
    con_create_obj ->> 'fkey_delete_action',
    con_create_obj ->> 'fkey_match_type',
    null -- not yet implemented
  )::__msar.con_def
) FROM jsonb_array_elements(con_create_arr) AS x(con_create_obj);
$$;


ALTER FUNCTION "__msar"."process_con_def_jsonb"("tab_id" "oid", "con_create_arr" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "__msar"."process_pk_col_def"("col_name" "text" DEFAULT 'id'::"text", "pkey_type" "msar"."pkey_kind" DEFAULT 'IDENTITY'::"msar"."pkey_kind") RETURNS "__msar"."col_def"[]
    LANGUAGE "sql"
    AS $$
  -- The below tuple(s) defines a default 'id' column for Mathesar. It can have a given name, type
  -- integer or uuid, it's not null, it uses the 'identity' or 'gen_random_uuid()' functionality to
  -- generate default values, has a default comment.
  SELECT CASE pkey_type 
    WHEN 'IDENTITY' THEN
      ARRAY[
        (col_name, 'integer', true, null, pkey_type, 'Mathesar default integer ID column')
      ]::__msar.col_def[]
    WHEN 'UUIDv4' THEN
      ARRAY[
        (col_name, 'uuid', true, null, pkey_type, 'Mathesar default uuid ID column')
      ]::__msar.col_def[]
  END;
$$;


ALTER FUNCTION "__msar"."process_pk_col_def"("col_name" "text", "pkey_type" "msar"."pkey_kind") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "__msar"."rename_column"("tab_name" "text", "old_col_name" "text", "new_col_name" "text") RETURNS "text"
    LANGUAGE "plpgsql" STRICT
    AS $$/*
Change a column name, returning the command executed

Args:
  tab_name: The qualified, quoted name of the table where we'll change a column name
  old_col_name: The quoted name of the column to change.
  new_col_name: The quoted new name for the column.
*/
DECLARE
  cmd_template text;
BEGIN
  cmd_template := 'ALTER TABLE %s RENAME COLUMN %s TO %s';
  IF old_col_name <> new_col_name THEN
    RETURN __msar.exec_ddl(cmd_template, tab_name, old_col_name, new_col_name);
  ELSE
    RETURN null;
  END IF;
END;
$$;


ALTER FUNCTION "__msar"."rename_column"("tab_name" "text", "old_col_name" "text", "new_col_name" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "__msar"."set_not_nulls"("tab_name" "text", "not_null_defs" "__msar"."not_null_def"[]) RETURNS "text"
    LANGUAGE "sql" STRICT
    AS $$/*
Set or drop not null constraints on columns
*/
WITH not_null_cte AS (
  SELECT string_agg(
    CASE
      WHEN not_null_def.not_null=true THEN format('ALTER %s SET NOT NULL', not_null_def.col_name)
      WHEN not_null_def.not_null=false THEN format ('ALTER %s DROP NOT NULL', not_null_def.col_name)
    END,
    ', '
  ) AS not_nulls
  FROM unnest(not_null_defs) as not_null_def
)
SELECT __msar.exec_ddl('ALTER TABLE %s %s', tab_name, not_nulls) FROM not_null_cte;
$$;


ALTER FUNCTION "__msar"."set_not_nulls"("tab_name" "text", "not_null_defs" "__msar"."not_null_def"[]) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."add_columns"("tab_id" "oid", "col_defs" "jsonb", "raw_default" boolean DEFAULT false) RETURNS smallint[]
    LANGUAGE "plpgsql" STRICT
    AS $$/*
Add columns to a table.

Args:
  tab_id: The OID of the table to which we'll add columns.
  col_defs: a JSONB array defining columns to add. See __msar.process_col_def_jsonb for details.
  raw_default: Whether to treat defaults as raw SQL. DANGER!
*/
DECLARE
  col_create_defs __msar.col_def[];
  fq_table_name text := __msar.get_qualified_relation_name(tab_id);
BEGIN
  col_create_defs := __msar.process_col_def_jsonb(tab_id, col_defs, raw_default);
  PERFORM __msar.add_columns(fq_table_name, variadic col_create_defs);

  PERFORM
  __msar.comment_on_column(
      fq_table_name,
      col_create_def.name_,
      col_create_def.description
    )
  FROM unnest(col_create_defs) AS col_create_def
  WHERE col_create_def.description IS NOT NULL;

  RETURN array_agg(attnum)
    FROM (SELECT * FROM pg_attribute WHERE attrelid=tab_id) L
    INNER JOIN unnest(col_create_defs) R
    ON quote_ident(L.attname) = R.name_;
END;
$$;


ALTER FUNCTION "msar"."add_columns"("tab_id" "oid", "col_defs" "jsonb", "raw_default" boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."add_constraints"("tab_id" "oid", "con_defs" "jsonb") RETURNS "oid"[]
    LANGUAGE "plpgsql" STRICT
    AS $$/*
Add constraints to a table.

Args:
  tab_id: The OID of the table to which we'll add constraints.
  col_defs: a JSONB array defining constraints to add. See __msar.process_con_def_jsonb for details.
*/
DECLARE
  con_create_defs __msar.con_def[];
BEGIN
  con_create_defs := __msar.process_con_def_jsonb(tab_id, con_defs);
  PERFORM __msar.add_constraints(
    __msar.get_qualified_relation_name(tab_id),
    variadic con_create_defs
  );
  RETURN array_agg(oid) FROM pg_constraint WHERE conrelid=tab_id;
END;
$$;


ALTER FUNCTION "msar"."add_constraints"("tab_id" "oid", "con_defs" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."add_foreign_key_column"("col_name" "text", "rel_id" "oid", "frel_id" "oid", "unique_link" boolean DEFAULT false) RETURNS smallint
    LANGUAGE "plpgsql" STRICT
    AS $$/*
Create a many-to-one or a one-to-one link between tables, returning the attnum of the newly created
column, returning the attnum of the added column.

Args:
  col_name: Name of the new column to be created in the referrer table, unquoted.
  rel_id: The OID of the referrer table, named for conrelid in the pg_attribute table.
  frel_id: The OID of the referent table, named for confrelid in the pg_attribute table.
  unique_link: Whether to make the link one-to-one instead of many-to-one.
*/
DECLARE
  pk_col_id smallint;
  col_defs jsonb;
  added_col_ids smallint[];
  con_defs jsonb;
BEGIN
  pk_col_id := msar.get_pk_column(frel_id);
  col_defs := jsonb_build_array(
    jsonb_build_object(
      'name', col_name,
      'type', jsonb_build_object('name', msar.get_column_type(frel_id, pk_col_id))
    )
  );
  added_col_ids := msar.add_columns(rel_id , col_defs , false);
  con_defs := jsonb_build_array(
    jsonb_build_object(
      'name', null,
      'type', 'f',
      'columns', added_col_ids,
      'deferrable', false,
      'fkey_relation_id', frel_id::integer,
      'fkey_columns', jsonb_build_array(pk_col_id)
    )
  );
  IF unique_link THEN
    con_defs := jsonb_build_array(
      jsonb_build_object(
        'name', null,
        'type', 'u',
        'columns', added_col_ids)
    ) || con_defs;
  END IF;
  PERFORM msar.add_constraints(rel_id , con_defs);
  RETURN added_col_ids[1];
END;
$$;


ALTER FUNCTION "msar"."add_foreign_key_column"("col_name" "text", "rel_id" "oid", "frel_id" "oid", "unique_link" boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."add_mapping_table"("sch_id" "oid", "tab_name" "text", "mapping_columns" "jsonb") RETURNS "oid"
    LANGUAGE "plpgsql" STRICT
    AS $$/*
Create a many-to-many link between tables, returning the oid of the newly created table.

Args:
  sch_id: The OID of the schema in which new referrer table is to be created.
  tab_name: Name of the referrer table to be created.
  mapping_columns: An array of objects giving the foreign key columns for the new table.

The elements of the mapping_columns array must have the form
  {"column_name": <str>, "referent_table_oid": <int>}

*/
DECLARE
  added_table_id oid;
BEGIN
  added_table_id := msar.add_mathesar_table(sch_id, tab_name, NULL, NULL, NULL, NULL, NULL) ->> 'oid';
  PERFORM msar.add_foreign_key_column(column_name, added_table_id, referent_table_oid)
  FROM jsonb_to_recordset(mapping_columns) AS x(column_name text, referent_table_oid oid);
  RETURN added_table_id;
END;
$$;


ALTER FUNCTION "msar"."add_mapping_table"("sch_id" "oid", "tab_name" "text", "mapping_columns" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."add_mathesar_table"("sch_id" "oid", "tab_name" "text", "pk_col_def" "jsonb", "col_defs" "jsonb", "con_defs" "jsonb", "own_id" "regrole", "comment_" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql"
    AS $_$/*
Add a table, with a default id column, returning the OID & name of the created table.

Args:
  sch_id: The OID of the schema where the table will be created.
  tab_name (optional): The unquoted name for the new table.
  pk_col_defs (optional): The primary key column for the new table.
  col_defs (optional): The columns for the new table, in order.
  con_defs (optional): The constraints for the new table.
  own_id   (optional): The OID of the role who will own the new table.
  comment_ (optional): The comment for the new table.

Note:
  - If tab_name is NULL, the table will be created with a name in the format 'Table <n>'.
  - If col_defs is NULL, the table will still be created with a default 'id' column.
  - If an 'id' column is provided, it will be renamed to an auto-generated name.
  - There would always be an 'id' column which would be created by Mathesar.
  - If own_id is NULL, the current role will be the owner of the new table.
*/
DECLARE
  schema_name text;
  table_count integer;
  prefix text;
  uq_table_name text;
  fq_table_name text;
  created_table_id oid;
  column_defs __msar.col_def[];
  constraint_defs __msar.con_def[];
  id_col_name text;
  existing_col_names text[];
  renamed_columns jsonb := '{}'::jsonb;
BEGIN
  schema_name := msar.get_schema_name(sch_id);
  IF NULLIF(tab_name, '') IS NOT NULL AND NOT EXISTS(
      SELECT oid FROM pg_catalog.pg_class WHERE relname = tab_name AND relnamespace = sch_id
    )
  THEN
    fq_table_name := format('%I.%I', schema_name, tab_name);
  ELSE
    -- determine what prefix to use for table name generation
    IF NULLIF(tab_name, '') IS NOT NULL THEN
      prefix := tab_name || ' ';
    ELSE
      prefix := 'Table ';
    END IF;
    -- generate a table name if one doesn't exist
    SELECT COUNT(*) + 1 INTO table_count
    FROM pg_catalog.pg_class
    WHERE relkind = 'r' AND relnamespace = sch_id;
    uq_table_name := prefix || table_count;
    -- avoid name collisions
    WHILE EXISTS (
      SELECT oid FROM pg_catalog.pg_class WHERE relname = uq_table_name AND relnamespace = sch_id
    ) LOOP
      table_count := table_count + 1;
      uq_table_name := prefix || table_count;
    END LOOP;
    fq_table_name := format('%I.%I', schema_name, uq_table_name);
  END IF;

  IF jsonb_path_exists(col_defs, '$[*] ? (@.name == "id")') THEN
    -- rename 'id' 
    SELECT array_agg(col_def->>'name') INTO existing_col_names FROM jsonb_array_elements(col_defs) col_def;
    id_col_name := msar.get_unique_local_identifier(existing_col_names, 'id');

    col_defs := (
      SELECT jsonb_agg(
        CASE WHEN col_def->>'name' = 'id' THEN jsonb_set(col_def, '{name}', to_jsonb(id_col_name))
          ELSE col_def END
    ) FROM jsonb_array_elements(col_defs) col_def);

    renamed_columns := jsonb_build_object('id', id_col_name);
  END IF;
  column_defs := array_cat(
    __msar.process_pk_col_def(
      COALESCE(pk_col_def->>'name', 'id'),
      COALESCE(pk_col_def->>'type', 'IDENTITY')::msar.pkey_kind
    ), __msar.process_col_def_jsonb(0, col_defs, false)
  );
  constraint_defs := __msar.process_con_def_jsonb(0, con_defs);
  PERFORM __msar.add_table(fq_table_name, column_defs, constraint_defs);
  created_table_id := fq_table_name::regclass::oid;
  PERFORM msar.comment_on_table(created_table_id, comment_);
  IF own_id IS NOT NULL THEN
    PERFORM msar.transfer_table_ownership(created_table_id, own_id);
  END IF;

  RETURN jsonb_build_object(
    'oid', created_table_id::bigint,
    'name', relname,
    'renamed_columns', renamed_columns::jsonb,
    'pkey_column_attnum', msar.get_pk_column(created_table_id)
  ) FROM pg_catalog.pg_class WHERE oid = created_table_id;
END;
$_$;


ALTER FUNCTION "msar"."add_mathesar_table"("sch_id" "oid", "tab_name" "text", "pk_col_def" "jsonb", "col_defs" "jsonb", "con_defs" "jsonb", "own_id" "regrole", "comment_" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."add_month_to_vector"("point_" "point", "date_" "date") RETURNS "point"
    LANGUAGE "sql" STRICT
    AS $$/*
Add the month, converted to a vector on unit circle, to the vector in the first argument.

We add a date to a point by
- Exracting the month and converting the result to degrees.
- converting the degrees to a point on the unit circle.
- adding that point to the point given in the first argument.

Args:
  point_: A point representing a vector.
  date_: A date_ that is converted to a vector and added to the vector represented by point_.

Returns:
  point that stores the resultant vector after the addition.
*/
WITH t(degrees) AS (SELECT msar.month_to_degrees(date_))
SELECT point_ + point(sind(degrees), cosd(degrees)) FROM t;
$$;


ALTER FUNCTION "msar"."add_month_to_vector"("point_" "point", "date_" "date") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."add_pkey_column"("tab_id" "regclass", "pkey_type" "msar"."pkey_kind", "drop_old_pkey_col" boolean DEFAULT false, "col_name" "text" DEFAULT 'id'::"text") RETURNS integer
    LANGUAGE "plpgsql"
    AS $$/*
Add a primary key column with a predefined default to a table.

Any name collisions for the column are resolved automatically, with this column's name deferring to
the original column names in the table.

Args:
  tab_id: This is the OID or name of the table to which we'll add the primary key column.
  pkey_type: The "type" of the pkey column. 'UUIDv4' means a `uuid` column using the
             `gen_random_uuid()` function for its default values. 'IDENTITY' means an `integer`
             using `GENERATED BY DEFAULT AS IDENTITY` for default values.
  drop_old_pkey_col: Whether we should drop the current primary key column during this operation.
  col_name: This optional value will set the name of the column.
*/
BEGIN
  IF drop_old_pkey_col THEN
    PERFORM msar.drop_columns(tab_id, msar.get_pk_column(tab_id));
  END IF;
  PERFORM msar.drop_constraint(tab_id, oid)
    FROM pg_constraint WHERE conrelid=tab_id AND contype='p';
  EXECUTE format(
    'ALTER TABLE %I.%I ADD COLUMN %I %s;',
    msar.get_relation_schema_name(tab_id),
    msar.get_relation_name(tab_id),
    msar.build_unique_column_name(tab_id, col_name),
    CASE pkey_type
      WHEN 'IDENTITY' THEN 'integer PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY'
      WHEN 'UUIDv4' THEN 'uuid PRIMARY KEY DEFAULT gen_random_uuid()'
    END
  );
  RETURN msar.get_pk_column(tab_id);
END;
$$;


ALTER FUNCTION "msar"."add_pkey_column"("tab_id" "regclass", "pkey_type" "msar"."pkey_kind", "drop_old_pkey_col" boolean, "col_name" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."add_record_to_table"("tab_id" "oid", "rec_def" "jsonb", "return_record_summaries" boolean DEFAULT false, "table_record_summary_templates" "jsonb" DEFAULT NULL::"jsonb") RETURNS "jsonb"
    LANGUAGE "plpgsql"
    AS $_$/*
Add a record to a table.

Args:
  tab_id: The OID of the table whose record we'll delete.
  rec_def: A JSON object defining the record.

The `rec_def` object's form is defined by the record being inserted.  It should have keys
corresponding to the attnums of desired columns and values corresponding to values we should
insert.

*/
DECLARE
  rec_created_id text;
  rec_created jsonb;
BEGIN
  EXECUTE format(
    $q$
    WITH insert_cte AS (%1$s RETURNING %2$I)
    SELECT *
    FROM insert_cte
    $q$,
    /* %1 */ msar.build_single_insert_expr(tab_id, rec_def),
    /* %2 */ msar.get_column_name(tab_id, msar.get_pk_column(tab_id))
  ) INTO rec_created_id;
  rec_created := msar.get_record_from_table(
    tab_id,
    rec_created_id,
    return_record_summaries,
    table_record_summary_templates
  );
  RETURN jsonb_build_object(
    'results', rec_created -> 'results',
    'record_summaries', rec_created -> 'record_summaries',
    'linked_record_summaries', rec_created -> 'linked_record_summaries'
  );
END;
$_$;


ALTER FUNCTION "msar"."add_record_to_table"("tab_id" "oid", "rec_def" "jsonb", "return_record_summaries" boolean, "table_record_summary_templates" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."add_time_to_vector"("point_" "point", "time_" time without time zone) RETURNS "point"
    LANGUAGE "sql" STRICT
    AS $$/*
Add the given time, converted to a vector on unit circle, to the vector given in first argument.

We add a time to a point by
- converting the time to a point on the unit circle.
- adding that point to the point given in the first argument.

Args:
  point_: A point representing a vector.
  time_: A time that is converted to a vector and added to the vector represented by point_.

Returns:
  point that stores the resultant vector after the addition.
*/
WITH t(degrees) AS (SELECT msar.time_to_degrees(time_))
SELECT point_ + point(sind(degrees), cosd(degrees)) FROM t;
$$;


ALTER FUNCTION "msar"."add_time_to_vector"("point_" "point", "time_" time without time zone) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."alter_columns"("tab_id" "oid", "col_alters" "jsonb") RETURNS integer[]
    LANGUAGE "plpgsql" STRICT
    AS $$/*
Alter columns of the given table in bulk, returning the IDs of the columns so altered.

Args:
  tab_id: The OID of the table whose columns we'll alter.
  col_alters: a JSONB describing the alterations to make.

For the specification of the col_alters JSONB, see the msar.process_col_alter_jsonb function.

Note that all alterations except renaming, commenting & setting/unsetting not-null are done in bulk,
and then all name changes are done one at a time afterwards. This is because the SQL design
specifies at most one name-changing clause per query.
*/
DECLARE
  col RECORD;
  col_alter_str text := msar.process_col_alter_jsonb(tab_id, col_alters);
  return_attnum_arr integer[];
BEGIN
  -- TODO: This section for bulk alter is to be removed entirely.
  --*************************************************
  IF col_alter_str IS NOT NULL THEN
    PERFORM __msar.exec_ddl(
      'ALTER TABLE %s %s',
      __msar.get_qualified_relation_name(tab_id),
      msar.process_col_alter_jsonb(tab_id, col_alters)
    );
  END IF;
  --**************************************************
  FOR col IN
    SELECT
      (col_alter_obj ->> 'attnum')::smallint AS attnum,
      (col_alter_obj -> 'not_null')::boolean AS not_null,
      (col_alter_obj ->> 'name')::text AS new_name,

      col_alter_obj->>'description' AS comment_,
      __msar.jsonb_key_exists(col_alter_obj, 'description') AS has_comment

    FROM jsonb_array_elements(col_alters) AS x(col_alter_obj)
  LOOP
    PERFORM msar.set_not_null(tab_id, col.attnum, col.not_null);
    PERFORM msar.rename_column(tab_id, col.attnum, col.new_name);
    IF col.has_comment THEN
      PERFORM msar.comment_on_column(tab_id, col.attnum, col.comment_);
    END IF;
    -- PG13 doesn't allow concat b/w integer[] and smallint need to typecast
    return_attnum_arr := return_attnum_arr || col.attnum::integer; 
  END LOOP;
  RETURN return_attnum_arr; -- do we really need this??
END;
$$;


ALTER FUNCTION "msar"."alter_columns"("tab_id" "oid", "col_alters" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."alter_table"("tab_id" "oid", "tab_alters" "jsonb") RETURNS "text"
    LANGUAGE "plpgsql" STRICT
    AS $$/*
Alter the name, description, or columns of a table, returning name of the altered table.

Args:
  tab_id: The OID of the table whose columns we'll alter.
  tab_alters: a JSONB describing the alterations to make.

  The tab_alters should have the form:
  {
    "name": <str>,
    "description": <str>
    "columns": <col_alters>,
  }
*/
DECLARE
  new_tab_name text;
  col_alters jsonb;
BEGIN
  new_tab_name := tab_alters->>'name';
  col_alters := tab_alters->'columns';
  PERFORM msar.rename_table(tab_id, new_tab_name);
  PERFORM CASE WHEN tab_alters ? 'description'
  THEN msar.comment_on_table(tab_id, tab_alters->>'description') END;
  PERFORM msar.alter_columns(tab_id, col_alters);
  RETURN __msar.get_qualified_relation_name_or_null(tab_id);
END;
$$;


ALTER FUNCTION "msar"."alter_table"("tab_id" "oid", "tab_alters" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."auto_generate_record_summary_template"("tab_id" "oid") RETURNS "jsonb"
    LANGUAGE "sql" STABLE STRICT
    AS $$/*
  Given a table OID, this function generates a record summary template for the table. The template
  is generated by picking the best column to use for the record summary and wrapping it in an array.

  Args:
    tab_id: The OID of the table for which to generate a record summary template.

  Return value:
    A JSON array that represents the record summary template as described in
      msar.build_record_summary_query_from_template. The array contains a single element which is an
      array of column attnums. The column attnum is the best column to use for the record summary.
*/
SELECT jsonb_build_array(jsonb_build_array(msar.get_default_summary_column(tab_id)));
$$;


ALTER FUNCTION "msar"."auto_generate_record_summary_template"("tab_id" "oid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."build_all_columns_expr"("tab_id" "regclass") RETURNS "text"
    LANGUAGE "sql" STABLE STRICT
    AS $_$/*
*/
SELECT string_agg(
  format(
    '%1$I.%2$I.%3$I AS %3$I',
    msar.get_relation_schema_name(tab_id),
    msar.get_relation_name(tab_id),
    attname
  ), ', '
)
FROM pg_catalog.pg_attribute
WHERE
  attrelid = tab_id
  AND attnum > 0
  AND NOT attisdropped;
$_$;


ALTER FUNCTION "msar"."build_all_columns_expr"("tab_id" "regclass") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."build_cast_expr"("tab_id" "regclass", "col_id" smallint, "typ_id" "regtype") RETURNS "text"
    LANGUAGE "sql" STRICT
    AS $$/*
Build an expression for casting a column in Mathesar, returning the text of that expression.

We throw an error in cases where the casting function doesn't exist. This is assumed to be an error
the user should know about.

Args:
  tab_id: The OID of the table whose column we're casting.
  col_id: The attnum of the column in the table.
  typ_id: The OID of the type we will cast to.
*/
SELECT msar.get_cast_function_name(typ_id)
  || '('
  || format('%I', msar.get_column_name(tab_id, col_id))
  || ')';
$$;


ALTER FUNCTION "msar"."build_cast_expr"("tab_id" "regclass", "col_id" smallint, "typ_id" "regtype") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."build_column_expr"("columns" "jsonb") RETURNS "text"
    LANGUAGE "sql" STABLE STRICT
    AS $$/*
Build an SQL select-target expression of columns from the argument.
This is meant to work together with output of functions like msar.get_selectable_columns.

Returns an expr in the form: msar.format_data("<column name>") as "<oid>", ...

Args:
  columns: The columns to build the expr for, in the following jsonb sample format:
           { "2": <name of column with oid 2>, "4": <name of column with oid 4> }

*/
SELECT string_agg(format('msar.format_data(%I) AS %I', sel_column.value, sel_column.key), ', ')
FROM jsonb_each_text(columns) as sel_column;
$$;


ALTER FUNCTION "msar"."build_column_expr"("columns" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."build_columns_expr"("tab_id" "regclass", "col_ids" smallint[]) RETURNS "text"
    LANGUAGE "sql" STABLE STRICT
    AS $_$/*
*/
SELECT string_agg(
  format(
    '%1$I.%2$I.%3$I AS %3$I',
    msar.get_relation_schema_name(tab_id),
    msar.get_relation_name(tab_id),
    attname
  ), ', '
)
FROM pg_catalog.pg_attribute JOIN unnest(col_ids) x(a) ON attnum = x.a
WHERE
  attrelid = tab_id;
$_$;


ALTER FUNCTION "msar"."build_columns_expr"("tab_id" "regclass", "col_ids" smallint[]) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."build_database_privilege_replace_expr"("rol_id" "regrole", "privileges_" "jsonb") RETURNS "text"
    LANGUAGE "sql" STABLE STRICT
    AS $_$
SELECT string_agg(
  format(
    concat(
      CASE WHEN privileges_ ? val THEN 'GRANT' ELSE 'REVOKE' END,
      ' %1$s ON DATABASE %2$I ',
      CASE WHEN privileges_ ? val THEN 'TO' ELSE 'FROM' END,
      ' %3$I'
    ),
    val,
    pg_catalog.current_database(),
    msar.get_role_name(rol_id)
  ),
  E';\n'
) || E';\n'
FROM unnest(ARRAY['CONNECT', 'CREATE', 'TEMPORARY']) as x(val);
$_$;


ALTER FUNCTION "msar"."build_database_privilege_replace_expr"("rol_id" "regrole", "privileges_" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."build_empty_record_summary_query"() RETURNS "text"
    LANGUAGE "sql" IMMUTABLE PARALLEL SAFE
    AS $_$/*
  Returns a stringified query structured consistently with a record summary query but which will
  yield no record summaries when run.
*/
  SELECT $q$ SELECT NULL AS key, NULL AS summary WHERE FALSE $q$;
$_$;


ALTER FUNCTION "msar"."build_empty_record_summary_query"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."build_expr"("rel_id" "oid", "tree" "jsonb") RETURNS "text"
    LANGUAGE "sql" STABLE STRICT
    AS $$
SELECT CASE tree ->> 'type'
  WHEN 'literal' THEN format('%L', tree ->> 'value')
  WHEN 'attnum' THEN format('%I', msar.get_column_name(rel_id, (tree ->> 'value')::smallint))
  ELSE
    format(max(expr_template), VARIADIC array_agg(msar.build_expr(rel_id, inner_tree)))
END
FROM jsonb_array_elements(tree -> 'args') inner_tree, msar.expr_templates
WHERE tree ->> 'type' = expr_key
$$;


ALTER FUNCTION "msar"."build_expr"("rel_id" "oid", "tree" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."build_grant_membership_expr"("parent_rol_id" "regrole", "g_roles" "oid"[]) RETURNS "text"
    LANGUAGE "sql" STABLE STRICT
    AS $_$
SELECT string_agg(
  format(
    'GRANT %1$I TO %2$I',
    msar.get_role_name(parent_rol_id),
    msar.get_role_name(rol_id)
  ),
  E';\n'
) || E';\n'
FROM unnest(g_roles) as x(rol_id);
$_$;


ALTER FUNCTION "msar"."build_grant_membership_expr"("parent_rol_id" "regrole", "g_roles" "oid"[]) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."build_group_count_expr"("tab_id" "oid", "group_" "jsonb") RETURNS "text"
    LANGUAGE "sql" STABLE STRICT
    AS $$/*
Build an expression that adds a column with a count for each group.
*/
SELECT 'count(1) OVER (PARTITION BY ' || msar.build_grouping_columns_expr(tab_id, group_) || ')';
$$;


ALTER FUNCTION "msar"."build_group_count_expr"("tab_id" "oid", "group_" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."build_group_id_expr"("tab_id" "oid", "group_" "jsonb") RETURNS "text"
    LANGUAGE "sql" STABLE STRICT
    AS $$/*
Build an expression to define an id value for each group.
*/
SELECT 'dense_rank() OVER (ORDER BY ' || msar.build_grouping_columns_expr(tab_id, group_) || ')';
$$;


ALTER FUNCTION "msar"."build_group_id_expr"("tab_id" "oid", "group_" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."build_grouping_columns_expr"("tab_id" "oid", "group_" "jsonb") RETURNS "text"
    LANGUAGE "sql" STABLE STRICT
    AS $$/*
Build a column expression for use in grouping window functions.

Args:
  tab_id: The OID of the table whose records we're grouping
  group_ A grouping definition.

The group_ object should have the form
    {
      "columns": [<int>, <int>, ...]
      "preproc": [<str>, <str>, ...]
    }

The items in the preproc array should be keys appearing in the
`expr_templates` table. The corresponding column will be wrapped
in the preproc function before grouping.
*/
SELECT string_agg(
  COALESCE(
    format(expr_template, quote_ident(msar.get_column_name(tab_id, col_id::smallint))),
    quote_ident(msar.get_column_name(tab_id, col_id::smallint))
  ), ', ' ORDER BY ordinality
)
FROM msar.expr_templates RIGHT JOIN ROWS FROM(
  jsonb_array_elements_text(group_ -> 'columns'),
  jsonb_array_elements_text(group_ -> 'preproc')
) WITH ORDINALITY AS x(col_id, preproc) ON expr_key = preproc
WHERE has_column_privilege(tab_id, col_id::smallint, 'SELECT');
$$;


ALTER FUNCTION "msar"."build_grouping_columns_expr"("tab_id" "oid", "group_" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."build_grouping_expr"("tab_id" "oid", "group_" "jsonb") RETURNS "text"
    LANGUAGE "sql" STABLE
    AS $$/*
Build an expression composed of an id and count for each group.

A group is defined by distinct combinations of the (potentially transformed by preproc functions)
columns passed in `group_`.
*/
SELECT concat(
  COALESCE(msar.build_group_id_expr(tab_id, group_), 'NULL'), ' AS __mathesar_gid, ',
  COALESCE(msar.build_group_count_expr(tab_id, group_), 'NULL'), ' AS __mathesar_gcount'
);
$$;


ALTER FUNCTION "msar"."build_grouping_expr"("tab_id" "oid", "group_" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."build_grouping_results_jsonb_expr"("tab_id" "oid", "cte_name" "text", "group_" "jsonb") RETURNS "text"
    LANGUAGE "sql" STABLE STRICT
    AS $_$/*
Build an SQL expresson string that, when added to the record listing query, produces a JSON array
with the groups resulting from the request.
*/
SELECT format(
  $gj$
  jsonb_build_object(
    'columns', %2$L::jsonb,
    'preproc', %3$L::jsonb,
    'groups', jsonb_agg(
      DISTINCT jsonb_build_object(
        'id', %1$I.id,
        'count', %1$I.count,
        'results_eq', %1$I.results_eq,
        'result_indices', %1$I.result_indices
      )
    )
  )
  $gj$,
  cte_name,
  group_ ->> 'columns',
  group_ ->> 'preproc'
)
$_$;


ALTER FUNCTION "msar"."build_grouping_results_jsonb_expr"("tab_id" "oid", "cte_name" "text", "group_" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."build_groups_cte_expr"("tab_id" "oid", "eq_cte_name" "text", "ranked_cte_name" "text", "group_" "jsonb") RETURNS "text"
    LANGUAGE "sql" STABLE STRICT
    AS $_$/*
*/
SELECT format(
  $gj$
    %1$I.__mathesar_gid AS id,
    __mathesar_gcount AS count,
    to_jsonb(%1$I) - '__mathesar_gid' AS results_eq,
    jsonb_agg( DISTINCT __mathesar_result_idx) AS result_indices
  FROM %1$I LEFT JOIN %2$I AS rcn ON %1$I.__mathesar_gid = rcn.__mathesar_gid
  GROUP BY id, count, results_eq
  $gj$,
  eq_cte_name,
  ranked_cte_name
);
$_$;


ALTER FUNCTION "msar"."build_groups_cte_expr"("tab_id" "oid", "eq_cte_name" "text", "ranked_cte_name" "text", "group_" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."build_insert_lookup_table"("field_info_list" "jsonb", "values_" "jsonb") RETURNS TABLE("table_name" "text", "column_names" "text", "values_" "text", "cte_name" "text", "from_cte_name" "text")
    LANGUAGE "sql" STABLE STRICT
    AS $$/*
Returns a lookup table for given field_info_list and values_

Example: Inserting into Items while creating a new book entry, adding a new Title,
creating a new entry for Author, picking a Publisher.
           table_name           |                  column_names                   |                values_                 | cte_name | from_cte_name 
 "Library Management"."Authors" | "First Name", "Last Name"                       | 'Jerome K.', 'Jerome                   | k1_cte   | 
 "Library Management"."Books"   | "Title", "Author", "Publisher"                  | 'Three men in a Boat', k1_cte.id, '12' | k0_cte   | k1_cte
 "Library Management"."Items"   | "Acquisition Date", "Acquisition Price", "Book" | '2025-10-09', '69.69', k0_cte.id       |          | k0_cte

Calling msar.form_insert() on this table would generate the following SQL:

WITH k1_cte AS (
  INSERT INTO "Library Management"."Authors"("First Name", "Last Name") SELECT 'Jerome K.', 'Jerome' RETURNING *
), k0_cte AS (
  INSERT INTO "Library Management"."Books"("Title", "Author", "Publisher") SELECT 'Three men in a Boat', k1_cte.id, '12' FROM k1_cte RETURNING *
) INSERT INTO "Library Management"."Items"("Acquisition Date", "Acquisition Price", "Book") SELECT '2025-10-09', '69.69', k0_cte.id FROM k0_cte RETURNING *
*/
WITH cte AS (
  SELECT
    pga.attname::name AS column_name,
    fields.table_oid::bigint AS table_oid,
    fields.depth::integer AS depth,
    CASE
      WHEN vals.value::jsonb->>'type' = 'create' THEN concat(quote_ident(concat(fields.key::text, '_cte')), '.', quote_ident(ref_attr.attname))
      WHEN vals.value::jsonb->>'type' = 'pick' THEN quote_nullable(vals.value::jsonb->>'value')
      ELSE quote_nullable(vals.value::jsonb #>> '{}')
    END AS value,
    CASE
      WHEN fields.parent_key IS NOT NULL THEN quote_ident(concat(fields.parent_key::text, '_cte'))
      ELSE NULL
    END AS cte_name,
    CASE
      WHEN vals.value::jsonb->>'type' = 'create' THEN quote_ident(concat(fields.key::text, '_cte'))
      ELSE NULL
    END AS from_cte_name
  FROM jsonb_to_recordset(field_info_list) AS fields(
    key text,
    parent_key text,
    column_attnum smallint,
    table_oid bigint,
    depth integer)
  INNER JOIN jsonb_each(values_) AS vals ON vals.key = fields.key
  LEFT JOIN pg_catalog.pg_attribute pga ON pga.attnum = fields.column_attnum AND pga.attrelid = fields.table_oid

  LEFT JOIN pg_constraint pgc
    ON fields.column_attnum = ANY(pgc.conkey)
    AND pgc.conrelid = fields.table_oid
    AND pgc.contype = 'f'
  LEFT JOIN unnest(pgc.conkey) WITH ORDINALITY AS ck(attnum, ord) ON ck.attnum = fields.column_attnum
  LEFT JOIN unnest(pgc.confkey) WITH ORDINALITY AS fk(attnum, ord) ON fk.ord = ck.ord
  LEFT JOIN pg_attribute ref_attr ON ref_attr.attrelid = pgc.confrelid AND ref_attr.attnum = fk.attnum
), multi_fks_cte AS (
  SELECT msar.raise_exception(
    'Inserting into a column with foreign key constraints referencing multiple columns is currently unsupported.'
  )
  FROM cte GROUP BY column_name, from_cte_name HAVING count(*) > 1
)
SELECT
  __msar.get_qualified_relation_name(table_oid) AS table_name,
  string_agg(quote_ident(column_name), ', ') AS column_names,
  string_agg(value, ', ') AS values_,
  cte_name,
  string_agg(from_cte_name, ', ') AS from_cte_name
FROM cte
CROSS JOIN (SELECT COUNT(*) FROM multi_fks_cte) AS force_multi_fks_cte_execution
GROUP BY table_oid, cte_name, depth ORDER BY depth DESC;
$$;


ALTER FUNCTION "msar"."build_insert_lookup_table"("field_info_list" "jsonb", "values_" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."build_linked_record_summaries_ctes"("tab_id" "oid", "table_record_summary_templates" "jsonb" DEFAULT NULL::"jsonb") RETURNS "text"
    LANGUAGE "sql" STABLE
    AS $_$/*
Build an SQL text expression defining a sequence of CTEs that give summaries for linked records.

Args:
  tab_id: The table for whose fkey values' linked records we'll get summaries.
*/
SELECT
  ', ' ||
  NULLIF(
    string_agg(
      format(
        $q$summary_cte_%1$s AS (%2$s)$q$,
        conkey,
        msar.build_record_summary_query_for_table(
          target_oid,
          confkey,
          table_record_summary_templates
        )
      ),
      ', '
    ),
    ''
  )
FROM msar.get_fkey_map_table(tab_id)
$_$;


ALTER FUNCTION "msar"."build_linked_record_summaries_ctes"("tab_id" "oid", "table_record_summary_templates" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."build_order_by_expr"("tab_id" "oid", "order_" "jsonb") RETURNS "text"
    LANGUAGE "sql" STABLE
    AS $$/*
Build an ORDER BY expression for the given table and order JSON.

The ORDER BY expression will refer to columns by their attnum. This is designed to work together
with `msar.build_selectable_column_expr`. It will only use the columns to which the user has access.
Finally, this function will append either a primary key, or all columns to the produced ORDER BY so
the resulting ordering is totally defined (i.e., deterministic).

Args:
  tab_id: The OID of the table whose columns we'll order by.
  order_: A JSONB array defining any desired ordering of columns.
*/
SELECT 'ORDER BY ' || msar.build_total_order_expr(tab_id, order_)
$$;


ALTER FUNCTION "msar"."build_order_by_expr"("tab_id" "oid", "order_" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."build_record_list_query_components_with_ctes"("tab_id" "oid", "limit_" integer, "offset_" integer, "order_" "jsonb", "filter_" "jsonb", "group_" "jsonb") RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE
    AS $_$/*
  Constructs the components necessary for generating enriched query results,
  including expressions, clauses, selectable_column list, and CTEs, for a table.

  Args:
    tab_id: The OID of the table whose records we'll get
    limit_: The maximum number of rows we'll return
    offset_: The number of rows to skip before returning records from following rows
    order_: An array of ordering definition objects
    filter_: An array of filter definition objects
    group_: An array of group definition objects

  Behavior:
    Fetches metadata about the table (selectable_column list, schema name, table name etc.,)
    Constructs expressions and SQL snippets (SELECT, WHERE, GROUP BY, etc.,)
    Generates two SQL queries:
      1. A query for paginated results (`results_cte_query`).
      2. A query to count the total matching rows (`count_cte_query`).
    Returns a jsonb object combining metadata, the expressions, and the generated SQL queries.
*/
DECLARE
  selectable_columns jsonb;
  expr_object jsonb;
  results_cte_query text;
  count_cte_query text;
BEGIN
  SELECT msar.get_selectable_columns(tab_id) INTO selectable_columns;

  SELECT jsonb_build_object(
    'relation_name', msar.get_relation_name(tab_id),
    'relation_schema_name', msar.get_relation_schema_name(tab_id),
    'selectable_columns', selectable_columns,
    'selectable_columns_expr', msar.build_column_expr(selectable_columns),
    'grouping_expr', msar.build_grouping_expr(tab_id, group_),
    'order_by_expr', msar.build_order_by_expr(tab_id, order_),
    'where_clause', msar.build_where_clause(tab_id, filter_)
  ) INTO expr_object;

  SELECT format(
    $q$SELECT %1$s, %2$s FROM %3$I.%4$I %5$s %6$s LIMIT %7$L OFFSET %8$L$q$,
    COALESCE(expr_object ->> 'selectable_columns_expr', 'NULL'),
    COALESCE(expr_object ->> 'grouping_expr', 'NULL'),
    expr_object ->> 'relation_schema_name',
    expr_object ->> 'relation_name',
    expr_object ->> 'where_clause',
    expr_object ->> 'order_by_expr',
    limit_,
    offset_
  ) INTO results_cte_query;

  SELECT format(
    $q$SELECT count(1) AS count FROM %1$I.%2$I %3$s$q$,
    expr_object ->> 'relation_schema_name',
    expr_object ->> 'relation_name',
    expr_object ->> 'where_clause'
  ) INTO count_cte_query;

  RETURN expr_object || jsonb_build_object(
    'results_cte_query', results_cte_query,
    'count_cte_query', count_cte_query
  );
END
$_$;


ALTER FUNCTION "msar"."build_record_list_query_components_with_ctes"("tab_id" "oid", "limit_" integer, "offset_" integer, "order_" "jsonb", "filter_" "jsonb", "group_" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."build_record_summary_query_for_table"("tab_id" "oid", "key_col_id" smallint DEFAULT NULL::smallint, "table_record_summary_templates" "jsonb" DEFAULT '{}'::"jsonb") RETURNS "text"
    LANGUAGE "sql" STABLE
    AS $$/*
Return text for an SQL query that will summarize records from a table.

Args:
  tab_id: the OID of the table for which we're getting summaries.
  key_col_id: (optional) This is a column attnum in the table. When given, this column will be used
    as the key in the summary. If not given, the table's PK column will be used.
  table_record_summary_templates: (optional) A JSON object that maps table OIDs to record summary
    templates.
*/
SELECT msar.build_record_summary_query_from_template(
  tab_id,
  COALESCE(key_col_id, msar.get_selectable_pkey_attnum(tab_id)),
  COALESCE(
    NULLIF(table_record_summary_templates -> tab_id::text, 'null'::jsonb),
    msar.auto_generate_record_summary_template(tab_id)
  )
);
$$;


ALTER FUNCTION "msar"."build_record_summary_query_for_table"("tab_id" "oid", "key_col_id" smallint, "table_record_summary_templates" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."build_record_summary_query_from_template"("tab_id" "oid", "key_col_id" smallint, "template" "jsonb") RETURNS "text"
    LANGUAGE "plpgsql" STABLE
    AS $$/*
  Given a table OID and a record summary template, this function returns a query that can be used to
  generate record summaries for the table.

  Args:
    tab_id: The OID of the table for which to generate a record summary query.
    template: A JSON array that represents the record summary template (described in detail below).

  Example template:

    [
      "#",
      [1],
      " - ",
      [2, 5],
      " - ",
      [2, 5, 10]
    ]

  A string entry in the template represents static text to be included in the record summary
  verbatim.

  An array entry in the template represents a reference to data. Each element in the array is a
  column attnum. The first column attnum refers to a column in the base table. If the array
  contains more than one column reference, it represents a chain of FK columns starting from
  the base table and ending with a non-FK column. This function follows the foreign keys to
  produce the joins. Multi-column FK constraints are not supported.

  Return value: a stringified query which produces a result set matching the structure described
    in the return value of msar.get_record_summaries_via_query.
*/
DECLARE
  base_alias CONSTANT text := 'base';
  expr_parts text[] := ARRAY[]::text[];
  expr text;
  base_sch_name text := msar.get_relation_schema_name(tab_id);
  base_tab_name text := msar.get_relation_name(tab_id);
  base_key_col_name text := msar.get_column_name(tab_id, key_col_id);
  template_part jsonb;
  join_clauses text[] := ARRAY[]::text[];
  join_section text;
BEGIN
  IF key_col_id IS NULL THEN
    -- If we don't have a key column, then we can't generate a record summary query.
    RETURN msar.build_empty_record_summary_query();
  END IF;

  IF NOT pg_catalog.has_column_privilege(tab_id, key_col_id, 'SELECT') THEN
    -- If we don't have permission to select the key column, then we can't generate a record
    RETURN msar.build_empty_record_summary_query();
  END IF;

  IF jsonb_typeof(template) <> 'array' THEN
    RAISE EXCEPTION 'Record summary template must be a JSON array.';
  END IF;

  <<template_parts_loop>>
  FOR template_part IN SELECT jsonb_array_elements(template) LOOP
    DECLARE
      ref_chain smallint[] := msar.extract_smallints(template_part);
      ref_chain_length integer := array_length(ref_chain, 1);
      fk_col_id smallint;
      contextual_tab_id oid := tab_id;
      prev_alias text := base_alias;
      ref_col_id smallint;
      ref_col_name text;
    BEGIN
      -- Column reference template parts
      IF ref_chain_length > 0 THEN
        -- Except for the final ref_chain element, process all array elements as attnums of FK
        -- columns.
        FOREACH fk_col_id IN ARRAY ref_chain[1:ref_chain_length-1] LOOP
          DECLARE
            fk_col_name text;
            ref_tab_id oid;
            ref_sch_name text;
            ref_tab_name text;
            alias text;
            join_clause text;
          BEGIN
            IF NOT pg_catalog.has_column_privilege(contextual_tab_id, fk_col_id, 'SELECT') THEN
              -- Silently ignore FK columns that we don't have permissions to select.
              CONTINUE template_parts_loop;
            END IF;

            fk_col_name := msar.get_column_name(contextual_tab_id, fk_col_id);

            IF fk_col_name IS NULL THEN
              -- Silently ignore references to non-existing FK columns. This can happen if a column
              -- has been deleted.
              CONTINUE template_parts_loop;
            END IF;

            SELECT confrelid, confkey[1] INTO ref_tab_id, ref_col_id
            FROM pg_catalog.pg_constraint
            WHERE contype = 'f' AND conrelid = contextual_tab_id AND conkey = array[fk_col_id];

            IF ref_tab_id IS NULL THEN
              -- Silently ignore references to non-FK columns. This can happen if the constraint
              -- has been dropped.
              CONTINUE template_parts_loop;
            END IF;

            IF NOT pg_catalog.has_column_privilege(ref_tab_id, ref_col_id, 'SELECT') THEN
              -- Silently ignore FK columns which point to columns that we don't have permission to
              -- select.
              CONTINUE template_parts_loop;
            END IF;

            ref_tab_name := msar.get_relation_name(ref_tab_id);
            ref_sch_name := msar.get_relation_schema_name(ref_tab_id);
            ref_col_name := msar.get_column_name(ref_tab_id, ref_col_id);
            alias := concat(prev_alias, '_', fk_col_id);
            join_clause := concat(
              'LEFT JOIN ',
              quote_ident(ref_sch_name), '.', quote_ident(ref_tab_name),
              ' AS ', alias,
              ' ON ',
              alias, '.', quote_ident(ref_col_name),
              ' = ',
              prev_alias, '.', quote_ident(fk_col_name)
            );

            IF NOT join_clauses @> ARRAY[join_clause] THEN
              join_clauses := array_append(join_clauses, join_clause);
            END IF;
            prev_alias := alias;
            contextual_tab_id := ref_tab_id;
          END;
        END LOOP;

        ref_col_id := ref_chain[ref_chain_length];

        IF NOT pg_catalog.has_column_privilege(contextual_tab_id, ref_col_id, 'SELECT') THEN
          -- Silently ignore the final column reference if we don't have permission to select it.
          CONTINUE template_parts_loop;
        END IF;

        ref_col_name := msar.get_column_name(contextual_tab_id, ref_col_id);
        IF ref_col_name IS NOT NULL THEN
          expr_parts := array_append(
            expr_parts,
            concat(
              'COALESCE(msar.format_data(',
              prev_alias, '.', quote_ident(ref_col_name),
              E')::text, \'\')'
            )
          );
        END IF;

      -- String literal template parts
      ELSIF jsonb_typeof(template_part) = 'string' THEN
        expr_parts := array_append(expr_parts, quote_literal(template_part #>> '{}'));
      END IF;
    END;
  END LOOP;

  IF cardinality(expr_parts) = 0 THEN
    -- If the template didn't give us anything to render, then we show '?' as a fallback. This can
    -- happen if (e.g.) the template only contains a reference which is no longer valid due to a
    -- column being deleted.
    expr_parts := array_append(expr_parts, quote_literal('?'));
  END IF;

  join_section := CASE
    WHEN array_length(join_clauses, 1) = 0 THEN ''
    ELSE E'\n' || array_to_string(join_clauses, E'\n')
  END;

  expr := array_to_string(expr_parts, E'\n    || ');

  RETURN concat(
    E'SELECT \n',
    '  ', base_alias, '.', quote_ident(base_key_col_name), E' AS key, \n',
    '  ', expr, E' AS summary \n',
    'FROM ',
    quote_ident(base_sch_name), '.', quote_ident(base_tab_name),
    ' AS ', base_alias,
    join_section
  );
END;
$$;


ALTER FUNCTION "msar"."build_record_summary_query_from_template"("tab_id" "oid", "key_col_id" smallint, "template" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."build_results_eq_cte_expr"("tab_id" "oid", "cte_name" "text", "group_" "jsonb") RETURNS "text"
    LANGUAGE "sql" STABLE STRICT
    AS $_$
SELECT string_agg(
  format(
    '%1$s AS %2$I',
    COALESCE(
      format(expr_template, quote_ident(cte_name) || '.' || quote_ident(col_id)),
      quote_ident(cte_name) || '.' || quote_ident(col_id)
    ),
    col_id
  ),
  ', ' ORDER BY ordinality
) || ', __mathesar_gid FROM ' || quote_ident(cte_name)
|| ' GROUP BY __mathesar_gid, '
|| string_agg(
  format(
    '%1$I',
    col_id
  ),
  ', ' ORDER BY ordinality
)
FROM msar.expr_templates RIGHT JOIN ROWS FROM(
  jsonb_array_elements_text(group_ -> 'columns'),
  jsonb_array_elements_text(group_ -> 'preproc')
) WITH ORDINALITY AS x(col_id, preproc) ON expr_key = preproc
WHERE has_column_privilege(tab_id, col_id::smallint, 'SELECT');
$_$;


ALTER FUNCTION "msar"."build_results_eq_cte_expr"("tab_id" "oid", "cte_name" "text", "group_" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."build_results_jsonb_array_expr"("cte_name" "text", "order_by_expr" "text") RETURNS "text"
    LANGUAGE "sql" STABLE
    AS $_$/*
Build an SQL expresson string that, when added to the record listing query, produces a JSON array
with the records resulting from the request.
*/
SELECT format(
  $j$
    COALESCE(
      jsonb_agg(
        to_jsonb(%2$I) - %3$L - %4$L %1$s
      ), jsonb_build_array()
    )
  $j$,
  /* %1 */ order_by_expr,
  /* %2 */ cte_name,
  /* %3 */ '__mathesar_gid',
  /* %4 */ '__mathesar_gcount'
);
$_$;


ALTER FUNCTION "msar"."build_results_jsonb_array_expr"("cte_name" "text", "order_by_expr" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."build_results_setof_jsonb_expr"("cte_name" "text") RETURNS "text"
    LANGUAGE "sql" STABLE
    AS $_$/*
Build an SQL expresson string that, when added to the record listing query, produces a setof jsonb
results with the records resulting from the request.
*/
SELECT format(
  'to_jsonb(%1$I) - %2$L - %3$L',
  /* %1 */ cte_name,
  /* %2 */ '__mathesar_gid',
  /* %3 */ '__mathesar_gcount'
);
$_$;


ALTER FUNCTION "msar"."build_results_setof_jsonb_expr"("cte_name" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."build_revoke_membership_expr"("parent_rol_id" "regrole", "r_roles" "oid"[]) RETURNS "text"
    LANGUAGE "sql" STABLE STRICT
    AS $_$
SELECT string_agg(
  format(
    'REVOKE %1$I FROM %2$I',
    msar.get_role_name(parent_rol_id),
    msar.get_role_name(rol_id)
  ),
  E';\n'
) || E';\n'
FROM unnest(r_roles) as x(rol_id);
$_$;


ALTER FUNCTION "msar"."build_revoke_membership_expr"("parent_rol_id" "regrole", "r_roles" "oid"[]) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."build_schema_privilege_replace_expr"("sch_id" "regnamespace", "rol_id" "regrole", "privileges_" "jsonb") RETURNS "text"
    LANGUAGE "sql" STABLE STRICT
    AS $_$
SELECT string_agg(
  format(
    concat(
      CASE WHEN privileges_ ? val THEN 'GRANT' ELSE 'REVOKE' END,
      ' %1$s ON SCHEMA %2$I ',
      CASE WHEN privileges_ ? val THEN 'TO' ELSE 'FROM' END,
      ' %3$I'
    ),
    val,
    msar.get_schema_name(sch_id),
    msar.get_role_name(rol_id)
  ),
  E';\n'
) || E';\n'
FROM unnest(ARRAY['USAGE', 'CREATE']) as x(val);
$_$;


ALTER FUNCTION "msar"."build_schema_privilege_replace_expr"("sch_id" "regnamespace", "rol_id" "regrole", "privileges_" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."build_selectable_column_expr"("tab_id" "oid") RETURNS "text"
    LANGUAGE "sql" STABLE STRICT
    AS $$/*
Build an SQL select-target expression of only columns to which the user has access.

Given columns with attnums 2, 3, and 4, and assuming the user has access only to columns 2 and 4,
this function will return an expression of the form:

msar.format_data("column_name") AS "2", msar.format_data("another_column_name") AS "4"

Args:
  tab_id: The OID of the table containing the columns to select.
*/
SELECT msar.build_column_expr(msar.get_selectable_columns(tab_id));
$$;


ALTER FUNCTION "msar"."build_selectable_column_expr"("tab_id" "oid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."build_self_summary_json_expr"("tab_id" "oid") RETURNS "text"
    LANGUAGE "sql" STABLE STRICT
    AS $_$/*
*/
SELECT CASE WHEN quote_ident(msar.get_selectable_pkey_attnum(tab_id)::text) IS NOT NULL THEN
  $j$
  COALESCE(
    jsonb_object_agg(
      summary_cte_self.key, summary_cte_self.summary
    ) FILTER (WHERE summary_cte_self.key IS NOT NULL), '{}'::jsonb
  ) AS summary_self
  $j$
END;
$_$;


ALTER FUNCTION "msar"."build_self_summary_json_expr"("tab_id" "oid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."build_single_insert_expr"("tab_id" "oid", "rec_def" "jsonb") RETURNS "text"
    LANGUAGE "sql" STABLE STRICT
    AS $$
SELECT CASE WHEN NULLIF(rec_def, '{}'::jsonb) IS NOT NULL THEN
  (
    SELECT
      format(
        'INSERT INTO %I.%I (%s) VALUES (%s)',
        msar.get_relation_schema_name(tab_id),
        msar.get_relation_name(tab_id),
        string_agg(format('%I', msar.get_column_name(tab_id, key::smallint)), ', '),
        string_agg(format('%L', value), ', ')
      )
    FROM jsonb_each_text(rec_def)
  )
ELSE
  format(
    'INSERT INTO %I.%I DEFAULT VALUES',
    msar.get_relation_schema_name(tab_id),
    msar.get_relation_name(tab_id)
  )
END;
$$;


ALTER FUNCTION "msar"."build_single_insert_expr"("tab_id" "oid", "rec_def" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."build_source_update_cte_join_condition_expr"("target_tab_id" "regclass", "target_join_col_id" smallint, "added_col_ids" smallint[], "update_target_cte_name" "text", "insert_cte_name" "text") RETURNS "text"
    LANGUAGE "sql" STABLE STRICT
    AS $_$
SELECT 'ON ' || string_agg(
  format(
    '%1$I.%3$I IS NOT DISTINCT FROM %2$I.%3$I',
    update_target_cte_name,
    insert_cte_name,
    attname
  ), ' AND '
)
FROM
  pg_catalog.pg_attribute
  JOIN unnest(msar.get_other_column_ids(target_tab_id, added_col_ids || target_join_col_id)) x(a)
  ON attnum = x.a
WHERE
  attrelid = target_tab_id;
$_$;


ALTER FUNCTION "msar"."build_source_update_cte_join_condition_expr"("target_tab_id" "regclass", "target_join_col_id" smallint, "added_col_ids" smallint[], "update_target_cte_name" "text", "insert_cte_name" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."build_source_update_move_cols_equal_expr"("source_tab_id" "regclass", "move_col_ids" smallint[], "cte_name" "text") RETURNS "text"
    LANGUAGE "sql" STABLE STRICT
    AS $_$
SELECT string_agg(
  format(
    -- TODO should be IS NOT DISTINCT FROM
    '%1$I.%2$I.%3$I = %4$I.%3$I',
    msar.get_relation_schema_name(source_tab_id),
    msar.get_relation_name(source_tab_id),
    attname,
    cte_name
  ), ' AND '
)
FROM pg_catalog.pg_attribute JOIN unnest(move_col_ids) x(a) ON attnum = x.a
WHERE
  attrelid = source_tab_id;
$_$;


ALTER FUNCTION "msar"."build_source_update_move_cols_equal_expr"("source_tab_id" "regclass", "move_col_ids" smallint[], "cte_name" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."build_summary_join_expr_for_table"("tab_id" "oid", "cte_name" "text") RETURNS "text"
    LANGUAGE "sql" STABLE STRICT
    AS $_$/*
Build an SQL expression to join the summary CTEs to the main CTE along fkey values.

Args:
  tab_oid: The table defining the columns of the main CTE.
  cte_name: The name of the main CTE we'll join the summary CTEs to.
*/
WITH fkey_map_cte AS (SELECT * FROM msar.get_fkey_map_table(tab_id))
SELECT concat(
  format(E'\nLEFT JOIN summary_cte_self ON %1$I.', cte_name)
  || quote_ident(msar.get_selectable_pkey_attnum(tab_id)::text)
  || ' = summary_cte_self.key' ,
  string_agg(
    format(
      $j$
      LEFT JOIN summary_cte_%1$s ON %2$I.%1$I = summary_cte_%1$s.key$j$,
      conkey,
      cte_name
    ), ' '
  )
)
FROM fkey_map_cte;
$_$;


ALTER FUNCTION "msar"."build_summary_join_expr_for_table"("tab_id" "oid", "cte_name" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."build_summary_json_expr_for_table"("tab_id" "oid") RETURNS "text"
    LANGUAGE "sql" STABLE STRICT
    AS $_$/*
Build a JSON object with the results of summarizing linked records.

Args:
  tab_oid: The OID of the table for which we're getting linked record summaries.
*/
WITH fkey_map_cte AS (SELECT * FROM msar.get_fkey_map_table(tab_id))
SELECT string_agg(
  format(
    $j$
      COALESCE(
        jsonb_object_agg(
          summary_cte_%1$s.key, summary_cte_%1$s.summary
        ) FILTER (WHERE summary_cte_%1$s.key IS NOT NULL), '{}'::jsonb
      ) AS %1$I
    $j$,
    conkey
  ), ', '
)
FROM fkey_map_cte;
$_$;


ALTER FUNCTION "msar"."build_summary_json_expr_for_table"("tab_id" "oid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."build_table_privilege_replace_expr"("tab_id" "regclass", "rol_id" "regrole", "privileges_" "jsonb") RETURNS "text"
    LANGUAGE "sql" STABLE STRICT
    AS $_$
SELECT string_agg(
  format(
    concat(
      CASE WHEN privileges_ ? val THEN 'GRANT' ELSE 'REVOKE' END,
      ' %1$s ON TABLE %2$I.%3$I ',
      CASE WHEN privileges_ ? val THEN 'TO' ELSE 'FROM' END,
      ' %4$I'
    ),
    val,
    msar.get_relation_schema_name(tab_id),
    msar.get_relation_name(tab_id),
    msar.get_role_name(rol_id)
  ),
  E';\n'
) || E';\n'
FROM unnest(ARRAY['INSERT', 'SELECT', 'UPDATE', 'DELETE', 'TRUNCATE', 'REFERENCES', 'TRIGGER']) as x(val);
$_$;


ALTER FUNCTION "msar"."build_table_privilege_replace_expr"("tab_id" "regclass", "rol_id" "regrole", "privileges_" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."build_total_order_expr"("tab_id" "oid", "order_" "jsonb") RETURNS "text"
    LANGUAGE "sql" STABLE
    AS $$/*
Build a deterministic order expression for the given table and order JSON.
Args:
  tab_id: The OID of the table whose columns we'll order by.
  order_: A JSONB array defining any desired ordering of columns.
*/
SELECT string_agg(format('%I %s', attnum, msar.sanitize_direction(direction)), ', ')
FROM jsonb_to_recordset(
    COALESCE(
      COALESCE(order_, '[]'::jsonb) || msar.get_pkey_order(tab_id),
      COALESCE(order_, '[]'::jsonb) || msar.get_total_order(tab_id)
    )
)
  AS x(attnum smallint, direction text)
WHERE has_column_privilege(tab_id, attnum, 'SELECT');
$$;


ALTER FUNCTION "msar"."build_total_order_expr"("tab_id" "oid", "order_" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."build_type_text"("typ_jsonb" "jsonb") RETURNS "text"
    LANGUAGE "sql"
    AS $$/*
Turns the given type-describing JSON into a proper string defining a type with arguments

The input JSON should be of the form
  {
    "id": <integer>
    "schema": <str>,
    "name": <str>,
    "modifier": <integer>,
    "options": {
      "length": <integer>,
      "precision": <integer>,
      "scale": <integer>
      "fields": <str>,
      "array": <boolean>
    }
  }

All fields are optional, and a null value as input returns 'text'
*/
SELECT COALESCE(
  -- First choice is the type specified by numeric IDs, since they're most reliable.
  format_type(
    (typ_jsonb ->> 'id')::integer,
    (typ_jsonb ->> 'modifier')::integer
  ),
  -- Second choice is the type specified by string IDs.
  __msar.get_formatted_base_type(
    COALESCE(
      __msar.build_qualified_name_sql(typ_jsonb ->> 'schema', typ_jsonb ->> 'name'),
      typ_jsonb ->> 'name',
      'text'  -- We fall back to 'text' when input is null or empty.
    ),
    typ_jsonb -> 'options'
  ) || CASE
    WHEN (typ_jsonb -> 'options' ->> 'array')::boolean THEN
      '[]'
    ELSE ''
  END
)
$$;


ALTER FUNCTION "msar"."build_type_text"("typ_jsonb" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."build_type_text_complete"("typ_jsonb" "jsonb", "old_type" "text") RETURNS "text"
    LANGUAGE "sql" STRICT
    AS $$/*
Build the text name of a type, using the old type as a base if only options are given.

The main use for this is to allow for altering only the options of the type of a column.

Args:
  typ_jsonb: This is a jsonb denoting the new type.
  old_type: This is the old type name, with no options.

The typ_jsonb should be in the form:
{
  "name": <str> (optional),
  "options": <obj> (optional)
}

*/
SELECT msar.build_type_text(
  jsonb_strip_nulls(
    jsonb_build_object(
      'name', COALESCE(typ_jsonb ->> 'name', old_type),
      'options', typ_jsonb -> 'options'
    )
  )
);
$$;


ALTER FUNCTION "msar"."build_type_text_complete"("typ_jsonb" "jsonb", "old_type" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."build_unique_column_name"("tab_id" "oid", "col_name" "text") RETURNS "text"
    LANGUAGE "plpgsql" STRICT
    AS $$/*
Get a unique column name based on the given name.

Args:
  tab_id: The OID of the table where the column name should be unique.
  col_name: The resulting column name will be equal to or at least based on this.

See the msar.get_fresh_copy_name function for how unique column names are generated.
*/
DECLARE
  col_attnum smallint;
BEGIN
  col_attnum := msar.get_attnum(tab_id, col_name);
  RETURN CASE
    WHEN col_attnum IS NOT NULL THEN msar.get_fresh_copy_name(tab_id, col_attnum) ELSE col_name
  END;
END;
$$;


ALTER FUNCTION "msar"."build_unique_column_name"("tab_id" "oid", "col_name" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."build_unique_fkey_column_name"("tab_id" "oid", "fk_col_name" "text", "frel_name" "text") RETURNS "text"
    LANGUAGE "plpgsql"
    AS $$/*
Create a unique name for a foreign key column.

Args:
  tab_id: The OID of the table where the column name should be unique.
  fk_col_name: The base name for the foreign key column.
  frel_name: The name of the referent table. Used for creating fk_col_name if not given.

Note that frel_name will be used to build the foreign key column name if it's not given. The result
will be of the form: <frel_name>_id. Then, we apply some logic to ensure the result is unique.
*/
BEGIN
  fk_col_name := COALESCE(fk_col_name, format('%s_id', frel_name));
  RETURN msar.build_unique_column_name(tab_id, fk_col_name);
END;
$$;


ALTER FUNCTION "msar"."build_unique_fkey_column_name"("tab_id" "oid", "fk_col_name" "text", "frel_name" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."build_unqualified_columns_expr"("tab_id" "regclass", "col_ids" smallint[]) RETURNS "text"
    LANGUAGE "sql" STABLE STRICT
    AS $$/*
*/
SELECT string_agg(format('%I', attname), ', ')
FROM pg_catalog.pg_attribute JOIN unnest(col_ids) x(a) ON attnum = x.a
WHERE
  attrelid = tab_id;
$$;


ALTER FUNCTION "msar"."build_unqualified_columns_expr"("tab_id" "regclass", "col_ids" smallint[]) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."build_update_expr"("tab_id" "oid", "rec_def" "jsonb") RETURNS "text"
    LANGUAGE "sql" STABLE STRICT
    AS $$
SELECT
  format(
    'UPDATE %I.%I SET (%s) = ROW(%s)',
    msar.get_relation_schema_name(tab_id),
    msar.get_relation_name(tab_id),
    string_agg(format('%I', msar.get_column_name(tab_id, key::smallint)), ', '),
    string_agg(format('%L', value), ', ')
  )
FROM jsonb_each_text(rec_def);
$$;


ALTER FUNCTION "msar"."build_update_expr"("tab_id" "oid", "rec_def" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."build_where_clause"("rel_id" "oid", "tree" "jsonb") RETURNS "text"
    LANGUAGE "sql" STABLE STRICT
    AS $$
SELECT 'WHERE ' || msar.build_expr(rel_id, tree);
$$;


ALTER FUNCTION "msar"."build_where_clause"("rel_id" "oid", "tree" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to__double_quote_char_double_quote_"("mathesar_types"."multicurrency_money") RETURNS "char"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to__double_quote_char_double_quote_"("mathesar_types"."multicurrency_money") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to__double_quote_char_double_quote_"(bit) RETURNS "char"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to__double_quote_char_double_quote_"(bit) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to__double_quote_char_double_quote_"(boolean) RETURNS "char"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to__double_quote_char_double_quote_"(boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to__double_quote_char_double_quote_"("bytea") RETURNS "char"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to__double_quote_char_double_quote_"("bytea") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to__double_quote_char_double_quote_"("cidr") RETURNS "char"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to__double_quote_char_double_quote_"("cidr") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to__double_quote_char_double_quote_"("date") RETURNS "char"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to__double_quote_char_double_quote_"("date") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to__double_quote_char_double_quote_"("daterange") RETURNS "char"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to__double_quote_char_double_quote_"("daterange") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to__double_quote_char_double_quote_"(real) RETURNS "char"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to__double_quote_char_double_quote_"(real) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to__double_quote_char_double_quote_"(double precision) RETURNS "char"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to__double_quote_char_double_quote_"(double precision) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to__double_quote_char_double_quote_"("inet") RETURNS "char"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to__double_quote_char_double_quote_"("inet") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to__double_quote_char_double_quote_"("int4range") RETURNS "char"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to__double_quote_char_double_quote_"("int4range") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to__double_quote_char_double_quote_"(bigint) RETURNS "char"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to__double_quote_char_double_quote_"(bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to__double_quote_char_double_quote_"("int8range") RETURNS "char"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to__double_quote_char_double_quote_"("int8range") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to__double_quote_char_double_quote_"(interval) RETURNS "char"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to__double_quote_char_double_quote_"(interval) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to__double_quote_char_double_quote_"(json) RETURNS "char"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to__double_quote_char_double_quote_"(json) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to__double_quote_char_double_quote_"("jsonb") RETURNS "char"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to__double_quote_char_double_quote_"("jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to__double_quote_char_double_quote_"("macaddr") RETURNS "char"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to__double_quote_char_double_quote_"("macaddr") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to__double_quote_char_double_quote_"("money") RETURNS "char"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to__double_quote_char_double_quote_"("money") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to__double_quote_char_double_quote_"(numeric) RETURNS "char"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to__double_quote_char_double_quote_"(numeric) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to__double_quote_char_double_quote_"("numrange") RETURNS "char"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to__double_quote_char_double_quote_"("numrange") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to__double_quote_char_double_quote_"("oid") RETURNS "char"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to__double_quote_char_double_quote_"("oid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to__double_quote_char_double_quote_"("regclass") RETURNS "char"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to__double_quote_char_double_quote_"("regclass") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to__double_quote_char_double_quote_"("text") RETURNS "char"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to__double_quote_char_double_quote_"("text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to__double_quote_char_double_quote_"(time without time zone) RETURNS "char"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to__double_quote_char_double_quote_"(time without time zone) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to__double_quote_char_double_quote_"(timestamp without time zone) RETURNS "char"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to__double_quote_char_double_quote_"(timestamp without time zone) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to__double_quote_char_double_quote_"(timestamp with time zone) RETURNS "char"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to__double_quote_char_double_quote_"(timestamp with time zone) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to__double_quote_char_double_quote_"(time with time zone) RETURNS "char"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to__double_quote_char_double_quote_"(time with time zone) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to__double_quote_char_double_quote_"("tsrange") RETURNS "char"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to__double_quote_char_double_quote_"("tsrange") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to__double_quote_char_double_quote_"("tstzrange") RETURNS "char"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to__double_quote_char_double_quote_"("tstzrange") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to__double_quote_char_double_quote_"("tsvector") RETURNS "char"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to__double_quote_char_double_quote_"("tsvector") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to__double_quote_char_double_quote_"("uuid") RETURNS "char"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to__double_quote_char_double_quote_"("uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_bigint"(boolean) RETURNS bigint
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT CASE WHEN $1 THEN 1::bigint ELSE 0::bigint END;
$_$;


ALTER FUNCTION "msar"."cast_to_bigint"(boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_bigint"(real) RETURNS bigint
    LANGUAGE "plpgsql" STRICT
    AS $_$
  DECLARE integer_res bigint;
  BEGIN
    SELECT $1::bigint INTO integer_res;
    IF integer_res = $1 THEN
      RETURN integer_res;
    END IF;
    RAISE EXCEPTION '% cannot be cast to bigint without loss', $1;
  END;
$_$;


ALTER FUNCTION "msar"."cast_to_bigint"(real) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_bigint"(double precision) RETURNS bigint
    LANGUAGE "plpgsql" STRICT
    AS $_$
  DECLARE integer_res bigint;
  BEGIN
    SELECT $1::bigint INTO integer_res;
    IF integer_res = $1 THEN
      RETURN integer_res;
    END IF;
    RAISE EXCEPTION '% cannot be cast to bigint without loss', $1;
  END;
$_$;


ALTER FUNCTION "msar"."cast_to_bigint"(double precision) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_bigint"(bigint) RETURNS bigint
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::bigint;
$_$;


ALTER FUNCTION "msar"."cast_to_bigint"(bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_bigint"("money") RETURNS bigint
    LANGUAGE "plpgsql" STRICT
    AS $_$
  DECLARE integer_res bigint;
  BEGIN
    SELECT $1::bigint INTO integer_res;
    IF integer_res = $1 THEN
      RETURN integer_res;
    END IF;
    RAISE EXCEPTION '% cannot be cast to bigint without loss', $1;
  END;
$_$;


ALTER FUNCTION "msar"."cast_to_bigint"("money") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_bigint"(numeric) RETURNS bigint
    LANGUAGE "plpgsql" STRICT
    AS $_$
  DECLARE integer_res bigint;
  BEGIN
    SELECT $1::bigint INTO integer_res;
    IF integer_res = $1 THEN
      RETURN integer_res;
    END IF;
    RAISE EXCEPTION '% cannot be cast to bigint without loss', $1;
  END;
$_$;


ALTER FUNCTION "msar"."cast_to_bigint"(numeric) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_bigint"("text") RETURNS bigint
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::bigint;
$_$;


ALTER FUNCTION "msar"."cast_to_bigint"("text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_boolean"(boolean) RETURNS boolean
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::boolean;
$_$;


ALTER FUNCTION "msar"."cast_to_boolean"(boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_boolean"(real) RETURNS boolean
    LANGUAGE "plpgsql" STRICT
    AS $_$
BEGIN
  IF $1<>0 AND $1<>1 THEN
    RAISE EXCEPTION '% is not a boolean', $1; END IF;
  RETURN $1<>0;
END;
$_$;


ALTER FUNCTION "msar"."cast_to_boolean"(real) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_boolean"(double precision) RETURNS boolean
    LANGUAGE "plpgsql" STRICT
    AS $_$
BEGIN
  IF $1<>0 AND $1<>1 THEN
    RAISE EXCEPTION '% is not a boolean', $1; END IF;
  RETURN $1<>0;
END;
$_$;


ALTER FUNCTION "msar"."cast_to_boolean"(double precision) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_boolean"(bigint) RETURNS boolean
    LANGUAGE "plpgsql" STRICT
    AS $_$
BEGIN
  IF $1<>0 AND $1<>1 THEN
    RAISE EXCEPTION '% is not a boolean', $1; END IF;
  RETURN $1<>0;
END;
$_$;


ALTER FUNCTION "msar"."cast_to_boolean"(bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_boolean"(numeric) RETURNS boolean
    LANGUAGE "plpgsql" STRICT
    AS $_$
BEGIN
  IF $1<>0 AND $1<>1 THEN
    RAISE EXCEPTION '% is not a boolean', $1; END IF;
  RETURN $1<>0;
END;
$_$;


ALTER FUNCTION "msar"."cast_to_boolean"(numeric) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_boolean"("text") RETURNS boolean
    LANGUAGE "plpgsql" STRICT
    AS $_$
DECLARE
  istrue boolean;
BEGIN
  SELECT
    $1='1' OR lower($1) = 'on'
    OR lower($1)='t' OR lower($1)='true'
    OR lower($1)='y' OR lower($1)='yes'
  INTO istrue;
  IF istrue
    OR $1='0' OR lower($1) = 'off'
    OR lower($1)='f' OR lower($1)='false'
    OR lower($1)='n' OR lower($1)='no'
  THEN
    RETURN istrue;
  END IF;
  RAISE EXCEPTION '% is not a boolean', $1;
END;
$_$;


ALTER FUNCTION "msar"."cast_to_boolean"("text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_character"("mathesar_types"."multicurrency_money") RETURNS character
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_character"("mathesar_types"."multicurrency_money") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_character"(bit) RETURNS character
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_character"(bit) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_character"(boolean) RETURNS character
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_character"(boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_character"("bytea") RETURNS character
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_character"("bytea") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_character"("cidr") RETURNS character
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_character"("cidr") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_character"("date") RETURNS character
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_character"("date") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_character"("daterange") RETURNS character
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_character"("daterange") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_character"(real) RETURNS character
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_character"(real) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_character"(double precision) RETURNS character
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_character"(double precision) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_character"("inet") RETURNS character
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_character"("inet") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_character"("int4range") RETURNS character
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_character"("int4range") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_character"(bigint) RETURNS character
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_character"(bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_character"("int8range") RETURNS character
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_character"("int8range") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_character"(interval) RETURNS character
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_character"(interval) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_character"(json) RETURNS character
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_character"(json) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_character"("jsonb") RETURNS character
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_character"("jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_character"("macaddr") RETURNS character
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_character"("macaddr") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_character"("money") RETURNS character
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_character"("money") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_character"(numeric) RETURNS character
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_character"(numeric) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_character"("numrange") RETURNS character
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_character"("numrange") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_character"("oid") RETURNS character
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_character"("oid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_character"("regclass") RETURNS character
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_character"("regclass") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_character"("text") RETURNS character
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_character"("text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_character"(time without time zone) RETURNS character
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_character"(time without time zone) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_character"(timestamp without time zone) RETURNS character
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_character"(timestamp without time zone) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_character"(timestamp with time zone) RETURNS character
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_character"(timestamp with time zone) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_character"(time with time zone) RETURNS character
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_character"(time with time zone) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_character"("tsrange") RETURNS character
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_character"("tsrange") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_character"("tstzrange") RETURNS character
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_character"("tstzrange") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_character"("tsvector") RETURNS character
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_character"("tsvector") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_character"("uuid") RETURNS character
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_character"("uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_character_varying"("mathesar_types"."multicurrency_money") RETURNS character varying
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_character_varying"("mathesar_types"."multicurrency_money") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_character_varying"(bit) RETURNS character varying
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_character_varying"(bit) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_character_varying"(boolean) RETURNS character varying
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_character_varying"(boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_character_varying"("bytea") RETURNS character varying
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_character_varying"("bytea") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_character_varying"("cidr") RETURNS character varying
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_character_varying"("cidr") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_character_varying"("date") RETURNS character varying
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_character_varying"("date") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_character_varying"("daterange") RETURNS character varying
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_character_varying"("daterange") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_character_varying"(real) RETURNS character varying
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_character_varying"(real) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_character_varying"(double precision) RETURNS character varying
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_character_varying"(double precision) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_character_varying"("inet") RETURNS character varying
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_character_varying"("inet") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_character_varying"("int4range") RETURNS character varying
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_character_varying"("int4range") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_character_varying"(bigint) RETURNS character varying
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_character_varying"(bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_character_varying"("int8range") RETURNS character varying
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_character_varying"("int8range") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_character_varying"(interval) RETURNS character varying
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_character_varying"(interval) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_character_varying"(json) RETURNS character varying
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_character_varying"(json) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_character_varying"("jsonb") RETURNS character varying
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_character_varying"("jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_character_varying"("macaddr") RETURNS character varying
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_character_varying"("macaddr") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_character_varying"("money") RETURNS character varying
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_character_varying"("money") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_character_varying"(numeric) RETURNS character varying
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_character_varying"(numeric) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_character_varying"("numrange") RETURNS character varying
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_character_varying"("numrange") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_character_varying"("oid") RETURNS character varying
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_character_varying"("oid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_character_varying"("regclass") RETURNS character varying
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_character_varying"("regclass") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_character_varying"("text") RETURNS character varying
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_character_varying"("text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_character_varying"(time without time zone) RETURNS character varying
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_character_varying"(time without time zone) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_character_varying"(timestamp without time zone) RETURNS character varying
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_character_varying"(timestamp without time zone) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_character_varying"(timestamp with time zone) RETURNS character varying
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_character_varying"(timestamp with time zone) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_character_varying"(time with time zone) RETURNS character varying
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_character_varying"(time with time zone) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_character_varying"("tsrange") RETURNS character varying
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_character_varying"("tsrange") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_character_varying"("tstzrange") RETURNS character varying
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_character_varying"("tstzrange") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_character_varying"("tsvector") RETURNS character varying
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_character_varying"("tsvector") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_character_varying"("uuid") RETURNS character varying
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_character_varying"("uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_date"("date") RETURNS "date"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::timestamp with time zone;
$_$;


ALTER FUNCTION "msar"."cast_to_date"("date") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_date"("text") RETURNS "date"
    LANGUAGE "plpgsql" STRICT
    AS $_$
DECLARE
  timestamp_value_with_tz NUMERIC;
  timestamp_value NUMERIC;
  date_value NUMERIC;
BEGIN
  SET LOCAL TIME ZONE 'UTC';
  SELECT EXTRACT(EPOCH FROM $1::TIMESTAMP WITH TIME ZONE ) INTO timestamp_value_with_tz;
  SELECT EXTRACT(EPOCH FROM $1::TIMESTAMP WITHOUT TIME ZONE) INTO timestamp_value;
  SELECT EXTRACT(EPOCH FROM $1::DATE ) INTO date_value;
  IF (timestamp_value_with_tz = date_value) THEN
    RETURN $1::date;
  END IF;
  RAISE EXCEPTION '% is not a date', $1;
END;
$_$;


ALTER FUNCTION "msar"."cast_to_date"("text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_date"(timestamp with time zone) RETURNS "date"
    LANGUAGE "plpgsql" STRICT
    AS $_$
DECLARE
  timestamp_value_with_tz NUMERIC;
  timestamp_value NUMERIC;
  date_value NUMERIC;
BEGIN
  SET LOCAL TIME ZONE 'UTC';
  SELECT EXTRACT(EPOCH FROM $1::TIMESTAMP WITH TIME ZONE ) INTO timestamp_value_with_tz;
  SELECT EXTRACT(EPOCH FROM $1::TIMESTAMP WITHOUT TIME ZONE) INTO timestamp_value;
  SELECT EXTRACT(EPOCH FROM $1::DATE ) INTO date_value;
  IF (timestamp_value_with_tz = date_value) THEN
    RETURN $1::date;
  END IF;
  RAISE EXCEPTION '% is not a date', $1;
END;
$_$;


ALTER FUNCTION "msar"."cast_to_date"(timestamp with time zone) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_double_precision"(boolean) RETURNS double precision
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT CASE WHEN $1 THEN 1::double precision ELSE 0::double precision END;
$_$;


ALTER FUNCTION "msar"."cast_to_double_precision"(boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_double_precision"(real) RETURNS double precision
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::double precision;
$_$;


ALTER FUNCTION "msar"."cast_to_double_precision"(real) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_double_precision"(double precision) RETURNS double precision
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::double precision;
$_$;


ALTER FUNCTION "msar"."cast_to_double_precision"(double precision) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_double_precision"(bigint) RETURNS double precision
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::double precision;
$_$;


ALTER FUNCTION "msar"."cast_to_double_precision"(bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_double_precision"(numeric) RETURNS double precision
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::double precision;
$_$;


ALTER FUNCTION "msar"."cast_to_double_precision"(numeric) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_double_precision"("text") RETURNS double precision
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::double precision;
$_$;


ALTER FUNCTION "msar"."cast_to_double_precision"("text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_email"("text") RETURNS "mathesar_types"."email"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::mathesar_types.email;
$_$;


ALTER FUNCTION "msar"."cast_to_email"("text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_integer"(boolean) RETURNS integer
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT CASE WHEN $1 THEN 1::integer ELSE 0::integer END;
$_$;


ALTER FUNCTION "msar"."cast_to_integer"(boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_integer"(real) RETURNS integer
    LANGUAGE "plpgsql" STRICT
    AS $_$
  DECLARE integer_res integer;
  BEGIN
    SELECT $1::integer INTO integer_res;
    IF integer_res = $1 THEN
      RETURN integer_res;
    END IF;
    RAISE EXCEPTION '% cannot be cast to integer without loss', $1;
  END;
$_$;


ALTER FUNCTION "msar"."cast_to_integer"(real) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_integer"(double precision) RETURNS integer
    LANGUAGE "plpgsql" STRICT
    AS $_$
  DECLARE integer_res integer;
  BEGIN
    SELECT $1::integer INTO integer_res;
    IF integer_res = $1 THEN
      RETURN integer_res;
    END IF;
    RAISE EXCEPTION '% cannot be cast to integer without loss', $1;
  END;
$_$;


ALTER FUNCTION "msar"."cast_to_integer"(double precision) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_integer"(bigint) RETURNS integer
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::integer;
$_$;


ALTER FUNCTION "msar"."cast_to_integer"(bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_integer"("money") RETURNS integer
    LANGUAGE "plpgsql" STRICT
    AS $_$
  DECLARE integer_res integer;
  BEGIN
    SELECT $1::integer INTO integer_res;
    IF integer_res = $1 THEN
      RETURN integer_res;
    END IF;
    RAISE EXCEPTION '% cannot be cast to integer without loss', $1;
  END;
$_$;


ALTER FUNCTION "msar"."cast_to_integer"("money") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_integer"(numeric) RETURNS integer
    LANGUAGE "plpgsql" STRICT
    AS $_$
  DECLARE integer_res integer;
  BEGIN
    SELECT $1::integer INTO integer_res;
    IF integer_res = $1 THEN
      RETURN integer_res;
    END IF;
    RAISE EXCEPTION '% cannot be cast to integer without loss', $1;
  END;
$_$;


ALTER FUNCTION "msar"."cast_to_integer"(numeric) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_integer"("text") RETURNS integer
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::integer;
$_$;


ALTER FUNCTION "msar"."cast_to_integer"("text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_interval"(interval) RETURNS interval
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1;
$_$;


ALTER FUNCTION "msar"."cast_to_interval"(interval) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_interval"("text") RETURNS interval
    LANGUAGE "plpgsql" STRICT
    AS $_$
BEGIN
  PERFORM $1::numeric;
  RAISE EXCEPTION '% is a numeric', $1;
  EXCEPTION
    WHEN sqlstate '22P02' THEN
      RETURN $1::interval;
END;
$_$;


ALTER FUNCTION "msar"."cast_to_interval"("text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_json"(json) RETURNS json
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::json;
$_$;


ALTER FUNCTION "msar"."cast_to_json"(json) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_json"("jsonb") RETURNS json
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::json;
$_$;


ALTER FUNCTION "msar"."cast_to_json"("jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_json"("text") RETURNS json
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::json;
$_$;


ALTER FUNCTION "msar"."cast_to_json"("text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_jsonb"(json) RETURNS "jsonb"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::jsonb;
$_$;


ALTER FUNCTION "msar"."cast_to_jsonb"(json) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_jsonb"("jsonb") RETURNS "jsonb"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::jsonb;
$_$;


ALTER FUNCTION "msar"."cast_to_jsonb"("jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_jsonb"("text") RETURNS "jsonb"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::jsonb;
$_$;


ALTER FUNCTION "msar"."cast_to_jsonb"("text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_mathesar_json_array"(json) RETURNS "mathesar_types"."mathesar_json_array"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::mathesar_types.mathesar_json_array;
$_$;


ALTER FUNCTION "msar"."cast_to_mathesar_json_array"(json) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_mathesar_json_array"("jsonb") RETURNS "mathesar_types"."mathesar_json_array"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::mathesar_types.mathesar_json_array;
$_$;


ALTER FUNCTION "msar"."cast_to_mathesar_json_array"("jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_mathesar_json_array"("text") RETURNS "mathesar_types"."mathesar_json_array"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::mathesar_types.mathesar_json_array;
$_$;


ALTER FUNCTION "msar"."cast_to_mathesar_json_array"("text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_mathesar_json_object"(json) RETURNS "mathesar_types"."mathesar_json_object"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::mathesar_types.mathesar_json_object;
$_$;


ALTER FUNCTION "msar"."cast_to_mathesar_json_object"(json) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_mathesar_json_object"("jsonb") RETURNS "mathesar_types"."mathesar_json_object"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::mathesar_types.mathesar_json_object;
$_$;


ALTER FUNCTION "msar"."cast_to_mathesar_json_object"("jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_mathesar_json_object"("text") RETURNS "mathesar_types"."mathesar_json_object"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::mathesar_types.mathesar_json_object;
$_$;


ALTER FUNCTION "msar"."cast_to_mathesar_json_object"("text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_mathesar_money"(real) RETURNS "mathesar_types"."mathesar_money"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::numeric::mathesar_types.mathesar_money;
$_$;


ALTER FUNCTION "msar"."cast_to_mathesar_money"(real) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_mathesar_money"(double precision) RETURNS "mathesar_types"."mathesar_money"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::numeric::mathesar_types.mathesar_money;
$_$;


ALTER FUNCTION "msar"."cast_to_mathesar_money"(double precision) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_mathesar_money"(bigint) RETURNS "mathesar_types"."mathesar_money"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::numeric::mathesar_types.mathesar_money;
$_$;


ALTER FUNCTION "msar"."cast_to_mathesar_money"(bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_mathesar_money"("money") RETURNS "mathesar_types"."mathesar_money"
    LANGUAGE "plpgsql" STRICT
    AS $_$
DECLARE
  decimal_point text;
  is_negative boolean;
  money_arr text[];
  money_num text;
BEGIN
  SELECT msar.get_mathesar_money_array($1::text) INTO money_arr;
  IF money_arr IS NULL THEN
    RAISE EXCEPTION '% cannot be cast to mathesar_types.mathesar_money', $1;
  END IF;
  SELECT money_arr[1] INTO money_num;
  SELECT ltrim(to_char(1, 'D'), ' ') INTO decimal_point;
  IF money_arr[2] IS NOT NULL THEN
    SELECT regexp_replace(money_num, money_arr[2], '', 'gq') INTO money_num;
  END IF;
  IF money_arr[3] IS NOT NULL THEN
    SELECT regexp_replace(money_num, money_arr[3], decimal_point, 'q') INTO money_num;
  END IF;
  RETURN money_num::mathesar_types.mathesar_money;
END;
$_$;


ALTER FUNCTION "msar"."cast_to_mathesar_money"("money") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_mathesar_money"(numeric) RETURNS "mathesar_types"."mathesar_money"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::numeric::mathesar_types.mathesar_money;
$_$;


ALTER FUNCTION "msar"."cast_to_mathesar_money"(numeric) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_mathesar_money"("text") RETURNS "mathesar_types"."mathesar_money"
    LANGUAGE "plpgsql" STRICT
    AS $_$
DECLARE
  decimal_point text;
  is_negative boolean;
  money_arr text[];
  money_num text;
BEGIN
  SELECT msar.get_mathesar_money_array($1::text) INTO money_arr;
  IF money_arr IS NULL THEN
    RAISE EXCEPTION '% cannot be cast to mathesar_types.mathesar_money', $1;
  END IF;
  SELECT money_arr[1] INTO money_num;
  SELECT ltrim(to_char(1, 'D'), ' ') INTO decimal_point;
  IF money_arr[2] IS NOT NULL THEN
    SELECT regexp_replace(money_num, money_arr[2], '', 'gq') INTO money_num;
  END IF;
  IF money_arr[3] IS NOT NULL THEN
    SELECT regexp_replace(money_num, money_arr[3], decimal_point, 'q') INTO money_num;
  END IF;
  RETURN money_num::mathesar_types.mathesar_money;
END;
$_$;


ALTER FUNCTION "msar"."cast_to_mathesar_money"("text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_mathesar_money"("num" "text", "group_sep" "char", "decimal_p" "char", "curr_pref" "text", "curr_suff" "text") RETURNS "mathesar_types"."mathesar_money"
    LANGUAGE "sql" STRICT
    AS $_$
  SELECT CASE WHEN num ~ '^.*(-|\(.+\)).*$' THEN -- Handle negative values
    ('-' || replace(replace(replace(replace(replace(replace(replace(num, '-', ''), '(', ''), ')', ''), curr_pref, ''), curr_suff, ''), group_sep, ''), decimal_p, ltrim(to_char(1, 'D'), ' ')))::mathesar_types.mathesar_money
  ELSE
    replace(replace(replace(replace(num, curr_pref, ''), curr_suff, ''), group_sep, ''), decimal_p, ltrim(to_char(1, 'D'), ' '))::mathesar_types.mathesar_money
  END;
$_$;


ALTER FUNCTION "msar"."cast_to_mathesar_money"("num" "text", "group_sep" "char", "decimal_p" "char", "curr_pref" "text", "curr_suff" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_money"(real) RETURNS "money"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::numeric::money;
$_$;


ALTER FUNCTION "msar"."cast_to_money"(real) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_money"(double precision) RETURNS "money"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::numeric::money;
$_$;


ALTER FUNCTION "msar"."cast_to_money"(double precision) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_money"(bigint) RETURNS "money"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::numeric::money;
$_$;


ALTER FUNCTION "msar"."cast_to_money"(bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_money"("money") RETURNS "money"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::money;
$_$;


ALTER FUNCTION "msar"."cast_to_money"("money") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_money"(numeric) RETURNS "money"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::numeric::money;
$_$;


ALTER FUNCTION "msar"."cast_to_money"(numeric) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_money"("text") RETURNS "money"
    LANGUAGE "plpgsql" STRICT
    AS $_$
DECLARE
  currency text;
BEGIN
  SELECT to_char(1, 'L') INTO currency;
  IF ($1 LIKE '%' || currency) OR ($1 LIKE currency || '%') THEN
    RETURN $1::money;
  END IF;
  RAISE EXCEPTION '% cannot be cast to money as currency symbol is missing', $1;
END;
$_$;


ALTER FUNCTION "msar"."cast_to_money"("text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_multicurrency_money"("mathesar_types"."multicurrency_money") RETURNS "mathesar_types"."multicurrency_money"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::mathesar_types.multicurrency_money;
$_$;


ALTER FUNCTION "msar"."cast_to_multicurrency_money"("mathesar_types"."multicurrency_money") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_multicurrency_money"(real) RETURNS "mathesar_types"."multicurrency_money"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT ROW($1, 'USD')::mathesar_types.multicurrency_money;
$_$;


ALTER FUNCTION "msar"."cast_to_multicurrency_money"(real) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_multicurrency_money"(double precision) RETURNS "mathesar_types"."multicurrency_money"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT ROW($1, 'USD')::mathesar_types.multicurrency_money;
$_$;


ALTER FUNCTION "msar"."cast_to_multicurrency_money"(double precision) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_multicurrency_money"(bigint) RETURNS "mathesar_types"."multicurrency_money"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT ROW($1, 'USD')::mathesar_types.multicurrency_money;
$_$;


ALTER FUNCTION "msar"."cast_to_multicurrency_money"(bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_multicurrency_money"("money") RETURNS "mathesar_types"."multicurrency_money"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT ROW($1, 'USD')::mathesar_types.multicurrency_money;
$_$;


ALTER FUNCTION "msar"."cast_to_multicurrency_money"("money") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_multicurrency_money"(numeric) RETURNS "mathesar_types"."multicurrency_money"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT ROW($1, 'USD')::mathesar_types.multicurrency_money;
$_$;


ALTER FUNCTION "msar"."cast_to_multicurrency_money"(numeric) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_multicurrency_money"("text") RETURNS "mathesar_types"."multicurrency_money"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT ROW($1, 'USD')::mathesar_types.multicurrency_money;
$_$;


ALTER FUNCTION "msar"."cast_to_multicurrency_money"("text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_name"("mathesar_types"."multicurrency_money") RETURNS "name"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_name"("mathesar_types"."multicurrency_money") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_name"(bit) RETURNS "name"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_name"(bit) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_name"(boolean) RETURNS "name"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_name"(boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_name"("bytea") RETURNS "name"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_name"("bytea") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_name"("cidr") RETURNS "name"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_name"("cidr") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_name"("date") RETURNS "name"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_name"("date") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_name"("daterange") RETURNS "name"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_name"("daterange") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_name"(real) RETURNS "name"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_name"(real) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_name"(double precision) RETURNS "name"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_name"(double precision) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_name"("inet") RETURNS "name"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_name"("inet") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_name"("int4range") RETURNS "name"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_name"("int4range") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_name"(bigint) RETURNS "name"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_name"(bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_name"("int8range") RETURNS "name"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_name"("int8range") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_name"(interval) RETURNS "name"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_name"(interval) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_name"(json) RETURNS "name"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_name"(json) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_name"("jsonb") RETURNS "name"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_name"("jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_name"("macaddr") RETURNS "name"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_name"("macaddr") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_name"("money") RETURNS "name"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_name"("money") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_name"(numeric) RETURNS "name"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_name"(numeric) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_name"("numrange") RETURNS "name"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_name"("numrange") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_name"("oid") RETURNS "name"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_name"("oid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_name"("regclass") RETURNS "name"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_name"("regclass") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_name"("text") RETURNS "name"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_name"("text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_name"(time without time zone) RETURNS "name"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_name"(time without time zone) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_name"(timestamp without time zone) RETURNS "name"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_name"(timestamp without time zone) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_name"(timestamp with time zone) RETURNS "name"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_name"(timestamp with time zone) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_name"(time with time zone) RETURNS "name"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_name"(time with time zone) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_name"("tsrange") RETURNS "name"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_name"("tsrange") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_name"("tstzrange") RETURNS "name"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_name"("tstzrange") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_name"("tsvector") RETURNS "name"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_name"("tsvector") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_name"("uuid") RETURNS "name"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_name"("uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_numeric"(boolean) RETURNS numeric
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT CASE WHEN $1 THEN 1::numeric ELSE 0::numeric END;
$_$;


ALTER FUNCTION "msar"."cast_to_numeric"(boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_numeric"(real) RETURNS numeric
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::numeric;
$_$;


ALTER FUNCTION "msar"."cast_to_numeric"(real) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_numeric"(double precision) RETURNS numeric
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::numeric;
$_$;


ALTER FUNCTION "msar"."cast_to_numeric"(double precision) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_numeric"(bigint) RETURNS numeric
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::numeric;
$_$;


ALTER FUNCTION "msar"."cast_to_numeric"(bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_numeric"("money") RETURNS numeric
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::numeric;
$_$;


ALTER FUNCTION "msar"."cast_to_numeric"("money") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_numeric"(numeric) RETURNS numeric
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::numeric;
$_$;


ALTER FUNCTION "msar"."cast_to_numeric"(numeric) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_numeric"("text") RETURNS numeric
    LANGUAGE "plpgsql" STRICT
    AS $_$
DECLARE
  decimal_point text;
  is_negative boolean;
  numeric_arr text[];
  numeric text;
BEGIN
  SELECT msar.get_numeric_array($1::text) INTO numeric_arr;
  IF numeric_arr IS NULL THEN
    RAISE EXCEPTION '% cannot be cast to numeric', $1;
  END IF;
  SELECT numeric_arr[1] INTO numeric;
  SELECT ltrim(to_char(1, 'D'), ' ') INTO decimal_point;
  SELECT $1::text ~ '^-.*$' INTO is_negative;
  IF numeric_arr[2] IS NOT NULL THEN
    SELECT regexp_replace(numeric, numeric_arr[2], '', 'gq') INTO numeric;
  END IF;
  IF numeric_arr[3] IS NOT NULL THEN
    SELECT regexp_replace(numeric, numeric_arr[3], decimal_point, 'q') INTO numeric;
  END IF;
  IF is_negative THEN
    RETURN ('-' || numeric)::numeric;
  END IF;
  RETURN numeric::numeric;
END;
$_$;


ALTER FUNCTION "msar"."cast_to_numeric"("text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_numeric"("num" "text", "group_sep" "char", "decimal_p" "char") RETURNS numeric
    LANGUAGE "sql" STRICT
    AS $$/*
Cast to numeric with prechosen group and decimal separators.

For performance, this function does not check for correctness of the given number format. It simply
replaces and removes characters as directed, then attempts to cast to numeric.

Args:
  num: The string we'll cast to numeric.
  group_sep: Any instance of this character will be removed from `num` before casting.
  decimal_p: Any instance of this character will be replaced with the locale decimal before casting.
*/
SELECT replace(replace(num, group_sep, ''), decimal_p, ltrim(to_char(1, 'D'), ' '))::numeric;
$$;


ALTER FUNCTION "msar"."cast_to_numeric"("num" "text", "group_sep" "char", "decimal_p" "char") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_real"(boolean) RETURNS real
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT CASE WHEN $1 THEN 1::real ELSE 0::real END;
$_$;


ALTER FUNCTION "msar"."cast_to_real"(boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_real"(real) RETURNS real
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::real;
$_$;


ALTER FUNCTION "msar"."cast_to_real"(real) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_real"(double precision) RETURNS real
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::real;
$_$;


ALTER FUNCTION "msar"."cast_to_real"(double precision) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_real"(bigint) RETURNS real
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::real;
$_$;


ALTER FUNCTION "msar"."cast_to_real"(bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_real"(numeric) RETURNS real
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::real;
$_$;


ALTER FUNCTION "msar"."cast_to_real"(numeric) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_real"("text") RETURNS real
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::real;
$_$;


ALTER FUNCTION "msar"."cast_to_real"("text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_smallint"(boolean) RETURNS smallint
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT CASE WHEN $1 THEN 1::smallint ELSE 0::smallint END;
$_$;


ALTER FUNCTION "msar"."cast_to_smallint"(boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_smallint"(real) RETURNS smallint
    LANGUAGE "plpgsql" STRICT
    AS $_$
  DECLARE integer_res smallint;
  BEGIN
    SELECT $1::smallint INTO integer_res;
    IF integer_res = $1 THEN
      RETURN integer_res;
    END IF;
    RAISE EXCEPTION '% cannot be cast to smallint without loss', $1;
  END;
$_$;


ALTER FUNCTION "msar"."cast_to_smallint"(real) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_smallint"(double precision) RETURNS smallint
    LANGUAGE "plpgsql" STRICT
    AS $_$
  DECLARE integer_res smallint;
  BEGIN
    SELECT $1::smallint INTO integer_res;
    IF integer_res = $1 THEN
      RETURN integer_res;
    END IF;
    RAISE EXCEPTION '% cannot be cast to smallint without loss', $1;
  END;
$_$;


ALTER FUNCTION "msar"."cast_to_smallint"(double precision) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_smallint"(bigint) RETURNS smallint
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::smallint;
$_$;


ALTER FUNCTION "msar"."cast_to_smallint"(bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_smallint"("money") RETURNS smallint
    LANGUAGE "plpgsql" STRICT
    AS $_$
  DECLARE integer_res smallint;
  BEGIN
    SELECT $1::smallint INTO integer_res;
    IF integer_res = $1 THEN
      RETURN integer_res;
    END IF;
    RAISE EXCEPTION '% cannot be cast to smallint without loss', $1;
  END;
$_$;


ALTER FUNCTION "msar"."cast_to_smallint"("money") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_smallint"(numeric) RETURNS smallint
    LANGUAGE "plpgsql" STRICT
    AS $_$
  DECLARE integer_res smallint;
  BEGIN
    SELECT $1::smallint INTO integer_res;
    IF integer_res = $1 THEN
      RETURN integer_res;
    END IF;
    RAISE EXCEPTION '% cannot be cast to smallint without loss', $1;
  END;
$_$;


ALTER FUNCTION "msar"."cast_to_smallint"(numeric) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_smallint"("text") RETURNS smallint
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::smallint;
$_$;


ALTER FUNCTION "msar"."cast_to_smallint"("text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_text"("mathesar_types"."multicurrency_money") RETURNS "text"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_text"("mathesar_types"."multicurrency_money") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_text"(bit) RETURNS "text"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_text"(bit) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_text"(boolean) RETURNS "text"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_text"(boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_text"("bytea") RETURNS "text"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_text"("bytea") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_text"("cidr") RETURNS "text"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_text"("cidr") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_text"("date") RETURNS "text"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_text"("date") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_text"("daterange") RETURNS "text"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_text"("daterange") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_text"(real) RETURNS "text"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_text"(real) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_text"(double precision) RETURNS "text"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_text"(double precision) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_text"("inet") RETURNS "text"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_text"("inet") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_text"("int4range") RETURNS "text"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_text"("int4range") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_text"(bigint) RETURNS "text"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_text"(bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_text"("int8range") RETURNS "text"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_text"("int8range") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_text"(interval) RETURNS "text"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_text"(interval) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_text"(json) RETURNS "text"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_text"(json) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_text"("jsonb") RETURNS "text"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_text"("jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_text"("macaddr") RETURNS "text"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_text"("macaddr") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_text"("money") RETURNS "text"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_text"("money") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_text"(numeric) RETURNS "text"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_text"(numeric) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_text"("numrange") RETURNS "text"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_text"("numrange") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_text"("oid") RETURNS "text"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_text"("oid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_text"("regclass") RETURNS "text"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_text"("regclass") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_text"("text") RETURNS "text"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_text"("text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_text"(time without time zone) RETURNS "text"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_text"(time without time zone) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_text"(timestamp without time zone) RETURNS "text"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_text"(timestamp without time zone) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_text"(timestamp with time zone) RETURNS "text"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_text"(timestamp with time zone) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_text"(time with time zone) RETURNS "text"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_text"(time with time zone) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_text"("tsrange") RETURNS "text"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_text"("tsrange") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_text"("tstzrange") RETURNS "text"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_text"("tstzrange") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_text"("tsvector") RETURNS "text"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_text"("tsvector") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_text"("uuid") RETURNS "text"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::text;
$_$;


ALTER FUNCTION "msar"."cast_to_text"("uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_time_with_time_zone"("text") RETURNS time with time zone
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::time with time zone;
$_$;


ALTER FUNCTION "msar"."cast_to_time_with_time_zone"("text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_time_with_time_zone"(time with time zone) RETURNS time with time zone
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::time with time zone;
$_$;


ALTER FUNCTION "msar"."cast_to_time_with_time_zone"(time with time zone) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_time_without_time_zone"("text") RETURNS time without time zone
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::time without time zone;
$_$;


ALTER FUNCTION "msar"."cast_to_time_without_time_zone"("text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_time_without_time_zone"(time with time zone) RETURNS time without time zone
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::time without time zone;
$_$;


ALTER FUNCTION "msar"."cast_to_time_without_time_zone"(time with time zone) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_timestamp_with_time_zone"("text") RETURNS timestamp with time zone
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::timestamp with time zone;
$_$;


ALTER FUNCTION "msar"."cast_to_timestamp_with_time_zone"("text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_timestamp_with_time_zone"(timestamp with time zone) RETURNS timestamp with time zone
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::timestamp with time zone;
$_$;


ALTER FUNCTION "msar"."cast_to_timestamp_with_time_zone"(timestamp with time zone) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_timestamp_without_time_zone"("date") RETURNS timestamp without time zone
    LANGUAGE "plpgsql" STRICT
    AS $_$
DECLARE
  timestamp_value_with_tz NUMERIC;
  timestamp_value NUMERIC;
  date_value NUMERIC;
BEGIN
  SET LOCAL TIME ZONE 'UTC';
  SELECT EXTRACT(EPOCH FROM $1::TIMESTAMP WITH TIME ZONE ) INTO timestamp_value_with_tz;
  SELECT EXTRACT(EPOCH FROM $1::TIMESTAMP WITHOUT TIME ZONE) INTO timestamp_value;
  SELECT EXTRACT(EPOCH FROM $1::DATE ) INTO date_value;
  IF (timestamp_value_with_tz = timestamp_value) THEN
    RETURN $1::timestamp without time zone;
  END IF;
  RAISE EXCEPTION '% is not a timestamp without time zone', $1;
END;
$_$;


ALTER FUNCTION "msar"."cast_to_timestamp_without_time_zone"("date") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_timestamp_without_time_zone"("text") RETURNS timestamp without time zone
    LANGUAGE "plpgsql" STRICT
    AS $_$
DECLARE
  timestamp_value_with_tz NUMERIC;
  timestamp_value NUMERIC;
  date_value NUMERIC;
BEGIN
  SET LOCAL TIME ZONE 'UTC';
  SELECT EXTRACT(EPOCH FROM $1::TIMESTAMP WITH TIME ZONE ) INTO timestamp_value_with_tz;
  SELECT EXTRACT(EPOCH FROM $1::TIMESTAMP WITHOUT TIME ZONE) INTO timestamp_value;
  SELECT EXTRACT(EPOCH FROM $1::DATE ) INTO date_value;
  IF (timestamp_value_with_tz = timestamp_value) THEN
    RETURN $1::timestamp without time zone;
  END IF;
  RAISE EXCEPTION '% is not a timestamp without time zone', $1;
END;
$_$;


ALTER FUNCTION "msar"."cast_to_timestamp_without_time_zone"("text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_timestamp_without_time_zone"(timestamp without time zone) RETURNS timestamp without time zone
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::timestamp without time zone;
$_$;


ALTER FUNCTION "msar"."cast_to_timestamp_without_time_zone"(timestamp without time zone) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_timestamp_without_time_zone"(timestamp with time zone) RETURNS timestamp without time zone
    LANGUAGE "plpgsql" STRICT
    AS $_$
DECLARE
  timestamp_value_with_tz NUMERIC;
  timestamp_value NUMERIC;
  date_value NUMERIC;
BEGIN
  SET LOCAL TIME ZONE 'UTC';
  SELECT EXTRACT(EPOCH FROM $1::TIMESTAMP WITH TIME ZONE ) INTO timestamp_value_with_tz;
  SELECT EXTRACT(EPOCH FROM $1::TIMESTAMP WITHOUT TIME ZONE) INTO timestamp_value;
  SELECT EXTRACT(EPOCH FROM $1::DATE ) INTO date_value;
  IF (timestamp_value_with_tz = timestamp_value) THEN
    RETURN $1::timestamp without time zone;
  END IF;
  RAISE EXCEPTION '% is not a timestamp without time zone', $1;
END;
$_$;


ALTER FUNCTION "msar"."cast_to_timestamp_without_time_zone"(timestamp with time zone) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_uri"("text") RETURNS "mathesar_types"."uri"
    LANGUAGE "plpgsql" STRICT
    AS $_$
DECLARE
  uri_res mathesar_types.uri := 'https://mathesar.org';
  uri_tld text;
BEGIN
  RETURN $1::mathesar_types.uri;
  EXCEPTION WHEN SQLSTATE '23514' THEN
    SELECT lower(('http://' || $1)::mathesar_types.uri) INTO uri_res;
    SELECT (regexp_match(msar.uri_authority(uri_res), '(?<=\.)(?:.(?!\.))+$'))[1]
      INTO uri_tld;
    IF EXISTS(SELECT 1 FROM msar.top_level_domains WHERE tld = uri_tld) THEN
      RETURN uri_res;
    END IF;
  RAISE EXCEPTION '% is not a mathesar_types.uri', $1;
END;
$_$;


ALTER FUNCTION "msar"."cast_to_uri"("text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_uuid"("text") RETURNS "uuid"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::uuid;
$_$;


ALTER FUNCTION "msar"."cast_to_uuid"("text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."cast_to_uuid"("uuid") RETURNS "uuid"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
  SELECT $1::uuid;
$_$;


ALTER FUNCTION "msar"."cast_to_uuid"("uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."check_column_mathesar_money_compat"("tab_id" "regclass", "col_id" smallint, "test_perc" numeric, OUT "compat_details" "msar"."type_compat_details") RETURNS "msar"."type_compat_details"
    LANGUAGE "plpgsql" STRICT
    AS $_$/*
Determine whether we can cast the given column to mathesar_money.

Args:
  tab_id: The OID of the table whose column we're checking.
  col_id: The attnum of the column in the table.
  test_perc: The percentage of the table to use for the `cast_to_X` default check.

Returns:
  Information about how to successfully cast the column to mathesar_money.
*/
BEGIN
  compat_details = msar.find_mathesar_money_attrs(
    tab_id, col_id, msar.downsize_table_sample(test_perc)
  );
  EXECUTE format(
    'SELECT msar.cast_to_mathesar_money(%1$I, %5$L, %6$L, %7$L, %8$L) FROM %2$I.%3$I TABLESAMPLE SYSTEM(%4$L);',
    /* %1 */ msar.get_column_name(tab_id, col_id),
    /* %2 */ msar.get_relation_schema_name(tab_id),
    /* %3 */ msar.get_relation_name(tab_id),
    /* %4 */ test_perc,
    /* %5 */ coalesce(compat_details.group_sep, ''),
    /* %6 */ coalesce(compat_details.decimal_p, ''),
    /* %7 */ coalesce(compat_details.curr_pref, ''),
    /* %8 */ coalesce(compat_details.curr_suff, '')
  );
  compat_details.mathesar_casting = true;
  compat_details.type_compatible = true;
EXCEPTION WHEN OTHERS THEN END;
$_$;


ALTER FUNCTION "msar"."check_column_mathesar_money_compat"("tab_id" "regclass", "col_id" smallint, "test_perc" numeric, OUT "compat_details" "msar"."type_compat_details") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."check_column_numeric_compat"("tab_id" "regclass", "col_id" smallint, "test_perc" numeric, OUT "compat_details" "msar"."type_compat_details") RETURNS "msar"."type_compat_details"
    LANGUAGE "plpgsql" STRICT
    AS $_$/*
Determine whether we can cast the given column to numeric.

Args:
  tab_id: The OID of the table whose column we're checking.
  col_id: The attnum of the column in the table.
  test_perc: The percentage of the table to use for the `cast_to_X` default check.

Returns:
  Information about how to successfully cast the column to numeric.
*/
BEGIN
  compat_details = msar.find_numeric_separators(
    tab_id, col_id, msar.downsize_table_sample(test_perc)
  );
  EXECUTE format(
    'SELECT msar.cast_to_numeric(%1$I, %5$L, %6$L) FROM %2$I.%3$I TABLESAMPLE SYSTEM(%4$L);',
    msar.get_column_name(tab_id, col_id),
    msar.get_relation_schema_name(tab_id),
    msar.get_relation_name(tab_id),
    test_perc,
    coalesce(compat_details.group_sep, ''),
    coalesce(compat_details.decimal_p, '')
  );
  compat_details.mathesar_casting = true;
  compat_details.type_compatible = true;
EXCEPTION WHEN OTHERS THEN END;
$_$;


ALTER FUNCTION "msar"."check_column_numeric_compat"("tab_id" "regclass", "col_id" smallint, "test_perc" numeric, OUT "compat_details" "msar"."type_compat_details") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."check_column_type_compat"("tab_id" "regclass", "col_id" smallint, "typ_id" "regtype", "test_perc" numeric, OUT "compat_details" "msar"."type_compat_details") RETURNS "msar"."type_compat_details"
    LANGUAGE "plpgsql" STRICT
    AS $_$/*
Get info about the compatibility of a given type for a given column.

Args:
  tab_id: The OID of the table whose column we're checking.
  col_id: The attnum of the column in the table.
  typ_id: The OID of the type we'll check against the column.
  test_perc: The percentage of the table to use for the `cast_to_X` default check.

Returns:
  Info about how to successfully cast the column to the given type.
*/
BEGIN
  CASE typ_id
    WHEN 'numeric'::regtype THEN
      compat_details = msar.check_column_numeric_compat(tab_id, col_id, test_perc);
    WHEN 'mathesar_types.mathesar_money'::regtype THEN
      compat_details = msar.check_column_mathesar_money_compat(tab_id, col_id, test_perc);
    ELSE
      EXECUTE format(
        'SELECT %1$s FROM %2$I.%3$I TABLESAMPLE SYSTEM(%4$L);',
        msar.build_cast_expr(tab_id, col_id, typ_id),
        msar.get_relation_schema_name(tab_id),
        msar.get_relation_name(tab_id),
        test_perc
      );
      compat_details.mathesar_casting = true;
      compat_details.type_compatible = true;
  END CASE;
EXCEPTION WHEN OTHERS THEN END;
$_$;


ALTER FUNCTION "msar"."check_column_type_compat"("tab_id" "regclass", "col_id" smallint, "typ_id" "regtype", "test_perc" numeric, OUT "compat_details" "msar"."type_compat_details") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."col_description"("tab_id" "oid", "col_id" integer) RETURNS "text"
    LANGUAGE "plpgsql"
    AS $$/*
Transparent wrapper for col_description. Putting it in the `msar` namespace helps route all DB calls
from Python through a single Python module.
*/
  BEGIN
    RETURN col_description(tab_id, col_id);
  END
$$;


ALTER FUNCTION "msar"."col_description"("tab_id" "oid", "col_id" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."column_info_table"("tab_id" "regclass") RETURNS TABLE("id" smallint, "name" "name", "type" "text", "type_options" "jsonb", "nullable" boolean, "primary_key" boolean, "default" "jsonb", "has_dependents" boolean, "description" "text", "current_role_priv" "jsonb")
    LANGUAGE "sql" STABLE STRICT
    AS $$
SELECT
  attnum AS id,
  attname AS name,
  CASE WHEN attndims>0 THEN '_array' ELSE atttypid::regtype::text END AS type,
  msar.get_type_options(atttypid, atttypmod, attndims) AS type_options,
  NOT attnotnull AS nullable,
  COALESCE(pgi.indisprimary, false) AS primary_key,
  msar.describe_column_default(tab_id, attnum) AS default,
  msar.has_dependents(tab_id, attnum) AS has_dependents,
  msar.col_description(tab_id, attnum) AS description,
  msar.list_column_privileges_for_current_role(tab_id, attnum) AS current_role_priv
FROM pg_catalog.pg_attribute pga
  LEFT JOIN pg_index pgi ON pga.attrelid=pgi.indrelid AND pga.attnum=ANY(pgi.indkey)
WHERE pga.attrelid=tab_id AND pga.attnum > 0 and NOT attisdropped;
$$;


ALTER FUNCTION "msar"."column_info_table"("tab_id" "regclass") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."comment_on_column"("tab_id" "oid", "col_id" integer, "comment_" "text") RETURNS "text"
    LANGUAGE "sql"
    AS $$/*
Change the description of a column, returning command executed.

Args:
  tab_id: The OID of the table containg the column whose comment we will change.
  col_id: The ATTNUM of the column whose comment we will change.
  comment_: The new comment.
*/
SELECT __msar.comment_on_column(
  tab_id,
  col_id,
  quote_literal(comment_)
);
$$;


ALTER FUNCTION "msar"."comment_on_column"("tab_id" "oid", "col_id" integer, "comment_" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."comment_on_column"("sch_name" "text", "tab_name" "text", "col_name" "text", "comment_" "text") RETURNS "text"
    LANGUAGE "sql"
    AS $$/*
Change the description of a column, returning command executed.

Args:
  sch_name: The schema of the table whose column's comment we will change.
  tab_name: The name of the table whose column's comment we will change.
  col_name: The name of the column whose comment we will change.
  comment_: The new comment.
*/
SELECT __msar.comment_on_column(
  __msar.build_qualified_name_sql(sch_name, tab_name),
  quote_ident(col_name),
  quote_literal(comment_)
);
$$;


ALTER FUNCTION "msar"."comment_on_column"("sch_name" "text", "tab_name" "text", "col_name" "text", "comment_" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."comment_on_table"("tab_id" "oid", "comment_" "text") RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$/*
Change the description of a table.

Args:
  tab_id: The OID of the table whose comment we will change.
  comment_: The new comment.
*/
BEGIN
  EXECUTE format(
    'COMMENT ON TABLE %I.%I IS %L',
    msar.get_relation_schema_name(tab_id),
    msar.get_relation_name(tab_id),
    comment_
  );
END;
$$;


ALTER FUNCTION "msar"."comment_on_table"("tab_id" "oid", "comment_" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."copy_column"("tab_id" "oid", "col_id" smallint, "copy_name" "text", "copy_data" boolean, "copy_constraints" boolean) RETURNS smallint
    LANGUAGE "plpgsql"
    AS $$/*
Copy a column of a table
*/
DECLARE
  col_defs __msar.col_def[];
  tab_name text;
  col_name text;
  created_col_id smallint;
BEGIN
  col_defs := __msar.get_duplicate_col_defs(
    tab_id, ARRAY[col_id], ARRAY[copy_name], copy_data
  );
  tab_name := __msar.get_qualified_relation_name(tab_id);
  col_name := quote_ident(msar.get_column_name(tab_id, col_id));
  PERFORM __msar.add_columns(tab_name, VARIADIC col_defs);
  created_col_id := attnum
    FROM pg_attribute
    WHERE attrelid=tab_id AND quote_ident(attname)=col_defs[1].name_;
  IF copy_data THEN
    PERFORM __msar.exec_ddl(
      'UPDATE %s SET %s=%s',
      tab_name, col_defs[1].name_, quote_ident(msar.get_column_name(tab_id, col_id))
    );
  END IF;
  IF copy_constraints THEN
    PERFORM msar.copy_constraint(oid, col_id, created_col_id)
    FROM pg_constraint
    WHERE conrelid=tab_id AND ARRAY[col_id] <@ conkey;
    PERFORM msar.set_not_null(
      tab_id, created_col_id, attnotnull
    )
    FROM pg_attribute WHERE attrelid=tab_id AND attnum=col_id;
  END IF;
  RETURN created_col_id;
END;
$$;


ALTER FUNCTION "msar"."copy_column"("tab_id" "oid", "col_id" smallint, "copy_name" "text", "copy_data" boolean, "copy_constraints" boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."copy_constraint"("con_id" "oid", "from_col_id" smallint, "to_col_id" smallint) RETURNS "oid"[]
    LANGUAGE "sql" STRICT
    AS $$/*
Copy a single constraint associated with a column.

Given a column with attnum 3 involved in the original constraint, and a column with attnum 4 to be
involved in the constraint copy, and other columns 1 and 2 involved in the constraint, suppose the
original constraint had conkey [1, 2, 3]. The copy constraint should then have conkey [1, 2, 4].

For now, this is only implemented for unique constraints.

Args:
  con_id: The oid of the constraint we'll copy.
  from_col_id: The column ID to be removed from the original's conkey in the copy.
  to_col_id: The column ID to be added to the original's conkey in the copy.
*/
WITH
  con_cte AS (SELECT * FROM pg_constraint WHERE oid=con_id AND contype='u'),
  con_def_cte AS (
    SELECT jsonb_agg(
      jsonb_build_object(
        'name', null,
        'type', con_cte.contype,
        'columns', array_replace(con_cte.conkey, from_col_id, to_col_id)
      )
    ) AS con_def FROM con_cte
  )
SELECT msar.add_constraints(con_cte.conrelid, con_def_cte.con_def) FROM con_cte, con_def_cte;
$$;


ALTER FUNCTION "msar"."copy_constraint"("con_id" "oid", "from_col_id" smallint, "to_col_id" smallint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."create_role"("rolename" "text", "password_" "text", "login_" boolean) RETURNS "jsonb"
    LANGUAGE "plpgsql"
    AS $$/*
Creates a login/non-login role, depending on whether the login_ flag is set.
Only the rolename field is required, the password field is required only if login_ is set to true.

Returns a JSON object describing the created role in the form:
  {
    "oid": <int>
    "name": <str>
    "super": <bool>
    "inherits": <bool>
    "create_role": <bool>
    "create_db": <bool>
    "login": <bool>
    "description": <str|null>
    "members": <[
        { "oid": <int>, "admin": <bool> }
      ]|null>
  }

Args:
  rolename: The name of the role to be created, unquoted.
  password_: The password for the rolename to set, unquoted.
  login_: Specify whether the role to be created could login.
*/
BEGIN
  CASE WHEN login_ THEN
    EXECUTE format('CREATE USER %I WITH PASSWORD %L', rolename, password_);
  ELSE
    EXECUTE format('CREATE ROLE %I', rolename);
  END CASE;
  RETURN msar.get_role(rolename);
END;
$$;


ALTER FUNCTION "msar"."create_role"("rolename" "text", "password_" "text", "login_" boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."create_schema"("sch_name" "text", "own_id" "regrole", "description" "text" DEFAULT ''::"text") RETURNS "jsonb"
    LANGUAGE "plpgsql"
    AS $$/*
Create a schema, possibly with a description.

If a schema with the given name already exists, an exception will be raised.

Args:
  sch_name: The name of the schema to be created, UNQUOTED.
  own_id:      (optional) The OID of the role who will own the new schema.
  description: (optional) A description for the schema, UNQUOTED.

Returns:
  A json object describing the user-defined schema in the database.

Note:
  - This function does not support IF NOT EXISTS because it's simpler that way. I originally tried
    to support descriptions and if_not_exists in the same function, but as I discovered more edge cases
    and inconsistencies, it got too complex, and I didn't think we'd have a good enough use case for it.
  - If own_id is NULL, the current role will be the owner of the new schema.
*/
DECLARE schema_oid oid;
BEGIN
  EXECUTE 'CREATE SCHEMA ' || quote_ident(sch_name);
  schema_oid := msar.get_schema_oid(sch_name);
  PERFORM msar.set_schema_description(schema_oid, description);
  IF own_id IS NOT NULL THEN
    PERFORM msar.transfer_schema_ownership(schema_oid, own_id);
  END IF;
  RETURN msar.get_schema(schema_oid);
END;
$$;


ALTER FUNCTION "msar"."create_schema"("sch_name" "text", "own_id" "regrole", "description" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."degrees_to_month"("degrees" double precision) RETURNS integer
    LANGUAGE "sql"
    AS $$/*
Convert degrees to discrete month.

To get the fraction of 360°, we divide degrees value by 360 and then to get the equivalent 
fractions of 12 months, we multiply by 12, which is equivalent to divide by 30.

Examples:
     0 =>  1
   120 =>  5
   240 =>  9
   330 => 12
  -120 =>  9
*/
SELECT (((degrees::numeric % 360 + 360) % 360)::double precision / 30)::int + 1;
$$;


ALTER FUNCTION "msar"."degrees_to_month"("degrees" double precision) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."degrees_to_time"("degrees" double precision) RETURNS time without time zone
    LANGUAGE "sql"
    AS $$/*
Convert given degrees to time (on a 24 hour clock, indexed from midnight).

Steps:
- First, the degrees value is confined to range [0,360°)
- Then the resulting value is converted to time indexed from midnight.

To get the fraction of 360°, we divide degrees value by 360 and then to get the
equivalent fractions of 86400 seconds, we multiply by 86400, which is equivalent
to multiply by 240. 

Examples:
    0 => 00:00:00
   90 => 06:00:00
  180 => 12:00:00
  270 => 18:00:00
  540 => 12:00:00
  -90 => 18:00:00

Inverse of msar.time_to_degrees.
*/
SELECT MAKE_INTERVAL(secs => ((degrees::numeric % 360 + 360) % 360)::double precision * 240)::time;
$$;


ALTER FUNCTION "msar"."degrees_to_time"("degrees" double precision) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."delete_records_from_table"("tab_id" "oid", "rec_ids" "jsonb") RETURNS integer
    LANGUAGE "plpgsql" STRICT
    AS $_$/*
Delete records from table by id.

Args:
  tab_id: The OID of the table whose record we'll delete.
  rec_ids: An array of primary key values

The table must have a single primary key column.
*/
DECLARE
  num_deleted integer;
BEGIN
  EXECUTE format(
    $d$
    WITH delete_cte AS (DELETE FROM %1$I.%2$I %3$s RETURNING *)
    SELECT count(1) FROM delete_cte
    $d$,
    msar.get_relation_schema_name(tab_id),
    msar.get_relation_name(tab_id),
    msar.build_where_clause(
      tab_id, jsonb_build_object(
        'type', 'element_in_json_array_untyped', 'args', jsonb_build_array(
          jsonb_build_object(
            'type', 'format_data', 'args', jsonb_build_array(
              jsonb_build_object('type', 'attnum', 'value', msar.get_pk_column(tab_id))
            )
          ),
          jsonb_build_object('type', 'literal', 'value', rec_ids)
        )
      )
    )
  ) INTO num_deleted;
  RETURN num_deleted;
END;
$_$;


ALTER FUNCTION "msar"."delete_records_from_table"("tab_id" "oid", "rec_ids" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."describe_column_default"("tab_id" "regclass", "col_id" smallint) RETURNS "jsonb"
    LANGUAGE "plpgsql" STRICT
    AS $$/*
Return a JSONB object describing the default (if any) of the given column in the given table.

The returned JSON will have the form:
  {
    "value": <any>,
    "is_dynamic": <bool>,
  }

If the default is possibly dynamic, i.e., if "is_dynamic" is true, then "value" will be a text SQL
expression that generates the default value if evaluated. If it is not dynamic, then "value" is the
actual default value.
*/
DECLARE
  def_expr text;
  def_json jsonb;
BEGIN
def_expr = CASE
  WHEN attidentity='' THEN pg_catalog.pg_get_expr(adbin, tab_id)
  ELSE 'identity'
END
FROM pg_catalog.pg_attribute LEFT JOIN pg_catalog.pg_attrdef ON attrelid=adrelid AND attnum=adnum
WHERE attrelid=tab_id AND attnum=col_id;
IF def_expr IS NULL THEN
  RETURN NULL;
ELSIF msar.is_default_possibly_dynamic(tab_id, col_id) THEN
  EXECUTE format(
    'SELECT jsonb_build_object(''value'', %L, ''is_dynamic'', true)', def_expr
  ) INTO def_json;
ELSE
  EXECUTE format(
    'SELECT jsonb_build_object(''value'', msar.format_data(%s), ''is_dynamic'', false)', def_expr
  ) INTO def_json;
END IF;
RETURN def_json;
END;
$$;


ALTER FUNCTION "msar"."describe_column_default"("tab_id" "regclass", "col_id" smallint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."downsize_table_sample"("test_perc" numeric) RETURNS numeric
    LANGUAGE "sql" IMMUTABLE STRICT PARALLEL SAFE
    AS $$
  SELECT (test_perc / 100) ^ 2 * 100;
$$;


ALTER FUNCTION "msar"."downsize_table_sample"("test_perc" numeric) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."drop_columns"("tab_id" "oid", VARIADIC "col_ids" integer[]) RETURNS "void"
    LANGUAGE "plpgsql" STRICT
    AS $$/*
Drop the given columns from the given table.

Args:
  tab_id: OID of the table whose columns we'll drop.
  col_ids: The attnums of the columns to drop.
*/
BEGIN
  col_ids := array_remove(col_ids, null);
  IF array_length(col_ids, 1) IS NOT NULL THEN
    EXECUTE format(
      'ALTER TABLE %I.%I %s',
      msar.get_relation_schema_name(tab_id),
      msar.get_relation_name(tab_id),
      string_agg(format('DROP COLUMN %I', attname), ', ')
    )
    FROM pg_catalog.pg_attribute AS pga INNER JOIN unnest(col_ids) AS x(col) ON pga.attnum=x.col
    WHERE attrelid=tab_id AND NOT attisdropped;
  END IF;
END;
$$;


ALTER FUNCTION "msar"."drop_columns"("tab_id" "oid", VARIADIC "col_ids" integer[]) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."drop_constraint"("tab_id" "oid", "con_id" "oid") RETURNS "text"
    LANGUAGE "plpgsql" STRICT
    AS $$/*
Drop a constraint

Args:
  tab_id: OID of the table that has the constraint to be dropped.
  con_id: OID of the constraint to be dropped.
*/
BEGIN
  RETURN msar.drop_constraint(
    msar.get_relation_schema_name(tab_id),
    msar.get_relation_name(tab_id),
    msar.get_constraint_name(con_id)
  );
END;
$$;


ALTER FUNCTION "msar"."drop_constraint"("tab_id" "oid", "con_id" "oid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."drop_constraint"("sch_name" "text", "tab_name" "text", "con_name" "text") RETURNS "text"
    LANGUAGE "plpgsql" STRICT
    AS $$/*
Drop a constraint

Args:
  sch_name: The name of the schema where the table with constraint to be dropped resides, unquoted.
  tab_name: The name of the table that has the constraint to be dropped, unquoted.
  con_name: Name of the constraint to drop, unquoted.
*/
BEGIN
  EXECUTE format('ALTER TABLE %I.%I DROP CONSTRAINT %I', sch_name, tab_name, con_name);
  RETURN con_name;
END;
$$;


ALTER FUNCTION "msar"."drop_constraint"("sch_name" "text", "tab_name" "text", "con_name" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."drop_database_query"("dat_id" "oid") RETURNS "text"
    LANGUAGE "plpgsql" STRICT
    AS $$/*
Return the SQL query to drop a database.

If no database exists with the given oid, an exception will be raised.

Args:
  dat_id: The OID of the role to drop.
*/
BEGIN
  RETURN format('DROP DATABASE %I', msar.get_database_name(dat_id));
END;
$$;


ALTER FUNCTION "msar"."drop_database_query"("dat_id" "oid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."drop_role"("rol_id" "regrole") RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$/*
Drop a role.

Note:
- To drop a superuser role, you must be a superuser yourself.
- To drop non-superuser roles, you must have CREATEROLE privilege and have been granted ADMIN OPTION on the role.

Args:
  rol_id: The OID of the role to drop on the database.
*/
BEGIN
  EXECUTE format('DROP ROLE %I', msar.get_role_name(rol_id));
END;
$$;


ALTER FUNCTION "msar"."drop_role"("rol_id" "regrole") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."drop_schemas"("sch_ids" "regnamespace"[]) RETURNS "void"
    LANGUAGE "plpgsql" STRICT
    AS $$/*
Safely drop all objects in each schema, then the schemas themselves.

Does not work on the msar schema.

If any passed schema doesn't exist, an exception will be raised. If any object exists in a schema
which isn't passed, but which depends on an object in a passed schema, an exception will be raised.

Args:
  sch_ids: The OIDs of the schemas to drop.
*/
DECLARE
  obj RECORD;
  message text;
  detail text;
  sch regnamespace;
  sch_name text;
  undropped_objects text[];
  drop_success boolean := false;
  drop_failed boolean := false;
BEGIN
  SET client_min_messages = WARNING;
  FOR obj IN
    SELECT obj_id, obj_schema, obj_name, obj_kind
    FROM msar.get_schema_objects_table(sch_ids)
    ORDER BY obj_id DESC  -- Objects more often depend on others of lower OID.
  LOOP
    BEGIN
      EXECUTE format('DROP %s IF EXISTS %I.%I', obj.obj_kind, obj.obj_schema, obj.obj_name);
      drop_success = true;
    EXCEPTION
      WHEN dependent_objects_still_exist THEN
        GET STACKED DIAGNOSTICS
          message = MESSAGE_TEXT,
          detail = PG_EXCEPTION_DETAIL;
        undropped_objects = undropped_objects || message;
        IF detail <> '' THEN
           undropped_objects = undropped_objects || concat('    ', detail);
        END IF;
      drop_failed =  true;
    END;
  END LOOP;
  SET client_min_messages = NOTICE;
  IF drop_failed IS false THEN
    -- We dropped every object that existed in the schemas.
    RAISE NOTICE E'All objects dropped successfully!\n\nDropping schemas...\n\n';
    FOREACH sch IN ARRAY sch_ids
      LOOP
        sch_name = msar.get_schema_name(sch);
        RAISE NOTICE 'Dropping Schema %', sch_name;
        EXECUTE(format('DROP SCHEMA IF EXISTS %I', sch_name));
      END LOOP;
  ELSIF drop_success IS false THEN
    -- We failed to drop anything in the schemas (and failed to drop at least one object).
    RAISE EXCEPTION USING
      MESSAGE = 'Nothing was dropped in this call due to dependent objects.',
      DETAIL = array_to_string(array_remove(undropped_objects, ''), E'\n         '),
      HINT = 'All changes will be reverted.',
      ERRCODE = 'dependent_objects_still_exist';
  ELSE
    -- We did drop some objects, but failed to drop at least one (due to dependencies). Recurse.
    PERFORM msar.drop_schemas(sch_ids);
  END IF;
END;
$$;


ALTER FUNCTION "msar"."drop_schemas"("sch_ids" "regnamespace"[]) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."drop_table"("tab_id" "oid", "cascade_" boolean) RETURNS "text"
    LANGUAGE "plpgsql" STRICT
    AS $$/*
Drop a table, returning the fully qualified name of the dropped table.

Args:
  tab_id: The OID of the table to drop
  cascade_: Whether to drop dependent objects.
*/
DECLARE relation_name text;
BEGIN
  relation_name := __msar.get_qualified_relation_name_or_null(tab_id);
  -- if_exists doesn't work while working with oids because
  -- the SQL query gets parameterized with tab_id instead of relation_name
  -- since we're unable to find the relation_name for a non existing table.
  PERFORM __msar.drop_table(relation_name, cascade_, if_exists => false);
  RETURN relation_name;
END;
$$;


ALTER FUNCTION "msar"."drop_table"("tab_id" "oid", "cascade_" boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."drop_table"("sch_name" "text", "tab_name" "text", "cascade_" boolean, "if_exists" boolean) RETURNS "text"
    LANGUAGE "plpgsql" STRICT
    AS $$/*
Drop a table, returning the command executed.

Args:
  sch_name: The schema of the table to drop.
  tab_name: The name of the table to drop.
  cascade_: Whether to drop dependent objects.
  if_exists_: Whether to ignore an error if the table doesn't exist
*/
DECLARE qualified_tab_name text;
BEGIN
  qualified_tab_name := __msar.build_qualified_name_sql(sch_name, tab_name);
  RETURN __msar.drop_table(qualified_tab_name, cascade_, if_exists);
END;
$$;


ALTER FUNCTION "msar"."drop_table"("sch_name" "text", "tab_name" "text", "cascade_" boolean, "if_exists" boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."email_domain_name"("mathesar_types"."email") RETURNS "text"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
    SELECT split_part($1, '@', 2);
$_$;


ALTER FUNCTION "msar"."email_domain_name"("mathesar_types"."email") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."email_local_part"("mathesar_types"."email") RETURNS "text"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
    SELECT split_part($1, '@', 1);
$_$;


ALTER FUNCTION "msar"."email_local_part"("mathesar_types"."email") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."extract_columns_from_table"("tab_id" "oid", "col_ids" integer[], "new_tab_name" "text", "fk_col_name" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql"
    AS $_$/*
Extract columns from a table to create a new table, linked by a foreign key.

Args:
  tab_id: The OID of the table whose columns we'll extract
  col_ids: An array of the attnums of the columns to extract
  new_tab_name: The name of the new table to be made from the extracted columns, unquoted
  fk_col_name: The name to give the new foreign key column in the remainder table (optional)

The extraction takes a set of columns from the table, and creates a new table from the set of
*distinct* tuples those columns comprise. We also add a new foreign key column to the original
 (remainder) table that links it to the new extracted table so they can be easily rejoined. The
 extracted columns are removed from the remainder table.
*/
DECLARE
  extracted_col_defs CONSTANT jsonb := msar.get_extracted_col_def_jsonb(tab_id, col_ids);
  extracted_con_defs CONSTANT jsonb := msar.get_extracted_con_def_jsonb(tab_id, col_ids);
  fkey_name CONSTANT text := msar.build_unique_fkey_column_name(tab_id, fk_col_name, new_tab_name);
  extracted_table_id integer;
  fkey_attnum integer;
BEGIN
  -- Begin by creating a new table with column definitions matching the extracted columns.
  extracted_table_id := msar.add_mathesar_table(
    msar.get_relation_namespace_oid(tab_id),
    new_tab_name,
    NULL,
    extracted_col_defs,
    extracted_con_defs,
    NULL, -- own_id is set to NULL so the current role would be the owner of the extracted table.
    format('Extracted from %s', __msar.get_qualified_relation_name(tab_id))
  ) ->> 'oid';
  -- Create a new fkey column and foreign key linking the original table to the extracted one.
  fkey_attnum := msar.add_foreign_key_column(fkey_name, tab_id, extracted_table_id);
  -- Insert the data from the original table's columns into the extracted columns, and add
  -- appropriate fkey values to the new fkey column in the original table to give the proper
  -- mapping.
  PERFORM __msar.exec_ddl($t$
    WITH fkey_cte AS (
      SELECT id, %1$s, dense_rank() OVER (ORDER BY %1$s) AS __msar_tmp_id
      FROM %2$s
    ), ins_cte AS (
      INSERT INTO %3$s (%1$s)
      SELECT DISTINCT %1$s FROM fkey_cte ORDER BY %1$s
    )
    UPDATE %2$s SET %4$I=__msar_tmp_id FROM fkey_cte WHERE
    %2$s.id=fkey_cte.id
    $t$,
    -- %1$s  This is a comma separated string of the extracted column names
    string_agg(quote_ident(col_def ->> 'name'), ', '),
    -- %2$s  This is the name of the original (remainder) table
    __msar.get_qualified_relation_name(tab_id),
    -- %3$s  This is the new extracted table name
    __msar.get_qualified_relation_name(extracted_table_id),
    -- %4$I  This is the name of the fkey column in the remainder table.
    fkey_name
  ) FROM jsonb_array_elements(extracted_col_defs) AS col_def;
  -- Drop the original versions of the extracted columns from the original table.
  PERFORM msar.drop_columns(tab_id, variadic col_ids);
  -- In case the user wanted to give a name to the fkey column matching one of the extracted
  -- columns, perform that operation now (since the original will now be dropped from the original
  -- table)
  IF fk_col_name IS NOT NULL AND fk_col_name IN (
    SELECT col_def ->> 'name'
    FROM jsonb_array_elements(extracted_col_defs) AS col_def
  ) THEN
    PERFORM msar.rename_column(tab_id, fkey_attnum, fk_col_name);
  END IF;
  RETURN jsonb_build_array(extracted_table_id, fkey_attnum);
END;
$_$;


ALTER FUNCTION "msar"."extract_columns_from_table"("tab_id" "oid", "col_ids" integer[], "new_tab_name" "text", "fk_col_name" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."extract_smallints"("v" "jsonb") RETURNS smallint[]
    LANGUAGE "plpgsql" IMMUTABLE STRICT PARALLEL SAFE
    AS $$/*
From the supplied JSONB value, extract all top-level JSONB array elements which can be successfully
cast to PostgreSQL smallint values. Return the resulting array of smallint values.

If the supplied jsonb value is not an array, this function will return an empty array.

If any jsonb array element cannot be cast to a smallint, it will be silently ignored.

This function does not raise any exceptions. It will always return an array.

This function should not be used on large arrays. It will be slow due to the performance
limitations[1] of EXCEPTION blocks.

[1]: https://www.postgresql.org/docs/current/plpgsql-control-structures.html#PLPGSQL-ERROR-TRAPPING

Args:
  v: any JSONB value.
*/
DECLARE
  result smallint[];
  element jsonb;
BEGIN
  FOR element IN SELECT jsonb_array_elements(v)
  LOOP
    BEGIN
      result := result || (element::smallint);
    EXCEPTION
      -- Ignore any elements that can't be cast to smallint.
      WHEN others THEN
        CONTINUE;
    END;
  END LOOP;
  RETURN result;
EXCEPTION
  WHEN others THEN
    RETURN '{}'::smallint[]; -- Return an empty array if the input is not an array.
END;
$$;


ALTER FUNCTION "msar"."extract_smallints"("v" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."find_mathesar_money_attrs"("tab_id" "regclass", "col_id" smallint, "test_perc" numeric, OUT "compat_details" "msar"."type_compat_details") RETURNS "msar"."type_compat_details"
    LANGUAGE "plpgsql" STABLE STRICT PARALLEL SAFE
    AS $_$/*
Given a table column, find group separators, decimal separators, currency prefixes & currency suffixes
for money values in the column.

Throws an error if more than one group separator, decimal separator, currency prefix or currency suffix is found.
*/
DECLARE
  group_sep text[];
  decimal_p text[];
  curr_pref text[];
  curr_suff text[];
BEGIN
EXECUTE format(
  $q$
  WITH moneyarr_cte AS (
    SELECT msar.get_mathesar_money_array(%1$I) AS n FROM %2$I.%3$I TABLESAMPLE SYSTEM(%4$L)
  )
  SELECT
    array_remove(array_agg(DISTINCT n[2]), null),
    array_remove(array_agg(DISTINCT n[3]), null),
    array_remove(array_agg(DISTINCT n[4]), null),
    array_remove(array_agg(DISTINCT n[5]), null)
  FROM moneyarr_cte;
  $q$,
  /* %1 */ msar.get_column_name(tab_id, col_id),
  /* %2 */ msar.get_relation_schema_name(tab_id),
  /* %3 */ msar.get_relation_name(tab_id),
  /* %4 */ test_perc
) INTO group_sep, decimal_p, curr_pref, curr_suff;
IF array_length(group_sep, 1) > 1 THEN RAISE EXCEPTION 'Too many grouping separators found!';
ELSIF array_length(decimal_p, 1) > 1 THEN RAISE EXCEPTION 'Too many decimal separators found!';
ELSIF array_length(curr_pref, 1) > 1 THEN RAISE EXCEPTION 'Too many currency prefixes found!';
ELSIF array_length(curr_suff, 1) > 1 THEN RAISE EXCEPTION 'Too many currency suffixes found!';
ELSE
  compat_details.group_sep := group_sep[1];
  compat_details.decimal_p := decimal_p[1];
  compat_details.curr_pref := curr_pref[1];
  compat_details.curr_suff := curr_suff[1];
END IF;
END;
$_$;


ALTER FUNCTION "msar"."find_mathesar_money_attrs"("tab_id" "regclass", "col_id" smallint, "test_perc" numeric, OUT "compat_details" "msar"."type_compat_details") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."find_numeric_separators"("tab_id" "regclass", "col_id" smallint, "test_perc" numeric, OUT "compat_details" "msar"."type_compat_details") RETURNS "msar"."type_compat_details"
    LANGUAGE "plpgsql" STABLE STRICT PARALLEL SAFE
    AS $_$/*
Given a table column, find group and decimal separators for number values in the column.

Throws an error if more than one group separator or decimal separator is found.
*/
DECLARE
  group_sep text[];
  decimal_p text[];
BEGIN
EXECUTE format(
  $q$
  WITH numarr_cte AS (
    SELECT msar.get_numeric_array(%1$I) AS n FROM %2$I.%3$I TABLESAMPLE SYSTEM(%4$L)
  )
  SELECT array_remove(array_agg(DISTINCT n[2]), null), array_remove(array_agg(DISTINCT n[3]),  null)
  FROM numarr_cte;
  $q$,
  msar.get_column_name(tab_id, col_id),
  msar.get_relation_schema_name(tab_id),
  msar.get_relation_name(tab_id),
  test_perc
) INTO group_sep, decimal_p;
IF array_length(group_sep, 1) > 1 THEN RAISE EXCEPTION 'Too many grouping separators found!';
ELSIF array_length(decimal_p, 1) > 1 THEN RAISE EXCEPTION 'Too many decimal separators found!';
ELSE
  compat_details.group_sep := group_sep[1];
  compat_details.decimal_p := decimal_p[1];
END IF;
END;
$_$;


ALTER FUNCTION "msar"."find_numeric_separators"("tab_id" "regclass", "col_id" smallint, "test_perc" numeric, OUT "compat_details" "msar"."type_compat_details") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."form_insert"("field_info_list" "jsonb", "values_" "jsonb") RETURNS "void"
    LANGUAGE "plpgsql" STRICT
    AS $$/*
Given field_info_list and values_, generates a lookup table for insert, builds and executes an insert statement.

field_info_list should have the folowing form:
[
  {"key": "k1", "parent_key":null, "column_attnum":5, "table_oid":1234, "depth":0},
  {"key": "k3", "parent_key":"k1", "column_attnum":3, "table_oid":4321, "depth":1},
  {"key": "k2", "parent_key":"k1", "column_attnum":2, "table_oid":4321, "depth":1},
]

values_ should be in the form:
{
  "k1": {"type": "create"},
  "k2": "Jane",
  "k3": "Doe"
}

Example of the SQL generated while Inserting into Items table while creating
a new book entry, adding a new Title, creating a new entry for Author, picking a Publisher.

WITH k1_cte AS (
  INSERT INTO "Library Management"."Authors"("First Name", "Last Name") SELECT 'Jerome K.', 'Jerome' RETURNING *
), k0_cte AS (
  INSERT INTO "Library Management"."Books"("Title", "Author", "Publisher") SELECT 'Three men in a Boat', k1_cte.id, '12' FROM k1_cte RETURNING *
) INSERT INTO "Library Management"."Items"("Acquisition Date", "Acquisition Price", "Book") SELECT '2025-10-09', '69.69', k0_cte.id FROM k0_cte RETURNING *
*/
DECLARE
  ins RECORD;
  insert_str text := '';
  insert_stub text;
  insert_count integer;
BEGIN
  SELECT COUNT(*) INTO insert_count FROM msar.build_insert_lookup_table(field_info_list, values_);

  FOR ins IN SELECT * FROM msar.build_insert_lookup_table(field_info_list, values_) LOOP
    insert_stub := 'INSERT INTO ' ||
      ins.table_name || '(' || ins.column_names || ') SELECT ' || ins.values_ ||
      CASE 
        WHEN ins.from_cte_name IS NOT NULL THEN CONCAT(' FROM ', ins.from_cte_name)
        ELSE '' END || ' RETURNING *';
    CASE
      WHEN insert_count > 1 AND ins.cte_name IS NOT NULL THEN
        insert_str := CONCAT_WS(',', NULLIF(insert_str, ''), ins.cte_name || ' AS (' || insert_stub || ')');
      WHEN ins.cte_name IS NULL THEN
        insert_str :=  insert_str || insert_stub;
    END CASE;
  END LOOP;

  CASE
    WHEN insert_count > 1 THEN
      insert_str := 'WITH ' || insert_str;
    ELSE NULL;
  END CASE;
  EXECUTE insert_str;
END;
$$;


ALTER FUNCTION "msar"."form_insert"("field_info_list" "jsonb", "values_" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."format_data"("val" json[]) RETURNS "text"[]
    LANGUAGE "sql" IMMUTABLE STRICT PARALLEL SAFE
    AS $$
SELECT val::text[];
$$;


ALTER FUNCTION "msar"."format_data"("val" json[]) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."format_data"("val" "jsonb"[]) RETURNS "text"[]
    LANGUAGE "sql" IMMUTABLE STRICT PARALLEL SAFE
    AS $$
SELECT val::text[];
$$;


ALTER FUNCTION "msar"."format_data"("val" "jsonb"[]) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."format_data"("val" "anyelement") RETURNS "anyelement"
    LANGUAGE "sql" IMMUTABLE STRICT PARALLEL SAFE
    AS $$
SELECT val;
$$;


ALTER FUNCTION "msar"."format_data"("val" "anyelement") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."format_data"("val" "date") RETURNS "text"
    LANGUAGE "sql" IMMUTABLE STRICT PARALLEL SAFE
    AS $$
SELECT to_char(val, 'YYYY-MM-DD AD');
$$;


ALTER FUNCTION "msar"."format_data"("val" "date") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."format_data"("val" interval) RETURNS "text"
    LANGUAGE "sql" IMMUTABLE STRICT PARALLEL SAFE
    AS $$
SELECT concat(
  to_char(val, 'PFMYYYY"Y"FMMM"M"FMDD"D""T"FMHH24"H"FMMI"M"'), date_part('seconds', val), 'S'
);
$$;


ALTER FUNCTION "msar"."format_data"("val" interval) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."format_data"("val" json) RETURNS "text"
    LANGUAGE "sql" IMMUTABLE STRICT PARALLEL SAFE
    AS $$
SELECT val::text;
$$;


ALTER FUNCTION "msar"."format_data"("val" json) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."format_data"("val" "jsonb") RETURNS "text"
    LANGUAGE "sql" IMMUTABLE STRICT PARALLEL SAFE
    AS $$
SELECT val::text;
$$;


ALTER FUNCTION "msar"."format_data"("val" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."format_data"("val" time without time zone) RETURNS "text"
    LANGUAGE "sql" IMMUTABLE STRICT PARALLEL SAFE
    AS $$
SELECT concat(to_char(val, 'HH24:MI'), ':', to_char(date_part('seconds', val), 'FM00.0999999999'));
$$;


ALTER FUNCTION "msar"."format_data"("val" time without time zone) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."format_data"("val" timestamp without time zone) RETURNS "text"
    LANGUAGE "sql" IMMUTABLE STRICT PARALLEL SAFE
    AS $$
SELECT
  concat(
    to_char(val, 'YYYY-MM-DD"T"HH24:MI'),
    ':', to_char(date_part('seconds', val), 'FM00.0999999999'),
    to_char(val, ' BC')
  );
$$;


ALTER FUNCTION "msar"."format_data"("val" timestamp without time zone) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."format_data"("val" timestamp with time zone) RETURNS "text"
    LANGUAGE "sql" IMMUTABLE STRICT PARALLEL SAFE
    AS $$
SELECT CASE
  WHEN date_part('timezone_hour', val) = 0 AND date_part('timezone_minute', val) = 0
    THEN concat(
      to_char(val, 'YYYY-MM-DD"T"HH24:MI'),
      ':', to_char(date_part('seconds', val), 'FM00.0999999999'), 'Z', to_char(val, ' BC')
    )
  ELSE
    concat(
      to_char(val, 'YYYY-MM-DD"T"HH24:MI'),
      ':', to_char(date_part('seconds', val), 'FM00.0999999999'),
      to_char(date_part('timezone_hour', val), 'S00'),
      ':', ltrim(to_char(date_part('timezone_minute', val), '00'), '+- '), to_char(val, ' BC')
    )
END;
$$;


ALTER FUNCTION "msar"."format_data"("val" timestamp with time zone) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."format_data"("val" time with time zone) RETURNS "text"
    LANGUAGE "sql" IMMUTABLE STRICT PARALLEL SAFE
    AS $$
SELECT CASE
  WHEN date_part('timezone_hour', val) = 0 AND date_part('timezone_minute', val) = 0
    THEN concat(
      to_char(date_part('hour', val), 'FM00'), ':', to_char(date_part('minute', val), 'FM00'),
      ':', to_char(date_part('seconds', val), 'FM00.0999999999'), 'Z'
    )
  ELSE
    concat(
      to_char(date_part('hour', val), 'FM00'), ':', to_char(date_part('minute', val), 'FM00'),
      ':', to_char(date_part('seconds', val), 'FM00.0999999999'),
      to_char(date_part('timezone_hour', val), 'S00'), ':',
      ltrim(to_char(date_part('timezone_minute', val), '00'), '+- ')
    )
END;
$$;


ALTER FUNCTION "msar"."format_data"("val" time with time zone) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."get_attnum"("rel_id" "oid", "att_name" "text") RETURNS smallint
    LANGUAGE "sql" STRICT
    AS $$/*
Get the attnum for a given attribute in the relation. Returns null if no such attribute exists.

Usually, this will be used to get the attnum for a column of a table.

Args:
  rel_id: The relation where we'll look for the attribute.
  att_name: The name of the attribute, unquoted.
*/
SELECT attnum FROM pg_attribute WHERE attrelid=rel_id AND attname=att_name;
$$;


ALTER FUNCTION "msar"."get_attnum"("rel_id" "oid", "att_name" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."get_cast_function_name"("target_type" "regtype") RETURNS "text"
    LANGUAGE "plpgsql" STRICT
    AS $$/*
Return a string giving the appropriate name of the casting function for the target_type.

Currently set up to duplicate the logic in our python casting function builder. This will be
changed. Given a qualified, potentially capitalized type name, we
- Remove the namespace (schema),
- Replace any white space in the type name with underscores,
- Replace double quotes in the type name (e.g., the "char" type) with '_double_quote_'
- Use the prepped type name in the name `msar.cast_to_%s`.

Args:
  target_type: This should be a type that exists.
*/
DECLARE target_type_prepped text;
BEGIN
  -- TODO: Come up with a way to build these names that is more robust against collisions.
  WITH unqualifier AS (
    SELECT x[array_upper(x, 1)] unqualified_type
    FROM regexp_split_to_array(target_type::text, '\.') x
  ), unspacer AS(
    SELECT replace(unqualified_type, ' ', '_') unspaced_type
    FROM unqualifier
  )
  SELECT replace(unspaced_type, '"', '_double_quote_')
  FROM unspacer
  INTO target_type_prepped;
  RETURN format('msar.cast_to_%s', target_type_prepped);
END;
$$;


ALTER FUNCTION "msar"."get_cast_function_name"("target_type" "regtype") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."get_column_info"("tab_id" "regclass") RETURNS "jsonb"
    LANGUAGE "sql" STRICT
    AS $$/*
Given a table identifier, return an array of objects describing the columns of the table.

Each returned JSON object in the array will have the form:
  {
    "id": <int>,
    "name": <str>,
    "type": <str>,
    "type_options": <obj>,
    "nullable": <bool>,
    "primary_key": <bool>,
    "default": {"value": <str>, "is_dynamic": <bool>},
    "has_dependents": <bool>,
    "description": <str>,
    "current_role_priv": [<str>, <str>, ...]
  }

The `type_options` object is described in the docstring of `msar.get_type_options`. The `default`
object has the keys:
  value: A string giving the value (as an SQL expression) of the default.
  is_dynamic: A boolean giving whether the default is (likely to be) dynamic.
*/
SELECT coalesce(jsonb_agg(column_data), '[]'::jsonb)
FROM msar.column_info_table(tab_id) AS column_data;
$$;


ALTER FUNCTION "msar"."get_column_info"("tab_id" "regclass") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."get_column_name"("rel_id" "oid", "col_id" integer) RETURNS "text"
    LANGUAGE "sql" STRICT
    AS $$/*
Return the UNQUOTED name for a given column in a given relation (e.g., table).

More precisely, this function returns the name of attributes of any relation appearing in the
pg_class catalog table (so you could find attributes of indices with this function).

Args:
  rel_id:  The OID of the relation.
  col_id:  The attnum of the column in the relation.
*/
SELECT attname::text FROM pg_attribute WHERE attrelid=rel_id AND attnum=col_id;
$$;


ALTER FUNCTION "msar"."get_column_name"("rel_id" "oid", "col_id" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."get_column_name"("rel_id" "oid", "col_name" "text") RETURNS "text"
    LANGUAGE "sql" STRICT
    AS $$/*
Return the UNQUOTED name for a given column in a given relation (e.g., table).

More precisely, this function returns the unquoted name of attributes of any relation appearing in the
pg_class catalog table (so you could find attributes of indices with this function). If the given
col_name is not in the relation, we return null.

This has the effect of both quoting and preparing the given col_name, and also validating that it
exists.

Args:
  rel_id:  The OID of the relation.
  col_name:  The unquoted name of the column in the relation.
*/
SELECT attname::text FROM pg_attribute WHERE attrelid=rel_id AND attname=col_name;
$$;


ALTER FUNCTION "msar"."get_column_name"("rel_id" "oid", "col_name" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."get_column_names"("rel_id" "oid", "columns" "jsonb") RETURNS "text"[]
    LANGUAGE "sql" STRICT
    AS $$/*
Return the QUOTED names for given columns in a given relation (e.g., table).

- If the rel_id is given as 0, the assumption is that this is a new table, so we just apply normal
quoting rules to a column without validating anything further.
- If the rel_id is given as nonzero, and a column is given as text, then we validate that
  the column name exists in the table, and use that.
- If the rel_id is given as nonzero, and the column is given as a number, then we look the column up
  by attnum and use that name.

The columns jsonb can have a mix of numerical IDs and column names. The reason for this is that we
may be adding a column algorithmically, and this saves having to modify the column adding logic
based on the IDs passed by the user for given columns.

Args:
  rel_id:  The OID of the relation.
  columns:  A JSONB array of the unquoted names or IDs (can be mixed) of the columns.
*/
SELECT array_agg(
  CASE
    WHEN rel_id=0 THEN quote_ident(col #>> '{}')
    WHEN jsonb_typeof(col)='number' THEN quote_ident(msar.get_column_name(rel_id, col::integer))
    WHEN jsonb_typeof(col)='string' THEN quote_ident(msar.get_column_name(rel_id, col #>> '{}'))
  END
)
FROM jsonb_array_elements(columns) AS x(col);
$$;


ALTER FUNCTION "msar"."get_column_names"("rel_id" "oid", "columns" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."get_column_type"("rel_id" "oid", "col_id" smallint) RETURNS "text"
    LANGUAGE "sql" STRICT
    AS $$/*
Return the type of a given column in a relation.

Args:
  rel_id: The OID of the relation.
  col_id: The attnum of the column in the relation.
*/
SELECT atttypid::regtype
FROM pg_attribute
WHERE attnum = col_id
AND attrelid = rel_id;
$$;


ALTER FUNCTION "msar"."get_column_type"("rel_id" "oid", "col_id" smallint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."get_constraint_name"("con_id" "oid") RETURNS "text"
    LANGUAGE "plpgsql" STRICT
    AS $$/*
Return the UNQUOTED constraint name of the corresponding constraint oid.

Args:
  con_id: The OID of the constraint.
*/
BEGIN
  RETURN conname::text FROM pg_constraint WHERE pg_constraint.oid = con_id;
END;
$$;


ALTER FUNCTION "msar"."get_constraint_name"("con_id" "oid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."get_constraint_type_api_code"("contype" character) RETURNS "text"
    LANGUAGE "sql"
    AS $$/*
This function returns a string that represents the constraint type code used to describe
constraints when listing them within the Mathesar API.

PostgreSQL constraint types are documented by the `contype` field here:
https://www.postgresql.org/docs/current/catalog-pg-constraint.html

Notably, we don't include 't' (trigger) because triggers a bit different structurally and we don't
support working with them (yet?) in Mathesar.
*/
SELECT CASE contype
  WHEN 'c' THEN 'check'
  WHEN 'f' THEN 'foreignkey'
  WHEN 'p' THEN 'primary'
  WHEN 'u' THEN 'unique'
  WHEN 'x' THEN 'exclude'
END;
$$;


ALTER FUNCTION "msar"."get_constraint_type_api_code"("contype" character) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."get_constraints_for_table"("tab_id" "oid") RETURNS TABLE("oid" "oid", "name" "text", "type" "text", "columns" smallint[], "referent_table_oid" "oid", "referent_columns" smallint[])
    LANGUAGE "sql"
    AS $$/*
Return data describing the constraints set on a given table.

Args:
  tab_id: The OID of the table.
*/
WITH constraints AS (
  SELECT
    oid,
    conname AS name,
    msar.get_constraint_type_api_code(contype::char) AS type,
    conkey AS columns,
    confrelid AS referent_table_oid,
    confkey AS referent_columns
  FROM pg_catalog.pg_constraint
  WHERE conrelid = tab_id
)
SELECT *
FROM constraints
WHERE type IS NOT NULL
$$;


ALTER FUNCTION "msar"."get_constraints_for_table"("tab_id" "oid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."get_current_database_info"() RETURNS "jsonb"
    LANGUAGE "sql" STABLE STRICT
    AS $$/*
Return information about the current database.

The returned JSON object has the form:
  {
    "oid": <bigint>,
    "name": <str>,
    "owner_oid": <bigint>,
    "current_role_priv": [<str>],
    "current_role_owner": <bool>
  }
*/
SELECT jsonb_build_object(
  'oid', pgd.oid::bigint,
  'name', pgd.datname,
  'owner_oid', pgd.datdba::bigint,
  'current_role_priv', msar.list_database_privileges_for_current_role(pgd.oid),
  'current_role_owns', pg_catalog.pg_has_role(pgd.datdba, 'USAGE')
) FROM pg_catalog.pg_database AS pgd
WHERE pgd.datname = pg_catalog.current_database();
$$;


ALTER FUNCTION "msar"."get_current_database_info"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."get_current_role"() RETURNS "jsonb"
    LANGUAGE "sql" STABLE
    AS $$/*
Returns a JSON object describing the current_role and the parent role(s) whose
privileges are immediately available to current_role without doing SET ROLE.
*/
SELECT jsonb_build_object(
  'current_role', msar.get_role(current_role),
  'parent_roles', COALESCE(array_remove(
    array_agg(
      CASE WHEN pg_has_role(current_role, role_data.name, 'USAGE')
      THEN msar.get_role(role_data.name) END
    ), NULL
  ), ARRAY[]::jsonb[])
)
FROM msar.role_info_table() AS role_data
WHERE role_data.name NOT LIKE 'pg_%'
AND role_data.name != current_role;
$$;


ALTER FUNCTION "msar"."get_current_role"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."get_database_name"("dat_id" "oid") RETURNS "text"
    LANGUAGE "plpgsql" STABLE STRICT
    AS $$/*
Return the UNQUOTED name of a given database.

If the database does not exist, an exception will be raised.

Args:
  dat_id: The OID of the role.
*/
DECLARE dat_name text;
BEGIN
  SELECT datname INTO dat_name FROM pg_catalog.pg_database WHERE oid=dat_id;

  IF dat_name IS NULL THEN
    RAISE EXCEPTION 'Database with OID % does not exist', dat_id
    USING ERRCODE = '42704'; -- undefined_object
  END IF;

  RETURN dat_name;
END;
$$;


ALTER FUNCTION "msar"."get_database_name"("dat_id" "oid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."get_default_summary_column"("tab_id" "oid") RETURNS smallint
    LANGUAGE "sql" STABLE STRICT
    AS $$/*
Choose a column to use for summarizing rows of a table.

If a string type column exists, we choose the one with a minimal attnum. If no such column exists,
we just return the column (of any type) with minimum attnum.

Only columns to which the user has access are returned.

Args:
  tab_id: The OID of the table for which we're finding a good summary column
*/
SELECT attnum
FROM pg_catalog.pg_attribute pga JOIN pg_catalog.pg_type pgt ON pga.atttypid = pgt.oid
WHERE pga.attrelid = tab_id
  AND pga.attnum > 0
  AND NOT pga.attisdropped
  AND has_column_privilege(pga.attrelid, pga.attnum, 'SELECT')
ORDER BY (CASE WHEN pgt.typcategory='S' THEN 0 ELSE 1 END), pga.attnum
LIMIT 1;
$$;


ALTER FUNCTION "msar"."get_default_summary_column"("tab_id" "oid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."get_extracted_col_def_jsonb"("tab_id" "oid", "col_ids" integer[]) RETURNS "jsonb"
    LANGUAGE "sql" STRICT
    AS $$/*
Get a JSON array of column definitions from given columns for creation of an extracted table.

See the __msar.process_col_def_jsonb for a description of the JSON.

Args:
  tab_id: The OID of the table containing the columns whose definitions we want.
  col_ids: The attnum of the columns whose definitions we want.
*/

SELECT jsonb_agg(
  jsonb_build_object(
    'name', attname,
    'type', jsonb_build_object('id', atttypid, 'modifier', atttypmod),
    'not_null', attnotnull,
    'default',
    -- We only copy non-dynamic default expressions to new table to avoid double-use of sequences.
    -- Sequences are owned by a specific column, and can't be reused without error.
    CASE WHEN NOT msar.is_default_possibly_dynamic(tab_id, col_id) THEN
      pg_get_expr(adbin, tab_id)
    END
  )
)
FROM pg_attribute AS pg_columns
  JOIN unnest(col_ids) AS columns_to_copy(col_id)
    ON pg_columns.attnum=columns_to_copy.col_id
  LEFT JOIN pg_attrdef AS pg_column_defaults
    ON pg_column_defaults.adnum=pg_columns.attnum AND pg_columns.attrelid=pg_column_defaults.adrelid
WHERE pg_columns.attrelid=tab_id AND NOT msar.is_pkey_col(tab_id, col_id);
$$;


ALTER FUNCTION "msar"."get_extracted_col_def_jsonb"("tab_id" "oid", "col_ids" integer[]) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."get_extracted_con_def_jsonb"("tab_id" "oid", "col_ids" integer[]) RETURNS "jsonb"
    LANGUAGE "sql" STRICT
    AS $$/*
Get a JSON array of constraint definitions from given columns for creation of an extracted table.

See the __msar.process_con_def_jsonb for a description of the JSON.

Args:
  tab_id: The OID of the table containing the constraints whose definitions we want.
  col_ids: The attnum of columns with the constraints whose definitions we want.
*/

SELECT jsonb_agg(
  jsonb_build_object(
    'type', contype,
    'columns', ARRAY[attname],
    'deferrable', condeferrable,
    'fkey_relation_id', confrelid::bigint,
    'fkey_columns', coalesce(confkey, ARRAY[]::smallint[]),
    'fkey_update_action', confupdtype,
    'fkey_delete_action', confdeltype,
    'fkey_match_type', confmatchtype
  )
)
FROM pg_constraint
  JOIN unnest(col_ids) AS columns_to_copy(col_id) ON pg_constraint.conkey[1]=columns_to_copy.col_id
  JOIN pg_attribute
    ON pg_attribute.attnum=columns_to_copy.col_id AND pg_attribute.attrelid=pg_constraint.conrelid
WHERE pg_constraint.conrelid=tab_id AND (pg_constraint.contype='f' OR pg_constraint.contype='u');
$$;


ALTER FUNCTION "msar"."get_extracted_con_def_jsonb"("tab_id" "oid", "col_ids" integer[]) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."get_fkey_action_from_char"("char") RETURNS "text"
    LANGUAGE "sql" STRICT
    AS $_$/*
Map the "char" from pg_constraint to the update or delete action string.
*/
SELECT CASE
  WHEN $1 = 'a' THEN 'NO ACTION'
  WHEN $1 = 'r' THEN 'RESTRICT'
  WHEN $1 = 'c' THEN 'CASCADE'
  WHEN $1 = 'n' THEN 'SET NULL'
  WHEN $1 = 'd' THEN 'SET DEFAULT'
END;
$_$;


ALTER FUNCTION "msar"."get_fkey_action_from_char"("char") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."get_fkey_map_table"("tab_id" "oid") RETURNS TABLE("target_oid" "oid", "conkey" smallint, "confkey" smallint)
    LANGUAGE "sql" STABLE STRICT
    AS $$/*
Generate a table mapping foreign key values from refererrer to referent tables.

Given an input table (identified by OID), we return a table with each row representing a foreign key
constraint on that table. We return only single-column foreign keys, and only one per foreign key
column.

Args:
  tab_id: The OID of the table containing the foreign key columns to map.
*/
SELECT DISTINCT ON (conkey) pgc.confrelid AS target_oid, x.conkey AS conkey, y.confkey AS confkey
FROM pg_constraint pgc, LATERAL unnest(conkey) x(conkey), LATERAL unnest(confkey) y(confkey)
WHERE
  pgc.conrelid = tab_id
  AND pgc.contype='f'
  AND cardinality(pgc.confkey) = 1
  AND has_column_privilege(tab_id, x.conkey, 'SELECT')
  AND has_column_privilege(pgc.confrelid, y.confkey, 'SELECT')
ORDER BY conkey, target_oid, confkey;
$$;


ALTER FUNCTION "msar"."get_fkey_map_table"("tab_id" "oid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."get_fkey_match_type_from_char"("char") RETURNS "text"
    LANGUAGE "sql" STRICT
    AS $_$/*
Convert a char to its proper string describing the match type.

NOTE: Since 'PARTIAL' is not implemented (and throws an error), we don't use it here.
*/
SELECT CASE
  WHEN $1 = 'f' THEN 'FULL'
  WHEN $1 = 's' THEN 'SIMPLE'
END;
$_$;


ALTER FUNCTION "msar"."get_fkey_match_type_from_char"("char") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."get_fresh_copy_name"("tab_id" "oid", "col_id" smallint) RETURNS "text"
    LANGUAGE "plpgsql" STRICT
    AS $$/*
This function generates a name to be used for a duplicated column.

Given an original column name 'abc', the resulting copies will be named 'abc <n>', where <n> is
minimal (at least 1) subject to the restriction that 'abc <n>' is not already a column of the table
given.

Args:
  tab_id: the table for which we'll generate a column name.
  col_id: the original column whose name we'll use as the prefix in our copied column name.
*/
DECLARE
  original_col_name text;
  idx integer := 1;
BEGIN
  original_col_name := attname FROM pg_attribute WHERE attrelid=tab_id AND attnum=col_id;
  WHILE format('%s %s', original_col_name, idx) IN (
    SELECT attname FROM pg_attribute WHERE attrelid=tab_id
  ) LOOP
    idx = idx + 1;
  END LOOP;
  RETURN format('%s %s', original_col_name, idx);
END;
$$;


ALTER FUNCTION "msar"."get_fresh_copy_name"("tab_id" "oid", "col_id" smallint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."get_interval_fields"("typ_mod" integer) RETURNS "text"
    LANGUAGE "sql" STRICT
    AS $$/*
Return the string giving the fields for an interval typmod integer.

This logic is ported from the relevant PostgreSQL source code, reimplemented in SQL. See the
`intervaltypmodout` function at
https://doxygen.postgresql.org/backend_2utils_2adt_2timestamp_8c.html

Args:
  typ_mod: The atttypmod from the pg_attribute table. Should be valid for the interval type.
*/
SELECT CASE (typ_mod >> 16 & 32767)
  WHEN 1 << 2 THEN 'year'
  WHEN 1 << 1 THEN 'month'
  WHEN 1 << 3 THEN 'day'
  WHEN 1 << 10 THEN 'hour'
  WHEN 1 << 11 THEN 'minute'
  WHEN 1 << 12 THEN 'second'
  WHEN (1 << 2) | (1 << 1) THEN 'year to month'
  WHEN (1 << 3) | (1 << 10) THEN 'day to hour'
  WHEN (1 << 3) | (1 << 10) | (1 << 11) THEN 'day to minute'
  WHEN (1 << 3) | (1 << 10) | (1 << 11) | (1 << 12) THEN 'day to second'
  WHEN (1 << 10) | (1 << 11) THEN 'hour to minute'
  WHEN (1 << 10) | (1 << 11) | (1 << 12) THEN 'hour to second'
  WHEN (1 << 11) | (1 << 12) THEN 'minute to second'
END;
$$;


ALTER FUNCTION "msar"."get_interval_fields"("typ_mod" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."get_joinable_tables"("max_depth" integer) RETURNS SETOF "msar"."joinable_tables"
    LANGUAGE "sql" STABLE
    AS $$/*
This function returns a table of msar.joinable_tables objects, giving paths to various
joinable tables.

Args:
  max_depth: This controls how far to search for joinable tables.

The base and target are OIDs of a base table, and a target table that can be
joined by some combination of joins along single-column foreign key column
restrictions in either way.
*/
WITH RECURSIVE symmetric_fkeys AS (
  SELECT
    c.oid::BIGINT fkey_oid,
    c.conrelid::BIGINT left_rel,
    c.confrelid::BIGINT right_rel,
    c.conkey[1]::INTEGER left_col,
    c.confkey[1]::INTEGER right_col,
    false multiple_results,
    false reversed
  FROM pg_constraint c
  WHERE c.contype='f' and array_length(c.conkey, 1)=1
UNION ALL
  SELECT
    c.oid::BIGINT fkey_oid,
    c.confrelid::BIGINT left_rel,
    c.conrelid::BIGINT right_rel,
    c.confkey[1]::INTEGER left_col,
    c.conkey[1]::INTEGER right_col,
    true multiple_results,
    true reversed
  FROM pg_constraint c
  WHERE c.contype='f' and array_length(c.conkey, 1)=1
),

search_fkey_graph(
    left_rel, right_rel, left_col, right_col, depth, join_path, fkey_path, multiple_results
) AS (
  SELECT
    sfk.left_rel,
    sfk.right_rel,
    sfk.left_col,
    sfk.right_col,
    1,
    jsonb_build_array(
      jsonb_build_array(
        jsonb_build_array(sfk.left_rel, sfk.left_col),
        jsonb_build_array(sfk.right_rel, sfk.right_col)
      )
    ),
    jsonb_build_array(jsonb_build_array(sfk.fkey_oid, sfk.reversed)),
    sfk.multiple_results
  FROM symmetric_fkeys sfk
UNION ALL
  SELECT
    sfk.left_rel,
    sfk.right_rel,
    sfk.left_col,
    sfk.right_col,
    sg.depth + 1,
    join_path || jsonb_build_array(
      jsonb_build_array(
        jsonb_build_array(sfk.left_rel, sfk.left_col),
        jsonb_build_array(sfk.right_rel, sfk.right_col)
      )
    ),
    fkey_path || jsonb_build_array(jsonb_build_array(sfk.fkey_oid, sfk.reversed)),
    sg.multiple_results OR sfk.multiple_results
  FROM symmetric_fkeys sfk, search_fkey_graph sg
  WHERE
    sfk.left_rel=sg.right_rel
    AND depth<max_depth
    AND (join_path -> -1) != jsonb_build_array(
      jsonb_build_array(sfk.right_rel, sfk.right_col),
      jsonb_build_array(sfk.left_rel, sfk.left_col)
    )
), output_cte AS (
  SELECT
    (join_path#>'{0, 0, 0}')::INTEGER base,
    (join_path#>'{-1, -1, 0}')::INTEGER target,
    join_path,
    fkey_path,
    depth,
    multiple_results
  FROM search_fkey_graph
)
SELECT * FROM output_cte;
$$;


ALTER FUNCTION "msar"."get_joinable_tables"("max_depth" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."get_joinable_tables"("max_depth" integer, "table_id" "oid") RETURNS "jsonb"
    LANGUAGE "sql" STABLE STRICT
    AS $$
  WITH jt_cte AS (
    SELECT * FROM msar.get_joinable_tables(max_depth) WHERE base=table_id
  ), target_cte AS (
    SELECT pga.attrelid AS tt_oid, 
      jsonb_build_object(
        'name', msar.get_relation_name(pga.attrelid),
        'columns', jsonb_object_agg(
            pga.attnum, jsonb_build_object(
              'name', pga.attname,
              'type', CASE WHEN attndims>0 THEN '_array' ELSE atttypid::regtype::text END
            )
          )
      ) AS tt_info
    FROM pg_catalog.pg_attribute AS pga, jt_cte
    WHERE pga.attrelid=jt_cte.target AND pga.attnum > 0 and NOT pga.attisdropped
    GROUP BY pga.attrelid
  ), joinable_tables AS (
    SELECT jsonb_agg(to_jsonb(jt_cte.*)) AS jt FROM jt_cte
  ), target_table_info AS (
    SELECT jsonb_object_agg(tt_oid, tt_info) AS tt FROM target_cte
  )
  SELECT jsonb_build_object(
    'joinable_tables', COALESCE(joinable_tables.jt, '[]'::jsonb),
    'target_table_info', COALESCE(target_table_info.tt, '{}'::jsonb)
  ) FROM joinable_tables, target_table_info;
$$;


ALTER FUNCTION "msar"."get_joinable_tables"("max_depth" integer, "table_id" "oid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."get_mathesar_money_array"("text") RETURNS "text"[]
    LANGUAGE "plpgsql"
    AS $_$
DECLARE
  raw_arr text[];
  actual_number_arr text[];
  group_divider_arr text[];
  decimal_point_arr text[];
  actual_number text;
  group_divider text;
  decimal_point text;
  currency_prefix text;
  currency_suffix text;

  -- pieces required for regex
  non_numeric text := '(?:[^.,0-9]+)';
  no_separator_big text := '[0-9]{4,}(?:([,.])[0-9]+)?';
  no_separator_small text := '[0-9]{1,3}(?:([,.])[0-9]{1,2}|[0-9]{4,})?';
  comma_separator_req_decimal text := '[0-9]{1,3}(,)[0-9]{3}(\.)[0-9]+';
  period_separator_req_decimal text := '[0-9]{1,3}(\.)[0-9]{3}(,)[0-9]+';
  comma_separator_opt_decimal text := '[0-9]{1,3}(?:(,)[0-9]{3}){2,}(?:(\.)[0-9]+)?';
  period_separator_opt_decimal text := '[0-9]{1,3}(?:(\.)[0-9]{3}){2,}(?:(,)[0-9]+)?';
  space_separator_opt_decimal text := '[0-9]{1,3}(?:( )[0-9]{3})+(?:([,.])[0-9]+)?';
  comma_separator_lakh_system text := '[0-9]{1,2}(?:(,)[0-9]{2})+,[0-9]{3}(?:(\.)[0-9]+)?';
  inner_number_tree text := concat_ws('|',
                            no_separator_big,
                            no_separator_small,
                            comma_separator_req_decimal,
                            period_separator_req_decimal,
                            comma_separator_opt_decimal,
                            period_separator_opt_decimal,
                            space_separator_opt_decimal,
                            comma_separator_lakh_system
                          );
  inner_number_group text := '(' || inner_number_tree || ')';/* Numbers without currency,
  including inner_number_group as its own capturing group in the money_finding_regex allows us to
  match columns without any currency symbols allowing users the flexibility
  to add currency prefixes and suffixes afterwards in the cases of type inference/data imports. */
  required_currency_beginning text := non_numeric || inner_number_group || non_numeric || '?';
  required_currency_ending text := non_numeric || '?' || inner_number_group || non_numeric;
  money_finding_regex text := '^(?:' || required_currency_beginning || '|' || required_currency_ending || '|' || inner_number_group || ')$';
BEGIN
  SELECT regexp_matches($1, money_finding_regex) INTO raw_arr;
  IF raw_arr IS NULL THEN
    RETURN NULL;
  END IF;
  SELECT array_remove(ARRAY[
    raw_arr[1], -- required_currency_beginning[x]
    raw_arr[16], -- required_currency_ending[x+15]
    raw_arr[31] -- inner_number_group[x+30]
  ], null) INTO actual_number_arr;
  SELECT array_remove(ARRAY[
    raw_arr[4],raw_arr[6],raw_arr[8],raw_arr[10],raw_arr[12],raw_arr[14], -- required_currency_beginning[x]
    raw_arr[19],raw_arr[21],raw_arr[23],raw_arr[25],raw_arr[27],raw_arr[29], -- required_currency_ending[x+15]
    raw_arr[34],raw_arr[36],raw_arr[38],raw_arr[40],raw_arr[42],raw_arr[44] -- inner_number_group[x+30]
  ], null) INTO group_divider_arr;
  SELECT array_remove(ARRAY[
    raw_arr[2],raw_arr[3],raw_arr[5],raw_arr[7],raw_arr[9],raw_arr[11],raw_arr[13],raw_arr[15], -- required_currency_beginning[x]
    raw_arr[17],raw_arr[18],raw_arr[20],raw_arr[22],raw_arr[24],raw_arr[26],raw_arr[28],raw_arr[30], -- required_currency_ending[x+15]
    raw_arr[32],raw_arr[33],raw_arr[35],raw_arr[37],raw_arr[39],raw_arr[41],raw_arr[43],raw_arr[45] -- inner_number_group[x+30]
  ], null) INTO decimal_point_arr;
  SELECT actual_number_arr[1] INTO actual_number;
  SELECT group_divider_arr[1] INTO group_divider;
  SELECT decimal_point_arr[1] INTO decimal_point;
  SELECT replace(replace(split_part($1, actual_number, 1), '-', ''), '(', '') INTO currency_prefix;
  SELECT replace(replace(split_part($1, actual_number, 2), '-', ''), ')', '') INTO currency_suffix;
  IF $1::text ~ '^.*(-|\(.+\)).*$' THEN -- Handle negative values
    actual_number := '-' || actual_number;
  END IF;
  RETURN ARRAY[actual_number, group_divider, decimal_point, currency_prefix, currency_suffix];
END;
$_$;


ALTER FUNCTION "msar"."get_mathesar_money_array"("text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."get_numeric_array"("text") RETURNS "text"[]
    LANGUAGE "plpgsql"
    AS $_$
  DECLARE
    raw_arr text[];
    actual_number_arr text[];
    group_divider_arr text[];
    decimal_point_arr text[];
    actual_number text;
    group_divider text;
    decimal_point text;
  BEGIN
    SELECT regexp_matches($1, '^(?:[+-]?([0-9]{4,}(?:([,.])[0-9]+)?|[0-9]{1,3}(?:([,.])[0-9]{1,2}|[0-9]{4,})?|[0-9]{1,3}(,)[0-9]{3}(\.)[0-9]+|[0-9]{1,3}(\.)[0-9]{3}(,)[0-9]+|[0-9]{1,3}(?:(,)[0-9]{3}){2,}(?:(\.)[0-9]+)?|[0-9]{1,3}(?:(\.)[0-9]{3}){2,}(?:(,)[0-9]+)?|[0-9]{1,3}(?:( )[0-9]{3})+(?:([,.])[0-9]+)?|[0-9]{1,2}(?:(,)[0-9]{2})+,[0-9]{3}(?:(\.)[0-9]+)?|[0-9]{1,3}(?:(\'')[0-9]{3})+(?:([.])[0-9]+)?))$') INTO raw_arr;
    IF raw_arr IS NULL THEN
      RETURN NULL;
    END IF;
    SELECT array_remove(ARRAY[raw_arr[1]], null) INTO actual_number_arr;
    SELECT array_remove(ARRAY[raw_arr[4],raw_arr[6],raw_arr[8],raw_arr[10],raw_arr[12],raw_arr[14],raw_arr[16]], null) INTO group_divider_arr;
    SELECT array_remove(ARRAY[raw_arr[2],raw_arr[3],raw_arr[5],raw_arr[7],raw_arr[9],raw_arr[11],raw_arr[13],raw_arr[15],raw_arr[17]], null) INTO decimal_point_arr;
    SELECT actual_number_arr[1] INTO actual_number;
    SELECT group_divider_arr[1] INTO group_divider;
    SELECT decimal_point_arr[1] INTO decimal_point;
    RETURN ARRAY[actual_number, group_divider, decimal_point];
  END;
$_$;


ALTER FUNCTION "msar"."get_numeric_array"("text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."get_object_counts"() RETURNS "jsonb"
    LANGUAGE "sql" STABLE
    AS $$/*
Return a JSON object with counts of some objects in the database.

We exclude the mathesar-system schemas.

The objects counted are:
- total schemas, excluding Mathesar internal schemas
- total tables in the included schemas
- total rows of tables included
*/
SELECT jsonb_build_object(
  'schema_count', COUNT(DISTINCT pgn.oid),
  'table_count', COUNT(pgc.oid),
  'record_count', SUM(pgc.reltuples)
)
FROM pg_catalog.pg_namespace pgn
LEFT JOIN pg_catalog.pg_class pgc ON pgc.relnamespace = pgn.oid AND pgc.relkind = 'r'
WHERE pgn.nspname <> 'information_schema'
AND NOT (pgn.nspname = ANY(msar.mathesar_system_schemas()))
AND pgn.nspname NOT LIKE 'pg_%';
$$;


ALTER FUNCTION "msar"."get_object_counts"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."get_other_column_ids"("tab_id" "regclass", "col_ids" smallint[]) RETURNS smallint[]
    LANGUAGE "sql" STABLE STRICT
    AS $$
SELECT array_agg(attnum)
FROM pg_catalog.pg_attribute
WHERE
  attrelid = tab_id
  AND attnum > 0
  AND NOT attisdropped
  AND attnum <> all(col_ids);
$$;


ALTER FUNCTION "msar"."get_other_column_ids"("tab_id" "regclass", "col_ids" smallint[]) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."get_pk_column"("rel_id" "oid") RETURNS smallint
    LANGUAGE "sql" STRICT
    AS $$/*
Return the first column attnum in the primary key of a given relation (e.g., table).

TODO: resolve potential code duplication between this function and `get_selectable_pkey_attnum`.

Args:
  rel_id: The OID of the relation.
*/
SELECT CASE WHEN array_length(conkey, 1) = 1 THEN conkey[1] END
FROM pg_constraint
WHERE contype='p'
AND conrelid=rel_id;
$$;


ALTER FUNCTION "msar"."get_pk_column"("rel_id" "oid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."get_pkey_order"("tab_id" "oid") RETURNS "jsonb"
    LANGUAGE "sql" STABLE STRICT
    AS $$
SELECT jsonb_agg(jsonb_build_object('attnum', attnum, 'direction', 'asc'))
FROM pg_constraint, LATERAL unnest(conkey) attnum
WHERE contype='p' AND conrelid=tab_id AND has_column_privilege(tab_id, attnum, 'SELECT');
$$;


ALTER FUNCTION "msar"."get_pkey_order"("tab_id" "oid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."get_preview"("tab_id" "oid", "col_cast_def" "jsonb", "rec_limit" integer) RETURNS "jsonb"
    LANGUAGE "plpgsql"
    AS $$/*
Preview a table, applying different type casts and options to the underlying columns before import,
returning a JSON object describing the records of the table.

Note that these casts are temporary and do not alter the data in the underlying table,
if you wish to alter these settings permanantly for the columns see msar.alter_columns.

Args:
  tab_id: The OID of the table to preview.
  col_cast_def: A JSON object describing the column settings to apply.
  rec_limit (optional): The upper limit for the number of records to return.

The col_cast_def JSONB should have the form:
[
  {
    "attnum": <int>,
    "type": {
      "name": <str>,
      "options": {
        "length": <integer>,
        "precision": <integer>,
        "scale": <integer>
        "fields": <str>,
        "array": <boolean>
      }
    },
  },
  {
    ...
  },
  ...
]
*/
DECLARE
  tab_name text;
  sel_query text;
  records jsonb;
BEGIN
  tab_name := __msar.get_qualified_relation_name(tab_id);
  sel_query := 'SELECT %s FROM %s LIMIT %L';
  WITH preview_cte AS (
    SELECT string_agg(
      'CAST(' ||
      __msar.build_cast_expr(
        quote_ident(msar.get_column_name(tab_id, (col_cast ->> 'attnum')::integer)), col_cast -> 'type' ->> 'name'
      ) ||
      ' AS ' ||
      msar.build_type_text(col_cast -> 'type') ||
      ')'|| ' AS ' || quote_ident(msar.get_column_name(tab_id, (col_cast ->> 'attnum')::integer)),
      ', '
    ) AS cast_expr
    FROM jsonb_array_elements(col_cast_def) AS col_cast
  )
  SELECT
    __msar.exec_dql(sel_query, cast_expr, tab_name, rec_limit::text)
  INTO records FROM preview_cte;
  RETURN records;
END;
$$;


ALTER FUNCTION "msar"."get_preview"("tab_id" "oid", "col_cast_def" "jsonb", "rec_limit" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."get_record_from_table"("tab_id" "oid", "rec_id" "anycompatible", "return_record_summaries" boolean DEFAULT false, "table_record_summary_templates" "jsonb" DEFAULT NULL::"jsonb") RETURNS "jsonb"
    LANGUAGE "sql" STABLE
    AS $$/*
Get single record from a table. Only columns to which the user has access are returned.

Args:
  tab_id: The OID of the table whose record we'll get.
  rec_id: The id value of the record.

The table must have a single primary key column.
*/
SELECT msar.list_records_from_table(
  tab_id,
  null,
  null,
  null,
  jsonb_build_object(
    'type', 'equal',
    'args', jsonb_build_array(
      jsonb_build_object('type', 'attnum', 'value', msar.get_pk_column(tab_id)),
      jsonb_build_object('type', 'literal', 'value', rec_id)
    )
  ),
  null,
  return_record_summaries,
  table_record_summary_templates
)
$$;


ALTER FUNCTION "msar"."get_record_from_table"("tab_id" "oid", "rec_id" "anycompatible", "return_record_summaries" boolean, "table_record_summary_templates" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."get_relation_name"("rel_oid" "oid") RETURNS "text"
    LANGUAGE "plpgsql" STRICT
    AS $$/*
Return the UNQUOTED name of a given relation (e.g., table).

If the relation does not exist, an exception will be raised.

Args:
  rel_oid: The OID of the relation.
*/
DECLARE rel_name text;
BEGIN
  SELECT relname INTO rel_name FROM pg_class WHERE oid=rel_oid;

  IF rel_name IS NULL THEN
    RAISE EXCEPTION 'Relation with OID % does not exist', rel_oid
    USING ERRCODE = '42P01'; -- undefined_table
  END IF;

  RETURN rel_name;
END;
$$;


ALTER FUNCTION "msar"."get_relation_name"("rel_oid" "oid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."get_relation_namespace_oid"("rel_id" "oid") RETURNS "oid"
    LANGUAGE "sql" STRICT
    AS $$/*
Get the OID of the namespace containing the given relation.

Most useful for getting the OID of the schema of a given table.

Args:
  rel_id: The OID of the relation whose namespace we want to find.
*/
SELECT relnamespace FROM pg_class WHERE oid=rel_id;
$$;


ALTER FUNCTION "msar"."get_relation_namespace_oid"("rel_id" "oid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."get_relation_schema_name"("rel_oid" "oid") RETURNS "text"
    LANGUAGE "plpgsql" STRICT
    AS $$/*
Return the UNQUOTED name of the schema which contains a given relation (e.g., table).

If the relation does not exist, an exception will be raised.

Args:
  rel_oid: The OID of the relation.
*/
DECLARE sch_name text;
BEGIN
  SELECT n.nspname INTO sch_name
  FROM pg_catalog.pg_class c
  JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
  WHERE c.oid = rel_oid;

  IF sch_name IS NULL THEN
    RAISE EXCEPTION 'Relation with OID % does not exist', rel_oid
    USING ERRCODE = '42P01'; -- undefined_table
  END IF;

  RETURN sch_name;
END;
$$;


ALTER FUNCTION "msar"."get_relation_schema_name"("rel_oid" "oid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."get_role"("rolename" "text") RETURNS "jsonb"
    LANGUAGE "sql" STABLE
    AS $$/*
Given a rolename, return a JSON object describing the role in a database server.

The returned JSON object has the form:
  {
    "oid": <int>
    "name": <str>
    "super": <bool>
    "inherits": <bool>
    "create_role": <bool>
    "create_db": <bool>
    "login": <bool>
    "description": <str|null>
    "members": <[
        { "oid": <int>, "admin": <bool> }
      ]|null>
  }
*/
SELECT to_jsonb(role_data)
FROM msar.role_info_table() AS role_data
WHERE role_data.name = rolename;
$$;


ALTER FUNCTION "msar"."get_role"("rolename" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."get_role_name"("rol_oid" "oid") RETURNS "text"
    LANGUAGE "plpgsql" STABLE STRICT
    AS $$/*
Return the UNQUOTED name of a given role.

If the role does not exist, an exception will be raised.

Args:
  rol_oid: The OID of the role.
*/
DECLARE rol_name text;
BEGIN
  SELECT rolname INTO rol_name FROM pg_catalog.pg_roles WHERE oid=rol_oid;

  IF rol_name IS NULL THEN
    RAISE EXCEPTION 'Role with OID % does not exist', rol_oid
    USING ERRCODE = '42704'; -- undefined_object
  END IF;

  RETURN rol_name;
END;
$$;


ALTER FUNCTION "msar"."get_role_name"("rol_oid" "oid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."get_schema"("sch_id" "regnamespace") RETURNS "jsonb"
    LANGUAGE "sql" STABLE
    AS $$/*
Return a json object describing the user-defined schema in the database.

Each returned JSON object will have the form:
  {
    "oid": <int>
    "name": <str>
    "description": <str|null>
    "owner_oid": <int>,
    "current_role_priv": [<str>],
    "current_role_owns": <bool>,
    "table_count": <int>
  }
*/
SELECT to_jsonb(schema_data)
FROM msar.schema_info_table() AS schema_data
WHERE schema_data.oid = sch_id;
$$;


ALTER FUNCTION "msar"."get_schema"("sch_id" "regnamespace") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."get_schema_name"("sch_id" "oid") RETURNS "text"
    LANGUAGE "plpgsql"
    AS $$/*
Return the UNQUOTED name for a given schema.

Raises an exception if the schema is not found.

Args:
  sch_id: The OID of the schema.
*/
DECLARE sch_name text;
BEGIN
  SELECT nspname INTO sch_name FROM pg_namespace WHERE oid=sch_id;

  IF sch_name IS NULL THEN
    RAISE EXCEPTION 'No schema with OID % exists.', sch_id
    USING ERRCODE = '3F000'; -- invalid_schema_name
  END IF;

  RETURN sch_name;
END;
$$;


ALTER FUNCTION "msar"."get_schema_name"("sch_id" "oid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."get_schema_objects_table"("sch_ids" "regnamespace"[]) RETURNS TABLE("obj_id" "oid", "obj_schema" "text", "obj_name" "text", "obj_kind" "text")
    LANGUAGE "sql" STABLE STRICT
    AS $$ /*
Return a table with information about most objects in the given schemas.
*/
WITH obj_cte AS (
  (
    SELECT
      oid AS obj_id,
      msar.get_schema_name(pronamespace) AS obj_schema,
      proname AS obj_name,
      CASE prokind
        WHEN 'a' THEN 'AGGREGATE'
        WHEN 'p' THEN 'PROCEDURE'
        ELSE 'FUNCTION'
      END AS obj_kind
    FROM pg_proc
    WHERE pronamespace=ANY(sch_ids)
  ) UNION (
    SELECT
      oid AS obj_id,
      msar.get_schema_name(typnamespace) AS obj_schema,
      typname AS obj_name,
      'TYPE' AS obj_kind
    FROM pg_type
    WHERE typnamespace=ANY(sch_ids)
  ) UNION (
    SELECT
      oid AS obj_id,
      msar.get_schema_name(relnamespace) AS obj_schema,
      relname AS obj_name,
      CASE relkind
        WHEN 'r' THEN 'TABLE'
        WHEN 'p' THEN 'TABLE'
        WHEN 'i' THEN 'INDEX'
        WHEN 'I' THEN 'INDEX'
        WHEN 'S' THEN 'SEQUENCE'
        WHEN 'v' THEN 'VIEW'
        WHEN 'm' THEN 'MATERIALIZED VIEW'
        WHEN 'c' THEN 'TYPE'
        WHEN 'f' THEN 'FOREIGN TABLE'
      END AS obj_kind
    FROM pg_class
    WHERE relnamespace=ANY(sch_ids)
  )
) SELECT DISTINCT obj_id, obj_schema, obj_name, obj_kind FROM obj_cte WHERE obj_kind IS NOT NULL;
$$;


ALTER FUNCTION "msar"."get_schema_objects_table"("sch_ids" "regnamespace"[]) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."get_schema_oid"("sch_name" "text") RETURNS "oid"
    LANGUAGE "sql" STRICT
    AS $$/*
Return the OID of a schema, or NULL if the schema does not exist.

Args :
  sch_name: The name of the schema, UNQUOTED.
*/
SELECT oid FROM pg_namespace WHERE nspname=sch_name;
$$;


ALTER FUNCTION "msar"."get_schema_oid"("sch_name" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."get_score_expr"("tab_id" "oid", "parameters_" "jsonb") RETURNS "text"
    LANGUAGE "sql" STABLE STRICT
    AS $_$
SELECT string_agg(
  CASE WHEN pgt.typcategory = 'S' OR pgt.typname = 'uuid' THEN
    format(
      $s$(CASE
        WHEN %1$I::text ILIKE %2$L THEN 4
        WHEN %1$I::text ILIKE %2$L || '%%' THEN 3
        WHEN %1$I::text ILIKE '%%' || %2$L || '%%' THEN 2
        ELSE 0
      END)$s$,
      pga.attname,
      x.literal
    )
  ELSE
    format('(CASE WHEN %1$I = %2$L THEN 4 ELSE 0 END)', pga.attname, x.literal)
  END,
  ' + '
)
FROM jsonb_to_recordset(parameters_) AS x(attnum smallint, literal text)
  INNER JOIN pg_catalog.pg_attribute AS pga ON x.attnum = pga.attnum
  INNER JOIN pg_catalog.pg_type AS pgt ON pga.atttypid = pgt.oid
WHERE
  pga.attrelid = tab_id
  AND NOT pga.attisdropped
  AND has_column_privilege(tab_id, x.attnum, 'SELECT')
$_$;


ALTER FUNCTION "msar"."get_score_expr"("tab_id" "oid", "parameters_" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."get_selectable_columns"("tab_id" "oid") RETURNS "jsonb"
    LANGUAGE "sql" STABLE STRICT
    AS $$/*
Returns a jsonb object with the columns to which the user has access.

Given columns with attnums 2, 3, and 4, and assuming the user has access only to columns 2 and 4,
this function will return a jsonb as follows:

{ "2": <name of column with oid 2>, "4": <name of column with oid 4> }

Args:
  tab_id: The OID of the table containing the columns to select.
*/
SELECT coalesce(jsonb_object_agg(attnum, attname), '{}'::jsonb)
FROM pg_catalog.pg_attribute
WHERE
  attrelid = tab_id
  AND attnum > 0
  AND NOT attisdropped
  AND has_column_privilege(attrelid, attnum, 'SELECT');
$$;


ALTER FUNCTION "msar"."get_selectable_columns"("tab_id" "oid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."get_selectable_pkey_attnum"("rel_id" "regclass") RETURNS smallint
    LANGUAGE "sql" STABLE STRICT
    AS $$/*
Get the attnum of the single-column primary key for a relation if it has one. If not, return null.

The attnum will only be returned if the current user has SELECT on that column.

TODO: resolve potential code duplication between this function and `get_pk_column`.

Args:
  rel_id:  The OID of the relation.
*/
SELECT conkey[1] FROM pg_constraint
WHERE
  conrelid = rel_id
  AND cardinality(conkey) = 1
  AND contype='p'
  AND has_column_privilege(rel_id, conkey[1], 'SELECT');
$$;


ALTER FUNCTION "msar"."get_selectable_pkey_attnum"("rel_id" "regclass") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."get_tab_col_info_map"("tab_col_map" "jsonb") RETURNS "jsonb"
    LANGUAGE "sql" STRICT
    AS $$/*
Returns table_info and column_info for a given tab_col_map.

tab_col_map should have the following form:
{
  "table_oid_1": [col_attnum_1, col_attnum_2, col_attnum_3],
  "table_oid_2": [col_attnum_4, col_attnum_5]
}

Returns:
{
  "table_oid_1": {
    "table_info": table_info(),
    "columns": {"col_attnum_1": col_info(), "col_attnum_2": col_info(), "col_attnum_3": col_info()
  },
  "table_oid2": {
    "table_info": table_info(),
    "columns": {"col_attnum_4": col_info(), "col_attnum_5": col_info()}
  }
}
*/
  WITH cte AS (
    SELECT
      tab_id::oid,
      ARRAY(SELECT jsonb_array_elements_text(attnums))::int[] AS attnums
    FROM jsonb_each(coalesce(tab_col_map, '{}'::jsonb)) AS x(tab_id, attnums)
  ),
  tab_info_cte AS (
    SELECT tab_id, jsonb_agg(tab_info) AS tab_info_json FROM cte
    LEFT JOIN msar.table_info_table() AS tab_info ON tab_info.oid=cte.tab_id
    GROUP BY tab_id
  ),
  col_info_cte AS (
    SELECT cte.tab_id AS tab_id,
    jsonb_object_agg(
      column_info.id, column_info
    ) AS col_info_json FROM cte
    LEFT JOIN pg_catalog.pg_attribute pga ON cte.tab_id = pga.attrelid
    LEFT JOIN msar.column_info_table(cte.tab_id) AS column_info ON pga.attnum = column_info.id
    WHERE column_info.id = ANY(cte.attnums)
    GROUP BY cte.tab_id
  )
  SELECT coalesce(
    jsonb_object_agg(
      tic.tab_id, jsonb_build_object(
      'table_info', coalesce(tic.tab_info_json,'{}'::jsonb),
      'columns', coalesce(cic.col_info_json, '{}'::jsonb)
    )
  ), '{}'::jsonb)
  FROM tab_info_cte AS tic
  LEFT JOIN col_info_cte AS cic ON tic.tab_id = cic.tab_id
$$;


ALTER FUNCTION "msar"."get_tab_col_info_map"("tab_col_map" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."get_table"("tab_id" "regclass") RETURNS "jsonb"
    LANGUAGE "sql" STRICT
    AS $$/*
Given a table identifier, return a JSON object describing the table.

Each returned JSON object will have the form:
  {
    "oid": <int>,
    "name": <str>,
    "schema": <int>,
    "description": <str>,
    "owner_oid": <int>,
    "current_role_priv": [<str>],
    "current_role_owns": <bool>
  }

Args:
  tab_id: The OID or name of the table.
*/
SELECT to_jsonb(table_data)
FROM msar.table_info_table() AS table_data
WHERE table_data.oid = tab_id;
$$;


ALTER FUNCTION "msar"."get_table"("tab_id" "regclass") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."get_table_columns_and_records"("tab_id" "oid", "limit_" integer, "offset_" integer, "order_" "jsonb", "filter_" "jsonb") RETURNS SETOF "jsonb"
    LANGUAGE "plpgsql" STABLE
    AS $_$
DECLARE
  expr_and_ctes jsonb;
BEGIN
  SELECT msar.build_record_list_query_components_with_ctes(
    tab_id,
    limit_,
    offset_,
    order_,
    filter_,
    null
  ) INTO expr_and_ctes;

  RETURN QUERY SELECT expr_and_ctes -> 'selectable_columns';
  RETURN QUERY EXECUTE format(
    $q$
    WITH results_cte AS ( %1$s )
    SELECT %2$s AS records FROM results_cte;
    $q$,
    expr_and_ctes ->> 'results_cte_query',
    COALESCE(
      msar.build_results_setof_jsonb_expr('results_cte'),
      'NULL'
    )
  );
END;
$_$;


ALTER FUNCTION "msar"."get_table_columns_and_records"("tab_id" "oid", "limit_" integer, "offset_" integer, "order_" "jsonb", "filter_" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."get_table_info"("sch_id" "regnamespace") RETURNS "jsonb"
    LANGUAGE "sql" STRICT
    AS $$/*
Given a schema identifier, return an array of objects describing the tables of the schema.

Each returned JSON object in the array will have the form:
  {
    "oid": <int>,
    "name": <str>,
    "schema": <int>,
    "description": <str>,
    "owner_oid": <int>,
    "current_role_priv": [<str>],
    "current_role_owns": <bool>
  }

Args:
  sch_id: The OID or name of the schema.
*/
SELECT coalesce(jsonb_agg(table_data),'[]'::jsonb)
FROM msar.table_info_table() AS table_data
WHERE table_data.schema = sch_id;
$$;


ALTER FUNCTION "msar"."get_table_info"("sch_id" "regnamespace") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."get_total_order"("tab_id" "oid") RETURNS "jsonb"
    LANGUAGE "sql" STABLE STRICT
    AS $$
WITH orderable_cte AS (
  SELECT attnum
  FROM pg_catalog.pg_attribute
    INNER JOIN pg_catalog.pg_cast ON atttypid=castsource
    INNER JOIN pg_catalog.pg_operator ON casttarget=oprleft
  WHERE
    attrelid = tab_id
    AND attnum > 0
    AND NOT attisdropped
    AND castcontext = 'i'
    AND oprname = '<'
  UNION SELECT attnum
  FROM pg_catalog.pg_attribute
    INNER JOIN pg_catalog.pg_operator ON atttypid=oprleft
  WHERE
    attrelid = tab_id
    AND attnum > 0
    AND NOT attisdropped
    AND oprname = '<'
  ORDER BY attnum
)
SELECT COALESCE(jsonb_agg(jsonb_build_object('attnum', attnum, 'direction', 'asc')), '[]'::jsonb)
FROM orderable_cte
WHERE has_column_privilege(tab_id, attnum, 'SELECT');
$$;


ALTER FUNCTION "msar"."get_total_order"("tab_id" "oid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."get_type_options"("typ_id" "regtype", "typ_mod" integer, "typ_ndims" integer) RETURNS "jsonb"
    LANGUAGE "sql" STRICT
    AS $$/*
Return the type options calculated from a type, typmod pair.

This function uses a number of hard-coded constants. The form of the returned object is determined
by the input type, but the keys will be a subset of:
  precision: the precision of a numeric or interval type. See PostgreSQL docs for details.
  scale: the scale of a numeric type
  fields: See PostgreSQL documentation of the `interval` type.
  length: Applies to "text" types where the user can specify the length.
  item_type: Gives the type of array members for array-types

Args:
  typ_id: an OID or valid type representing string will work here.
  typ_mod: The integer corresponding to the type options; see pg_attribute catalog table.
  typ_ndims: Used to determine whether the type is actually an array without an extra join.
*/
SELECT nullif(
  CASE
    WHEN typ_id = ANY('{numeric, _numeric}'::regtype[]) THEN
      jsonb_build_object(
        -- This calculation is modified from the relevant PostgreSQL source code. See the function
        -- numeric_typmod_precision(int32) at
        -- https://doxygen.postgresql.org/backend_2utils_2adt_2numeric_8c.html
        'precision', ((nullif(typ_mod, -1) - 4) >> 16) & 65535,
        -- This calculation is from numeric_typmod_scale(int32) at the same location
        'scale', (((nullif(typ_mod, -1) - 4) & 2047) # 1024) - 1024
      )
    WHEN typ_id = ANY('{interval, _interval}'::regtype[]) THEN
      jsonb_build_object(
        'precision', nullif(typ_mod & 65535, 65535),
        'fields', msar.get_interval_fields(typ_mod)
      )
    WHEN typ_id = ANY('{bpchar, _bpchar, varchar, _varchar}'::regtype[]) THEN
      -- For char and varchar types, the typemod is equal to 4 more than the set length.
      jsonb_build_object('length', nullif(typ_mod, -1) - 4)
    WHEN typ_id = ANY(
      '{bit, varbit, time, timetz, timestamp, timestamptz}'::regtype[]
      || '{_bit, _varbit, _time, _timetz, _timestamp, _timestamptz}'::regtype[]
    ) THEN
      -- For all these types, the typmod is equal to the precision.
      jsonb_build_object(
        'precision', nullif(typ_mod, -1)
      )
    ELSE jsonb_build_object()
  END
  || CASE
    WHEN typ_ndims>0 THEN
      -- This string wrangling is debatably dubious, but avoids a slow join.
      jsonb_build_object('item_type', rtrim(typ_id::regtype::text, '[]'))
    ELSE '{}'
  END,
  '{}'
)
$$;


ALTER FUNCTION "msar"."get_type_options"("typ_id" "regtype", "typ_mod" integer, "typ_ndims" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."get_unique_local_identifier"("existing_identifiers" "text"[], "base_identifier" "text") RETURNS "text"
    LANGUAGE "plpgsql" IMMUTABLE STRICT
    AS $$/*
  This function generates a unique identifier based on a given base identifier and list
  of existing identifiers.

  If the base identifier already exists in the provided array of existing identifiers,
  it appends a counter to ensure uniqueness, else it returns the base identifier.
*/
DECLARE
  unique_identifier text;
  counter integer := 0;
BEGIN
  unique_identifier := base_identifier;

  WHILE unique_identifier = ANY(existing_identifiers) LOOP
    counter := counter + 1;
    unique_identifier := format('%s %s', base_identifier, counter);
  END LOOP;

  RETURN unique_identifier;
END;
$$;


ALTER FUNCTION "msar"."get_unique_local_identifier"("existing_identifiers" "text"[], "base_identifier" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."grant_usage_on_custom_mathesar_types_to_public"() RETURNS "void"
    LANGUAGE "plpgsql"
    AS $_$
BEGIN
  EXECUTE string_agg(
    format(
      'GRANT USAGE ON TYPE %1$I.%2$I TO PUBLIC',
      pgn.nspname,
      pgt.typname
    ),
    E';\n'
  ) || E';\n'
  FROM pg_catalog.pg_type AS pgt
  JOIN pg_catalog.pg_namespace pgn ON pgn.oid = pgt.typnamespace
  WHERE (pgn.nspname = 'msar'
  OR pgn.nspname = '__msar'
  OR pgn.nspname = 'mathesar_types')
  AND (pgt.typtype = 'c' OR pgt.typtype = 'd')
  AND pgt.typcategory != 'A';
END;
$_$;


ALTER FUNCTION "msar"."grant_usage_on_custom_mathesar_types_to_public"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."has_dependents"("rel_id" "oid", "att_id" smallint) RETURNS boolean
    LANGUAGE "sql" STRICT
    AS $$/*
Return a boolean according to whether the column identified by the given oid, attnum pair is
referenced (i.e., would dropping that column require CASCADE?).

Args:
  rel_id: The relation of the attribute.
  att_id: The attnum of the attribute in the relation.
*/
SELECT EXISTS (
  SELECT 1 FROM pg_depend WHERE refobjid=rel_id AND refobjsubid=att_id AND deptype='n'
);
$$;


ALTER FUNCTION "msar"."has_dependents"("rel_id" "oid", "att_id" smallint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."infer_column_data_type"("tab_id" "regclass", "col_id" smallint, "test_perc" numeric DEFAULT 100) RETURNS "jsonb"
    LANGUAGE "plpgsql" STRICT
    AS $_$/*
Infer the best type for a given column.

Note that we currently only try for `text` columns, since we only do this at import. I.e.,
if the column is some other type we just return that original type.

Args:
  tab_id: The OID of the table of the column whose type we're inferring.
  col_id: The attnum of the column whose type we're inferring.
*/
DECLARE
  inferred_type regtype;
  inferred_type_details jsonb;
  test_type_details msar.type_compat_details;
  infer_sequence_raw text[] := ARRAY[
    'boolean',
    'date',
    'numeric',
    'mathesar_types.mathesar_money',
    'uuid',
    'timestamp without time zone',
    'timestamp with time zone',
    'time without time zone',
    'interval',
    'mathesar_types.email',
    'mathesar_types.mathesar_json_array',
    'mathesar_types.mathesar_json_object',
    'mathesar_types.uri'
  ];
  infer_sequence regtype[];
  column_nonempty boolean;
  test_type regtype;
BEGIN
  infer_sequence := array_agg(pg_catalog.to_regtype(t))
    FILTER (WHERE pg_catalog.to_regtype(t) IS NOT NULL)
    FROM unnest(infer_sequence_raw) AS x(t);
  EXECUTE format(
    'SELECT EXISTS (SELECT 1 FROM %1$I.%2$I WHERE %3$I IS NOT NULL)',
    msar.get_relation_schema_name(tab_id),
    msar.get_relation_name(tab_id),
    msar.get_column_name(tab_id, col_id)
  ) INTO column_nonempty;
  inferred_type := atttypid FROM pg_catalog.pg_attribute WHERE attrelid=tab_id AND attnum=col_id;
  IF inferred_type <> 'text'::regtype OR NOT column_nonempty THEN
    RETURN jsonb_build_object('type', inferred_type);
  END IF;
  FOREACH test_type IN ARRAY infer_sequence
    LOOP
      test_type_details := msar.check_column_type_compat(tab_id, col_id, test_type, test_perc);
      IF test_type_details.type_compatible THEN
        inferred_type := test_type;
        inferred_type_details := to_jsonb(test_type_details) - 'type_compatible';
        EXIT;
      END IF;
    END LOOP;
  RETURN jsonb_strip_nulls(
    jsonb_build_object('type', inferred_type, 'details', inferred_type_details)
  );
END;
$_$;


ALTER FUNCTION "msar"."infer_column_data_type"("tab_id" "regclass", "col_id" smallint, "test_perc" numeric) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."infer_table_column_data_types"("tab_id" "regclass") RETURNS "jsonb"
    LANGUAGE "plpgsql" STRICT
    AS $_$/*
Infer the best type for each column in the table.

Currently we only suggest different types for columns which originate as type `text`.

Args:
  tab_id: The OID of the table whose columns we're inferring types for.

The response JSON will have attnum keys, and values will be the result of `format_type`
for the inferred type of each column. Restricted to columns to which the user has access.

For tables with at most 9900 rows, we infer based on entire row set. For tables with more rows, we
decrease the percentage used to maintain an inference row set of 9,900-10,000 rows, down to a
minimum of 5% of the rows. This increases the performance of inference on large tables, at the cost
of possibly misidentifying the type of a column.

| row count  | perc |
|------------+------|
|   <= 9,900 | 100% |
|     19,900 |  50% |
|     39,900 |  25% |
|     99,900 |  10% |
| >= 199,900 |   5% |
*/
DECLARE
  test_perc integer;
BEGIN
EXECUTE(
  format(
    'SELECT GREATEST(LEAST(10000 / (COUNT(1) + 1), 100), 5) FROM %1$I.%2$I TABLESAMPLE SYSTEM(1)',
    msar.get_relation_schema_name(tab_id),
    msar.get_relation_name(tab_id)
  )
) INTO test_perc;
RETURN jsonb_object_agg(attnum, msar.infer_column_data_type(attrelid, attnum, test_perc))
FROM pg_catalog.pg_attribute
WHERE
  attrelid = tab_id
  AND attnum > 0
  AND NOT attisdropped
  AND has_column_privilege(attrelid, attnum, 'SELECT');
END;
$_$;


ALTER FUNCTION "msar"."infer_table_column_data_types"("tab_id" "regclass") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."is_default_possibly_dynamic"("tab_id" "oid", "col_id" integer) RETURNS boolean
    LANGUAGE "sql" STRICT
    AS $$/*
Determine whether the default value for the given column is an expression or constant.

If the column default is an expression, then we return 'True', since that could be dynamic. If the
column default is a simple constant, we return 'False'. The check is not very sophisticated, and
errs on the side of returning 'True'. We simply pull apart the pg_node_tree representation of the
expression, and check whether the root node is a known function call type. Note that we do *not*
search any deeper in the tree than the root node. This means we won't notice that some expressions
are actually constant (or at least static), if they have a function call or operator as their root
node.

For example, the following would return 'True', even though they're not dynamic:
  3 + 5
  msar.cast_to_integer('8')

Args:
  tab_id: The OID of the table with the column.
  col_id: The attnum of the column in the table.
*/
SELECT
  -- This is a typical dynamic default like NOW() or CURRENT_DATE
  (split_part(substring(adbin, 2), ' ', 1) IN (('SQLVALUEFUNCTION'), ('FUNCEXPR')))
  OR
  -- This is an identity column `GENERATED {ALWAYS | DEFAULT} AS IDENTITY`
  (attidentity <> '')
  OR
  -- Other generated columns show up here.
  (attgenerated <> '')
FROM pg_attribute LEFT JOIN pg_attrdef ON attrelid=adrelid AND attnum=adnum
WHERE attrelid=tab_id AND attnum=col_id;
$$;


ALTER FUNCTION "msar"."is_default_possibly_dynamic"("tab_id" "oid", "col_id" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."is_mathesar_id_column"("tab_id" "oid", "col_id" integer) RETURNS boolean
    LANGUAGE "sql" STRICT
    AS $$/*
Determine whether the given column is our default Mathesar ID column.

The column in question is always attnum 1, and is created with the string

  id integer PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY

Args:
  tab_id: The OID of the table whose column we'll check
  col_id: The attnum of the column in question
*/
SELECT col_id=1 AND attname='id' AND atttypid='integer'::regtype::oid AND attidentity <> ''
FROM pg_attribute WHERE attrelid=tab_id AND attnum=col_id;
$$;


ALTER FUNCTION "msar"."is_mathesar_id_column"("tab_id" "oid", "col_id" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."is_pkey_col"("rel_id" "oid", "col_id" integer) RETURNS boolean
    LANGUAGE "sql" STABLE STRICT
    AS $$/*
Return whether the given column is in the primary key of the given relation (e.g., table).

Args:
  rel_id:  The OID of the relation.
  col_id:  The attnum of the column in the relation.
*/
SELECT EXISTS (
  SELECT 1 FROM pg_constraint WHERE
    ARRAY[col_id::smallint] <@ conkey AND conrelid=rel_id AND contype='p'
);
$$;


ALTER FUNCTION "msar"."is_pkey_col"("rel_id" "oid", "col_id" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."list_by_record_summaries"("tab_id" "oid", "limit_" integer, "offset_" integer, "search_" "text" DEFAULT NULL::"text", "table_record_summary_templates" "jsonb" DEFAULT NULL::"jsonb") RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE
    AS $_$/*
Get record summaries from a table, optionally filtering by a search term. Results are sorted by
the summary text.

Args:
  tab_id: The OID of the table whose record summaries we'll get.
  limit_: The maximum number of record summaries to return.
  offset_: The number of record summaries to skip before returning results.
  search_: A search term to filter the summaries by. If provided, only summaries containing this
    term (case insensitive) in their text will be returned.
  table_record_summary_templates: (optional) A JSON object that maps table OIDs to record summary
    templates.
*/
DECLARE
  search_where_clause text := '';
  final_sql text;
  result_json jsonb;
BEGIN
  IF search_ IS NOT NULL AND search_ <> '' THEN
    search_where_clause := format(' WHERE summary ILIKE %L', '%'||search_||'%');
  END IF;

  final_sql := format(
    $q$
    WITH
      all_record_summaries AS ( %1$s ),
      filtered AS ( SELECT * FROM all_record_summaries %2$s ),
      sorted AS ( SELECT * FROM filtered ORDER BY summary LIMIT %3$s OFFSET %4$s ),
      results AS ( SELECT coalesce(json_agg(sorted), '[]') AS results FROM sorted ),
      count_all_results AS ( SELECT count(*) AS num FROM filtered )
    SELECT
      json_build_object(
        'count', count_all_results.num,
        'results', results.results
      )
    FROM count_all_results, results
    $q$,
    /* 1 */ msar.build_record_summary_query_for_table(tab_id, NULL, table_record_summary_templates),
    /* 2 */ search_where_clause,
    /* 3 */ limit_,
    /* 4 */ offset_
  );

  EXECUTE final_sql INTO result_json;
  RETURN result_json;
END;
$_$;


ALTER FUNCTION "msar"."list_by_record_summaries"("tab_id" "oid", "limit_" integer, "offset_" integer, "search_" "text", "table_record_summary_templates" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."list_column_privileges_for_current_role"("tab_id" "regclass", "attnum" smallint) RETURNS "jsonb"
    LANGUAGE "sql" STABLE STRICT
    AS $$/*
Return a JSONB array of all privileges current_user holds on the passed table.
*/
SELECT coalesce(jsonb_agg(privilege), '[]'::jsonb)
FROM
  unnest(ARRAY['SELECT', 'INSERT', 'UPDATE', 'REFERENCES']) AS x(privilege),
  pg_catalog.has_column_privilege(tab_id, attnum, privilege) as has_privilege
WHERE has_privilege;
$$;


ALTER FUNCTION "msar"."list_column_privileges_for_current_role"("tab_id" "regclass", "attnum" smallint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."list_database_privileges_for_current_role"("dat_id" "oid") RETURNS "jsonb"
    LANGUAGE "sql" STABLE STRICT
    AS $$/*
Return a JSONB array of all privileges current_user holds on the passed database.
*/
SELECT coalesce(jsonb_agg(privilege), '[]'::jsonb)
FROM
  unnest(
    ARRAY['CONNECT', 'CREATE', 'TEMPORARY']
  ) AS x(privilege),
  pg_catalog.has_database_privilege(dat_id, privilege) as has_privilege
WHERE has_privilege;
$$;


ALTER FUNCTION "msar"."list_database_privileges_for_current_role"("dat_id" "oid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."list_db_priv"() RETURNS "jsonb"
    LANGUAGE "sql" STABLE STRICT
    AS $$/*
Given a database name, returns a json array of objects with database privileges for non-inherited roles.

Each returned JSON object in the array has the form:
  {
    "role_oid": <int>,
    "direct" [<str>]
  }
*/
WITH priv_cte AS (
  SELECT
    jsonb_build_object(
      'role_oid', pgr.oid::bigint,
      'direct',  jsonb_agg(acl.privilege_type)
    ) AS p
  FROM
    pg_catalog.pg_roles AS pgr,
    pg_catalog.pg_database AS pgd,
    aclexplode(COALESCE(pgd.datacl, acldefault('d', pgd.datdba))) AS acl
  WHERE pgd.datname = pg_catalog.current_database()
    AND pgr.oid = acl.grantee AND pgr.rolname NOT LIKE 'pg_%'
  GROUP BY pgr.oid, pgd.oid
)
SELECT COALESCE(jsonb_agg(priv_cte.p), '[]'::jsonb) FROM priv_cte;
$$;


ALTER FUNCTION "msar"."list_db_priv"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."list_records_from_table"("tab_id" "oid", "limit_" integer, "offset_" integer, "order_" "jsonb", "filter_" "jsonb", "group_" "jsonb", "return_record_summaries" boolean DEFAULT false, "table_record_summary_templates" "jsonb" DEFAULT NULL::"jsonb") RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE
    AS $_$/*
Get records from a table. Only columns to which the user has access are returned.

Args:
  tab_id: The OID of the table whose records we'll get
  limit_: The maximum number of rows we'll return
  offset_: The number of rows to skip before returning records from following rows.
  order_: An array of ordering definition objects.
  filter_: An array of filter definition objects.
  group_: An array of group definition objects.
  return_record_summaries : Whether to return a summary for each record listed.
  table_record_summary_templates: (optional) A JSON object that maps table OIDs to record summary
    templates.

The order definition objects should have the form
  {"attnum": <int>, "direction": <text>}
*/
DECLARE
  expr_and_ctes jsonb;
  records jsonb;
BEGIN
  SELECT msar.build_record_list_query_components_with_ctes(
    tab_id,
    limit_,
    offset_,
    order_,
    filter_,
    group_
  ) INTO expr_and_ctes;

  EXECUTE format(
    $q$
    WITH
    count_cte AS ( %1$s ),
    enriched_results_cte AS ( %2$s ),
    results_ranked_cte AS (
      SELECT *, row_number() OVER (%3$s) - 1 AS __mathesar_result_idx FROM enriched_results_cte
    ),
    results_eq_cte AS (
      SELECT %11$s
    ),
    groups_cte AS ( SELECT %6$s ),
    summary_cte_self AS (%7$s)
    %8$s,
    summary_cte AS ( SELECT %10$s FROM enriched_results_cte %9$s ),
    summaries_json_cte AS ( 
      SELECT
        jsonb_build_object(
          'linked_record_summaries',
          NULLIF(
            to_jsonb(summary_cte) - 'summary_self' - 'count_hack',
            '{}'::jsonb
          ),
          'record_summaries',
          NULLIF(
            to_jsonb(summary_cte) - 'count_hack' -> 'summary_self',
            '{}'::jsonb
          )
        )
      AS sj
      FROM summary_cte
    ),
    records_json_cte AS ( SELECT jsonb_build_object(
      'results', %4$s,
      'count', coalesce(max(count_cte.count), 0),
      'grouping', %5$s
    ) AS rj
    FROM enriched_results_cte
      LEFT JOIN groups_cte ON enriched_results_cte.__mathesar_gid = groups_cte.id
      CROSS JOIN count_cte
    )
    SELECT records_json_cte.rj || summaries_json_cte.sj
    FROM records_json_cte, summaries_json_cte;
    $q$,
    /* %1 */ expr_and_ctes ->> 'count_cte_query',
    /* %2 */ expr_and_ctes ->> 'results_cte_query',
    /* %3 */ expr_and_ctes ->> 'order_by_expr',
    /* %4 */ COALESCE(
      msar.build_results_jsonb_array_expr(
        'enriched_results_cte',
        expr_and_ctes ->> 'order_by_expr'
      ),
      'NULL'
    ),
    /* %5 */ COALESCE(
      msar.build_grouping_results_jsonb_expr(tab_id, 'groups_cte', group_),
      'NULL'
    ),
    /* %6 */ COALESCE(
      msar.build_groups_cte_expr(tab_id, 'results_eq_cte', 'results_ranked_cte', group_),
      'NULL AS id'
    ),
    /* %7 */ msar.build_record_summary_query_for_table(
      tab_id,
      null,
      table_record_summary_templates
    ),
    /* %8 */ msar.build_linked_record_summaries_ctes(
      tab_id,
      table_record_summary_templates
    ),
    /* %9 */ msar.build_summary_join_expr_for_table(tab_id, 'enriched_results_cte'),
    /* %10 */ COALESCE(
      NULLIF(
        concat_ws(', ',
          msar.build_summary_json_expr_for_table(tab_id),
          CASE WHEN return_record_summaries
          THEN msar.build_self_summary_json_expr(tab_id)
          END
        ), ''
      ), 'COUNT(1) AS count_hack' 
      -- count_hack ensures that summary_cte is not empty,
      -- which in turn helps to generate summaries_json_cte
    ),
    /* %11 */ msar.build_results_eq_cte_expr(tab_id, 'results_ranked_cte', group_)
  ) INTO records;
  RETURN records;
END;
$_$;


ALTER FUNCTION "msar"."list_records_from_table"("tab_id" "oid", "limit_" integer, "offset_" integer, "order_" "jsonb", "filter_" "jsonb", "group_" "jsonb", "return_record_summaries" boolean, "table_record_summary_templates" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."list_roles"() RETURNS "jsonb"
    LANGUAGE "sql" STABLE
    AS $$/*
Return a json array of objects with the list of roles in a database server,
excluding pg system roles.

Each returned JSON object in the array has the form:
  {
    "oid": <int>
    "name": <str>
    "super": <bool>
    "inherits": <bool>
    "create_role": <bool>
    "create_db": <bool>
    "login": <bool>
    "description": <str|null>
    "members": <[
        { "oid": <int>, "admin": <bool> }
      ]|null>
  }
*/
SELECT jsonb_agg(role_data)
FROM msar.role_info_table() AS role_data
WHERE role_data.name NOT LIKE 'pg_%';
$$;


ALTER FUNCTION "msar"."list_roles"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."list_schema_privileges"("sch_id" "regnamespace") RETURNS "jsonb"
    LANGUAGE "sql" STABLE STRICT
    AS $$/*
Given a schema, returns a json array of objects with direct, non-default schema privileges

Each returned JSON object in the array has the form:
  {
    "role_oid": <int>,
    "direct" [<str>]
  }
*/
WITH priv_cte AS (
  SELECT
    jsonb_build_object(
      'role_oid', pgr.oid::bigint,
      'direct',  jsonb_agg(acl.privilege_type)
    ) AS p
  FROM
    pg_catalog.pg_roles AS pgr,
    pg_catalog.pg_namespace AS pgn,
    aclexplode(COALESCE(pgn.nspacl, acldefault('n', pgn.nspowner))) AS acl
  WHERE pgn.oid = sch_id AND pgr.oid = acl.grantee AND pgr.rolname NOT LIKE 'pg_%'
  GROUP BY pgr.oid, pgn.oid
)
SELECT COALESCE(jsonb_agg(priv_cte.p), '[]'::jsonb) FROM priv_cte;
$$;


ALTER FUNCTION "msar"."list_schema_privileges"("sch_id" "regnamespace") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."list_schema_privileges_for_current_role"("sch_id" "regnamespace") RETURNS "jsonb"
    LANGUAGE "sql" STABLE STRICT
    AS $$/*
Return a JSONB array of all privileges current_user holds on the passed schema.
*/
SELECT coalesce(jsonb_agg(privilege), '[]'::jsonb)
FROM
  unnest(
    ARRAY['USAGE', 'CREATE']
  ) AS x(privilege),
  pg_catalog.has_schema_privilege(sch_id, privilege) as has_privilege
WHERE has_privilege;
$$;


ALTER FUNCTION "msar"."list_schema_privileges_for_current_role"("sch_id" "regnamespace") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."list_schemas"() RETURNS "jsonb"
    LANGUAGE "sql" STABLE
    AS $$/*
Return a json array of objects describing the user-defined schemas in the database.

PostgreSQL system schemas are ignored.

Internal Mathesar-specifc schemas are INCLUDED. These should be filtered out by the caller. This
behavior is to avoid tight coupling between this function and other SQL files that might need to
define additional Mathesar-specific schemas as our codebase grows.

Each returned JSON object in the array will have the form:
  {
    "oid": <int>
    "name": <str>
    "description": <str|null>
    "owner_oid": <int>,
    "current_role_priv": [<str>],
    "current_role_owns": <bool>,
    "table_count": <int>
  }
*/
SELECT jsonb_agg(schema_data)
FROM msar.schema_info_table() AS schema_data
WHERE schema_data.name <> 'information_schema'
AND schema_data.name NOT LIKE 'pg_%';
$$;


ALTER FUNCTION "msar"."list_schemas"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."list_table_privileges"("tab_id" "regclass") RETURNS "jsonb"
    LANGUAGE "sql" STABLE STRICT
    AS $$/*
Given a table, returns a json array of objects with direct, non-default table privileges.

Each returned JSON object in the array has the form:
  {
    "role_oid": <int>,
    "direct" [<str>]
  }
*/
WITH priv_cte AS (
  SELECT
    jsonb_build_object(
      'role_oid', pgr.oid::bigint,
      'direct',  jsonb_agg(acl.privilege_type)
    ) AS p
  FROM
    pg_catalog.pg_roles AS pgr,
    pg_catalog.pg_class AS pgc,
    aclexplode(COALESCE(pgc.relacl, acldefault('r', pgc.relowner))) AS acl
  WHERE pgc.oid = tab_id AND pgr.oid = acl.grantee AND pgr.rolname NOT LIKE 'pg_%'
  GROUP BY pgr.oid, pgc.oid
)
SELECT COALESCE(jsonb_agg(priv_cte.p), '[]'::jsonb) FROM priv_cte;
$$;


ALTER FUNCTION "msar"."list_table_privileges"("tab_id" "regclass") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."list_table_privileges_for_current_role"("tab_id" "regclass") RETURNS "jsonb"
    LANGUAGE "sql" STABLE STRICT
    AS $$/*
Return a JSONB array of all privileges current_user holds on the passed table.
*/
SELECT coalesce(jsonb_agg(privilege), '[]'::jsonb)
FROM
  unnest(
    ARRAY['SELECT', 'INSERT', 'UPDATE', 'DELETE', 'TRUNCATE', 'REFERENCES', 'TRIGGER']
  ) AS x(privilege),
  pg_catalog.has_table_privilege(tab_id, privilege) as has_privilege
WHERE has_privilege;
$$;


ALTER FUNCTION "msar"."list_table_privileges_for_current_role"("tab_id" "regclass") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."mathesar_system_schemas"() RETURNS "text"[]
    LANGUAGE "sql" STABLE
    AS $$/*
Return a text array of the Mathesar System schemas.

Update this function whenever the list changes.
*/
SELECT ARRAY['msar', '__msar', 'mathesar_types']
$$;


ALTER FUNCTION "msar"."mathesar_system_schemas"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."month_to_degrees"("date_" "date") RETURNS double precision
    LANGUAGE "sql"
    AS $$/*
Convert discrete month to degrees.

To get the fraction of 12 months passed, we extract the month from date, subtract 1 from 
the result to confine it in range [0, 12) and divide by 12, then to get the equivalent
fraction of 360°, we multiply by 360, which is equivalent to multiply by 30.

Examples:
  2023-05-02 => 120
  2023-07-12 => 180
  2023-01-01 =>   0
  2023-12-12 => 330
*/
SELECT ((EXTRACT(MONTH FROM date_) - 1)::double precision) * 30;    
$$;


ALTER FUNCTION "msar"."month_to_degrees"("date_" "date") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."move_columns_to_referenced_table"("source_tab_id" "regclass", "target_tab_id" "regclass", "move_col_ids" smallint[]) RETURNS "void"
    LANGUAGE "plpgsql"
    AS $_$
DECLARE
  source_join_col_id smallint;
  target_join_col_id smallint;
  preexisting_col_expr CONSTANT text := msar.build_all_columns_expr(target_tab_id);
  move_col_expr CONSTANT text := msar.build_columns_expr(source_tab_id, move_col_ids);
  move_col_defs CONSTANT jsonb := msar.get_extracted_col_def_jsonb(source_tab_id, move_col_ids);
  move_con_defs CONSTANT jsonb := msar.get_extracted_con_def_jsonb(source_tab_id, move_col_ids);
  added_col_ids smallint[];
BEGIN
  -- TODO Add a custom validator that throws pretty errors in these scenario:
    -- test to make sure no multi-col fkeys reference the moved columns
    -- just throw error if _any_ multicol constraint references the moved columns.
    -- check behavior if one of the moving columns is referenced by another table (should raise)
  SELECT conkey, confkey INTO source_join_col_id, target_join_col_id
    FROM msar.get_fkey_map_table(source_tab_id)
    WHERE target_oid = target_tab_id;
  IF move_col_ids @> ARRAY[source_join_col_id] THEN
    RAISE EXCEPTION 'The joining column cannot be moved.';
  END IF;
  added_col_ids := msar.add_columns(target_tab_id, move_col_defs, true);
  EXECUTE format(
    $q$WITH merged_cte AS (
      SELECT DISTINCT %1$s, %2$s
      FROM %3$I.%4$I JOIN %6$I.%7$I ON %3$I.%4$I.%5$I = %6$I.%7$I.%8$I
    ), row_numbered_cte AS (
      SELECT *, row_number() OVER (PARTITION BY %8$I ORDER BY %9$s) AS __msar_row_number
      FROM merged_cte
    ), update_target_cte AS (
      UPDATE %6$I.%7$I SET (%9$s) = (
        SELECT %9$s
        FROM row_numbered_cte
        WHERE row_numbered_cte.%8$I=%6$I.%7$I.%8$I
        AND __msar_row_number = 1
      )
      RETURNING *
    ), insert_cte AS (
      INSERT INTO %6$I.%7$I (%10$s)
      SELECT %10$s FROM row_numbered_cte
      WHERE __msar_row_number <> 1
      RETURNING *
    )
    UPDATE %3$I.%4$I SET %5$I = insert_cte.%8$I
    FROM update_target_cte JOIN insert_cte %11$s
    WHERE %3$I.%4$I.%5$I = update_target_cte.%8$I AND %12$s
    $q$,
    preexisting_col_expr,
    move_col_expr,
    msar.get_relation_schema_name(source_tab_id),
    msar.get_relation_name(source_tab_id),
    msar.get_column_name(source_tab_id, source_join_col_id),
    msar.get_relation_schema_name(target_tab_id),
    msar.get_relation_name(target_tab_id),
    msar.get_column_name(target_tab_id, target_join_col_id),
    msar.build_unqualified_columns_expr(source_tab_id, move_col_ids),
    msar.build_unqualified_columns_expr(
      target_tab_id, msar.get_other_column_ids(target_tab_id, ARRAY[target_join_col_id])
    ),
    msar.build_source_update_cte_join_condition_expr(
      target_tab_id, target_join_col_id, added_col_ids, 'update_target_cte', 'insert_cte'
    ),
    msar.build_source_update_move_cols_equal_expr(source_tab_id, move_col_ids, 'insert_cte')
  );
  PERFORM msar.add_constraints(target_tab_id, move_con_defs);
  PERFORM msar.drop_columns(source_tab_id, variadic move_col_ids);
END;
$_$;


ALTER FUNCTION "msar"."move_columns_to_referenced_table"("source_tab_id" "regclass", "target_tab_id" "regclass", "move_col_ids" smallint[]) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."obj_description"("obj_id" "oid", "catalog_name" "text") RETURNS "text"
    LANGUAGE "plpgsql"
    AS $$/*
Transparent wrapper for obj_description. Putting it in the `msar` namespace helps route all DB calls
from Python through a single Python module.
*/
  BEGIN
    RETURN obj_description(obj_id, catalog_name);
  END
$$;


ALTER FUNCTION "msar"."obj_description"("obj_id" "oid", "catalog_name" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."patch_record_in_table"("tab_id" "oid", "rec_id" "anycompatible", "rec_def" "jsonb", "return_record_summaries" boolean DEFAULT false, "table_record_summary_templates" "jsonb" DEFAULT NULL::"jsonb") RETURNS "jsonb"
    LANGUAGE "plpgsql"
    AS $_$/*
Modify (update/patch) a record in a table.

Args:
  tab_id: The OID of the table whose record we'll delete.
  rec_id: The primary key value of the record we'll modify.
  rec_patch: A JSON object defining the parts of the record to patch.

Only tables with a single primary key column are supported.

The `rec_def` object's form is defined by the record being updated.  It should have keys
corresponding to the attnums of desired columns and values corresponding to values we should set.
*/
DECLARE
  rec_modified jsonb;
BEGIN
  EXECUTE format(
    $p$ %1$s %2$s $p$,
    msar.build_update_expr(tab_id, rec_def),
    msar.build_where_clause(
      tab_id, jsonb_build_object(
        'type', 'equal', 'args', jsonb_build_array(
          jsonb_build_object('type', 'literal', 'value', rec_id),
          jsonb_build_object('type', 'attnum', 'value', msar.get_pk_column(tab_id))
        )
      )
    )
  );
  rec_modified := msar.get_record_from_table(
    tab_id,
    rec_id,
    return_record_summaries,
    table_record_summary_templates
  );
  RETURN jsonb_build_object(
    'results', rec_modified -> 'results',
    'record_summaries', rec_modified -> 'record_summaries',
    'linked_record_summaries', rec_modified -> 'linked_record_summaries'
  );
END;
$_$;


ALTER FUNCTION "msar"."patch_record_in_table"("tab_id" "oid", "rec_id" "anycompatible", "rec_def" "jsonb", "return_record_summaries" boolean, "table_record_summary_templates" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."patch_schema"("sch_id" "oid", "patch" "jsonb") RETURNS "jsonb"
    LANGUAGE "plpgsql" STRICT
    AS $$/*
Modify a schema according to the given patch.

Args:
  sch_id: The OID of the schema.
  patch: A JSONB object with the following keys:
    - name: (optional) The new name of the schema
    - description: (optional) The new description of the schema. To remove a description, pass an
      empty string or NULL.

Returns:
  A json object describing the user-defined schema in the database.
*/
BEGIN
  PERFORM msar.rename_schema(sch_id, patch->>'name');
  PERFORM CASE WHEN patch ? 'description'
  THEN msar.set_schema_description(sch_id, patch->>'description') END;
  RETURN msar.get_schema(sch_id);
END;
$$;


ALTER FUNCTION "msar"."patch_schema"("sch_id" "oid", "patch" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."point_to_month"("point_" "point") RETURNS integer
    LANGUAGE "sql"
    AS $$/*
Convert a point to degrees and then to discrete month.

Point is converted to month by:
- first converting to degrees by calculating the inverse tangent of the point.
- then converting the degrees to the discrete month.
- If the point is on or very near to the origin, we return null.

Args:
  point_: A point that represents a vector.

Returns:
  discrete month corresponding to the vector represented by point_.
*/
SELECT CASE
  /*
  When both sine and cosine are zero, the answer should be null.

  To avoid garbage output caused by the precision errors of the float
  variables, it's better to extend the condition to:
  Output is null when the distance of the point from the origin is less than
  a certain epsilon. (Epsilon here is 1e-10)
  */
  WHEN point_ <-> point(0,0) < 1e-10 THEN NULL
  ELSE msar.degrees_to_month(atan2d(point_[0],point_[1]))
END;
$$;


ALTER FUNCTION "msar"."point_to_month"("point_" "point") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."point_to_time"("point_" "point") RETURNS time without time zone
    LANGUAGE "sql"
    AS $$/*
Convert a point to degrees and then to time.

Point is converted to time by:
- first converting to degrees by calculating the inverse tangent of the point
- then converting the degrees to the time.
- If the point is on or very near the origin, we return null.

Args:
  point_: A point that represents a vector

Returns:
  time corresponding to the vector represented by point_.
*/
SELECT CASE
  /*
  When both sine and cosine are zero, the answer should be null.

  To avoid garbage output caused by the precision errors of the float
  variables, it's better to extend the condition to:
  Output is null when the distance of the point from the origin is less than
  a certain epsilon. (Epsilon here is 1e-10)
  */
  WHEN point_ <-> point(0,0) < 1e-10 THEN NULL
  ELSE msar.degrees_to_time(atan2d(point_[0],point_[1]))
END;
$$;


ALTER FUNCTION "msar"."point_to_time"("point_" "point") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."prepare_table_for_import"("sch_id" "oid", "tab_name" "text", "col_names" "text"[], "comment_" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql"
    AS $$/*
Add a table, with a default id column, returning a JSON object containing a properly formatted SQL
statement to carry out `COPY FROM`, table_oid & table_name of the created table.

Each returned JSON object will have the form:
  {
    "copy_sql": <str>,
    "table_oid": <int>,
    "table_name": <str>,
    "renamed_columns": <arr>
  }

Args:
  sch_id: The OID of the schema where the table will be created.
  tab_name (optional): The unquoted name for the new table.
  col_defs: The columns for the new table, in order.
  comment_ (optional): The comment for the new table.
*/
DECLARE
  sch_name text;
  rel_name text;
  col_defs jsonb;
  mathesar_table json;
  rel_id oid;
  col_names_sql text;
  copy_sql text;
BEGIN
  -- Build column definition jsonb
  col_defs := jsonb_agg(jsonb_build_object('name', n)) FROM unnest(col_names) AS x(n);
  -- Create string table
  mathesar_table := msar.add_mathesar_table(sch_id, tab_name, NULL, col_defs, NULL, NULL, comment_);
  rel_id := mathesar_table ->> 'oid';
  -- Get unquoted schema and table name for the created table
  SELECT nspname, relname INTO sch_name, rel_name
  FROM pg_catalog.pg_class AS pgc
  LEFT JOIN pg_catalog.pg_namespace AS pgn
  ON pgc.relnamespace = pgn.oid
  WHERE pgc.oid = rel_id;
  -- Aggregate TEXT type column names of the created table
  SELECT string_agg(quote_ident(attname), ', ') INTO col_names_sql
  FROM pg_catalog.pg_attribute
  WHERE attrelid = rel_id AND atttypid = 'TEXT'::regtype::oid;
  -- Create a properly formatted COPY SQL string
  copy_sql := format('COPY %I.%I (%s) FROM STDIN', sch_name, rel_name, col_names_sql);
  RETURN jsonb_build_object(
    'copy_sql', copy_sql,
    'table_oid', rel_id::bigint,
    'table_name', relname,
    'renamed_columns', mathesar_table -> 'renamed_columns',
    'pkey_column_attnum', mathesar_table -> 'pkey_column_attnum'
  ) FROM pg_catalog.pg_class WHERE oid = rel_id;
END;
$$;


ALTER FUNCTION "msar"."prepare_table_for_import"("sch_id" "oid", "tab_name" "text", "col_names" "text"[], "comment_" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."process_col_alter_jsonb"("tab_id" "oid", "col_alters" "jsonb") RETURNS "text"
    LANGUAGE "sql" STRICT
    AS $$/*
Turn a JSONB array representing a set of desired column alterations into a text expression.

Args:
  tab_id The OID of the table whose columns we'll alter.
  col_alters: a JSONB array defining the list of column alterations.

The col_alters JSONB should have the form:
[
  {
    "attnum": <int>,
    "type": <obj> (optional),
    "default": <any> (optional),
    "not_null": <bool> (optional),
    "delete": <bool> (optional),
    "name": <str> (optional),
  },
  {
    ...
  },
  ...
]

Notes on the col_alters JSONB
- For more info about the type object, see the msar.build_type_text function.
- The "name" key isn't used in this function; it's included here for completeness.
- A possible 'gotcha' is the "default" key.
  - If omitted, no change to the default for the given column will occur, other than to cast it to
    the new type if a type change is specified.
  - If, on the other hand, the "default" key is set to an explicit value of null, then we will
    interpret that as a directive to set the column's default to NULL, i.e., we'll drop the current
    default setting.
- If the column is a default mathesar ID column, we will silently skip it so it won't be altered.
*/
WITH prepped_alters AS (
  SELECT
    tab_id,
    (col_alter_obj ->> 'attnum')::integer AS col_id,
    msar.build_type_text_complete(col_alter_obj -> 'type', format_type(atttypid, null)) AS new_type,
    -- We get the old default expression from a catalog table before modifying anything, so we can
    -- reset it properly if we alter the column type.
    pg_get_expr(adbin, tab_id) old_default,
    col_alter_obj -> 'default' AS new_default,
    (col_alter_obj -> 'not_null')::boolean AS not_null,
    (col_alter_obj -> 'delete')::boolean AS delete_
  FROM
    (SELECT tab_id) as arg,
    jsonb_array_elements(col_alters) as t(col_alter_obj)
    INNER JOIN pg_attribute ON (t.col_alter_obj ->> 'attnum')::smallint=attnum AND tab_id=attrelid
    LEFT JOIN pg_attrdef ON (t.col_alter_obj ->> 'attnum')::smallint=adnum AND tab_id=adrelid
  WHERE NOT msar.is_mathesar_id_column(tab_id, (t.col_alter_obj ->> 'attnum')::integer)
)
SELECT string_agg(
  nullif(
    concat_ws(
      ', ',
      __msar.build_col_drop_default_expr(tab_id, col_id, new_type, new_default),
      __msar.build_col_retype_expr(tab_id, col_id, new_type),
      __msar.build_col_default_expr(tab_id, col_id, old_default, new_default, new_type),
      __msar.build_col_drop_text(tab_id, col_id, delete_)
    ),
    ''
  ),
  ', '
)
FROM prepped_alters;
$$;


ALTER FUNCTION "msar"."process_col_alter_jsonb"("tab_id" "oid", "col_alters" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."raise_exception"("err_msg" "text") RETURNS "void"
    LANGUAGE "plpgsql" STRICT
    AS $$/* 
Utility function to raise an exceptions with an error message.

Having this utility function allows us to raise exceptions within SQL functions
where raising exceptions isn't otherwise possible.
*/
BEGIN
  RAISE EXCEPTION '%', err_msg;
END;
$$;


ALTER FUNCTION "msar"."raise_exception"("err_msg" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."rename_column"("tab_id" "oid", "col_id" integer, "new_col_name" "text") RETURNS smallint
    LANGUAGE "plpgsql" STRICT
    AS $$/*
Change a column name, returning the command executed

Args:
  tab_id: The OID of the table whose column we're renaming
  col_id: The ID of the column to rename
  new_col_name: The unquoted new name for the column.
*/
BEGIN
  PERFORM __msar.rename_column(
    tab_name => __msar.get_qualified_relation_name(tab_id),
    old_col_name => quote_ident(msar.get_column_name(tab_id, col_id)),
    new_col_name => quote_ident(new_col_name)
  );
  RETURN col_id;
END;
$$;


ALTER FUNCTION "msar"."rename_column"("tab_id" "oid", "col_id" integer, "new_col_name" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."rename_schema"("sch_id" "oid", "new_sch_name" "text") RETURNS "void"
    LANGUAGE "plpgsql" STRICT
    AS $$/*
Change a schema's name

Args:
  sch_id: The OID of the schema to rename
  new_sch_name: A new for the schema, UNQUOTED
*/
DECLARE
  old_sch_name text := msar.get_schema_name(sch_id);
BEGIN
  IF old_sch_name = new_sch_name THEN
    -- Return early if the names are the same. This avoids an error from Postgres.
    RETURN;
  END IF;
  EXECUTE format('ALTER SCHEMA %I RENAME TO %I', old_sch_name, new_sch_name);
END;
$$;


ALTER FUNCTION "msar"."rename_schema"("sch_id" "oid", "new_sch_name" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."rename_table"("tab_id" "oid", "new_tab_name" "text") RETURNS "void"
    LANGUAGE "plpgsql" STRICT
    AS $$/*
Change a table's name.

Args:
  tab_id: the OID of the table whose name we want to change
  new_tab_name: unquoted, unqualified table name
*/
DECLARE
  old_tab_name text := msar.get_relation_name(tab_id);
BEGIN
  IF old_tab_name <> new_tab_name THEN
    EXECUTE format(
      'ALTER TABLE %I.%I RENAME TO %I',
      msar.get_relation_schema_name(tab_id),
      old_tab_name,
      new_tab_name
    );
  END IF;
END;
$$;


ALTER FUNCTION "msar"."rename_table"("tab_id" "oid", "new_tab_name" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."replace_database_privileges_for_roles"("priv_spec" "jsonb") RETURNS "jsonb"
    LANGUAGE "plpgsql" STRICT
    AS $$/*
Grant/Revoke privileges for a set of roles on the current database.

Args:
  priv_spec: An array defining the privileges to grant or revoke for each role.

Each object in the priv_spec should have the form:
{role_oid: <int>, privileges: SET<"CONNECT"|"CREATE"|"TEMPORARY">}

Any privilege that exists in the privileges subarray will be granted. Any which is missing will be
revoked.
*/
BEGIN
EXECUTE string_agg(
  msar.build_database_privilege_replace_expr(role_oid, direct),
  E';\n'
) || ';'
FROM jsonb_to_recordset(priv_spec) AS x(role_oid regrole, direct jsonb);
RETURN msar.list_db_priv();
END;
$$;


ALTER FUNCTION "msar"."replace_database_privileges_for_roles"("priv_spec" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."replace_schema_privileges_for_roles"("sch_id" "regnamespace", "priv_spec" "jsonb") RETURNS "jsonb"
    LANGUAGE "plpgsql" STRICT
    AS $$/*
Grant/Revoke privileges for a set of roles on the given schema.

Args:
  sch_id The OID of the schema for which we're setting privileges for roles.
  priv_spec: An array defining the privileges to grant or revoke for each role.

Each object in the priv_spec should have the form:
{role_oid: <int>, privileges: SET<"USAGE"|"CREATE">}

Any privilege that exists in the privileges subarray will be granted. Any which is missing will be
revoked.
*/
BEGIN
EXECUTE string_agg(
  msar.build_schema_privilege_replace_expr(sch_id, role_oid, direct),
  E';\n'
) || ';'
FROM jsonb_to_recordset(priv_spec) AS x(role_oid regrole, direct jsonb);
RETURN msar.list_schema_privileges(sch_id);
END;
$$;


ALTER FUNCTION "msar"."replace_schema_privileges_for_roles"("sch_id" "regnamespace", "priv_spec" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."replace_table_privileges_for_roles"("tab_id" "regclass", "priv_spec" "jsonb") RETURNS "jsonb"
    LANGUAGE "plpgsql" STRICT
    AS $$/*
Grant/Revoke privileges for a set of roles on the given table.

Args:
  tab_id The OID of the table for which we're setting privileges for roles.
  priv_spec: An array defining the privileges to grant or revoke for each role.

Each object in the priv_spec should have the form:
{role_oid: <int>, privileges: SET<"INSERT"|"SELECT"|"UPDATE"|"DELETE"|"TRUNCATE"|"REFERENCES"|"TRIGGER">}

Any privilege that exists in the privileges subarray will be granted. Any which is missing will be
revoked.
*/
BEGIN
EXECUTE string_agg(
  msar.build_table_privilege_replace_expr(tab_id, role_oid, direct),
  E';\n'
) || ';'
FROM jsonb_to_recordset(priv_spec) AS x(role_oid regrole, direct jsonb);
RETURN msar.list_table_privileges(tab_id);
END;
$$;


ALTER FUNCTION "msar"."replace_table_privileges_for_roles"("tab_id" "regclass", "priv_spec" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."reset_mash"("tab_id" "regclass", "col_id" smallint, "uri_mash_map" "jsonb") RETURNS "void"
    LANGUAGE "plpgsql" STRICT
    AS $_$/*
Resets the outdated "mash" for a given json/jsonb file column.

A typical file column has records in the following form:
{
  "uri": "s3://mathesar-storages/admin/20250915-181554471621/mathesar_logo.jpeg",
  "mash": "b0a15ad5117a008daf8671e0d3bc552161889f4beac01fb1ff10807f36fade69"
}

uri_mash_map should have the following form:
{
  <uri_1> : <mash_1>,
  <uri_2> : <mash_2>
  ...
}

Args:
  tab_id: The OID of the target table.
  col_id: The attnum of a file json(b) column.
  uri_mash_map: A map of uri and the new mash.
*/
DECLARE
  sch_name text := msar.get_relation_schema_name(tab_id);
  tab_name text := msar.get_relation_name(tab_id);
  col_name text := msar.get_column_name(tab_id, col_id);
BEGIN
  EXECUTE format(
    $j$
      UPDATE %1$I.%2$I
      SET %3$I = jsonb_set(%2$I.%3$I::jsonb, '{mash}', mapping.mash)
      FROM jsonb_each(%4$L) AS mapping(uri, mash)
      WHERE %2$I.%3$I ->> 'uri' = mapping.uri
    $j$,
    sch_name,
    tab_name,
    col_name,
    uri_mash_map
  );
END;
$_$;


ALTER FUNCTION "msar"."reset_mash"("tab_id" "regclass", "col_id" smallint, "uri_mash_map" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."role_info_table"() RETURNS TABLE("oid" bigint, "name" "name", "super" boolean, "inherits" boolean, "create_role" boolean, "create_db" boolean, "login" boolean, "description" "text", "members" "jsonb")
    LANGUAGE "sql" STABLE
    AS $$/*
Returns a table describing all the roles present on the database server.
*/
WITH rolemembers as (
  SELECT
    pgr.oid AS oid,
    jsonb_agg(
      jsonb_build_object(
        'oid', pgm.member::bigint,
        'admin', pgm.admin_option
      )
    ) AS members
    FROM pg_catalog.pg_roles pgr
      INNER JOIN pg_catalog.pg_auth_members pgm ON pgr.oid=pgm.roleid
    GROUP BY pgr.oid
)
SELECT
  r.oid::bigint AS oid,
  r.rolname AS name,
  r.rolsuper AS super,
  r.rolinherit AS inherits,
  r.rolcreaterole AS create_role,
  r.rolcreatedb AS create_db,
  r.rolcanlogin AS login,
  pg_catalog.shobj_description(r.oid, 'pg_authid') AS description,
  rolemembers.members AS members
FROM pg_catalog.pg_roles r
LEFT OUTER JOIN rolemembers ON r.oid = rolemembers.oid;
$$;


ALTER FUNCTION "msar"."role_info_table"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."sanitize_direction"("direction" "text") RETURNS "text"
    LANGUAGE "sql" IMMUTABLE STRICT PARALLEL SAFE
    AS $$/*
*/
SELECT CASE lower(direction)
  WHEN 'asc' THEN 'ASC'
  WHEN 'desc' THEN 'DESC'
END;
$$;


ALTER FUNCTION "msar"."sanitize_direction"("direction" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."schema_info_table"() RETURNS TABLE("oid" bigint, "name" "name", "description" "text", "owner_oid" bigint, "current_role_priv" "jsonb", "current_role_owns" boolean, "table_count" integer)
    LANGUAGE "sql" STABLE
    AS $$
SELECT
  s.oid::bigint AS oid,
  s.nspname AS name,
  pg_catalog.obj_description(s.oid) AS description,
  s.nspowner::bigint AS owner_oid,
  msar.list_schema_privileges_for_current_role(s.oid) AS current_role_priv,
  pg_catalog.pg_has_role(s.nspowner, 'USAGE') AS current_role_owns,
  COALESCE(count(c.oid), 0) AS table_count
FROM pg_catalog.pg_namespace s
LEFT JOIN pg_catalog.pg_class c ON c.relnamespace = s.oid AND c.relkind = 'r'
GROUP BY
  s.oid,
  s.nspname,
  s.nspowner
ORDER BY s.nspname;
$$;


ALTER FUNCTION "msar"."schema_info_table"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."search_records_from_table"("tab_id" "oid", "search_" "jsonb", "limit_" integer, "offset_" integer DEFAULT 0, "return_record_summaries" boolean DEFAULT false, "table_record_summary_templates" "jsonb" DEFAULT NULL::"jsonb") RETURNS "jsonb"
    LANGUAGE "plpgsql"
    AS $_$/*
Get records from a table, filtering and sorting according to a search specification.

Only columns to which the user has access are returned.

Args:
  tab_id: The OID of the table whose records we'll get
  search_: An array of search definition objects.
  limit_: The maximum number of rows we'll return.
  offset_: The number of rows to skip before returning records from following rows

The search definition objects should have the form
  {"attnum": <int>, "literal": <any>}
*/
DECLARE
  records jsonb;
BEGIN
  EXECUTE format(
    $q$
    WITH
    count_cte AS (
      SELECT count(1) AS count FROM %2$I.%3$I %4$s
    ),
    results_cte AS (
      SELECT %1$s FROM %2$I.%3$I %4$s %7$s LIMIT %5$L OFFSET %6$L
    ),
    summary_cte_self AS (%8$s)
    %9$s,
    summary_cte AS ( SELECT %11$s FROM results_cte %10$s ),
    summaries_json_cte AS (
      SELECT
        jsonb_build_object(
          'linked_record_summaries',
          NULLIF(
            to_jsonb(summary_cte) - 'summary_self' - 'count_hack',
            '{}'::jsonb
          ),
          'record_summaries',
          NULLIF(
            to_jsonb(summary_cte) - 'count_hack' -> 'summary_self',
            '{}'::jsonb
          )
        )
      AS sj
      FROM summary_cte
    ),
    results_json_cte AS (
      SELECT jsonb_build_object(
        'results', coalesce(jsonb_agg(row_to_json(results_cte.*)), jsonb_build_array()),
        'count', coalesce(max(count_cte.count), 0)
      ) AS rj
      FROM results_cte CROSS JOIN count_cte
    )
    SELECT results_json_cte.rj || summaries_json_cte.sj
    FROM results_json_cte, summaries_json_cte;
    $q$,
    /* %1 */ COALESCE(msar.build_selectable_column_expr(tab_id), 'NULL'),
    /* %2 */ msar.get_relation_schema_name(tab_id),
    /* %3 */ msar.get_relation_name(tab_id),
    /* %4 */ 'WHERE ' || msar.get_score_expr(tab_id, search_) || ' > 0',
    /* %5 */ limit_,
    /* %6 */ offset_,
    /* %7 */ 'ORDER BY ' || NULLIF(
      concat(
        msar.get_score_expr(tab_id, search_) || ' DESC, ',
        msar.build_total_order_expr(tab_id, null)
      ),
      ''
    ),
    /* %8 */ msar.build_record_summary_query_for_table(
      tab_id,
      msar.get_selectable_pkey_attnum(tab_id),
      table_record_summary_templates
    ),
    /* %9 */ msar.build_linked_record_summaries_ctes(tab_id),
    /* %10 */ msar.build_summary_join_expr_for_table(tab_id, 'results_cte'),
    /* %11 */ COALESCE(
      NULLIF(
        concat_ws(', ',
          msar.build_summary_json_expr_for_table(tab_id),
          CASE WHEN return_record_summaries
          THEN msar.build_self_summary_json_expr(tab_id)
          END
        ), ''
      ), 'COUNT(1) AS count_hack'
      -- count_hack ensures that summary_cte is not empty,
      -- which in turn helps to generate summaries_json_cte
    )
  ) INTO records;
  RETURN records;
END;
$_$;


ALTER FUNCTION "msar"."search_records_from_table"("tab_id" "oid", "search_" "jsonb", "limit_" integer, "offset_" integer, "return_record_summaries" boolean, "table_record_summary_templates" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."set_members_to_role"("parent_rol_id" "regrole", "members" "oid"[]) RETURNS "jsonb"
    LANGUAGE "plpgsql" STRICT
    AS $$/*
Grant/Revoke direct membership to/from roles.

Returns a json object describing the updated information of the parent role.

  {
    "oid": <int>
    "name": <str>
    "super": <bool>
    "inherits": <bool>
    "create_role": <bool>
    "create_db": <bool>
    "login": <bool>
    "description": <str|null>
    "members": <[
        { "oid": <int>, "admin": <bool> }
      ]|null>
  }

Args:
  parent_rol_id: The OID of role whose membership will be granted/revoked to/from other roles.
  members: An array of role OID(s) whom we want to grant direct membership of the parent role.
           Only the OID(s) present in the array will be granted membership of parent role,
           Membership will be revoked for existing members not present in this array.
*/
DECLARE
  parent_role_name text := msar.get_role_name(parent_rol_id);
  parent_role_info jsonb := msar.get_role(parent_role_name);
  all_members_array bigint[];
  revoke_members_array bigint[];
  set_members_expr text;
BEGIN
  -- Get all the members of parent_role.
  SELECT array_agg(x.oid)
    FROM jsonb_to_recordset(
      CASE WHEN parent_role_info ->> 'members' IS NOT NULL
      THEN parent_role_info -> 'members'
      ELSE NULL END
    ) AS x(oid oid, admin boolean)
  INTO all_members_array;
  -- Find all the roles whose membership we want to revoke.
  SELECT ARRAY(
    SELECT unnest(all_members_array)
    EXCEPT
    SELECT unnest(members)
  ) INTO revoke_members_array;
  -- REVOKE/GRANT membership for parent_role.
  set_members_expr := concat_ws(
    E'\n',
    msar.build_revoke_membership_expr(parent_rol_id, revoke_members_array),
    msar.build_grant_membership_expr(parent_rol_id, members)
  );
  EXECUTE set_members_expr;
  -- Return the updated parent_role info including membership details.
  RETURN msar.get_role(parent_role_name);
END;
$$;


ALTER FUNCTION "msar"."set_members_to_role"("parent_rol_id" "regrole", "members" "oid"[]) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."set_not_null"("tab_id" "regclass", "col_id" smallint, "not_null" boolean) RETURNS "text"
    LANGUAGE "sql" STRICT
    AS $$/*
Alter a column's NOT NULL setting, returning the text of the expression executed.

Args:
  tab_id: The OID of the table containing the column whose nullability we'll alter.
  col_id: The attnum of the column whose nullability we'll alter.
  not_null: If true, we 'SET NOT NULL'. If false, we 'DROP NOT NULL' if null, we do nothing.
*/
  SELECT __msar.exec_ddl(
    'ALTER TABLE %I.%I ALTER COLUMN %I %s NOT NULL',
    msar.get_relation_schema_name(tab_id),
    msar.get_relation_name(tab_id),
    msar.get_column_name(tab_id, col_id),
    CASE WHEN not_null THEN 'SET' ELSE 'DROP' END
  );
$$;


ALTER FUNCTION "msar"."set_not_null"("tab_id" "regclass", "col_id" smallint, "not_null" boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."set_pkey_column"("tab_id" "regclass", "col_id" integer, "default_type" "msar"."pkey_kind" DEFAULT NULL::"msar"."pkey_kind", "drop_old_pkey_col" boolean DEFAULT false) RETURNS "void"
    LANGUAGE "plpgsql"
    AS $_$/*
Set a primary key column with an optional predefined default on a table.

Args:
  tab_id: This is the OID or name of the table for which we'll set the primary key column.
  col_id: This is the attnum of the column we'll set as the primary key column.
  pkey_type: The "type" of the pkey column. 'UUIDv4' means a `uuid` column using the
             `gen_random_uuid()` function for its default values. 'IDENTITY' means an `integer`
             using `GENERATED BY DEFAULT AS IDENTITY` for default values. If `null` is passed, we
             do not set any default, or change the column type.
  drop_old_pkey_col: Whether we should drop the current primary key column during this operation.
*/
BEGIN
  IF drop_old_pkey_col THEN
    PERFORM msar.drop_columns(tab_id, msar.get_pk_column(tab_id));
  END IF;
  PERFORM msar.drop_constraint(tab_id, oid)
    FROM pg_constraint WHERE conrelid=tab_id AND contype='p';
  PERFORM msar.add_constraints(
    tab_id,
    jsonb_build_array(jsonb_build_object('type', 'p', 'columns', jsonb_build_array(col_id)))
  );
  IF default_type IS NOT NULL THEN
    EXECUTE format(
      CASE WHEN default_type = 'IDENTITY' AND attidentity = '' THEN
        $s$
        ALTER TABLE %1$I.%2$I
          ALTER COLUMN %3$I TYPE integer USING msar.cast_to_integer(%3$I),
          ALTER COLUMN %3$I ADD GENERATED BY DEFAULT AS IDENTITY;
        SELECT setval(pg_get_serial_sequence('%1$I.%2$I', '%3$s'), max(%3$I)) FROM %1$I.%2$I;
        $s$
      WHEN default_type = 'UUIDv4' THEN
        'ALTER TABLE %1$I.%2$I ALTER COLUMN %3$I SET DEFAULT gen_random_uuid();'
      ELSE
        ''
      END,
      msar.get_relation_schema_name(tab_id),
      msar.get_relation_name(tab_id),
      msar.get_column_name(tab_id, col_id)
    ) FROM pg_catalog.pg_attribute WHERE attrelid=tab_id AND attnum=col_id;
  END IF;
END;
$_$;


ALTER FUNCTION "msar"."set_pkey_column"("tab_id" "regclass", "col_id" integer, "default_type" "msar"."pkey_kind", "drop_old_pkey_col" boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."set_schema_description"("sch_id" "oid", "description" "text") RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$/*
Set the PostgreSQL description (aka COMMENT) of a schema.

Descriptions are removed by passing an empty string or NULL.

Args:
  sch_id: The OID of the schema.
  description: The new description, UNQUOTED
*/
BEGIN
  EXECUTE format('COMMENT ON SCHEMA %I IS %L', msar.get_schema_name(sch_id), description);
END;
$$;


ALTER FUNCTION "msar"."set_schema_description"("sch_id" "oid", "description" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."table_info_table"() RETURNS TABLE("oid" bigint, "name" "name", "schema" bigint, "description" "text", "owner_oid" bigint, "current_role_priv" "jsonb", "current_role_owns" boolean)
    LANGUAGE "sql" STABLE
    AS $$
SELECT
  oid::bigint AS oid,
  relname AS name,
  relnamespace::bigint AS schema,
  msar.obj_description(oid, 'pg_class') AS description,
  relowner::bigint AS owner_oid,
  msar.list_table_privileges_for_current_role(oid) AS current_role_priv,
  pg_catalog.pg_has_role(relowner, 'USAGE') AS current_role_owns
FROM pg_catalog.pg_class
WHERE relkind = 'r';
$$;


ALTER FUNCTION "msar"."table_info_table"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."time_to_degrees"("time_" time without time zone) RETURNS double precision
    LANGUAGE "sql"
    AS $$/*
Convert the given time to degrees (on a 24 hour clock, indexed from midnight).

To get the fraction of 86400 seconds passed, we divide time_ by 86400 and then 
to get the equivalent fraction of 360°, we multiply by 360, which is equivalent
to divide by 240. 

Examples:
  00:00:00 =>   0
  06:00:00 =>  90
  12:00:00 => 180
  18:00:00 => 270
*/
SELECT EXTRACT(EPOCH FROM time_) / 240;
$$;


ALTER FUNCTION "msar"."time_to_degrees"("time_" time without time zone) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."transfer_database_ownership"("new_owner_oid" "regrole") RETURNS "jsonb"
    LANGUAGE "plpgsql" STRICT
    AS $$/*
Transfers ownership of the current database to a new owner.

Args:
  new_owner_oid: The OID of the role whom we want to be the new owner of the current database.

NOTE: To successfully transfer ownership of a database to a new owner the current user must:
  - Be a Superuser/Owner of the current database.
  - Be a `MEMBER` of the new owning role. i.e. The current role should be able to `SET ROLE`
    to the new owning role.
  - Have `CREATEDB` privilege.
*/
BEGIN
  EXECUTE format(
    'ALTER DATABASE %I OWNER TO %I',
    pg_catalog.current_database(),
    msar.get_role_name(new_owner_oid)
  );
  RETURN msar.get_current_database_info();
END;
$$;


ALTER FUNCTION "msar"."transfer_database_ownership"("new_owner_oid" "regrole") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."transfer_schema_ownership"("sch_id" "regnamespace", "new_owner_oid" "regrole") RETURNS "jsonb"
    LANGUAGE "plpgsql" STRICT
    AS $$/*
Transfers ownership of a given schema to a new owner.

Args:
  sch_id: The OID of the schema to transfer.
  new_owner_oid: The OID of the role whom we want to be the new owner of the schema.

NOTE: To successfully transfer ownership of a schema to a new owner the current user must:
  - Be a Superuser/Owner of the schema.
  - Be a `MEMBER` of the new owning role. i.e. The current role should be able to `SET ROLE`
    to the new owning role.
  - Have `CREATE` privilege for the database.
*/
BEGIN
  EXECUTE format(
    'ALTER SCHEMA %I OWNER TO %I',
    msar.get_schema_name(sch_id),
    msar.get_role_name(new_owner_oid)
  );
  RETURN msar.get_schema(sch_id);
END;
$$;


ALTER FUNCTION "msar"."transfer_schema_ownership"("sch_id" "regnamespace", "new_owner_oid" "regrole") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."transfer_table_ownership"("tab_id" "regclass", "new_owner_oid" "regrole") RETURNS "jsonb"
    LANGUAGE "plpgsql" STRICT
    AS $$/*
Transfers ownership of a given table to a new owner.

Args:
  tab_id: The OID of the table to transfer.
  new_owner_oid: The OID of the role whom we want to be the new owner of the table.

NOTE: To successfully transfer ownership of a table to a new owner the current user must:
  - Be a Superuser/Owner of the table.
  - Be a `MEMBER` of the new owning role. i.e. The current role should be able to `SET ROLE`
    to the new owning role.
  - Have `CREATE` privilege on the table's schema.
*/
BEGIN
  EXECUTE format(
    'ALTER TABLE %I.%I OWNER TO %I',
    msar.get_relation_schema_name(tab_id),
    msar.get_relation_name(tab_id),
    msar.get_role_name(new_owner_oid)
  );
  RETURN msar.get_table(tab_id);
END;
$$;


ALTER FUNCTION "msar"."transfer_table_ownership"("tab_id" "regclass", "new_owner_oid" "regrole") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."uri_authority"("text") RETURNS "text"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
    SELECT (msar.uri_parts($1))[4];
$_$;


ALTER FUNCTION "msar"."uri_authority"("text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."uri_fragment"("text") RETURNS "text"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
    SELECT (msar.uri_parts($1))[9];
$_$;


ALTER FUNCTION "msar"."uri_fragment"("text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."uri_parts"("text") RETURNS "text"[]
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
    SELECT regexp_match($1, '^(([^:/?#]+):)?(//([^/?#]*))?([^?#]*)(\?([^#]*))?(#(.*))?');
$_$;


ALTER FUNCTION "msar"."uri_parts"("text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."uri_path"("text") RETURNS "text"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
    SELECT (msar.uri_parts($1))[5];
$_$;


ALTER FUNCTION "msar"."uri_path"("text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."uri_query"("text") RETURNS "text"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
    SELECT (msar.uri_parts($1))[7];
$_$;


ALTER FUNCTION "msar"."uri_query"("text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "msar"."uri_scheme"("text") RETURNS "text"
    LANGUAGE "sql" IMMUTABLE STRICT
    AS $_$
    SELECT (msar.uri_parts($1))[2];
$_$;


ALTER FUNCTION "msar"."uri_scheme"("text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."call_location_lookup_edge_function"("p_contact_id" bigint, "p_postcode" "text", "p_street_address" "text") RETURNS bigint
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  edge_function_url text;
  supabase_url text;
  service_role_key text;
  request_id bigint;
BEGIN
  -- Get Supabase URL
  supabase_url := get_supabase_url();

  -- Construct Edge Function URL
  edge_function_url := supabase_url || '/functions/v1/location-lookup';

  -- Get service role key for authentication
  -- Manually set your service role key here (get from Supabase Dashboard → Project Settings → API)
  -- Leave as NULL if you want to call without auth (Edge Function should handle internal calls)
  service_role_key := 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdqYnpqand0d2NnZmJqam11ZXJ5Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0ODg0OTI1NiwiZXhwIjoyMDY0NDI1MjU2fQ.65ppa6roapEA_mvuec7876PMeyqdY0T6MkvoWvGsBvs'; -- TODO: Set your service role key here, or leave NULL for no auth
  
  -- Example (uncomment and set your actual key):
  -- service_role_key := 'your-service-role-key-here';

  -- Call Edge Function asynchronously via pg_net
  -- This is fire-and-forget - errors are logged but don't block the transaction
  IF service_role_key IS NOT NULL AND service_role_key != '' THEN
    SELECT net.http_post(
      url := edge_function_url,
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || service_role_key
      ),
      body := jsonb_build_object(
        'contact_id', p_contact_id,
        'postcode', p_postcode,
        'street_address', p_street_address
      )
    ) INTO request_id;
  ELSE
    -- Call without auth header (Edge Function should validate internally if needed)
    SELECT net.http_post(
      url := edge_function_url,
      headers := jsonb_build_object(
        'Content-Type', 'application/json'
      ),
      body := jsonb_build_object(
        'contact_id', p_contact_id,
        'postcode', p_postcode,
        'street_address', p_street_address
      )
    ) INTO request_id;
  END IF;

  RETURN request_id;
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING 'Failed to call location lookup Edge Function for contact %: %', p_contact_id, SQLERRM;
  RETURN NULL;
END;
$$;


ALTER FUNCTION "public"."call_location_lookup_edge_function"("p_contact_id" bigint, "p_postcode" "text", "p_street_address" "text") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."call_location_lookup_edge_function"("p_contact_id" bigint, "p_postcode" "text", "p_street_address" "text") IS 'Calls the location lookup Edge Function via HTTP request';



CREATE OR REPLACE FUNCTION "public"."check_events_sync_cron"() RETURNS TABLE("jobname" "text", "schedule" "text", "active" boolean, "command" "text")
    LANGUAGE "sql" SECURITY DEFINER
    AS $$
  SELECT 
    jobname::text,
    schedule::text,
    active,
    command::text
  FROM cron.job
  WHERE jobname = 'events-sync';
$$;


ALTER FUNCTION "public"."check_events_sync_cron"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."check_feature_permission"("p_role_id" "text", "p_feature_id" "text") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  "v_enabled" boolean;
  "v_allowed" boolean;
  "v_role_exists" boolean;
BEGIN
  -- Check if role exists
  SELECT EXISTS(SELECT 1 FROM "public"."roles" WHERE "id" = "p_role_id") INTO "v_role_exists";
  
  IF NOT "v_role_exists" THEN
    RETURN false;
  END IF;
  
  -- Check if feature exists and is enabled
  SELECT "enabled" INTO "v_enabled"
  FROM "public"."features"
  WHERE "id" = "p_feature_id";
  
  -- If feature doesn't exist or is disabled, return false
  IF NOT FOUND OR NOT "v_enabled" THEN
    RETURN false;
  END IF;
  
  -- Check if role has permission
  SELECT "allowed" INTO "v_allowed"
  FROM "public"."feature_permissions"
  WHERE "feature_id" = "p_feature_id"
    AND "role_id" = "p_role_id";
  
  -- If no permission record exists, default to false (deny by default)
  IF NOT FOUND THEN
    RETURN false;
  END IF;
  
  RETURN "v_allowed";
END;
$$;


ALTER FUNCTION "public"."check_feature_permission"("p_role_id" "text", "p_feature_id" "text") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."check_feature_permission"("p_role_id" "text", "p_feature_id" "text") IS 'Checks if a role (system or custom) has permission to access a feature. Returns false if feature is disabled, permission not granted, or feature/permission does not exist.';



CREATE OR REPLACE FUNCTION "public"."check_survey_send_worker_cron"() RETURNS TABLE("jobname" "text", "schedule" "text", "active" boolean, "command" "text")
    LANGUAGE "sql" SECURITY DEFINER
    AS $$
  SELECT 
    jobname::text,
    schedule::text,
    active,
    command::text
  FROM cron.job
  WHERE jobname = 'survey-send-worker';
$$;


ALTER FUNCTION "public"."check_survey_send_worker_cron"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."ensure_single_pinned_note"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  -- If this note is being pinned, unpin all other notes for this contact
  IF NEW."is_pinned" = true THEN
    IF TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND OLD."is_pinned" = false) THEN
      UPDATE "public"."contact_note"
      SET "is_pinned" = false
      WHERE "contact_id" = NEW."contact_id"
        AND "id" != NEW."id"
        AND "is_pinned" = true;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."ensure_single_pinned_note"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_organizer_leaderboard"() RETURNS TABLE("name" "text", "count" bigint)
    LANGUAGE "plpgsql" STABLE
    AS $$
BEGIN
  RETURN QUERY
  WITH organizer_tags AS (
    SELECT trim(unnest(string_to_array(organizer, ','))) as tag
    FROM public.contact
    WHERE organizer IS NOT NULL 
      AND organizer != ''
  ),
  tag_counts AS (
    SELECT 
      tag,
      LOWER(tag) as tag_lower,
      count(*)::bigint as variant_count
    FROM organizer_tags
    WHERE tag != ''
    GROUP BY tag
  ),
  -- Try to find proper format from profiles table
  -- Match the tag pattern (FirstLast, FLast, etc.) and rebuild with proper casing
  proper_format_from_profiles AS (
    SELECT DISTINCT ON (LOWER(p.organizer_tag))
      LOWER(p.organizer_tag) as tag_lower,
      -- Rebuild tag matching the original pattern but with proper casing
      -- Extract normalized first name and surname parts
      CASE 
        -- Match FirstLast pattern: tag matches firstname + surname
        WHEN LOWER(p.organizer_tag) = LOWER(REGEXP_REPLACE(p.first_name, '\s+', '', 'g') || REGEXP_REPLACE(p.surname, '\s+', '', 'g')) THEN
          INITCAP(REGEXP_REPLACE(p.first_name, '\s+', '', 'g')) || INITCAP(REGEXP_REPLACE(p.surname, '\s+', '', 'g'))
        -- Match FLast pattern: tag starts with first letter of firstname
        WHEN LOWER(p.organizer_tag) = LOWER(SUBSTRING(REGEXP_REPLACE(p.first_name, '\s+', '', 'g'), 1, 1) || REGEXP_REPLACE(p.surname, '\s+', '', 'g')) THEN
          UPPER(SUBSTRING(REGEXP_REPLACE(p.first_name, '\s+', '', 'g'), 1, 1)) || INITCAP(REGEXP_REPLACE(p.surname, '\s+', '', 'g'))
        -- Match First2Last pattern: tag starts with first 2 letters
        WHEN LOWER(p.organizer_tag) = LOWER(SUBSTRING(REGEXP_REPLACE(p.first_name, '\s+', '', 'g'), 1, 2) || REGEXP_REPLACE(p.surname, '\s+', '', 'g')) THEN
          INITCAP(SUBSTRING(REGEXP_REPLACE(p.first_name, '\s+', '', 'g'), 1, 2)) || INITCAP(REGEXP_REPLACE(p.surname, '\s+', '', 'g'))
        -- Match First3Last pattern: tag starts with first 3 letters
        WHEN LOWER(p.organizer_tag) = LOWER(SUBSTRING(REGEXP_REPLACE(p.first_name, '\s+', '', 'g'), 1, 3) || REGEXP_REPLACE(p.surname, '\s+', '', 'g')) THEN
          INITCAP(SUBSTRING(REGEXP_REPLACE(p.first_name, '\s+', '', 'g'), 1, 3)) || INITCAP(REGEXP_REPLACE(p.surname, '\s+', '', 'g'))
        -- Match First_Last pattern with underscore
        WHEN LOWER(p.organizer_tag) = LOWER(REGEXP_REPLACE(p.first_name, '\s+', '', 'g') || '_' || REGEXP_REPLACE(p.surname, '\s+', '', 'g')) THEN
          INITCAP(REGEXP_REPLACE(p.first_name, '\s+', '', 'g')) || '_' || INITCAP(REGEXP_REPLACE(p.surname, '\s+', '', 'g'))
        -- Default: use FirstLast format
        ELSE
          INITCAP(REGEXP_REPLACE(p.first_name, '\s+', '', 'g')) || INITCAP(REGEXP_REPLACE(p.surname, '\s+', '', 'g'))
      END as proper_name
    FROM public.profiles p
    WHERE p.organizer_tag IS NOT NULL 
      AND p.organizer_tag != ''
      AND p.first_name IS NOT NULL
      AND p.surname IS NOT NULL
  ),
  -- For tags not found in profiles, use the most common casing variant
  -- This is likely to be the correct format since it appears most frequently
  most_common_casing AS (
    SELECT DISTINCT ON (tc.tag_lower)
      tc.tag_lower,
      tc.tag as proper_name,
      tc.variant_count
    FROM tag_counts tc
    WHERE NOT EXISTS (
      SELECT 1 FROM proper_format_from_profiles pfp 
      WHERE pfp.tag_lower = tc.tag_lower
    )
    ORDER BY tc.tag_lower, tc.variant_count DESC, tc.tag ASC
  ),
  -- Combine proper formats from profiles and most common casing
  all_proper_formats AS (
    SELECT tag_lower, proper_name FROM proper_format_from_profiles
    UNION
    SELECT tag_lower, proper_name FROM most_common_casing
  ),
  aggregated_counts AS (
    SELECT 
      tag_lower,
      SUM(variant_count)::bigint as total_count
    FROM tag_counts
    GROUP BY tag_lower
  )
  SELECT 
    COALESCE(apf.proper_name, UPPER(SUBSTRING(ac.tag_lower, 1, 1)) || SUBSTRING(ac.tag_lower, 2)) as name,
    ac.total_count as count
  FROM aggregated_counts ac
  LEFT JOIN all_proper_formats apf ON ac.tag_lower = apf.tag_lower
  ORDER BY ac.total_count DESC;
END;
$$;


ALTER FUNCTION "public"."get_organizer_leaderboard"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_supabase_url"() RETURNS "text"
    LANGUAGE "plpgsql" STABLE
    AS $$
BEGIN
  -- Production URL - update if your project ref is different
  RETURN 'https://gjbzjjwtwcgfbjjmuery.supabase.co';
  
  -- For local development, uncomment the line below and comment out the production URL:
  -- RETURN 'http://localhost:54321';
END;
$$;


ALTER FUNCTION "public"."get_supabase_url"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_survey_previous_answers"("p_contact_id" bigint, "p_survey_id" bigint, "p_exclude_response_id" bigint DEFAULT NULL::bigint, "p_question_ids" bigint[] DEFAULT NULL::bigint[], "p_limit_responses" integer DEFAULT 10) RETURNS TABLE("question_id" bigint, "response_id" bigint, "created_at" timestamp with time zone, "completed_at" timestamp with time zone, "answer_text" "text", "answer_number" numeric, "answer_date" "date", "answer_boolean" boolean, "answer_json" "jsonb")
    LANGUAGE "plpgsql" STABLE
    AS $$
BEGIN
  RETURN QUERY
  WITH recent_responses AS (
    -- First, get the N most recent completed responses
    SELECT 
      sr.id,
      sr.created_at,
      sr.completed_at
    FROM survey_responses sr
    WHERE sr.contact_id = p_contact_id
      AND sr.survey_id = p_survey_id
      AND sr.status = 'completed'
      AND (p_exclude_response_id IS NULL OR sr.id != p_exclude_response_id)
    ORDER BY sr.completed_at DESC NULLS LAST, sr.created_at DESC
    LIMIT p_limit_responses
  )
  -- Then, get all answers for those responses
  SELECT
    sra.question_id,
    rr.id as response_id,
    rr.created_at,
    rr.completed_at,
    sra.answer_text,
    sra.answer_number,
    sra.answer_date,
    sra.answer_boolean,
    sra.answer_json
  FROM recent_responses rr
  INNER JOIN survey_response_answers sra ON rr.id = sra.response_id
  WHERE p_question_ids IS NULL OR sra.question_id = ANY(p_question_ids)
  ORDER BY rr.completed_at DESC NULLS LAST, rr.created_at DESC, sra.question_id;
END;
$$;


ALTER FUNCTION "public"."get_survey_previous_answers"("p_contact_id" bigint, "p_survey_id" bigint, "p_exclude_response_id" bigint, "p_question_ids" bigint[], "p_limit_responses" integer) OWNER TO "postgres";


COMMENT ON FUNCTION "public"."get_survey_previous_answers"("p_contact_id" bigint, "p_survey_id" bigint, "p_exclude_response_id" bigint, "p_question_ids" bigint[], "p_limit_responses" integer) IS 'Efficiently retrieves previous survey answers for a contact and survey. Returns answers from the N most recent completed responses, optionally filtered by question IDs. Performs the join in the database for better performance.';



CREATE OR REPLACE FUNCTION "public"."get_web_requests"("filter_success" boolean DEFAULT NULL::boolean, "filter_status" "text" DEFAULT NULL::"text", "filter_category" "text" DEFAULT NULL::"text", "date_from" timestamp with time zone DEFAULT NULL::timestamp with time zone, "date_to" timestamp with time zone DEFAULT NULL::timestamp with time zone, "search_term" "text" DEFAULT NULL::"text", "sort_by" "text" DEFAULT 'created_at'::"text", "sort_order" "text" DEFAULT 'desc'::"text", "page_offset" integer DEFAULT 0, "page_limit" integer DEFAULT 25) RETURNS TABLE("id" bigint, "created_at" timestamp with time zone, "origin" "text", "payload" "jsonb", "ip" "text", "email" "text", "success" boolean, "status" "text", "category" "text", "notes" "text", "total_count" bigint)
    LANGUAGE "plpgsql" STABLE
    AS $$
DECLARE
  base_query text;
BEGIN
  -- Build base query with filters
  base_query := '
    WITH filtered_requests AS (
      SELECT 
        r.id,
        r.created_at,
        r.origin,
        r.payload,
        r.ip,
        r.email,
        r.success,
        r.status::text,
        r.category::text,
        r.notes,
        -- Extract first IP from comma-separated string (client IP is first, proxies follow)
        COALESCE(
          CASE 
            WHEN r.ip IS NOT NULL AND r.ip LIKE ''%,%'' THEN
              TRIM(SPLIT_PART(r.ip, '','', 1))
            ELSE r.ip
          END,
          ''no-ip''
        ) as ip_key,
        -- Use origin column if available, otherwise extract referer from payload._meta.referer
        -- Normalize to just the origin (scheme + host, lowercase, no trailing slash)
        LOWER(
          TRIM(TRAILING ''/'' FROM
            COALESCE(
              -- Normalize origin column (remove trailing slash, keep scheme + host)
              CASE 
                WHEN r.origin IS NOT NULL AND (r.origin LIKE ''http://%'' OR r.origin LIKE ''https://%'') THEN
                  regexp_replace(r.origin, ''(https?://[^/]+).*'', ''\1'')
                ELSE r.origin
              END,
              -- Extract from payload if origin column is null
              CASE 
                WHEN r.payload IS NOT NULL AND r.payload::text != ''null'' 
                  AND r.payload->''_meta''->>''referer'' IS NOT NULL 
                  AND (r.payload->''_meta''->>''referer'' LIKE ''http://%'' OR r.payload->''_meta''->>''referer'' LIKE ''https://%'') THEN
                  regexp_replace(r.payload->''_meta''->>''referer'', ''(https?://[^/]+).*'', ''\1'')
                WHEN r.payload IS NOT NULL AND r.payload::text != ''null'' 
                  AND r.payload->''_meta''->>''referer'' IS NOT NULL THEN
                  r.payload->''_meta''->>''referer''
                WHEN r.payload IS NOT NULL AND r.payload::text != ''null'' 
                  AND r.payload->>''referer'' IS NOT NULL 
                  AND (r.payload->>''referer'' LIKE ''http://%'' OR r.payload->>''referer'' LIKE ''https://%'') THEN
                  regexp_replace(r.payload->>''referer'', ''(https?://[^/]+).*'', ''\1'')
                WHEN r.payload IS NOT NULL AND r.payload::text != ''null'' 
                  AND r.payload->>''referer'' IS NOT NULL THEN
                  r.payload->>''referer''
                WHEN r.payload IS NOT NULL AND r.payload::text != ''null'' 
                  AND r.payload->>''origin'' IS NOT NULL THEN
                  r.payload->>''origin''
                ELSE ''no-origin''
              END
            )
          )
        ) as origin_key
      FROM request r
      WHERE 1=1';
  
  IF filter_success IS NOT NULL THEN
    base_query := base_query || format(' AND r.success = %L', filter_success);
  END IF;
  
  IF filter_status IS NOT NULL THEN
    base_query := base_query || format(' AND r.status = %L', filter_status);
  END IF;
  
  IF filter_category IS NOT NULL THEN
    base_query := base_query || format(' AND r.category = %L', filter_category);
  END IF;
  
  IF date_from IS NOT NULL THEN
    base_query := base_query || format(' AND r.created_at >= %L', date_from);
  END IF;
  
  IF date_to IS NOT NULL THEN
    base_query := base_query || format(' AND r.created_at <= %L', date_to);
  END IF;
  
  IF search_term IS NOT NULL AND search_term != '' THEN
    base_query := base_query || format(' AND r.email ILIKE %L', '%' || search_term || '%');
  END IF;
  
  base_query := base_query || '
    ),
    grouped_requests AS (
      SELECT 
        id,
        created_at,
        origin,
        payload,
        ip,
        email,
        success,
        status::text,
        category::text,
        notes,
        ip_key,
        origin_key,
        length(payload::text) as payload_length,
        MIN(created_at) OVER (
          PARTITION BY ip_key, origin_key
        ) as first_in_group
      FROM filtered_requests
    ),
    requests_in_window AS (
      SELECT 
        id,
        created_at,
        origin,
        payload,
        ip,
        email,
        success,
        status::text,
        category::text,
        notes,
        ip_key,
        origin_key,
        payload_length,
        first_in_group
      FROM grouped_requests
      WHERE (created_at - first_in_group) <= INTERVAL ''10 minutes''
    ),
    requests_outside_window AS (
      SELECT 
        id,
        created_at,
        origin,
        payload,
        ip,
        email,
        success,
        status::text,
        category::text,
        notes,
        ip_key,
        origin_key,
        payload_length,
        first_in_group
      FROM grouped_requests
      WHERE (created_at - first_in_group) > INTERVAL ''10 minutes''
    ),
    ranked_requests_in_window AS (
      SELECT 
        id,
        created_at,
        origin,
        payload,
        ip,
        email,
        success,
        status::text,
        category::text,
        notes,
        ROW_NUMBER() OVER (
          PARTITION BY ip_key, origin_key
          ORDER BY payload_length DESC, created_at ASC
        ) as rn
      FROM requests_in_window
    ),
    merged_requests AS (
      SELECT 
        id,
        created_at,
        origin,
        payload,
        ip,
        email,
        success,
        status::text,
        category::text,
        notes
      FROM ranked_requests_in_window
      WHERE rn = 1
      UNION ALL
      SELECT 
        id,
        created_at,
        origin,
        payload,
        ip,
        email,
        success,
        status::text,
        category::text,
        notes
      FROM requests_outside_window
    ),
    non_duplicate_requests AS (
      SELECT 
        id,
        created_at,
        origin,
        payload,
        ip,
        email,
        success,
        status::text,
        category::text,
        notes,
        COUNT(*) OVER () as total_count
      FROM merged_requests
    )
    SELECT 
      id,
      created_at,
      origin,
      payload,
      ip,
      email,
      success,
      status::text,
      category::text,
      notes,
      MAX(total_count) OVER () as total_count
    FROM non_duplicate_requests';
  
  -- Add sorting
  IF sort_by IS NOT NULL AND sort_by != '' THEN
    -- Validate sort_by to prevent SQL injection
    IF sort_by IN ('id', 'created_at', 'email', 'success', 'status', 'category') THEN
      IF sort_order = 'asc' THEN
        base_query := base_query || format(' ORDER BY %I ASC', sort_by);
      ELSE
        base_query := base_query || format(' ORDER BY %I DESC', sort_by);
      END IF;
    ELSE
      base_query := base_query || ' ORDER BY created_at DESC';
    END IF;
  ELSE
    base_query := base_query || ' ORDER BY created_at DESC';
  END IF;
  
  -- Add pagination
  IF page_limit > 0 THEN
    base_query := base_query || ' LIMIT ' || page_limit::text;
    IF page_offset > 0 THEN
      base_query := base_query || ' OFFSET ' || page_offset::text;
    END IF;
  END IF;
  
  base_query := base_query || ';';
  
  RETURN QUERY EXECUTE base_query;
END;
$$;


ALTER FUNCTION "public"."get_web_requests"("filter_success" boolean, "filter_status" "text", "filter_category" "text", "date_from" timestamp with time zone, "date_to" timestamp with time zone, "search_term" "text", "sort_by" "text", "sort_order" "text", "page_offset" integer, "page_limit" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_web_requests"("filter_success" boolean DEFAULT NULL::boolean, "filter_status" "text" DEFAULT NULL::"text", "filter_category" "text" DEFAULT NULL::"text", "date_from" timestamp with time zone DEFAULT NULL::timestamp with time zone, "date_to" timestamp with time zone DEFAULT NULL::timestamp with time zone, "search_term" "text" DEFAULT NULL::"text", "sort_by" "text" DEFAULT 'created_at'::"text", "sort_order" "text" DEFAULT 'desc'::"text", "page_offset" integer DEFAULT 0, "page_limit" integer DEFAULT 25, "show_duplicates" boolean DEFAULT false) RETURNS TABLE("id" bigint, "created_at" timestamp with time zone, "origin" "text", "payload" "jsonb", "ip" "text", "email" "text", "success" boolean, "status" "text", "category" "text", "notes" "text", "total_count" bigint, "is_duplicate" boolean)
    LANGUAGE "plpgsql" STABLE
    AS $$
DECLARE
  base_query text;
BEGIN
  -- Build base query with filters and duplicate detection
  base_query := '
    WITH filtered_requests AS (
      SELECT 
        r.id,
        r.created_at,
        r.origin,
        r.payload,
        r.ip,
        r.email,
        r.success,
        r.status::text,
        r.category::text,
        r.notes,
        -- Extract first IP from comma-separated string
        COALESCE(
          CASE 
            WHEN r.ip IS NOT NULL AND r.ip LIKE ''%,%'' THEN
              TRIM(SPLIT_PART(r.ip, '','', 1))
            ELSE r.ip
          END,
          ''no-ip''
        ) as ip_key,
        -- Normalize origin (scheme + host, lowercase, no trailing slash)
        LOWER(
          TRIM(TRAILING ''/'' FROM
            COALESCE(
              CASE 
                WHEN r.origin IS NOT NULL AND (r.origin LIKE ''http://%'' OR r.origin LIKE ''https://%'') THEN
                  regexp_replace(r.origin, ''(https?://[^/]+).*'', ''\1'')
                ELSE r.origin
              END,
              CASE 
                WHEN r.payload IS NOT NULL AND r.payload::text != ''null'' 
                  AND r.payload->''_meta''->>''referer'' IS NOT NULL 
                  AND (r.payload->''_meta''->>''referer'' LIKE ''http://%'' OR r.payload->''_meta''->>''referer'' LIKE ''https://%'') THEN
                  regexp_replace(r.payload->''_meta''->>''referer'', ''(https?://[^/]+).*'', ''\1'')
                WHEN r.payload IS NOT NULL AND r.payload::text != ''null'' 
                  AND r.payload->''_meta''->>''referer'' IS NOT NULL THEN
                  r.payload->''_meta''->>''referer''
                WHEN r.payload IS NOT NULL AND r.payload::text != ''null'' 
                  AND r.payload->>''referer'' IS NOT NULL 
                  AND (r.payload->>''referer'' LIKE ''http://%'' OR r.payload->>''referer'' LIKE ''https://%'') THEN
                  regexp_replace(r.payload->>''referer'', ''(https?://[^/]+).*'', ''\1'')
                WHEN r.payload IS NOT NULL AND r.payload::text != ''null'' 
                  AND r.payload->>''referer'' IS NOT NULL THEN
                  r.payload->>''referer''
                WHEN r.payload IS NOT NULL AND r.payload::text != ''null'' 
                  AND r.payload->>''origin'' IS NOT NULL THEN
                  r.payload->>''origin''
                ELSE ''no-origin''
              END
            )
          )
        ) as origin_key,
        -- Normalize email to lowercase
        LOWER(TRIM(COALESCE(r.email, ''''))) as email_key,
        -- Extract step index from payload (try body._meta.step.index first, then _meta.step.index)
        COALESCE(
          CASE 
            WHEN r.payload IS NOT NULL AND r.payload::text != ''null''
              AND r.payload->''body'' IS NOT NULL THEN
              CASE
                WHEN jsonb_typeof(r.payload->''body'') = ''string'' THEN
                  -- body is a JSON string, try to parse it
                  CASE
                    WHEN (r.payload->''body'')::text::jsonb->''_meta''->''step''->>''index'' IS NOT NULL THEN
                      ((r.payload->''body'')::text::jsonb->''_meta''->''step''->>''index'')::integer
                    ELSE NULL
                  END
                WHEN jsonb_typeof(r.payload->''body'') = ''object'' THEN
                  -- body is a JSON object
                  CASE
                    WHEN r.payload->''body''->''_meta''->''step''->>''index'' IS NOT NULL THEN
                      (r.payload->''body''->''_meta''->''step''->>''index'')::integer
                    ELSE NULL
                  END
                ELSE NULL
              END
            ELSE NULL
          END,
          CASE
            WHEN r.payload IS NOT NULL AND r.payload::text != ''null''
              AND r.payload->''_meta''->''step''->>''index'' IS NOT NULL THEN
              (r.payload->''_meta''->''step''->>''index'')::integer
            ELSE NULL
          END
        ) as step_index,
        -- Extract name (firstname + surname) from payload
        -- Try body.firstname + body.surname first, then root-level
        CASE
          WHEN r.payload IS NOT NULL AND r.payload::text != ''null''
            AND r.payload->''body'' IS NOT NULL THEN
            CASE
              WHEN jsonb_typeof(r.payload->''body'') = ''string'' THEN
                -- body is a JSON string, try to parse it
                CASE
                  WHEN (r.payload->''body'')::text::jsonb->>''firstname'' IS NOT NULL
                    AND (r.payload->''body'')::text::jsonb->>''surname'' IS NOT NULL THEN
                    LOWER(TRIM((r.payload->''body'')::text::jsonb->>''firstname'')) || ''|'' || 
                    LOWER(TRIM((r.payload->''body'')::text::jsonb->>''surname''))
                  ELSE NULL
                END
              WHEN jsonb_typeof(r.payload->''body'') = ''object'' THEN
                -- body is a JSON object
                CASE
                  WHEN r.payload->''body''->>''firstname'' IS NOT NULL
                    AND r.payload->''body''->>''surname'' IS NOT NULL THEN
                    LOWER(TRIM(r.payload->''body''->>''firstname'')) || ''|'' || 
                    LOWER(TRIM(r.payload->''body''->>''surname''))
                  ELSE NULL
                END
              ELSE NULL
            END
          WHEN r.payload IS NOT NULL AND r.payload::text != ''null''
            AND r.payload->>''firstname'' IS NOT NULL
            AND r.payload->>''surname'' IS NOT NULL THEN
            LOWER(TRIM(r.payload->>''firstname'')) || ''|'' || LOWER(TRIM(r.payload->>''surname''))
          ELSE NULL
        END as name_key,
        -- Payload length for ranking
        length(r.payload::text) as payload_length
      FROM request r
      WHERE 1=1';
  
  -- Add filters
  IF filter_success IS NOT NULL THEN
    base_query := base_query || format(' AND r.success = %L', filter_success);
  END IF;
  
  IF filter_status IS NOT NULL THEN
    base_query := base_query || format(' AND r.status = %L', filter_status);
  END IF;
  
  IF filter_category IS NOT NULL THEN
    base_query := base_query || format(' AND r.category = %L', filter_category);
  END IF;
  
  IF date_from IS NOT NULL THEN
    base_query := base_query || format(' AND r.created_at >= %L', date_from);
  END IF;
  
  IF date_to IS NOT NULL THEN
    base_query := base_query || format(' AND r.created_at <= %L', date_to);
  END IF;
  
  IF search_term IS NOT NULL AND search_term != '' THEN
    base_query := base_query || format(' AND r.email ILIKE %L', '%' || search_term || '%');
  END IF;
  
  -- Continue with grouping and duplicate detection
  base_query := base_query || '
    ),
    -- Group by email+origin (or ip+origin if no email)
    grouped_by_email_origin AS (
      SELECT 
        id,
        created_at,
        origin,
        payload,
        ip,
        email,
        success,
        status,
        category,
        notes,
        ip_key,
        origin_key,
        email_key,
        step_index,
        name_key,
        payload_length,
        -- Create session key: email|origin or ip|origin
        CASE
          WHEN email_key IS NOT NULL AND email_key != '''' THEN
            email_key || ''|'' || origin_key
          ELSE
            ip_key || ''|'' || origin_key
        END as session_key
      FROM filtered_requests
    ),
    -- Split groups by name if different names exist
    split_by_name AS (
      SELECT 
        id,
        created_at,
        origin,
        payload,
        ip,
        email,
        success,
        status,
        category,
        notes,
        ip_key,
        origin_key,
        email_key,
        step_index,
        name_key,
        payload_length,
        session_key,
        -- Create final group key: session_key_name_<name> or session_key_no_name
        CASE
          WHEN name_key IS NOT NULL THEN
            session_key || ''_name_'' || name_key
          ELSE
            session_key || ''_no_name''
        END as group_key,
        -- Count distinct names per session to determine if splitting is needed
        (SELECT COUNT(DISTINCT s2.name_key) 
         FROM grouped_by_email_origin s2 
         WHERE s2.session_key = grouped_by_email_origin.session_key 
           AND s2.name_key IS NOT NULL) as name_count,
        -- Count of no-name requests per session
        COUNT(*) FILTER (WHERE name_key IS NULL) OVER (PARTITION BY session_key) as no_name_count,
        -- Count of named requests per session
        COUNT(*) FILTER (WHERE name_key IS NOT NULL) OVER (PARTITION BY session_key) as named_count
      FROM grouped_by_email_origin
    ),
    -- Merge no-name requests with single named group (step 0 with later steps)
    merged_name_groups AS (
      SELECT 
        sbn.id,
        sbn.created_at,
        sbn.origin,
        sbn.payload,
        sbn.ip,
        sbn.email,
        sbn.success,
        sbn.status,
        sbn.category,
        sbn.notes,
        sbn.ip_key,
        sbn.origin_key,
        sbn.email_key,
        sbn.step_index,
        sbn.name_key,
        sbn.payload_length,
        sbn.session_key,
        sbn.name_count,
        sbn.no_name_count,
        sbn.named_count,
        sbn.group_key,
        CASE
          -- If only one named group and some no-name requests, merge them
          WHEN sbn.name_count = 1 AND sbn.no_name_count > 0 AND sbn.named_count = 1 AND sbn.name_key IS NULL THEN
            -- Find the single name key in this session
            (SELECT DISTINCT s2.name_key FROM split_by_name s2 
             WHERE s2.session_key = sbn.session_key AND s2.name_key IS NOT NULL 
             LIMIT 1)
          ELSE
            sbn.name_key
        END as merged_name_key,
        CASE
          WHEN sbn.name_count = 1 AND sbn.no_name_count > 0 AND sbn.named_count = 1 AND sbn.name_key IS NULL THEN
            sbn.session_key || ''_name_'' || 
            (SELECT DISTINCT s2.name_key FROM split_by_name s2 
             WHERE s2.session_key = sbn.session_key AND s2.name_key IS NOT NULL 
             LIMIT 1)
          ELSE
            sbn.group_key
        END as final_group_key
      FROM split_by_name sbn
    ),
    -- Merge groups with same email+origin+name that overlap in time (10-minute windows)
    -- This handles IP changes during form submission
    time_clustered AS (
      SELECT 
        id,
        created_at,
        origin,
        payload,
        ip,
        email,
        success,
        status,
        category,
        notes,
        ip_key,
        origin_key,
        email_key,
        step_index,
        name_key,
        payload_length,
        session_key,
        merged_name_key,
        final_group_key,
        -- Find the earliest request in each final_group_key
        MIN(created_at) OVER (PARTITION BY final_group_key) as group_start_time,
        -- Find the latest request in each final_group_key
        MAX(created_at) OVER (PARTITION BY final_group_key) as group_end_time
      FROM merged_name_groups
    ),
    -- Identify overlapping groups (same email+origin+name, different IPs, within 10 minutes)
    overlapping_groups AS (
      SELECT DISTINCT
        t1.final_group_key as group1,
        t2.final_group_key as group2
      FROM time_clustered t1
      JOIN time_clustered t2 ON 
        t1.email_key = t2.email_key
        AND t1.origin_key = t2.origin_key
        AND t1.merged_name_key = t2.merged_name_key
        AND t1.final_group_key < t2.final_group_key
        AND (
          -- Groups overlap if their time ranges are within 10 minutes
          (t1.group_start_time <= t2.group_end_time + INTERVAL ''10 minutes''
           AND t1.group_end_time >= t2.group_start_time - INTERVAL ''10 minutes'')
        )
    ),
    -- Create merged group keys for overlapping groups
    merged_groups AS (
      SELECT 
        tc.*,
        COALESCE(
          -- Use the first group key if this group overlaps with others
          (SELECT MIN(LEAST(group1, group2)) 
           FROM overlapping_groups og 
           WHERE og.group1 = tc.final_group_key OR og.group2 = tc.final_group_key),
          tc.final_group_key
        ) as merged_group_key
      FROM time_clustered tc
    ),
    -- Rank requests within each merged group
    ranked_requests AS (
      SELECT 
        id,
        created_at,
        origin,
        payload,
        ip,
        email,
        success,
        status,
        category,
        notes,
        merged_group_key,
        ROW_NUMBER() OVER (
          PARTITION BY merged_group_key
          ORDER BY 
            COALESCE(step_index, -1) DESC,  -- Prefer highest step index
            payload_length DESC,              -- Then longest payload
            created_at DESC                   -- Then most recent
        ) as rn
      FROM merged_groups
    ),
    -- Calculate total count before filtering
    total_count_cte AS (
      SELECT COUNT(DISTINCT merged_group_key) as total_count
      FROM ranked_requests
      WHERE rn = 1
    ),
    -- Final selection based on show_duplicates flag
    final_requests AS (
      SELECT 
        rr.id,
        rr.created_at,
        rr.origin,
        rr.payload,
        rr.ip,
        rr.email,
        rr.success,
        rr.status,
        rr.category,
        rr.notes,
        (SELECT total_count FROM total_count_cte) as total_count,
        CASE WHEN rr.rn > 1 THEN true ELSE false END as is_duplicate
      FROM ranked_requests rr
    ),
    filtered_final AS (
      SELECT 
        id,
        created_at,
        origin,
        payload,
        ip,
        email,
        success,
        status,
        category,
        notes,
        MAX(total_count) OVER () as total_count,
        is_duplicate
      FROM final_requests
      WHERE ' || (CASE WHEN show_duplicates THEN 'true' ELSE 'is_duplicate = false' END) || '
    )
    SELECT 
      id,
      created_at,
      origin,
      payload,
      ip,
      email,
      success,
      status,
      category,
      notes,
      MAX(total_count) OVER () as total_count,
      is_duplicate
    FROM filtered_final';
  
  -- Add sorting
  IF sort_by IS NOT NULL AND sort_by != '' THEN
    IF sort_by IN ('id', 'created_at', 'email', 'success', 'status', 'category') THEN
      IF sort_order = 'asc' THEN
        base_query := base_query || format(' ORDER BY %I ASC', sort_by);
      ELSE
        base_query := base_query || format(' ORDER BY %I DESC', sort_by);
      END IF;
    ELSE
      base_query := base_query || ' ORDER BY created_at DESC';
    END IF;
  ELSE
    base_query := base_query || ' ORDER BY created_at DESC';
  END IF;
  
  -- Add pagination
  IF page_limit > 0 THEN
    base_query := base_query || ' LIMIT ' || page_limit::text;
    IF page_offset > 0 THEN
      base_query := base_query || ' OFFSET ' || page_offset::text;
    END IF;
  END IF;
  
  base_query := base_query || ';';
  
  RETURN QUERY EXECUTE base_query;
END;
$$;


ALTER FUNCTION "public"."get_web_requests"("filter_success" boolean, "filter_status" "text", "filter_category" "text", "date_from" timestamp with time zone, "date_to" timestamp with time zone, "search_term" "text", "sort_by" "text", "sort_order" "text", "page_offset" integer, "page_limit" integer, "show_duplicates" boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."increment_campaign_sent_count"("campaign_id_param" bigint, "increment_amount" integer DEFAULT 1) RETURNS TABLE("id" bigint, "sent_count" integer, "total_recipients" integer, "status" "text")
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  current_status text;
BEGIN
  -- Get current status to check if campaign is cancelled
  SELECT status INTO current_status
  FROM public.campaigns
  WHERE id = campaign_id_param;
  
  -- Don't update if campaign is cancelled
  IF current_status = 'cancelled' THEN
    RAISE EXCEPTION 'Cannot update progress for cancelled campaign';
  END IF;
  
  -- Atomically increment sent_count
  UPDATE public.campaigns
  SET sent_count = sent_count + increment_amount,
      updated_at = now()
  WHERE id = campaign_id_param
    AND status != 'cancelled';
  
  -- Return updated campaign data
  RETURN QUERY
  SELECT 
    c.id,
    c.sent_count,
    c.total_recipients,
    c.status::text
  FROM public.campaigns c
  WHERE c.id = campaign_id_param;
END;
$$;


ALTER FUNCTION "public"."increment_campaign_sent_count"("campaign_id_param" bigint, "increment_amount" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."log_attachment_deletion"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  IF OLD."deleted_at" IS NULL AND NEW."deleted_at" IS NOT NULL THEN
    INSERT INTO "public"."attachment_audit_log" ("attachment_id", "action", "performed_by", "metadata")
    VALUES (
      NEW."id",
      'delete',
      COALESCE(NEW."deleted_by", '00000000-0000-0000-0000-000000000000'::uuid),
      jsonb_build_object('file_name', NEW."file_name", 'deleted_at', NEW."deleted_at")
    );
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."log_attachment_deletion"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."mark_campaign_job_complete"("campaign_id_param" bigint, "instance_id_param" bigint, "success_param" boolean, "error_message" "text" DEFAULT NULL::"text") RETURNS boolean
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  contact_id_val bigint;
  current_sent_count integer;
  total_recipients_val integer;
BEGIN
  -- Update survey instance status
  IF success_param THEN
    UPDATE public.survey_instances
    SET 
      status = 'sent',
      sent_at = now()
    WHERE id = instance_id_param;
  ELSE
    UPDATE public.survey_instances
    SET status = 'failed'
    WHERE id = instance_id_param;
  END IF;

  -- Get contact ID from instance
  SELECT contact_id INTO contact_id_val
  FROM public.survey_instances
  WHERE id = instance_id_param;

  IF success_param AND campaign_id_param IS NOT NULL THEN
    -- Update campaign progress atomically
    UPDATE public.campaigns
    SET sent_count = sent_count + 1
    WHERE id = campaign_id_param
    RETURNING sent_count, total_recipients INTO current_sent_count, total_recipients_val;

    -- Check if campaign is complete
    IF current_sent_count >= total_recipients_val THEN
      UPDATE public.campaigns
      SET status = 'sent'
      WHERE id = campaign_id_param;
    END IF;
  ELSIF NOT success_param AND campaign_id_param IS NOT NULL AND contact_id_val IS NOT NULL THEN
    -- Track failed contact
    UPDATE public.campaigns
    SET failed_contact_ids = COALESCE(failed_contact_ids, '[]'::jsonb) || jsonb_build_array(contact_id_val)
    WHERE id = campaign_id_param
    AND NOT (failed_contact_ids @> jsonb_build_array(contact_id_val));
  END IF;

  RETURN true;
EXCEPTION
  WHEN OTHERS THEN
    -- Log error and return false
    RAISE WARNING 'Failed to mark campaign job complete: %', SQLERRM;
    RETURN false;
END;
$$;


ALTER FUNCTION "public"."mark_campaign_job_complete"("campaign_id_param" bigint, "instance_id_param" bigint, "success_param" boolean, "error_message" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."pgmq_archive_survey_job"("queue_name" "text", "msg_id_param" bigint) RETURNS boolean
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  -- Call pgmq.archive
  PERFORM pgmq.archive(queue_name, msg_id_param);
  RETURN true;
EXCEPTION
  WHEN OTHERS THEN
    -- Return false on error
    RETURN false;
END;
$$;


ALTER FUNCTION "public"."pgmq_archive_survey_job"("queue_name" "text", "msg_id_param" bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."pgmq_archive_webhook_job"("queue_name" "text", "msg_id_param" bigint) RETURNS boolean
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  -- Call pgmq.archive
  PERFORM pgmq.archive(queue_name, msg_id_param);
  RETURN true;
EXCEPTION
  WHEN OTHERS THEN
    -- Return false on error
    RETURN false;
END;
$$;


ALTER FUNCTION "public"."pgmq_archive_webhook_job"("queue_name" "text", "msg_id_param" bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."pgmq_delete_survey_job"("queue_name" "text", "msg_id_param" bigint) RETURNS boolean
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  -- Call pgmq.delete
  PERFORM pgmq.delete(queue_name, msg_id_param);
  RETURN true;
EXCEPTION
  WHEN OTHERS THEN
    -- Return false on error
    RETURN false;
END;
$$;


ALTER FUNCTION "public"."pgmq_delete_survey_job"("queue_name" "text", "msg_id_param" bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."pgmq_delete_webhook_job"("queue_name" "text", "msg_id_param" bigint) RETURNS boolean
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  -- Call pgmq.delete
  PERFORM pgmq.delete(queue_name, msg_id_param);
  RETURN true;
EXCEPTION
  WHEN OTHERS THEN
    -- Return false on error
    RETURN false;
END;
$$;


ALTER FUNCTION "public"."pgmq_delete_webhook_job"("queue_name" "text", "msg_id_param" bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."pgmq_read_survey_jobs"("queue_name" "text", "vt" integer DEFAULT 300, "qty" integer DEFAULT 10) RETURNS TABLE("msg_id" bigint, "message" "jsonb")
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  -- Call pgmq.read and return messages
  RETURN QUERY
  SELECT 
    m.msg_id,
    m.message
  FROM pgmq.read(queue_name, vt, qty) m;
EXCEPTION
  WHEN OTHERS THEN
    -- Re-raise the error with context
    RAISE EXCEPTION 'Failed to read jobs from queue %: %', queue_name, SQLERRM;
END;
$$;


ALTER FUNCTION "public"."pgmq_read_survey_jobs"("queue_name" "text", "vt" integer, "qty" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."pgmq_read_webhook_jobs"("queue_name" "text", "vt" integer DEFAULT 300, "qty" integer DEFAULT 10) RETURNS TABLE("msg_id" bigint, "message" "jsonb")
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  -- Call pgmq.read and return messages
  RETURN QUERY
  SELECT 
    m.msg_id,
    m.message
  FROM pgmq.read(queue_name, vt, qty) m;
EXCEPTION
  WHEN OTHERS THEN
    -- Re-raise the error with context
    RAISE EXCEPTION 'Failed to read jobs from queue %: %', queue_name, SQLERRM;
END;
$$;


ALTER FUNCTION "public"."pgmq_read_webhook_jobs"("queue_name" "text", "vt" integer, "qty" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."pgmq_send_survey_job"("queue_name" "text", "message" "jsonb") RETURNS TABLE("msg_id" bigint)
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  result_msg_id bigint;
BEGIN
  -- Call pgmq.send and return the message ID
  SELECT msg_id INTO result_msg_id
  FROM pgmq.send(queue_name, message);
  
  RETURN QUERY SELECT result_msg_id;
EXCEPTION
  WHEN OTHERS THEN
    -- Re-raise the error with context
    RAISE EXCEPTION 'Failed to send job to queue %: %', queue_name, SQLERRM;
END;
$$;


ALTER FUNCTION "public"."pgmq_send_survey_job"("queue_name" "text", "message" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."pgmq_send_webhook_job"("queue_name" "text", "message" "jsonb") RETURNS TABLE("msg_id" bigint)
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  result_msg_id bigint;
BEGIN
  -- Call pgmq.send and return the message ID
  SELECT msg_id INTO result_msg_id
  FROM pgmq.send(queue_name, message);
  
  RETURN QUERY SELECT result_msg_id;
EXCEPTION
  WHEN OTHERS THEN
    -- Re-raise the error with context
    RAISE EXCEPTION 'Failed to send job to queue %: %', queue_name, SQLERRM;
END;
$$;


ALTER FUNCTION "public"."pgmq_send_webhook_job"("queue_name" "text", "message" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."prevent_sensitive_profile_updates"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
    user_role text;
BEGIN
    -- Check if current user is an admin (allows service_role operations too)
    -- This is a quick lookup by primary key
    SELECT role::text INTO user_role
    FROM public.profiles
    WHERE id = auth.uid();
    
    -- Allow admins and service_role (when auth.uid() is NULL, it's likely service_role)
    -- to update any field
    IF user_role IN ('super_admin', 'admin') OR auth.uid() IS NULL THEN
        RETURN NEW;
    END IF;
    
    -- Prevent updates to sensitive fields for regular authenticated users
    IF OLD.id IS DISTINCT FROM NEW.id THEN
        RAISE EXCEPTION 'Cannot update profile id';
    END IF;
    
    IF OLD.email IS DISTINCT FROM NEW.email THEN
        RAISE EXCEPTION 'Cannot update email. Please contact an administrator.';
    END IF;
    
    IF OLD.role IS DISTINCT FROM NEW.role THEN
        RAISE EXCEPTION 'Cannot update role. Please contact an administrator.';
    END IF;
    
    IF OLD.organizer_tag IS DISTINCT FROM NEW.organizer_tag THEN
        RAISE EXCEPTION 'Cannot update organizer_tag. Please contact an administrator.';
    END IF;
    
    IF OLD.created_at IS DISTINCT FROM NEW.created_at THEN
        RAISE EXCEPTION 'Cannot update created_at';
    END IF;
    
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."prevent_sensitive_profile_updates"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."schedule_events_sync_cron"("schedule_cron" "text" DEFAULT '0 2 * * *'::"text") RETURNS TABLE("jobid" bigint, "jobname" "text", "schedule" "text")
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  config_record record;
  job_id bigint;
  sql_command text;
BEGIN
  -- Get config
  SELECT "auth_token", "project_ref" INTO config_record
  FROM "public"."events_sync_config"
  WHERE "id" = 'default';

  IF config_record IS NULL OR config_record."auth_token" IS NULL OR config_record."auth_token" = '' THEN
    RAISE EXCEPTION 'Auth token not configured. Call set_events_sync_auth_token() first.';
  END IF;

  -- Check if cron job already exists
  IF EXISTS (
    SELECT 1 FROM cron.job WHERE cron.job.jobname = 'events-sync'
  ) THEN
    RAISE EXCEPTION 'Cron job "events-sync" already exists. Use cron.unschedule() to remove it first.';
  END IF;

  -- Build the SQL command with the auth token from config
  sql_command := format('
    SELECT net.http_post(
      url := ''https://%s.supabase.co/api/events/sync'',
      headers := jsonb_build_object(
        ''Authorization'', ''Bearer %s'',
        ''Content-Type'', ''application/json''
      ),
      body := ''{}''::jsonb
    ) AS request_id;
  ', config_record."project_ref", config_record."auth_token");

  -- Schedule the cron job
  SELECT cron.schedule(
    'events-sync',
    schedule_cron,
    sql_command
  ) INTO job_id;

  RETURN QUERY
  SELECT 
    job_id,
    'events-sync'::text,
    schedule_cron::text;
END;
$$;


ALTER FUNCTION "public"."schedule_events_sync_cron"("schedule_cron" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_events_sync_auth_token"("auth_token" "text", "project_ref" "text" DEFAULT 'gjbzjjwtwcgfbjjmuery'::"text") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  INSERT INTO "public"."events_sync_config" ("id", "auth_token", "project_ref")
  VALUES ('default', auth_token, project_ref)
  ON CONFLICT ("id") 
  DO UPDATE SET 
    "auth_token" = EXCLUDED."auth_token",
    "project_ref" = EXCLUDED."project_ref",
    "updated_at" = now();
END;
$$;


ALTER FUNCTION "public"."set_events_sync_auth_token"("auth_token" "text", "project_ref" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."trigger_location_lookup"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  postcode_changed boolean;
  address_changed boolean;
  request_id bigint;
BEGIN
  -- Check if postcode or street_address changed
  IF TG_OP = 'UPDATE' THEN
    postcode_changed := (OLD.postcode IS DISTINCT FROM NEW.postcode);
    address_changed := (OLD.street_address IS DISTINCT FROM NEW.street_address);
    
    -- Only proceed if at least one of them changed
    IF NOT postcode_changed AND NOT address_changed THEN
      RETURN NEW;
    END IF;
  END IF;

  -- Skip if postcode is empty (required for lookup)
  IF NEW.postcode IS NULL OR trim(NEW.postcode) = '' THEN
    RETURN NEW;
  END IF;

  -- Call the Edge Function via the helper function
  SELECT call_location_lookup_edge_function(
    NEW.id,
    NEW.postcode,
    NEW.street_address
  ) INTO request_id;

  -- Log the result
  IF request_id IS NOT NULL THEN
    RAISE NOTICE 'Location lookup triggered for contact %: request_id %', NEW.id, request_id;
  ELSE
    RAISE WARNING 'Location lookup request failed for contact %: request_id is NULL', NEW.id;
  END IF;

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  -- Log error but don't fail the transaction
  RAISE WARNING 'Location lookup trigger error for contact %: %', NEW.id, SQLERRM;
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."trigger_location_lookup"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."trigger_location_lookup"() IS 'Trigger function that validates conditions and calls the location lookup Edge Function when contact postcode or street_address changes';



CREATE OR REPLACE FUNCTION "public"."update_contact_custom_fields_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_contact_custom_fields_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_contact_enrichment_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  NEW."updated_at" = now();
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_contact_enrichment_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_contact_location"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  -- Update location geometry if both latitude and longitude are provided
  IF NEW.latitude IS NOT NULL AND NEW.longitude IS NOT NULL THEN
    NEW.location := ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326);
  ELSE
    NEW.location := NULL;
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_contact_location"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."update_contact_location"() IS 'Automatically updates the location geometry point from latitude and longitude columns';



CREATE OR REPLACE FUNCTION "public"."update_contact_note_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  NEW."updated_at" = now();
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_contact_note_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_custom_columns_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_custom_columns_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_survey_column_update_rules_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_survey_column_update_rules_updated_at"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."update_survey_column_update_rules_updated_at"() IS 'Automatically updates the updated_at timestamp when a rule is modified';



CREATE OR REPLACE FUNCTION "public"."update_updated_at_column"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
   NEW.updated_at = now(); 
   RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_updated_at_column"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."validate_attachment_update"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  is_admin boolean;
BEGIN
  -- Check if user is admin
  SELECT EXISTS (
    SELECT 1 FROM "public"."profiles" "p"
    WHERE "p"."id" = auth.uid()
      AND "p"."role"::text = ANY (ARRAY['super_admin', 'admin'])
  ) INTO is_admin;

  -- Validate deleted_at changes
  IF OLD."deleted_at" IS DISTINCT FROM NEW."deleted_at" THEN
    -- Soft delete: must be uploader and deleted_at was NULL
    IF OLD."deleted_at" IS NULL AND NEW."deleted_at" IS NOT NULL THEN
      IF NEW."uploaded_by" != auth.uid() THEN
        RAISE EXCEPTION 'Only the uploader can delete attachments';
      END IF;
      IF NEW."deleted_by" != auth.uid() THEN
        RAISE EXCEPTION 'deleted_by must match the current user';
      END IF;
    -- Restore: must be admin and deleted_at was NOT NULL
    ELSIF OLD."deleted_at" IS NOT NULL AND NEW."deleted_at" IS NULL THEN
      IF NOT is_admin THEN
        RAISE EXCEPTION 'Only admins can restore deleted attachments';
      END IF;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."validate_attachment_update"() OWNER TO "postgres";


CREATE AGGREGATE "msar"."peak_month"("date") (
    SFUNC = "msar"."add_month_to_vector",
    STYPE = "point",
    INITCOND = '(0,0)',
    FINALFUNC = "msar"."point_to_month"
);


ALTER AGGREGATE "msar"."peak_month"("date") OWNER TO "postgres";


CREATE AGGREGATE "msar"."peak_time"(time without time zone) (
    SFUNC = "msar"."add_time_to_vector",
    STYPE = "point",
    INITCOND = '(0,0)',
    FINALFUNC = "msar"."point_to_time"
);


ALTER AGGREGATE "msar"."peak_time"(time without time zone) OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "msar"."expr_templates" (
    "expr_key" "text" NOT NULL,
    "expr_template" "text"
);


ALTER TABLE "msar"."expr_templates" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "msar"."top_level_domains" (
    "tld" "text" NOT NULL
);


ALTER TABLE "msar"."top_level_domains" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."action_logs" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "profile_id" "uuid",
    "action_type" "text" NOT NULL,
    "entity_type" "text" NOT NULL,
    "entity_id" "text",
    "route" "text" NOT NULL,
    "success" boolean NOT NULL,
    "metadata" "jsonb",
    "request_id" "text"
);


ALTER TABLE "public"."action_logs" OWNER TO "postgres";


COMMENT ON TABLE "public"."action_logs" IS 'Audit log for all mutations; each row tied to a referencing document (entity_type + entity_id)';



CREATE TABLE IF NOT EXISTS "public"."api_logs" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "request_id" "text" NOT NULL,
    "method" "text" NOT NULL,
    "path" "text" NOT NULL,
    "ip" "text" NOT NULL,
    "user_agent" "text",
    "profile_id" "uuid",
    "token_id" "uuid",
    "status" integer,
    "duration_ms" numeric,
    "response_size_bytes" integer,
    "error_message" "text",
    "error_stack" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."api_logs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."api_tokens" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "token_hash" "text" NOT NULL,
    "name" "text" NOT NULL,
    "profile_id" "uuid" NOT NULL,
    "created_by" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "expires_at" timestamp with time zone,
    "last_used_at" timestamp with time zone,
    "is_active" boolean DEFAULT true NOT NULL
);


ALTER TABLE "public"."api_tokens" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."attachment_audit_log" (
    "id" bigint NOT NULL,
    "attachment_id" bigint NOT NULL,
    "action" "text" NOT NULL,
    "performed_by" "uuid" NOT NULL,
    "performed_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "metadata" "jsonb"
);


ALTER TABLE "public"."attachment_audit_log" OWNER TO "postgres";


COMMENT ON TABLE "public"."attachment_audit_log" IS 'Audit log for attachment actions (upload, delete, etc.).';



CREATE SEQUENCE IF NOT EXISTS "public"."attachment_audit_log_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."attachment_audit_log_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."attachment_audit_log_id_seq" OWNED BY "public"."attachment_audit_log"."id";



CREATE TABLE IF NOT EXISTS "public"."audiences" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid",
    "name" "text" NOT NULL,
    "description" "text",
    "config" "jsonb" NOT NULL,
    "visibility" "text" DEFAULT 'private'::"text" NOT NULL,
    "last_contact_count" integer,
    "last_calculated_at" timestamp with time zone,
    CONSTRAINT "audiences_visibility_check" CHECK (("visibility" = ANY (ARRAY['private'::"text", 'team'::"text"])))
);


ALTER TABLE "public"."audiences" OWNER TO "postgres";


ALTER TABLE "public"."audiences" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."audiences_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."campaigns" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid",
    "campaign_type" "text" NOT NULL,
    "content_id" bigint NOT NULL,
    "name" "text" NOT NULL,
    "description" "text",
    "config" "jsonb" NOT NULL,
    "status" "text" DEFAULT 'draft'::"text" NOT NULL,
    "scheduled_at" timestamp with time zone,
    "total_recipients" integer DEFAULT 0,
    "sent_count" integer DEFAULT 0,
    "archived" boolean DEFAULT false,
    "failed_contact_ids" "jsonb",
    CONSTRAINT "campaigns_campaign_type_check" CHECK (("campaign_type" = ANY (ARRAY['survey'::"text", 'email'::"text", 'sms'::"text"]))),
    CONSTRAINT "campaigns_status_check" CHECK (("status" = ANY (ARRAY['draft'::"text", 'scheduled'::"text", 'sending'::"text", 'sent'::"text", 'cancelled'::"text"])))
);


ALTER TABLE "public"."campaigns" OWNER TO "postgres";


ALTER TABLE "public"."campaigns" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."campaigns_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."column_visibility" (
    "id" bigint NOT NULL,
    "column_name" "text" NOT NULL,
    "column_label" "text" NOT NULL,
    "visible" boolean DEFAULT true NOT NULL,
    "display_order" integer DEFAULT 0 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "global_display_order" integer,
    "hidden_from_organizers" boolean DEFAULT false NOT NULL,
    "data_type" "text" DEFAULT 'text'::"text",
    "options" "jsonb",
    "allow_other" boolean DEFAULT false NOT NULL,
    CONSTRAINT "column_visibility_data_type_check" CHECK (("data_type" = ANY (ARRAY['text'::"text", 'number'::"text", 'date'::"text", 'boolean'::"text", 'select'::"text"])))
);


ALTER TABLE "public"."column_visibility" OWNER TO "postgres";


COMMENT ON COLUMN "public"."column_visibility"."data_type" IS 'Override data type for display/filtering. When set, this overrides the default inferred type. Allows converting text columns to select dropdowns, etc.';



COMMENT ON COLUMN "public"."column_visibility"."options" IS 'For select type columns, stores an array of allowed option values. Example: ["Option 1", "Option 2", "Option 3"]';



COMMENT ON COLUMN "public"."column_visibility"."allow_other" IS 'For select type columns, when true, allows users to add custom values in addition to predefined options. Similar to survey question "Allow Other" functionality.';



ALTER TABLE "public"."column_visibility" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."column_visibility_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."contact" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone,
    "firstname" "text",
    "surname" "text",
    "email" "text",
    "phone" "text",
    "birthdate" smallint,
    "birthmonth" smallint,
    "birthyear" smallint,
    "street_address" "text",
    "municipality" "text",
    "division" "text",
    "region" "text",
    "country" "text",
    "postcode" "text",
    "federal_electoral_district" "text",
    "division_electoral_district" "text",
    "municipal_electoral_district" "text",
    "ballot1" "text",
    "ballot2" "text",
    "ballot3" "text",
    "ballot4" "text",
    "comms_consent" boolean,
    "signup_consent" boolean,
    "signup_submitted" boolean,
    "member" boolean,
    "organizer" "text",
    "language" "text",
    "olp23_ballot1" "text",
    "olp23_ballot2" "text",
    "olp23_ballot3" "text",
    "olp23_ballot4" "text",
    "olp23_comms_consent" "text",
    "olp23_signup_consent" "text",
    "olp23_volunteer_status" "text",
    "olp23_donor_status" "text",
    "olp23_donation_amount" "text",
    "olp23_signup_submitted" "text",
    "olp23_organizer" "text",
    "olp23_source" "text",
    "olp23_member" "text",
    "olp23_voted" "text",
    "olp23_voting_group" "text",
    "olp23_voting_location" "text",
    "olp23_voting_period" "text",
    "olp23_voting_association" "text",
    "olp23_nate_signup" "text",
    "olp23_campus_club" "text",
    "olp23_callhub_notes" "text",
    "olp23_nes_support_level" "text",
    "olp23_gender" "text",
    "olp23_riding" "text",
    "olp23_organizer_ref_id" "text",
    "olp23_membership_status" "text",
    "olp_van_id" "text",
    "lpc_van_id" "text",
    "last_request" bigint,
    "tags" "text",
    "gender" "text",
    "mailerlite_id" "text",
    "campus_club" "text",
    "ride_request_status" "text",
    "contact_status" "text",
    "latitude" double precision,
    "longitude" double precision,
    "location" "public"."geometry"(Point,4326),
    "research_data" "jsonb",
    "research_updated_at" timestamp with time zone,
    "research_status" character varying(20) DEFAULT NULL::character varying,
    CONSTRAINT "contact_research_status_check" CHECK ((("research_status")::"text" = ANY ((ARRAY['pending'::character varying, 'completed'::character varying, 'failed'::character varying])::"text"[])))
);


ALTER TABLE "public"."contact" OWNER TO "postgres";


COMMENT ON COLUMN "public"."contact"."latitude" IS 'Latitude coordinate in decimal degrees (WGS84)';



COMMENT ON COLUMN "public"."contact"."longitude" IS 'Longitude coordinate in decimal degrees (WGS84)';



COMMENT ON COLUMN "public"."contact"."location" IS 'PostGIS geometry point (SRID 4326) automatically generated from latitude/longitude';



COMMENT ON COLUMN "public"."contact"."research_data" IS 'AI research results following contact-research skill format, stored as JSONB with sections for basic information, public statements, advocacy, appearances, contributions, and sources';



COMMENT ON COLUMN "public"."contact"."research_updated_at" IS 'Timestamp of when AI research was last updated or requested';



COMMENT ON COLUMN "public"."contact"."research_status" IS 'Current status of AI research: pending (in progress), completed (success), failed (error)';



CREATE TABLE IF NOT EXISTS "public"."contact_attachment" (
    "id" bigint NOT NULL,
    "contact_id" bigint NOT NULL,
    "file_name" "text" NOT NULL,
    "file_size" bigint NOT NULL,
    "mime_type" "text" NOT NULL,
    "storage_path" "text" NOT NULL,
    "deleted_at" timestamp with time zone,
    "deleted_by" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "uploaded_by" "uuid" NOT NULL,
    CONSTRAINT "contact_attachment_file_size_check" CHECK ((("file_size" > 0) AND ("file_size" <= 10485760)))
);


ALTER TABLE "public"."contact_attachment" OWNER TO "postgres";


COMMENT ON TABLE "public"."contact_attachment" IS 'Stores metadata for files attached to contacts. Supports soft deletion. Maximum file size is 10MB.';



CREATE SEQUENCE IF NOT EXISTS "public"."contact_attachment_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."contact_attachment_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."contact_attachment_id_seq" OWNED BY "public"."contact_attachment"."id";



CREATE TABLE IF NOT EXISTS "public"."contact_custom_fields" (
    "id" bigint NOT NULL,
    "contact_id" bigint NOT NULL,
    "column_id" bigint NOT NULL,
    "value_text" "text",
    "value_number" numeric,
    "value_date" "date",
    "value_boolean" boolean,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."contact_custom_fields" OWNER TO "postgres";


ALTER TABLE "public"."contact_custom_fields" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."contact_custom_fields_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."contact_enrichment" (
    "id" bigint NOT NULL,
    "contact_id" bigint NOT NULL,
    "enrichment_type" "text" NOT NULL,
    "enrichment_data" "jsonb" NOT NULL,
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "source" "text",
    "confidence_score" numeric,
    CONSTRAINT "contact_enrichment_enrichment_type_check" CHECK (("enrichment_type" = ANY (ARRAY['linkedin'::"text", 'company'::"text", 'social'::"text", 'news'::"text"]))),
    CONSTRAINT "contact_enrichment_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'completed'::"text", 'failed'::"text"])))
);


ALTER TABLE "public"."contact_enrichment" OWNER TO "postgres";


COMMENT ON TABLE "public"."contact_enrichment" IS 'Stores enrichment data for contacts from external sources. Admin-only access.';



CREATE SEQUENCE IF NOT EXISTS "public"."contact_enrichment_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."contact_enrichment_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."contact_enrichment_id_seq" OWNED BY "public"."contact_enrichment"."id";



ALTER TABLE "public"."contact" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."contact_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."contact_note" (
    "id" bigint NOT NULL,
    "contact_id" bigint NOT NULL,
    "content" "text" NOT NULL,
    "content_format" "text" DEFAULT 'plain'::"text" NOT NULL,
    "visibility" "text" DEFAULT 'team'::"text" NOT NULL,
    "is_pinned" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid" NOT NULL,
    "updated_by" "uuid",
    CONSTRAINT "contact_note_content_check" CHECK ((("char_length"("content") >= 1) AND ("char_length"("content") <= 10000))),
    CONSTRAINT "contact_note_content_format_check" CHECK (("content_format" = ANY (ARRAY['plain'::"text", 'markdown'::"text"]))),
    CONSTRAINT "contact_note_visibility_check" CHECK (("visibility" = ANY (ARRAY['private'::"text", 'team'::"text"])))
);


ALTER TABLE "public"."contact_note" OWNER TO "postgres";


COMMENT ON TABLE "public"."contact_note" IS 'Stores notes associated with contacts. Supports plain text and markdown formats, with visibility controls (private/team) and pinning capability.';



CREATE SEQUENCE IF NOT EXISTS "public"."contact_note_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."contact_note_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."contact_note_id_seq" OWNED BY "public"."contact_note"."id";



CREATE TABLE IF NOT EXISTS "public"."contact_voting_history" (
    "id" bigint NOT NULL,
    "contact_id" bigint NOT NULL,
    "voted" boolean NOT NULL,
    "marked_by" "uuid",
    "marked_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "notes" "text"
);


ALTER TABLE "public"."contact_voting_history" OWNER TO "postgres";


ALTER TABLE "public"."contact_voting_history" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."contact_voting_history_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."custom_columns" (
    "id" bigint NOT NULL,
    "name" "text" NOT NULL,
    "label" "text" NOT NULL,
    "data_type" "text" NOT NULL,
    "options" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid",
    "visible" boolean DEFAULT true NOT NULL,
    "display_order" integer DEFAULT 0 NOT NULL,
    "global_display_order" integer,
    "hidden_from_organizers" boolean DEFAULT false NOT NULL,
    CONSTRAINT "custom_columns_data_type_check" CHECK (("data_type" = ANY (ARRAY['text'::"text", 'number'::"text", 'date'::"text", 'boolean'::"text", 'select'::"text"])))
);


ALTER TABLE "public"."custom_columns" OWNER TO "postgres";


ALTER TABLE "public"."custom_columns" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."custom_columns_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."data_access_field_permissions" (
    "id" bigint NOT NULL,
    "role" "text" NOT NULL,
    "column_name" "text",
    "custom_column_id" bigint,
    "can_view" boolean DEFAULT true NOT NULL,
    "can_filter" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "data_access_field_permissions_column_type_check" CHECK (((("column_name" IS NOT NULL) AND ("custom_column_id" IS NULL)) OR (("column_name" IS NULL) AND ("custom_column_id" IS NOT NULL))))
);


ALTER TABLE "public"."data_access_field_permissions" OWNER TO "postgres";


COMMENT ON TABLE "public"."data_access_field_permissions" IS 'Role-based field-level access control. Determines which fields each role can view and use in filters. Supports both default and custom columns.';



COMMENT ON COLUMN "public"."data_access_field_permissions"."role" IS 'RoleType enum value: super_admin, admin, member, locked, developer';



COMMENT ON COLUMN "public"."data_access_field_permissions"."can_view" IS 'Can this role see this field in tables and expanded views?';



COMMENT ON COLUMN "public"."data_access_field_permissions"."can_filter" IS 'Can this role use this field in filter configurations?';



ALTER TABLE "public"."data_access_field_permissions" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."data_access_field_permissions_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."data_access_record_permissions" (
    "id" bigint NOT NULL,
    "role" "text" NOT NULL,
    "permission_type" "text" NOT NULL,
    "permission_scope" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "data_access_record_permissions_permission_type_check" CHECK (("permission_type" = ANY (ARRAY['riding'::"text", 'region'::"text", 'campus_club'::"text", 'all'::"text"])))
);


ALTER TABLE "public"."data_access_record_permissions" OWNER TO "postgres";


COMMENT ON TABLE "public"."data_access_record_permissions" IS 'Role-based record-level access control. Works alongside user-specific profile_*_access tables (user-specific overrides role-based).';



COMMENT ON COLUMN "public"."data_access_record_permissions"."role" IS 'RoleType enum value: super_admin, admin, member, locked, developer';



COMMENT ON COLUMN "public"."data_access_record_permissions"."permission_type" IS 'Type of access: riding, region, campus_club, or all';



COMMENT ON COLUMN "public"."data_access_record_permissions"."permission_scope" IS 'Specific riding/region/club name, or NULL for all access';



ALTER TABLE "public"."data_access_record_permissions" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."data_access_record_permissions_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."division_electoral_district" (
    "name" "text" NOT NULL,
    "olp_region" "text" NOT NULL
);


ALTER TABLE "public"."division_electoral_district" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."events" (
    "id" "text" NOT NULL,
    "slug" "text" NOT NULL,
    "name" "text" NOT NULL,
    "description" "text",
    "start_date" timestamp with time zone NOT NULL,
    "end_date" timestamp with time zone NOT NULL,
    "location_name" "text",
    "location_address" "text",
    "category" "text",
    "source" "text" NOT NULL,
    "is_external" boolean DEFAULT false NOT NULL,
    "external_url" "text",
    "is_ticketed" boolean DEFAULT false NOT NULL,
    "cost" "text",
    "tags" "text"[],
    "status" "text" DEFAULT 'active'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "last_synced_at" timestamp with time zone,
    "sync_error" "text",
    CONSTRAINT "events_status_check" CHECK (("status" = ANY (ARRAY['active'::"text", 'cancelled'::"text", 'archived'::"text"])))
);


ALTER TABLE "public"."events" OWNER TO "postgres";


COMMENT ON TABLE "public"."events" IS 'Events synced from external sources (OLP) and internal/manual events. Supports ICS calendar generation with filtering.';



COMMENT ON COLUMN "public"."events"."id" IS 'Unique event ID (e.g., olp-slug-2025-01-15)';



COMMENT ON COLUMN "public"."events"."slug" IS 'URL-friendly identifier';



COMMENT ON COLUMN "public"."events"."source" IS 'Event source: olp or nate';



COMMENT ON COLUMN "public"."events"."is_external" IS 'True for synced events from external sources (OLP), false for internal/manual events';



COMMENT ON COLUMN "public"."events"."status" IS 'Event status: active, cancelled, or archived';



COMMENT ON COLUMN "public"."events"."last_synced_at" IS 'When this event was last updated from source';



COMMENT ON COLUMN "public"."events"."sync_error" IS 'Last sync error message if sync failed';



CREATE TABLE IF NOT EXISTS "public"."events_sync_config" (
    "id" "text" DEFAULT 'default'::"text" NOT NULL,
    "auth_token" "text" NOT NULL,
    "project_ref" "text" DEFAULT 'gjbzjjwtwcgfbjjmuery'::"text" NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "events_sync_config_single_row" CHECK (("id" = 'default'::"text"))
);


ALTER TABLE "public"."events_sync_config" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."feature_permissions" (
    "id" integer NOT NULL,
    "feature_id" "text" NOT NULL,
    "role_id" "text" NOT NULL,
    "allowed" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."feature_permissions" OWNER TO "postgres";


COMMENT ON TABLE "public"."feature_permissions" IS 'Links features to roles with permission flags. role_id references roles table for both system and custom roles.';



CREATE SEQUENCE IF NOT EXISTS "public"."feature_permissions_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."feature_permissions_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."feature_permissions_id_seq" OWNED BY "public"."feature_permissions"."id";



CREATE TABLE IF NOT EXISTS "public"."features" (
    "id" "text" NOT NULL,
    "name" "text" NOT NULL,
    "description" "text",
    "category" "text",
    "enabled" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."features" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."organizer_tags" (
    "tag" "text" NOT NULL,
    "display_name" "text" NOT NULL,
    "created_by" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."organizer_tags" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."page_questions" (
    "id" bigint NOT NULL,
    "page_id" bigint NOT NULL,
    "question_id" bigint NOT NULL,
    "question_order" integer NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "show_condition" "jsonb"
);


ALTER TABLE "public"."page_questions" OWNER TO "postgres";


COMMENT ON TABLE "public"."page_questions" IS 'Junction table linking reusable pages to questions. Questions can be shared across multiple pages.';



COMMENT ON COLUMN "public"."page_questions"."question_order" IS '1-indexed order of the question within the page';



COMMENT ON COLUMN "public"."page_questions"."show_condition" IS 'JSONB object defining when this question should be shown. Format: { "conditions": [{"questionId": number, "operator": string, "value": any}], "conditionLogic": "AND" | "OR" }. If null, question is always shown.';



ALTER TABLE "public"."page_questions" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."page_questions_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."permission_audit_log" (
    "id" integer NOT NULL,
    "changed_by" "uuid" NOT NULL,
    "change_type" "text" NOT NULL,
    "entity_type" "text" NOT NULL,
    "entity_id" "text" NOT NULL,
    "old_value" "jsonb",
    "new_value" "jsonb",
    "metadata" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "permission_audit_log_change_type_check" CHECK (("change_type" = ANY (ARRAY['create'::"text", 'update'::"text", 'delete'::"text"]))),
    CONSTRAINT "permission_audit_log_entity_type_check" CHECK (("entity_type" = ANY (ARRAY['role'::"text", 'feature'::"text", 'permission'::"text"])))
);


ALTER TABLE "public"."permission_audit_log" OWNER TO "postgres";


COMMENT ON TABLE "public"."permission_audit_log" IS 'Audit log for all permission-related changes (roles, features, permissions)';



CREATE SEQUENCE IF NOT EXISTS "public"."permission_audit_log_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."permission_audit_log_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."permission_audit_log_id_seq" OWNED BY "public"."permission_audit_log"."id";



CREATE TABLE IF NOT EXISTS "public"."profile_campus_club_access" (
    "profile_id" "uuid" NOT NULL,
    "campus_club" "text" NOT NULL,
    "can_write" boolean DEFAULT false NOT NULL,
    "granted_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."profile_campus_club_access" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."profile_organizer_tags" (
    "profile_id" "uuid" NOT NULL,
    "tag" "text" NOT NULL
);


ALTER TABLE "public"."profile_organizer_tags" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."profile_region_access" (
    "profile_id" "uuid" NOT NULL,
    "region" "text" NOT NULL,
    "can_write" boolean DEFAULT false NOT NULL,
    "granted_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."profile_region_access" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."profile_riding_access" (
    "profile_id" "uuid" NOT NULL,
    "riding" "text" NOT NULL,
    "can_write" boolean DEFAULT false NOT NULL,
    "granted_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."profile_riding_access" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."profiles" (
    "id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone,
    "email" "text" NOT NULL,
    "first_name" "text" NOT NULL,
    "surname" "text" NOT NULL,
    "phone" "text" NOT NULL,
    "street_address" "text" NOT NULL,
    "postal_code" "text" NOT NULL,
    "birth_year" smallint NOT NULL,
    "birth_month" smallint NOT NULL,
    "birth_day" smallint NOT NULL,
    "organizer_tag" "text" NOT NULL,
    "role" "public"."role_type" DEFAULT 'member'::"public"."role_type" NOT NULL,
    "last_seen_at" timestamp with time zone
);


ALTER TABLE "public"."profiles" OWNER TO "postgres";


COMMENT ON COLUMN "public"."profiles"."last_seen_at" IS 'Timestamp of when the user was last seen online (last authenticated request). Updated periodically to avoid excessive database writes.';



CREATE TABLE IF NOT EXISTS "public"."request" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "origin" "text",
    "payload" "jsonb",
    "ip" "text",
    "email" "text",
    "success" boolean,
    "logs" "jsonb",
    "status" "public"."status" DEFAULT 'new'::"public"."status" NOT NULL,
    "category" "text",
    "notes" "text",
    "contact_id" bigint,
    "step" integer,
    "utm_source" "text",
    "utm_medium" "text",
    "utm_campaign" "text",
    "utm_term" "text"[],
    "utm_content" "text",
    "search_params" "jsonb"
);


ALTER TABLE "public"."request" OWNER TO "postgres";


ALTER TABLE "public"."request" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."requests_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."roles" (
    "id" "text" NOT NULL,
    "name" "text" NOT NULL,
    "description" "text",
    "is_system" boolean DEFAULT false NOT NULL,
    "display_order" integer DEFAULT 0 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "roles_system_role_id_check" CHECK ((("is_system" = false) OR ("id" = "name")))
);


ALTER TABLE "public"."roles" OWNER TO "postgres";


COMMENT ON TABLE "public"."roles" IS 'Stores both system roles (super_admin, admin, member, locked, developer) and custom roles';



CREATE TABLE IF NOT EXISTS "public"."saved_filters" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "name" "text" NOT NULL,
    "owner_id" "uuid",
    "visibility" "public"."filter_visibility" DEFAULT 'private'::"public"."filter_visibility" NOT NULL,
    "config" "jsonb" NOT NULL
);


ALTER TABLE "public"."saved_filters" OWNER TO "postgres";


ALTER TABLE "public"."saved_filters" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."saved_filters_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."signup_requests" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "email" "text" NOT NULL,
    "password_hash" "text",
    "first_name" "text",
    "surname" "text",
    "phone" "text",
    "street_address" "text",
    "postal_code" "text",
    "birth_year" smallint,
    "birth_month" smallint,
    "birth_day" smallint,
    "comms_consent" boolean,
    "signup_consent" boolean,
    "wants_student_club" boolean,
    "campus_club" "text",
    "associations" "text"[] DEFAULT '{}'::"text"[] NOT NULL,
    "organizer_tag" "text" NOT NULL,
    "reviewer_id" "uuid",
    "reviewed_at" timestamp with time zone,
    "reviewer_notes" "text",
    "invited" boolean DEFAULT false NOT NULL,
    "invited_by" "uuid",
    "invited_role" "text" DEFAULT 'member'::"text",
    "invited_campus_clubs" "text"[] DEFAULT '{}'::"text"[] NOT NULL,
    "invite_completed_at" timestamp with time zone,
    "province" "text"
);


ALTER TABLE "public"."signup_requests" OWNER TO "postgres";


ALTER TABLE "public"."signup_requests" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."signup_requests_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."survey_column_update_rules" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid",
    "updated_by" "uuid",
    "question_id" bigint,
    "survey_id" bigint,
    "rule_config" "jsonb" NOT NULL,
    "enabled" boolean DEFAULT true NOT NULL,
    "priority" integer DEFAULT 0 NOT NULL,
    "description" "text",
    "tags" "text"[],
    "last_applied_at" timestamp with time zone,
    "application_count" bigint DEFAULT 0,
    CONSTRAINT "survey_column_update_rules_scope_check" CHECK (((("question_id" IS NOT NULL) AND ("survey_id" IS NULL)) OR (("question_id" IS NULL) AND ("survey_id" IS NOT NULL))))
);


ALTER TABLE "public"."survey_column_update_rules" OWNER TO "postgres";


COMMENT ON TABLE "public"."survey_column_update_rules" IS 'Stores column update rules for survey responses. Rules can be scoped to a specific question or to the entire survey.';



COMMENT ON COLUMN "public"."survey_column_update_rules"."question_id" IS 'If set, this rule applies only to answers for this specific question';



COMMENT ON COLUMN "public"."survey_column_update_rules"."survey_id" IS 'If set, this rule applies to all answers in the survey (survey-level rule)';



COMMENT ON COLUMN "public"."survey_column_update_rules"."rule_config" IS 'JSONB field storing the comprehensive ColumnUpdateRule configuration';



COMMENT ON COLUMN "public"."survey_column_update_rules"."priority" IS 'Lower numbers execute first. Default is 0.';



COMMENT ON COLUMN "public"."survey_column_update_rules"."application_count" IS 'Number of times this rule has been successfully applied';



ALTER TABLE "public"."survey_column_update_rules" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."survey_column_update_rules_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."survey_instances" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "survey_id" bigint NOT NULL,
    "contact_id" bigint NOT NULL,
    "sent_at" timestamp with time zone,
    "sent_by" "uuid",
    "token" "text" NOT NULL,
    "status" "text" NOT NULL,
    "completed_at" timestamp with time zone,
    "expires_at" timestamp with time zone,
    "campaign_id" bigint,
    CONSTRAINT "survey_instances_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'sent'::"text", 'started'::"text", 'completed'::"text", 'expired'::"text"])))
);


ALTER TABLE "public"."survey_instances" OWNER TO "postgres";


ALTER TABLE "public"."survey_instances" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."survey_instances_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."survey_page_assignments" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "survey_id" bigint NOT NULL,
    "page_id" bigint NOT NULL,
    "page_number" integer NOT NULL,
    "title" "text",
    "routing_rules" "jsonb",
    "visible_to_roles" "text"[],
    CONSTRAINT "survey_page_assignments_page_number_positive" CHECK (("page_number" > 0))
);


ALTER TABLE "public"."survey_page_assignments" OWNER TO "postgres";


COMMENT ON TABLE "public"."survey_page_assignments" IS 'Junction table linking surveys to reusable pages with survey-specific overrides (page_number, routing_rules, visible_to_roles)';



COMMENT ON COLUMN "public"."survey_page_assignments"."page_number" IS '1-indexed page number within the survey';



COMMENT ON COLUMN "public"."survey_page_assignments"."title" IS 'Survey-specific title override (overrides page template title if set)';



COMMENT ON COLUMN "public"."survey_page_assignments"."routing_rules" IS 'Survey-specific routing rules override (overrides page template routing_rules if set)';



COMMENT ON COLUMN "public"."survey_page_assignments"."visible_to_roles" IS 'Survey-specific visibility override (overrides page template visible_to_roles if set)';



ALTER TABLE "public"."survey_page_assignments" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."survey_page_assignments_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."survey_pages" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid",
    "page_code" "text" NOT NULL,
    "title" "text",
    "routing_rules" "jsonb",
    "visible_to_roles" "text"[] DEFAULT '{super_admin,admin,member}'::"text"[],
    "archived" boolean DEFAULT false
);


ALTER TABLE "public"."survey_pages" OWNER TO "postgres";


COMMENT ON TABLE "public"."survey_pages" IS 'Reusable page templates that can be used across multiple surveys (similar to survey_questions)';



COMMENT ON COLUMN "public"."survey_pages"."page_code" IS 'Unique identifier for the page (similar to question_code)';



COMMENT ON COLUMN "public"."survey_pages"."routing_rules" IS 'JSONB array of PageRoutingRule objects defining default page-level routing';



COMMENT ON COLUMN "public"."survey_pages"."visible_to_roles" IS 'Array of role types that can see this page by default. NULL or empty array means visible to all roles. Valid values: super_admin, admin, member, locked, developer';



ALTER TABLE "public"."survey_pages" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."survey_pages_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."survey_questions" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid",
    "question_text" "text" NOT NULL,
    "question_type" "text" NOT NULL,
    "options" "jsonb",
    "required" boolean DEFAULT false,
    "validation_config" "jsonb",
    "archived" boolean DEFAULT false,
    "question_code" "text" NOT NULL,
    "visible_to_roles" "jsonb",
    "show_condition" "jsonb",
    CONSTRAINT "survey_questions_question_type_check" CHECK (("question_type" = ANY (ARRAY['text'::"text", 'textarea'::"text", 'multiple_choice'::"text", 'checkbox'::"text", 'multi_select'::"text", 'boolean'::"text", 'number'::"text", 'date'::"text", 'email'::"text", 'descriptive_text'::"text"])))
);


ALTER TABLE "public"."survey_questions" OWNER TO "postgres";


COMMENT ON COLUMN "public"."survey_questions"."visible_to_roles" IS 'Array of role types that can see this question. NULL or empty array means visible to all roles. Valid values: super_admin, admin, member, locked, developer';



COMMENT ON COLUMN "public"."survey_questions"."show_condition" IS 'JSONB object defining when this question should be shown. Format: { "conditions": [{"questionId": number, "operator": string, "value": any}], "conditionLogic": "AND" | "OR" }. If null, question is always shown.';



ALTER TABLE "public"."survey_questions" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."survey_questions_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."survey_response_answers" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "response_id" bigint NOT NULL,
    "question_id" bigint NOT NULL,
    "answer_text" "text",
    "answer_number" numeric,
    "answer_date" "date",
    "answer_boolean" boolean,
    "answer_json" "jsonb"
);


ALTER TABLE "public"."survey_response_answers" OWNER TO "postgres";


ALTER TABLE "public"."survey_response_answers" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."survey_response_answers_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."survey_responses" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "survey_instance_id" bigint NOT NULL,
    "survey_id" bigint NOT NULL,
    "contact_id" bigint NOT NULL,
    "status" "text" NOT NULL,
    "started_at" timestamp with time zone,
    "completed_at" timestamp with time zone,
    "metadata" "jsonb",
    "channel" "text" DEFAULT 'email'::"text" NOT NULL,
    "notes" "text",
    "linked_event" "text",
    "column_updates_status" "text" DEFAULT 'pending'::"text",
    "column_updates_reviewed_by" "uuid",
    "column_updates_reviewed_at" timestamp with time zone,
    "column_updates_reviewer_notes" "text",
    CONSTRAINT "survey_responses_channel_check" CHECK (("channel" = ANY (ARRAY['email'::"text", 'phone'::"text", 'canvass'::"text", 'event'::"text"]))),
    CONSTRAINT "survey_responses_column_updates_status_check" CHECK (("column_updates_status" = ANY (ARRAY['pending'::"text", 'applied'::"text", 'rejected'::"text"]))),
    CONSTRAINT "survey_responses_status_check" CHECK (("status" = ANY (ARRAY['in_progress'::"text", 'completed'::"text"])))
);


ALTER TABLE "public"."survey_responses" OWNER TO "postgres";


COMMENT ON COLUMN "public"."survey_responses"."column_updates_status" IS 'Status of column updates from this survey response: pending (needs review), applied (approved and applied), rejected (not applied)';



ALTER TABLE "public"."survey_responses" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."survey_responses_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."surveys" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid",
    "title" "text" NOT NULL,
    "description" "text",
    "status" "text" NOT NULL,
    "structure" "jsonb" NOT NULL,
    "settings" "jsonb",
    "archived" boolean DEFAULT false,
    "pages" "jsonb" DEFAULT '[]'::"jsonb",
    "visible_to_roles" "jsonb",
    CONSTRAINT "surveys_status_check" CHECK (("status" = ANY (ARRAY['draft'::"text", 'active'::"text", 'closed'::"text"])))
);


ALTER TABLE "public"."surveys" OWNER TO "postgres";


COMMENT ON COLUMN "public"."surveys"."pages" IS 'Array of SurveyPage objects defining page-level routing rules and page metadata';



COMMENT ON COLUMN "public"."surveys"."visible_to_roles" IS 'Array of role types that can see this survey. NULL or empty array means visible to all roles. Valid values: super_admin, admin, member, locked, developer';



ALTER TABLE "public"."surveys" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."surveys_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."user_column_preferences" (
    "id" bigint NOT NULL,
    "user_id" "uuid" NOT NULL,
    "route" "text" NOT NULL,
    "column_name" "text",
    "custom_column_id" bigint,
    "visible" boolean DEFAULT true NOT NULL,
    "display_order" integer NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "user_column_preferences_column_type_check" CHECK (((("column_name" IS NOT NULL) AND ("custom_column_id" IS NULL)) OR (("column_name" IS NULL) AND ("custom_column_id" IS NOT NULL))))
);


ALTER TABLE "public"."user_column_preferences" OWNER TO "postgres";


COMMENT ON TABLE "public"."user_column_preferences" IS 'Stores user column visibility and order preferences, scoped by route. Supports both default columns (via column_name) and custom columns (via custom_column_id).';



COMMENT ON COLUMN "public"."user_column_preferences"."route" IS 'Normalized route path (e.g., "dashboards/gotv") used to scope preferences per page';



COMMENT ON COLUMN "public"."user_column_preferences"."column_name" IS 'References column_visibility.column_name for default columns. Must be NULL if custom_column_id is set.';



COMMENT ON COLUMN "public"."user_column_preferences"."custom_column_id" IS 'References custom_columns.id for custom columns. Must be NULL if column_name is set.';



ALTER TABLE "public"."user_column_preferences" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."user_column_preferences_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."user_expanded_sections" (
    "id" bigint NOT NULL,
    "user_id" "uuid" NOT NULL,
    "route" "text" NOT NULL,
    "section_key" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."user_expanded_sections" OWNER TO "postgres";


COMMENT ON TABLE "public"."user_expanded_sections" IS 'Stores which sections are expanded for a user on a specific route. Each row represents one expanded section.';



COMMENT ON COLUMN "public"."user_expanded_sections"."route" IS 'Normalized route path (e.g., "admin/team") used to scope expanded sections per page';



COMMENT ON COLUMN "public"."user_expanded_sections"."section_key" IS 'Identifier for the section (e.g., "team-directory", "pending-requests")';



ALTER TABLE "public"."user_expanded_sections" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."user_expanded_sections_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."user_filter_defaults" (
    "id" bigint NOT NULL,
    "user_id" "uuid" NOT NULL,
    "route" "text" NOT NULL,
    "filter_config" "jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."user_filter_defaults" OWNER TO "postgres";


COMMENT ON TABLE "public"."user_filter_defaults" IS 'Stores default filter preferences per route. Uses JSONB for FilterGroup structure, following the same pattern as saved_filters.config and views.filter_config.';



COMMENT ON COLUMN "public"."user_filter_defaults"."route" IS 'Normalized route path (e.g., "dashboards/gotv") used to scope filter defaults per page';



COMMENT ON COLUMN "public"."user_filter_defaults"."filter_config" IS 'FilterGroup JSON structure matching saved_filters.filter_config format';



ALTER TABLE "public"."user_filter_defaults" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."user_filter_defaults_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."user_preferences" (
    "id" bigint NOT NULL,
    "user_id" "uuid" NOT NULL,
    "current_view_id" bigint,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "theme" "text" DEFAULT 'system'::"text" NOT NULL,
    CONSTRAINT "user_preferences_theme_check" CHECK (("theme" = ANY (ARRAY['light'::"text", 'dark'::"text", 'system'::"text"])))
);


ALTER TABLE "public"."user_preferences" OWNER TO "postgres";


COMMENT ON TABLE "public"."user_preferences" IS 'Stores user preferences: theme and current view. One row per user. Can be extended with more preference columns in the future.';



COMMENT ON COLUMN "public"."user_preferences"."current_view_id" IS 'The view ID currently selected by the user. NULL means using global defaults.';



COMMENT ON COLUMN "public"."user_preferences"."theme" IS 'User theme preference: light, dark, or system (follows OS preference)';



ALTER TABLE "public"."user_preferences" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."user_preferences_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."user_table_preferences" (
    "id" bigint NOT NULL,
    "user_id" "uuid" NOT NULL,
    "route" "text" NOT NULL,
    "page_size" integer,
    "sort_by" "text",
    "sort_order" "text",
    "pinned_headers" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "user_table_preferences_sort_order_check" CHECK (("sort_order" = ANY (ARRAY['asc'::"text", 'desc'::"text"])))
);


ALTER TABLE "public"."user_table_preferences" OWNER TO "postgres";


COMMENT ON TABLE "public"."user_table_preferences" IS 'Stores table-specific preferences per route: default page size, sort column/order, and pinned headers state.';



COMMENT ON COLUMN "public"."user_table_preferences"."route" IS 'Normalized route path (e.g., "dashboards/gotv") used to scope table preferences per page';



COMMENT ON COLUMN "public"."user_table_preferences"."page_size" IS 'Default page size for pagination on this route. NULL means use global default.';



COMMENT ON COLUMN "public"."user_table_preferences"."sort_by" IS 'Default sort column for this route. NULL means use global default.';



COMMENT ON COLUMN "public"."user_table_preferences"."sort_order" IS 'Default sort order (asc/desc) for this route. NULL means use global default.';



COMMENT ON COLUMN "public"."user_table_preferences"."pinned_headers" IS 'Whether table headers should be pinned (sticky) on this route.';



ALTER TABLE "public"."user_table_preferences" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."user_table_preferences_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."view_column_visibility" (
    "id" bigint NOT NULL,
    "view_id" bigint NOT NULL,
    "column_name" "text",
    "custom_column_id" bigint,
    "visible" boolean DEFAULT true NOT NULL,
    "display_order" integer NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "view_column_visibility_column_type_check" CHECK (((("column_name" IS NOT NULL) AND ("custom_column_id" IS NULL)) OR (("column_name" IS NULL) AND ("custom_column_id" IS NOT NULL))))
);


ALTER TABLE "public"."view_column_visibility" OWNER TO "postgres";


COMMENT ON TABLE "public"."view_column_visibility" IS 'Junction table linking views to column visibility overrides. Supports both default columns (via column_name) and custom columns (via custom_column_id) using a polymorphic pattern.';



COMMENT ON COLUMN "public"."view_column_visibility"."column_name" IS 'References column_visibility.column_name for default columns. Must be NULL if custom_column_id is set.';



COMMENT ON COLUMN "public"."view_column_visibility"."custom_column_id" IS 'References custom_columns.id for custom columns. Must be NULL if column_name is set.';



ALTER TABLE "public"."view_column_visibility" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."view_column_visibility_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."views" (
    "id" bigint NOT NULL,
    "name" "text" NOT NULL,
    "description" "text",
    "filter_config" "jsonb",
    "is_default" boolean DEFAULT false NOT NULL,
    "is_shared" boolean DEFAULT false NOT NULL,
    "created_by" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "sort_rules" "jsonb"
);


ALTER TABLE "public"."views" OWNER TO "postgres";


COMMENT ON TABLE "public"."views" IS 'View configurations combining column visibility and filters. Supports personal, shared, and default views.';



COMMENT ON COLUMN "public"."views"."filter_config" IS 'FilterGroup JSON structure matching saved_filters.filter_config format';



COMMENT ON COLUMN "public"."views"."is_default" IS 'Admin-configured default views available to all users';



COMMENT ON COLUMN "public"."views"."is_shared" IS 'Shared views available to team members (set by admins)';



COMMENT ON COLUMN "public"."views"."sort_rules" IS 'Default sort rules: [{ "column": string, "order": "asc"|"desc" }]. Array index = priority (0 primary, 1 secondary). Example: [{"column":"survey_status","order":"desc"},{"column":"id","order":"asc"}]. Used when view is selected and URL has no sort params.';



ALTER TABLE "public"."views" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."views_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



ALTER TABLE ONLY "public"."attachment_audit_log" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."attachment_audit_log_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."contact_attachment" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."contact_attachment_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."contact_enrichment" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."contact_enrichment_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."contact_note" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."contact_note_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."feature_permissions" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."feature_permissions_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."permission_audit_log" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."permission_audit_log_id_seq"'::"regclass");



ALTER DOMAIN "mathesar_types"."uri"
    ADD CONSTRAINT "uri_check" CHECK (((VALUE IS NULL) OR ("array_position"("regexp_match"(VALUE, '^(?:([^:/?#]+):)?(?://(?:[^/?#]*))?([^?#]*)(?:\?(?:[^#]*))?(?:#(?:.*))?'::"text"), NULL::"text") IS NULL))) NOT VALID;



ALTER TABLE ONLY "msar"."expr_templates"
    ADD CONSTRAINT "expr_templates_pkey" PRIMARY KEY ("expr_key");



ALTER TABLE ONLY "msar"."top_level_domains"
    ADD CONSTRAINT "top_level_domains_pkey" PRIMARY KEY ("tld");



ALTER TABLE ONLY "public"."action_logs"
    ADD CONSTRAINT "action_logs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."api_logs"
    ADD CONSTRAINT "api_logs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."api_tokens"
    ADD CONSTRAINT "api_tokens_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."api_tokens"
    ADD CONSTRAINT "api_tokens_token_hash_key" UNIQUE ("token_hash");



ALTER TABLE ONLY "public"."attachment_audit_log"
    ADD CONSTRAINT "attachment_audit_log_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."audiences"
    ADD CONSTRAINT "audiences_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."campaigns"
    ADD CONSTRAINT "campaigns_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."column_visibility"
    ADD CONSTRAINT "column_visibility_column_name_key" UNIQUE ("column_name");



ALTER TABLE ONLY "public"."column_visibility"
    ADD CONSTRAINT "column_visibility_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."contact_attachment"
    ADD CONSTRAINT "contact_attachment_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."contact_custom_fields"
    ADD CONSTRAINT "contact_custom_fields_contact_column_unique" UNIQUE ("contact_id", "column_id");



ALTER TABLE ONLY "public"."contact_custom_fields"
    ADD CONSTRAINT "contact_custom_fields_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."contact_enrichment"
    ADD CONSTRAINT "contact_enrichment_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."contact_note"
    ADD CONSTRAINT "contact_note_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."contact"
    ADD CONSTRAINT "contact_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."contact_voting_history"
    ADD CONSTRAINT "contact_voting_history_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."custom_columns"
    ADD CONSTRAINT "custom_columns_name_key" UNIQUE ("name");



ALTER TABLE ONLY "public"."custom_columns"
    ADD CONSTRAINT "custom_columns_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."data_access_field_permissions"
    ADD CONSTRAINT "data_access_field_permissions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."data_access_field_permissions"
    ADD CONSTRAINT "data_access_field_permissions_role_column_unique" UNIQUE ("role", "column_name", "custom_column_id");



ALTER TABLE ONLY "public"."data_access_record_permissions"
    ADD CONSTRAINT "data_access_record_permissions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."data_access_record_permissions"
    ADD CONSTRAINT "data_access_record_permissions_role_scope_unique" UNIQUE ("role", "permission_type", "permission_scope");



ALTER TABLE ONLY "public"."division_electoral_district"
    ADD CONSTRAINT "division_electoral_district_division_electoral_district_key" UNIQUE ("name");



ALTER TABLE ONLY "public"."division_electoral_district"
    ADD CONSTRAINT "division_electoral_district_pkey" PRIMARY KEY ("name");



ALTER TABLE ONLY "public"."events"
    ADD CONSTRAINT "events_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."events_sync_config"
    ADD CONSTRAINT "events_sync_config_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."feature_permissions"
    ADD CONSTRAINT "feature_permissions_feature_id_role_id_key" UNIQUE ("feature_id", "role_id");



ALTER TABLE ONLY "public"."feature_permissions"
    ADD CONSTRAINT "feature_permissions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."features"
    ADD CONSTRAINT "features_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."organizer_tags"
    ADD CONSTRAINT "organizer_tags_pkey" PRIMARY KEY ("tag");



ALTER TABLE ONLY "public"."page_questions"
    ADD CONSTRAINT "page_questions_page_question_unique" UNIQUE ("page_id", "question_id");



ALTER TABLE ONLY "public"."page_questions"
    ADD CONSTRAINT "page_questions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."permission_audit_log"
    ADD CONSTRAINT "permission_audit_log_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."profile_campus_club_access"
    ADD CONSTRAINT "profile_campus_club_access_pkey" PRIMARY KEY ("profile_id", "campus_club");



ALTER TABLE ONLY "public"."profile_organizer_tags"
    ADD CONSTRAINT "profile_organizer_tags_pkey" PRIMARY KEY ("profile_id", "tag");



ALTER TABLE ONLY "public"."profile_region_access"
    ADD CONSTRAINT "profile_region_access_pkey" PRIMARY KEY ("profile_id", "region");



ALTER TABLE ONLY "public"."profile_riding_access"
    ADD CONSTRAINT "profile_riding_access_pkey" PRIMARY KEY ("profile_id", "riding");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_email_key" UNIQUE ("email");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_organizer_tag_key" UNIQUE ("organizer_tag");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."request"
    ADD CONSTRAINT "requests_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."roles"
    ADD CONSTRAINT "roles_name_key" UNIQUE ("name");



ALTER TABLE ONLY "public"."roles"
    ADD CONSTRAINT "roles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."saved_filters"
    ADD CONSTRAINT "saved_filters_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."signup_requests"
    ADD CONSTRAINT "signup_requests_email_key" UNIQUE ("email");



ALTER TABLE ONLY "public"."signup_requests"
    ADD CONSTRAINT "signup_requests_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."survey_column_update_rules"
    ADD CONSTRAINT "survey_column_update_rules_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."survey_instances"
    ADD CONSTRAINT "survey_instances_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."survey_instances"
    ADD CONSTRAINT "survey_instances_token_key" UNIQUE ("token");



ALTER TABLE ONLY "public"."survey_page_assignments"
    ADD CONSTRAINT "survey_page_assignments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."survey_page_assignments"
    ADD CONSTRAINT "survey_page_assignments_survey_page_unique" UNIQUE ("survey_id", "page_number");



ALTER TABLE ONLY "public"."survey_pages"
    ADD CONSTRAINT "survey_pages_page_code_key" UNIQUE ("page_code");



ALTER TABLE ONLY "public"."survey_pages"
    ADD CONSTRAINT "survey_pages_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."survey_questions"
    ADD CONSTRAINT "survey_questions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."survey_response_answers"
    ADD CONSTRAINT "survey_response_answers_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."survey_response_answers"
    ADD CONSTRAINT "survey_response_answers_response_question_unique" UNIQUE ("response_id", "question_id");



ALTER TABLE ONLY "public"."survey_responses"
    ADD CONSTRAINT "survey_responses_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."survey_responses"
    ADD CONSTRAINT "survey_responses_survey_instance_id_unique" UNIQUE ("survey_instance_id");



COMMENT ON CONSTRAINT "survey_responses_survey_instance_id_unique" ON "public"."survey_responses" IS 'Ensures that each survey instance can only have one response. A contact can take the same survey multiple times (multiple instances), but each instance (session) should only have one response.';



ALTER TABLE ONLY "public"."surveys"
    ADD CONSTRAINT "surveys_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_column_preferences"
    ADD CONSTRAINT "user_column_preferences_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_column_preferences"
    ADD CONSTRAINT "user_column_preferences_user_route_column_unique" UNIQUE ("user_id", "route", "column_name", "custom_column_id");



ALTER TABLE ONLY "public"."user_expanded_sections"
    ADD CONSTRAINT "user_expanded_sections_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_expanded_sections"
    ADD CONSTRAINT "user_expanded_sections_user_route_section_unique" UNIQUE ("user_id", "route", "section_key");



ALTER TABLE ONLY "public"."user_filter_defaults"
    ADD CONSTRAINT "user_filter_defaults_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_filter_defaults"
    ADD CONSTRAINT "user_filter_defaults_user_route_unique" UNIQUE ("user_id", "route");



ALTER TABLE ONLY "public"."user_preferences"
    ADD CONSTRAINT "user_preferences_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_preferences"
    ADD CONSTRAINT "user_preferences_user_id_unique" UNIQUE ("user_id");



ALTER TABLE ONLY "public"."user_table_preferences"
    ADD CONSTRAINT "user_table_preferences_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_table_preferences"
    ADD CONSTRAINT "user_table_preferences_user_route_unique" UNIQUE ("user_id", "route");



ALTER TABLE ONLY "public"."view_column_visibility"
    ADD CONSTRAINT "view_column_visibility_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."view_column_visibility"
    ADD CONSTRAINT "view_column_visibility_view_column_unique" UNIQUE ("view_id", "column_name", "custom_column_id");



ALTER TABLE ONLY "public"."views"
    ADD CONSTRAINT "views_pkey" PRIMARY KEY ("id");



CREATE INDEX "action_logs_created_at_idx" ON "public"."action_logs" USING "btree" ("created_at" DESC);



CREATE INDEX "action_logs_entity_idx" ON "public"."action_logs" USING "btree" ("entity_type", "entity_id");



CREATE INDEX "action_logs_profile_created_idx" ON "public"."action_logs" USING "btree" ("profile_id", "created_at");



CREATE INDEX "api_logs_error_stack_idx" ON "public"."api_logs" USING "btree" ("error_stack");



CREATE INDEX "attachment_audit_log_attachment_id_idx" ON "public"."attachment_audit_log" USING "btree" ("attachment_id");



CREATE INDEX "attachment_audit_log_performed_at_idx" ON "public"."attachment_audit_log" USING "btree" ("performed_at");



CREATE INDEX "attachment_audit_log_performed_by_idx" ON "public"."attachment_audit_log" USING "btree" ("performed_by");



CREATE INDEX "audiences_created_by_idx" ON "public"."audiences" USING "btree" ("created_by");



CREATE INDEX "audiences_visibility_idx" ON "public"."audiences" USING "btree" ("visibility");



CREATE INDEX "campaigns_archived_idx" ON "public"."campaigns" USING "btree" ("archived");



CREATE INDEX "campaigns_campaign_type_content_id_idx" ON "public"."campaigns" USING "btree" ("campaign_type", "content_id");



CREATE INDEX "campaigns_created_by_idx" ON "public"."campaigns" USING "btree" ("created_by");



CREATE INDEX "campaigns_status_idx" ON "public"."campaigns" USING "btree" ("status");



CREATE INDEX "column_visibility_display_order_idx" ON "public"."column_visibility" USING "btree" ("display_order");



CREATE INDEX "column_visibility_global_display_order_idx" ON "public"."column_visibility" USING "btree" ("global_display_order");



CREATE INDEX "column_visibility_hidden_from_organizers_idx" ON "public"."column_visibility" USING "btree" ("hidden_from_organizers");



CREATE INDEX "contact_attachment_contact_id_idx" ON "public"."contact_attachment" USING "btree" ("contact_id");



CREATE INDEX "contact_attachment_deleted_at_idx" ON "public"."contact_attachment" USING "btree" ("deleted_at") WHERE ("deleted_at" IS NULL);



CREATE INDEX "contact_attachment_uploaded_by_idx" ON "public"."contact_attachment" USING "btree" ("uploaded_by");



CREATE INDEX "contact_campus_club_idx" ON "public"."contact" USING "btree" ("campus_club") WHERE ("campus_club" IS NOT NULL);



CREATE INDEX "contact_custom_fields_column_id_idx" ON "public"."contact_custom_fields" USING "btree" ("column_id");



CREATE INDEX "contact_custom_fields_contact_id_idx" ON "public"."contact_custom_fields" USING "btree" ("contact_id");



CREATE INDEX "contact_division_electoral_district_idx" ON "public"."contact" USING "btree" ("division_electoral_district") WHERE ("division_electoral_district" IS NOT NULL);



CREATE INDEX "contact_division_electoral_district_idx1" ON "public"."contact" USING "btree" ("division_electoral_district");



CREATE INDEX "contact_email_idx" ON "public"."contact" USING "btree" ("email") WHERE ("email" IS NOT NULL);



CREATE INDEX "contact_enrichment_contact_id_idx" ON "public"."contact_enrichment" USING "btree" ("contact_id");



CREATE INDEX "contact_enrichment_status_idx" ON "public"."contact_enrichment" USING "btree" ("status");



CREATE INDEX "contact_firstname_idx" ON "public"."contact" USING "btree" ("firstname") WHERE ("firstname" IS NOT NULL);



CREATE INDEX "contact_firstname_idx1" ON "public"."contact" USING "btree" ("firstname");



CREATE INDEX "contact_last_request_idx" ON "public"."contact" USING "btree" ("last_request");



CREATE INDEX "contact_name_search_idx" ON "public"."contact" USING "btree" ("firstname", "surname") WHERE (("firstname" IS NOT NULL) OR ("surname" IS NOT NULL));



CREATE INDEX "contact_note_contact_id_idx" ON "public"."contact_note" USING "btree" ("contact_id");



CREATE INDEX "contact_note_contact_pinned_idx" ON "public"."contact_note" USING "btree" ("contact_id", "is_pinned") WHERE ("is_pinned" = true);



CREATE INDEX "contact_note_created_by_idx" ON "public"."contact_note" USING "btree" ("created_by");



CREATE INDEX "contact_note_is_pinned_idx" ON "public"."contact_note" USING "btree" ("is_pinned");



CREATE INDEX "contact_organizer_idx" ON "public"."contact" USING "btree" ("organizer") WHERE ("organizer" IS NOT NULL);



CREATE INDEX "contact_organizer_idx1" ON "public"."contact" USING "btree" ("organizer");



CREATE INDEX "contact_phone_idx" ON "public"."contact" USING "btree" ("phone");



CREATE INDEX "contact_street_address_idx" ON "public"."contact" USING "btree" ("street_address");



CREATE INDEX "contact_surname_idx" ON "public"."contact" USING "btree" ("surname") WHERE ("surname" IS NOT NULL);



CREATE INDEX "contact_surname_idx1" ON "public"."contact" USING "btree" ("surname");



CREATE INDEX "contact_updated_at_idx" ON "public"."contact" USING "btree" ("updated_at");



CREATE INDEX "contact_voting_history_contact_id_idx" ON "public"."contact_voting_history" USING "btree" ("contact_id");



CREATE INDEX "custom_columns_display_order_idx" ON "public"."custom_columns" USING "btree" ("display_order");



CREATE INDEX "custom_columns_global_display_order_idx" ON "public"."custom_columns" USING "btree" ("global_display_order");



CREATE INDEX "custom_columns_hidden_from_organizers_idx" ON "public"."custom_columns" USING "btree" ("hidden_from_organizers");



CREATE INDEX "custom_columns_name_idx" ON "public"."custom_columns" USING "btree" ("name");



CREATE INDEX "data_access_field_permissions_column_name_idx" ON "public"."data_access_field_permissions" USING "btree" ("column_name");



CREATE INDEX "data_access_field_permissions_custom_column_id_idx" ON "public"."data_access_field_permissions" USING "btree" ("custom_column_id");



CREATE INDEX "data_access_field_permissions_role_idx" ON "public"."data_access_field_permissions" USING "btree" ("role");



CREATE INDEX "data_access_record_permissions_role_idx" ON "public"."data_access_record_permissions" USING "btree" ("role");



CREATE INDEX "data_access_record_permissions_type_scope_idx" ON "public"."data_access_record_permissions" USING "btree" ("permission_type", "permission_scope");



CREATE INDEX "events_category_idx" ON "public"."events" USING "btree" ("category");



CREATE INDEX "events_composite_idx" ON "public"."events" USING "btree" ("is_external", "status", "start_date");



CREATE INDEX "events_is_external_idx" ON "public"."events" USING "btree" ("is_external");



CREATE INDEX "events_source_idx" ON "public"."events" USING "btree" ("source");



CREATE INDEX "events_start_date_idx" ON "public"."events" USING "btree" ("start_date");



CREATE INDEX "events_status_idx" ON "public"."events" USING "btree" ("status");



CREATE INDEX "feature_permissions_feature_idx" ON "public"."feature_permissions" USING "btree" ("feature_id");



CREATE INDEX "feature_permissions_role_idx" ON "public"."feature_permissions" USING "btree" ("role_id");



CREATE INDEX "idx_api_logs_created_at" ON "public"."api_logs" USING "btree" ("created_at" DESC);



CREATE INDEX "idx_api_logs_profile_id" ON "public"."api_logs" USING "btree" ("profile_id") WHERE ("profile_id" IS NOT NULL);



CREATE INDEX "idx_api_logs_request_id" ON "public"."api_logs" USING "btree" ("request_id");



CREATE INDEX "idx_api_logs_status" ON "public"."api_logs" USING "btree" ("status") WHERE ("status" >= 400);



CREATE INDEX "idx_api_logs_token_id" ON "public"."api_logs" USING "btree" ("token_id") WHERE ("token_id" IS NOT NULL);



CREATE INDEX "idx_api_tokens_is_active" ON "public"."api_tokens" USING "btree" ("is_active") WHERE ("is_active" = true);



CREATE INDEX "idx_api_tokens_profile_id" ON "public"."api_tokens" USING "btree" ("profile_id");



CREATE INDEX "idx_api_tokens_token_hash" ON "public"."api_tokens" USING "btree" ("token_hash");



CREATE INDEX "idx_contact_location" ON "public"."contact" USING "gist" ("location");



CREATE INDEX "idx_contact_research_status" ON "public"."contact" USING "btree" ("research_status") WHERE ("research_status" IS NOT NULL);



CREATE INDEX "idx_contact_research_updated_at" ON "public"."contact" USING "btree" ("research_updated_at") WHERE ("research_updated_at" IS NOT NULL);



CREATE INDEX "idx_request_contact_id" ON "public"."request" USING "btree" ("contact_id");



CREATE INDEX "page_questions_page_id_idx" ON "public"."page_questions" USING "btree" ("page_id");



CREATE INDEX "page_questions_page_order_idx" ON "public"."page_questions" USING "btree" ("page_id", "question_order");



CREATE INDEX "page_questions_question_id_idx" ON "public"."page_questions" USING "btree" ("question_id");



CREATE INDEX "permission_audit_log_changed_by_idx" ON "public"."permission_audit_log" USING "btree" ("changed_by");



CREATE INDEX "permission_audit_log_created_at_idx" ON "public"."permission_audit_log" USING "btree" ("created_at");



CREATE INDEX "permission_audit_log_entity_idx" ON "public"."permission_audit_log" USING "btree" ("entity_type", "entity_id");



CREATE INDEX "profiles_last_seen_at_idx" ON "public"."profiles" USING "btree" ("last_seen_at");



CREATE INDEX "request_created_at_idx" ON "public"."request" USING "btree" ("created_at");



CREATE INDEX "survey_column_update_rules_enabled_priority_idx" ON "public"."survey_column_update_rules" USING "btree" ("enabled", "priority");



CREATE INDEX "survey_column_update_rules_question_id_idx" ON "public"."survey_column_update_rules" USING "btree" ("question_id");



CREATE INDEX "survey_column_update_rules_survey_id_idx" ON "public"."survey_column_update_rules" USING "btree" ("survey_id");



CREATE INDEX "survey_instances_campaign_id_idx" ON "public"."survey_instances" USING "btree" ("campaign_id");



CREATE INDEX "survey_instances_contact_id_idx" ON "public"."survey_instances" USING "btree" ("contact_id");



CREATE INDEX "survey_instances_contact_survey_idx" ON "public"."survey_instances" USING "btree" ("contact_id", "survey_id");



CREATE INDEX "survey_instances_survey_id_idx" ON "public"."survey_instances" USING "btree" ("survey_id");



CREATE INDEX "survey_instances_token_idx" ON "public"."survey_instances" USING "btree" ("token");



CREATE INDEX "survey_page_assignments_page_id_idx" ON "public"."survey_page_assignments" USING "btree" ("page_id");



CREATE INDEX "survey_page_assignments_survey_id_idx" ON "public"."survey_page_assignments" USING "btree" ("survey_id");



CREATE INDEX "survey_page_assignments_survey_page_idx" ON "public"."survey_page_assignments" USING "btree" ("survey_id", "page_number");



CREATE INDEX "survey_page_assignments_visible_to_roles_idx" ON "public"."survey_page_assignments" USING "gin" ("visible_to_roles");



CREATE INDEX "survey_pages_archived_idx" ON "public"."survey_pages" USING "btree" ("archived");



CREATE INDEX "survey_pages_created_by_idx" ON "public"."survey_pages" USING "btree" ("created_by");



CREATE INDEX "survey_pages_page_code_idx" ON "public"."survey_pages" USING "btree" ("page_code");



CREATE INDEX "survey_pages_visible_to_roles_idx" ON "public"."survey_pages" USING "gin" ("visible_to_roles");



CREATE INDEX "survey_questions_archived_idx" ON "public"."survey_questions" USING "btree" ("archived");



CREATE INDEX "survey_questions_created_by_idx" ON "public"."survey_questions" USING "btree" ("created_by");



CREATE UNIQUE INDEX "survey_questions_question_code_idx" ON "public"."survey_questions" USING "btree" ("question_code") WHERE ("question_code" IS NOT NULL);



CREATE INDEX "survey_questions_visible_to_roles_idx" ON "public"."survey_questions" USING "gin" ("visible_to_roles");



CREATE INDEX "survey_response_answers_question_id_idx" ON "public"."survey_response_answers" USING "btree" ("question_id");



CREATE INDEX "survey_response_answers_response_id_idx" ON "public"."survey_response_answers" USING "btree" ("response_id");



CREATE INDEX "survey_responses_channel_idx" ON "public"."survey_responses" USING "btree" ("channel");



CREATE INDEX "survey_responses_column_updates_status_idx" ON "public"."survey_responses" USING "btree" ("column_updates_status", "completed_at") WHERE (("status" = 'completed'::"text") AND ("column_updates_status" = 'pending'::"text"));



CREATE INDEX "survey_responses_contact_id_idx" ON "public"."survey_responses" USING "btree" ("contact_id");



CREATE INDEX "survey_responses_survey_id_idx" ON "public"."survey_responses" USING "btree" ("survey_id");



CREATE INDEX "survey_responses_survey_instance_id_idx" ON "public"."survey_responses" USING "btree" ("survey_instance_id");



CREATE INDEX "surveys_archived_idx" ON "public"."surveys" USING "btree" ("archived");



CREATE INDEX "surveys_created_by_idx" ON "public"."surveys" USING "btree" ("created_by");



CREATE INDEX "surveys_status_idx" ON "public"."surveys" USING "btree" ("status");



CREATE INDEX "surveys_visible_to_roles_idx" ON "public"."surveys" USING "gin" ("visible_to_roles");



CREATE INDEX "user_column_preferences_column_name_idx" ON "public"."user_column_preferences" USING "btree" ("column_name");



CREATE INDEX "user_column_preferences_custom_column_id_idx" ON "public"."user_column_preferences" USING "btree" ("custom_column_id");



CREATE INDEX "user_column_preferences_route_idx" ON "public"."user_column_preferences" USING "btree" ("route");



CREATE INDEX "user_column_preferences_user_id_idx" ON "public"."user_column_preferences" USING "btree" ("user_id");



CREATE INDEX "user_column_preferences_user_route_idx" ON "public"."user_column_preferences" USING "btree" ("user_id", "route");



CREATE INDEX "user_expanded_sections_route_idx" ON "public"."user_expanded_sections" USING "btree" ("route");



CREATE INDEX "user_expanded_sections_user_id_idx" ON "public"."user_expanded_sections" USING "btree" ("user_id");



CREATE INDEX "user_expanded_sections_user_route_idx" ON "public"."user_expanded_sections" USING "btree" ("user_id", "route");



CREATE INDEX "user_filter_defaults_route_idx" ON "public"."user_filter_defaults" USING "btree" ("route");



CREATE INDEX "user_filter_defaults_user_id_idx" ON "public"."user_filter_defaults" USING "btree" ("user_id");



CREATE INDEX "user_filter_defaults_user_route_idx" ON "public"."user_filter_defaults" USING "btree" ("user_id", "route");



CREATE INDEX "user_table_preferences_route_idx" ON "public"."user_table_preferences" USING "btree" ("route");



CREATE INDEX "user_table_preferences_user_id_idx" ON "public"."user_table_preferences" USING "btree" ("user_id");



CREATE INDEX "user_table_preferences_user_route_idx" ON "public"."user_table_preferences" USING "btree" ("user_id", "route");



CREATE INDEX "user_view_preferences_current_view_id_idx" ON "public"."user_preferences" USING "btree" ("current_view_id");



CREATE INDEX "user_view_preferences_user_id_idx" ON "public"."user_preferences" USING "btree" ("user_id");



CREATE INDEX "view_column_visibility_column_name_idx" ON "public"."view_column_visibility" USING "btree" ("column_name");



CREATE INDEX "view_column_visibility_custom_column_id_idx" ON "public"."view_column_visibility" USING "btree" ("custom_column_id");



CREATE INDEX "view_column_visibility_display_order_idx" ON "public"."view_column_visibility" USING "btree" ("view_id", "display_order");



CREATE INDEX "view_column_visibility_view_id_idx" ON "public"."view_column_visibility" USING "btree" ("view_id");



CREATE INDEX "views_created_by_idx" ON "public"."views" USING "btree" ("created_by");



CREATE INDEX "views_is_default_idx" ON "public"."views" USING "btree" ("is_default");



CREATE INDEX "views_is_shared_idx" ON "public"."views" USING "btree" ("is_shared");



CREATE OR REPLACE TRIGGER "ensure_single_pinned_note" BEFORE INSERT OR UPDATE ON "public"."contact_note" FOR EACH ROW EXECUTE FUNCTION "public"."ensure_single_pinned_note"();



CREATE OR REPLACE TRIGGER "log_attachment_deletion" AFTER UPDATE ON "public"."contact_attachment" FOR EACH ROW EXECUTE FUNCTION "public"."log_attachment_deletion"();



CREATE OR REPLACE TRIGGER "prevent_sensitive_profile_updates_trigger" BEFORE UPDATE ON "public"."profiles" FOR EACH ROW EXECUTE FUNCTION "public"."prevent_sensitive_profile_updates"();



CREATE OR REPLACE TRIGGER "trigger_location_lookup_on_address_change" AFTER INSERT OR UPDATE OF "postcode", "street_address" ON "public"."contact" FOR EACH ROW WHEN ((("new"."postcode" IS NOT NULL) AND (TRIM(BOTH FROM "new"."postcode") <> ''::"text"))) EXECUTE FUNCTION "public"."trigger_location_lookup"();



CREATE OR REPLACE TRIGGER "update_audiences_updated_at" BEFORE UPDATE ON "public"."audiences" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_campaigns_updated_at" BEFORE UPDATE ON "public"."campaigns" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_column_visibility_updated_at" BEFORE UPDATE ON "public"."column_visibility" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_contact_custom_fields_updated_at" BEFORE UPDATE ON "public"."contact_custom_fields" FOR EACH ROW EXECUTE FUNCTION "public"."update_contact_custom_fields_updated_at"();



CREATE OR REPLACE TRIGGER "update_contact_enrichment_updated_at" BEFORE UPDATE ON "public"."contact_enrichment" FOR EACH ROW EXECUTE FUNCTION "public"."update_contact_enrichment_updated_at"();



CREATE OR REPLACE TRIGGER "update_contact_location_trigger" BEFORE INSERT OR UPDATE OF "latitude", "longitude" ON "public"."contact" FOR EACH ROW EXECUTE FUNCTION "public"."update_contact_location"();



CREATE OR REPLACE TRIGGER "update_contact_note_updated_at" BEFORE UPDATE ON "public"."contact_note" FOR EACH ROW EXECUTE FUNCTION "public"."update_contact_note_updated_at"();



CREATE OR REPLACE TRIGGER "update_contact_updated_at" BEFORE INSERT OR UPDATE ON "public"."contact" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_custom_columns_updated_at" BEFORE UPDATE ON "public"."custom_columns" FOR EACH ROW EXECUTE FUNCTION "public"."update_custom_columns_updated_at"();



CREATE OR REPLACE TRIGGER "update_data_access_field_permissions_updated_at" BEFORE UPDATE ON "public"."data_access_field_permissions" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_data_access_record_permissions_updated_at" BEFORE UPDATE ON "public"."data_access_record_permissions" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_events_sync_config_updated_at" BEFORE UPDATE ON "public"."events_sync_config" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_events_updated_at" BEFORE UPDATE ON "public"."events" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_page_questions_updated_at" BEFORE UPDATE ON "public"."page_questions" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_survey_column_update_rules_updated_at" BEFORE UPDATE ON "public"."survey_column_update_rules" FOR EACH ROW EXECUTE FUNCTION "public"."update_survey_column_update_rules_updated_at"();



CREATE OR REPLACE TRIGGER "update_survey_instances_updated_at" BEFORE UPDATE ON "public"."survey_instances" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_survey_page_assignments_updated_at" BEFORE UPDATE ON "public"."survey_page_assignments" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_survey_pages_updated_at" BEFORE UPDATE ON "public"."survey_pages" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_survey_questions_updated_at" BEFORE UPDATE ON "public"."survey_questions" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_survey_response_answers_updated_at" BEFORE UPDATE ON "public"."survey_response_answers" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_survey_responses_updated_at" BEFORE UPDATE ON "public"."survey_responses" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_surveys_updated_at" BEFORE UPDATE ON "public"."surveys" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_user_column_preferences_updated_at" BEFORE UPDATE ON "public"."user_column_preferences" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_user_expanded_sections_updated_at" BEFORE UPDATE ON "public"."user_expanded_sections" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_user_filter_defaults_updated_at" BEFORE UPDATE ON "public"."user_filter_defaults" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_user_preferences_updated_at" BEFORE UPDATE ON "public"."user_preferences" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_user_table_preferences_updated_at" BEFORE UPDATE ON "public"."user_table_preferences" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_view_column_visibility_updated_at" BEFORE UPDATE ON "public"."view_column_visibility" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_views_updated_at" BEFORE UPDATE ON "public"."views" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "validate_attachment_update" BEFORE UPDATE ON "public"."contact_attachment" FOR EACH ROW EXECUTE FUNCTION "public"."validate_attachment_update"();



ALTER TABLE ONLY "public"."action_logs"
    ADD CONSTRAINT "action_logs_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."api_logs"
    ADD CONSTRAINT "api_logs_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."api_logs"
    ADD CONSTRAINT "api_logs_token_id_fkey" FOREIGN KEY ("token_id") REFERENCES "public"."api_tokens"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."api_tokens"
    ADD CONSTRAINT "api_tokens_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."profiles"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."api_tokens"
    ADD CONSTRAINT "api_tokens_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."attachment_audit_log"
    ADD CONSTRAINT "attachment_audit_log_attachment_id_fkey" FOREIGN KEY ("attachment_id") REFERENCES "public"."contact_attachment"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."attachment_audit_log"
    ADD CONSTRAINT "attachment_audit_log_performed_by_fkey" FOREIGN KEY ("performed_by") REFERENCES "public"."profiles"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."audiences"
    ADD CONSTRAINT "audiences_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."campaigns"
    ADD CONSTRAINT "campaigns_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."contact_attachment"
    ADD CONSTRAINT "contact_attachment_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "public"."contact"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."contact_attachment"
    ADD CONSTRAINT "contact_attachment_deleted_by_fkey" FOREIGN KEY ("deleted_by") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."contact_attachment"
    ADD CONSTRAINT "contact_attachment_uploaded_by_fkey" FOREIGN KEY ("uploaded_by") REFERENCES "public"."profiles"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."contact_custom_fields"
    ADD CONSTRAINT "contact_custom_fields_column_id_fkey" FOREIGN KEY ("column_id") REFERENCES "public"."custom_columns"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."contact_custom_fields"
    ADD CONSTRAINT "contact_custom_fields_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "public"."contact"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."contact_enrichment"
    ADD CONSTRAINT "contact_enrichment_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "public"."contact"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."contact"
    ADD CONSTRAINT "contact_last_request_fkey" FOREIGN KEY ("last_request") REFERENCES "public"."request"("id") ON UPDATE CASCADE;



ALTER TABLE ONLY "public"."contact_note"
    ADD CONSTRAINT "contact_note_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "public"."contact"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."contact_note"
    ADD CONSTRAINT "contact_note_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."profiles"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."contact_note"
    ADD CONSTRAINT "contact_note_updated_by_fkey" FOREIGN KEY ("updated_by") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."contact_voting_history"
    ADD CONSTRAINT "contact_voting_history_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "public"."contact"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."contact_voting_history"
    ADD CONSTRAINT "contact_voting_history_marked_by_fkey" FOREIGN KEY ("marked_by") REFERENCES "public"."profiles"("id") ON UPDATE CASCADE ON DELETE SET NULL;



ALTER TABLE ONLY "public"."custom_columns"
    ADD CONSTRAINT "custom_columns_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."profiles"("id") ON UPDATE CASCADE ON DELETE SET NULL;



ALTER TABLE ONLY "public"."data_access_field_permissions"
    ADD CONSTRAINT "data_access_field_permissions_custom_column_id_fkey" FOREIGN KEY ("custom_column_id") REFERENCES "public"."custom_columns"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."feature_permissions"
    ADD CONSTRAINT "feature_permissions_feature_id_fkey" FOREIGN KEY ("feature_id") REFERENCES "public"."features"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."feature_permissions"
    ADD CONSTRAINT "feature_permissions_role_id_fkey" FOREIGN KEY ("role_id") REFERENCES "public"."roles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."organizer_tags"
    ADD CONSTRAINT "organizer_tags_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."page_questions"
    ADD CONSTRAINT "page_questions_page_id_fkey" FOREIGN KEY ("page_id") REFERENCES "public"."survey_pages"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."page_questions"
    ADD CONSTRAINT "page_questions_question_id_fkey" FOREIGN KEY ("question_id") REFERENCES "public"."survey_questions"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."permission_audit_log"
    ADD CONSTRAINT "permission_audit_log_changed_by_fkey" FOREIGN KEY ("changed_by") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."profile_campus_club_access"
    ADD CONSTRAINT "profile_campus_club_access_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."profile_organizer_tags"
    ADD CONSTRAINT "profile_organizer_tags_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."profile_organizer_tags"
    ADD CONSTRAINT "profile_organizer_tags_tag_fkey" FOREIGN KEY ("tag") REFERENCES "public"."organizer_tags"("tag") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."profile_region_access"
    ADD CONSTRAINT "profile_region_access_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."profile_riding_access"
    ADD CONSTRAINT "profile_riding_access_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."profile_riding_access"
    ADD CONSTRAINT "profile_riding_access_riding_fkey" FOREIGN KEY ("riding") REFERENCES "public"."division_electoral_district"("name") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."request"
    ADD CONSTRAINT "request_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "public"."contact"("id") ON UPDATE CASCADE ON DELETE SET NULL;



ALTER TABLE ONLY "public"."saved_filters"
    ADD CONSTRAINT "saved_filters_owner_id_fkey" FOREIGN KEY ("owner_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."signup_requests"
    ADD CONSTRAINT "signup_requests_invited_by_fkey" FOREIGN KEY ("invited_by") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."signup_requests"
    ADD CONSTRAINT "signup_requests_reviewer_id_fkey" FOREIGN KEY ("reviewer_id") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."survey_column_update_rules"
    ADD CONSTRAINT "survey_column_update_rules_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."survey_column_update_rules"
    ADD CONSTRAINT "survey_column_update_rules_question_id_fkey" FOREIGN KEY ("question_id") REFERENCES "public"."survey_questions"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."survey_column_update_rules"
    ADD CONSTRAINT "survey_column_update_rules_survey_id_fkey" FOREIGN KEY ("survey_id") REFERENCES "public"."surveys"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."survey_column_update_rules"
    ADD CONSTRAINT "survey_column_update_rules_updated_by_fkey" FOREIGN KEY ("updated_by") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."survey_instances"
    ADD CONSTRAINT "survey_instances_campaign_id_fkey" FOREIGN KEY ("campaign_id") REFERENCES "public"."campaigns"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."survey_instances"
    ADD CONSTRAINT "survey_instances_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "public"."contact"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."survey_instances"
    ADD CONSTRAINT "survey_instances_sent_by_fkey" FOREIGN KEY ("sent_by") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."survey_instances"
    ADD CONSTRAINT "survey_instances_survey_id_fkey" FOREIGN KEY ("survey_id") REFERENCES "public"."surveys"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."survey_page_assignments"
    ADD CONSTRAINT "survey_page_assignments_page_id_fkey" FOREIGN KEY ("page_id") REFERENCES "public"."survey_pages"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."survey_page_assignments"
    ADD CONSTRAINT "survey_page_assignments_survey_id_fkey" FOREIGN KEY ("survey_id") REFERENCES "public"."surveys"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."survey_pages"
    ADD CONSTRAINT "survey_pages_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."survey_questions"
    ADD CONSTRAINT "survey_questions_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."survey_response_answers"
    ADD CONSTRAINT "survey_response_answers_question_id_fkey" FOREIGN KEY ("question_id") REFERENCES "public"."survey_questions"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."survey_response_answers"
    ADD CONSTRAINT "survey_response_answers_response_id_fkey" FOREIGN KEY ("response_id") REFERENCES "public"."survey_responses"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."survey_responses"
    ADD CONSTRAINT "survey_responses_column_updates_reviewed_by_fkey" FOREIGN KEY ("column_updates_reviewed_by") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."survey_responses"
    ADD CONSTRAINT "survey_responses_contact_id_fkey" FOREIGN KEY ("contact_id") REFERENCES "public"."contact"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."survey_responses"
    ADD CONSTRAINT "survey_responses_survey_id_fkey" FOREIGN KEY ("survey_id") REFERENCES "public"."surveys"("id") ON DELETE RESTRICT;



ALTER TABLE ONLY "public"."survey_responses"
    ADD CONSTRAINT "survey_responses_survey_instance_id_fkey" FOREIGN KEY ("survey_instance_id") REFERENCES "public"."survey_instances"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."surveys"
    ADD CONSTRAINT "surveys_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."user_column_preferences"
    ADD CONSTRAINT "user_column_preferences_custom_column_id_fkey" FOREIGN KEY ("custom_column_id") REFERENCES "public"."custom_columns"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_column_preferences"
    ADD CONSTRAINT "user_column_preferences_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_expanded_sections"
    ADD CONSTRAINT "user_expanded_sections_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_filter_defaults"
    ADD CONSTRAINT "user_filter_defaults_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_preferences"
    ADD CONSTRAINT "user_preferences_current_view_id_fkey" FOREIGN KEY ("current_view_id") REFERENCES "public"."views"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."user_preferences"
    ADD CONSTRAINT "user_preferences_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_table_preferences"
    ADD CONSTRAINT "user_table_preferences_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."view_column_visibility"
    ADD CONSTRAINT "view_column_visibility_custom_column_id_fkey" FOREIGN KEY ("custom_column_id") REFERENCES "public"."custom_columns"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."view_column_visibility"
    ADD CONSTRAINT "view_column_visibility_view_id_fkey" FOREIGN KEY ("view_id") REFERENCES "public"."views"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."views"
    ADD CONSTRAINT "views_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."profiles"("id") ON UPDATE CASCADE ON DELETE SET NULL;



CREATE POLICY "Allow authenticated read access scopes" ON "public"."profile_organizer_tags" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "profile_id"));



CREATE POLICY "Allow authenticated read campus access" ON "public"."profile_campus_club_access" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "profile_id"));



CREATE POLICY "Allow authenticated read organizer tags" ON "public"."organizer_tags" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Allow authenticated read own profile" ON "public"."profiles" FOR SELECT USING (("auth"."uid"() = "id"));



CREATE POLICY "Allow authenticated read region access" ON "public"."profile_region_access" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "profile_id"));



CREATE POLICY "Allow authenticated read riding access" ON "public"."profile_riding_access" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "profile_id"));



CREATE POLICY "Allow authenticated read saved filters" ON "public"."saved_filters" FOR SELECT TO "authenticated" USING ((("owner_id" = "auth"."uid"()) OR ("visibility" = 'team'::"public"."filter_visibility")));



CREATE POLICY "Allow authenticated update own profile" ON "public"."profiles" FOR UPDATE TO "authenticated" USING (("auth"."uid"() = "id")) WITH CHECK (("auth"."uid"() = "id"));



CREATE POLICY "Allow service manage access tables" ON "public"."profile_organizer_tags" TO "service_role" USING (true) WITH CHECK (true);



CREATE POLICY "Allow service manage access tables regions" ON "public"."profile_region_access" TO "service_role" USING (true) WITH CHECK (true);



CREATE POLICY "Allow service manage access tables ridings" ON "public"."profile_riding_access" TO "service_role" USING (true) WITH CHECK (true);



CREATE POLICY "Allow service manage campus club access" ON "public"."profile_campus_club_access" TO "service_role" USING (true) WITH CHECK (true);



CREATE POLICY "Allow service manage profiles" ON "public"."profiles" TO "service_role" USING (true) WITH CHECK (true);



CREATE POLICY "Allow service manage saved filters" ON "public"."saved_filters" TO "service_role" USING (true) WITH CHECK (true);



CREATE POLICY "Allow service manage signup requests" ON "public"."signup_requests" TO "service_role" USING (true) WITH CHECK (true);



CREATE POLICY "Only super_admins can create tokens" ON "public"."api_tokens" FOR INSERT TO "authenticated" WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = 'super_admin'::"public"."role_type")))));



CREATE POLICY "Users can delete own tokens, super_admins can delete any" ON "public"."api_tokens" FOR DELETE TO "authenticated" USING ((("profile_id" = "auth"."uid"()) OR (EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = 'super_admin'::"public"."role_type"))))));



CREATE POLICY "Users can update own tokens, super_admins can update any" ON "public"."api_tokens" FOR UPDATE TO "authenticated" USING ((("profile_id" = "auth"."uid"()) OR (EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = 'super_admin'::"public"."role_type")))))) WITH CHECK ((("profile_id" = "auth"."uid"()) OR (EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = 'super_admin'::"public"."role_type"))))));



CREATE POLICY "Users can view logs for own tokens, super_admins can view all" ON "public"."api_logs" FOR SELECT TO "authenticated" USING (((("token_id" IS NOT NULL) AND (EXISTS ( SELECT 1
   FROM "public"."api_tokens"
  WHERE (("api_tokens"."id" = "api_logs"."token_id") AND ("api_tokens"."profile_id" = "auth"."uid"()))))) OR (("token_id" IS NULL) AND ("profile_id" = "auth"."uid"())) OR (EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = 'super_admin'::"public"."role_type"))))));



CREATE POLICY "Users can view own tokens, super_admins can view all" ON "public"."api_tokens" FOR SELECT TO "authenticated" USING ((("profile_id" = "auth"."uid"()) OR (EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = 'super_admin'::"public"."role_type"))))));



ALTER TABLE "public"."action_logs" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "action_logs_authenticated_read" ON "public"."action_logs" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "action_logs_service_role_all" ON "public"."action_logs" TO "service_role" USING (true) WITH CHECK (true);



CREATE POLICY "allow admin delete custom_columns" ON "public"."custom_columns" FOR DELETE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "auth"."uid"()) AND ("p"."role" = ANY (ARRAY['super_admin'::"public"."role_type", 'admin'::"public"."role_type"]))))));



CREATE POLICY "allow admin insert custom_columns" ON "public"."custom_columns" FOR INSERT TO "authenticated" WITH CHECK (((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "auth"."uid"()) AND ("p"."role" = ANY (ARRAY['super_admin'::"public"."role_type", 'admin'::"public"."role_type"]))))) AND ("created_by" = "auth"."uid"())));



CREATE POLICY "allow admin manage audiences" ON "public"."audiences" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['super_admin'::"public"."role_type", 'admin'::"public"."role_type"])))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['super_admin'::"public"."role_type", 'admin'::"public"."role_type"]))))));



CREATE POLICY "allow admin manage campaigns" ON "public"."campaigns" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['super_admin'::"public"."role_type", 'admin'::"public"."role_type"])))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['super_admin'::"public"."role_type", 'admin'::"public"."role_type"]))))));



CREATE POLICY "allow admin manage events" ON "public"."events" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['super_admin'::"public"."role_type", 'admin'::"public"."role_type"])))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['super_admin'::"public"."role_type", 'admin'::"public"."role_type"]))))));



CREATE POLICY "allow admin manage field_permissions" ON "public"."data_access_field_permissions" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['super_admin'::"public"."role_type", 'admin'::"public"."role_type"])))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['super_admin'::"public"."role_type", 'admin'::"public"."role_type"]))))));



CREATE POLICY "allow admin manage page_questions" ON "public"."page_questions" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['super_admin'::"public"."role_type", 'admin'::"public"."role_type"]))))));



CREATE POLICY "allow admin manage record_permissions" ON "public"."data_access_record_permissions" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['super_admin'::"public"."role_type", 'admin'::"public"."role_type"])))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['super_admin'::"public"."role_type", 'admin'::"public"."role_type"]))))));



CREATE POLICY "allow admin manage survey_column_update_rules" ON "public"."survey_column_update_rules" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['super_admin'::"public"."role_type", 'admin'::"public"."role_type"])))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['super_admin'::"public"."role_type", 'admin'::"public"."role_type"]))))));



CREATE POLICY "allow admin manage survey_instances" ON "public"."survey_instances" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['super_admin'::"public"."role_type", 'admin'::"public"."role_type"])))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['super_admin'::"public"."role_type", 'admin'::"public"."role_type"]))))));



CREATE POLICY "allow admin manage survey_page_assignments" ON "public"."survey_page_assignments" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['super_admin'::"public"."role_type", 'admin'::"public"."role_type"])))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['super_admin'::"public"."role_type", 'admin'::"public"."role_type"]))))));



CREATE POLICY "allow admin manage survey_pages" ON "public"."survey_pages" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['super_admin'::"public"."role_type", 'admin'::"public"."role_type"])))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['super_admin'::"public"."role_type", 'admin'::"public"."role_type"]))))));



CREATE POLICY "allow admin manage survey_questions" ON "public"."survey_questions" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['super_admin'::"public"."role_type", 'admin'::"public"."role_type"])))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['super_admin'::"public"."role_type", 'admin'::"public"."role_type"]))))));



CREATE POLICY "allow admin manage survey_response_answers" ON "public"."survey_response_answers" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['super_admin'::"public"."role_type", 'admin'::"public"."role_type"])))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['super_admin'::"public"."role_type", 'admin'::"public"."role_type"]))))));



CREATE POLICY "allow admin manage survey_responses" ON "public"."survey_responses" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['super_admin'::"public"."role_type", 'admin'::"public"."role_type"])))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['super_admin'::"public"."role_type", 'admin'::"public"."role_type"]))))));



CREATE POLICY "allow admin manage surveys" ON "public"."surveys" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['super_admin'::"public"."role_type", 'admin'::"public"."role_type"])))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['super_admin'::"public"."role_type", 'admin'::"public"."role_type"]))))));



CREATE POLICY "allow admin manage view_column_visibility" ON "public"."view_column_visibility" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "auth"."uid"()) AND ("p"."role" = ANY (ARRAY['super_admin'::"public"."role_type", 'admin'::"public"."role_type"])))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "auth"."uid"()) AND ("p"."role" = ANY (ARRAY['super_admin'::"public"."role_type", 'admin'::"public"."role_type"]))))));



CREATE POLICY "allow admin manage views" ON "public"."views" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['super_admin'::"public"."role_type", 'admin'::"public"."role_type"])))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['super_admin'::"public"."role_type", 'admin'::"public"."role_type"]))))));



CREATE POLICY "allow admin modify column_visibility" ON "public"."column_visibility" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "auth"."uid"()) AND ("p"."role" = ANY (ARRAY['super_admin'::"public"."role_type", 'admin'::"public"."role_type"]))))));



CREATE POLICY "allow admin read column preferences" ON "public"."user_column_preferences" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['super_admin'::"public"."role_type", 'admin'::"public"."role_type"]))))));



CREATE POLICY "allow admin read expanded sections" ON "public"."user_expanded_sections" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['super_admin'::"public"."role_type", 'admin'::"public"."role_type"]))))));



CREATE POLICY "allow admin read filter defaults" ON "public"."user_filter_defaults" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['super_admin'::"public"."role_type", 'admin'::"public"."role_type"]))))));



CREATE POLICY "allow admin read preferences" ON "public"."user_preferences" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['super_admin'::"public"."role_type", 'admin'::"public"."role_type"]))))));



CREATE POLICY "allow admin read table preferences" ON "public"."user_table_preferences" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles"
  WHERE (("profiles"."id" = "auth"."uid"()) AND ("profiles"."role" = ANY (ARRAY['super_admin'::"public"."role_type", 'admin'::"public"."role_type"]))))));



CREATE POLICY "allow admin update custom_columns" ON "public"."custom_columns" FOR UPDATE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "auth"."uid"()) AND ("p"."role" = ANY (ARRAY['super_admin'::"public"."role_type", 'admin'::"public"."role_type"]))))));



CREATE POLICY "allow all actions for anon" ON "public"."contact" TO "anon" USING (true) WITH CHECK (true);



CREATE POLICY "allow all actions for anon" ON "public"."request" TO "anon" USING (true) WITH CHECK (true);



CREATE POLICY "allow authenticated contacts by tag" ON "public"."contact" FOR SELECT TO "authenticated" USING ((("organizer" IS NOT NULL) AND ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "auth"."uid"()) AND ("p"."organizer_tag" IS NOT NULL) AND ("contact"."organizer" ~~* (('%'::"text" || "p"."organizer_tag") || '%'::"text"))))) OR (EXISTS ( SELECT 1
   FROM "public"."profile_organizer_tags" "pot"
  WHERE (("pot"."profile_id" = "auth"."uid"()) AND ("pot"."tag" IS NOT NULL) AND ("contact"."organizer" ~~* (('%'::"text" || "pot"."tag") || '%'::"text"))))))));



CREATE POLICY "allow authenticated insert voting history" ON "public"."contact_voting_history" FOR INSERT TO "authenticated" WITH CHECK (((EXISTS ( SELECT 1
   FROM "public"."contact" "c"
  WHERE (("c"."id" = "contact_voting_history"."contact_id") AND ("c"."organizer" IS NOT NULL) AND ((EXISTS ( SELECT 1
           FROM "public"."profiles" "p"
          WHERE (("p"."id" = "auth"."uid"()) AND ("p"."organizer_tag" IS NOT NULL) AND ("c"."organizer" ~~* (('%'::"text" || "p"."organizer_tag") || '%'::"text"))))) OR (EXISTS ( SELECT 1
           FROM "public"."profile_organizer_tags" "pot"
          WHERE (("pot"."profile_id" = "auth"."uid"()) AND ("pot"."tag" IS NOT NULL) AND ("c"."organizer" ~~* (('%'::"text" || "pot"."tag") || '%'::"text"))))))))) AND ("marked_by" = "auth"."uid"())));



CREATE POLICY "allow authenticated modify contact_custom_fields" ON "public"."contact_custom_fields" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."contact" "c"
  WHERE (("c"."id" = "contact_custom_fields"."contact_id") AND (("c"."organizer" IS NULL) OR (EXISTS ( SELECT 1
           FROM "public"."profiles" "p"
          WHERE (("p"."id" = "auth"."uid"()) AND ("p"."organizer_tag" IS NOT NULL) AND ("c"."organizer" ~~* (('%'::"text" || "p"."organizer_tag") || '%'::"text"))))) OR (EXISTS ( SELECT 1
           FROM "public"."profile_organizer_tags" "pot"
          WHERE (("pot"."profile_id" = "auth"."uid"()) AND ("pot"."tag" IS NOT NULL) AND ("c"."organizer" ~~* (('%'::"text" || "pot"."tag") || '%'::"text"))))) OR (EXISTS ( SELECT 1
           FROM "public"."profiles" "p"
          WHERE (("p"."id" = "auth"."uid"()) AND ("p"."role" = ANY (ARRAY['super_admin'::"public"."role_type", 'admin'::"public"."role_type"]))))))))));



CREATE POLICY "allow authenticated read column_visibility" ON "public"."column_visibility" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "allow authenticated read contact_custom_fields" ON "public"."contact_custom_fields" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."contact" "c"
  WHERE (("c"."id" = "contact_custom_fields"."contact_id") AND (("c"."organizer" IS NULL) OR (EXISTS ( SELECT 1
           FROM "public"."profiles" "p"
          WHERE (("p"."id" = "auth"."uid"()) AND ("p"."organizer_tag" IS NOT NULL) AND ("c"."organizer" ~~* (('%'::"text" || "p"."organizer_tag") || '%'::"text"))))) OR (EXISTS ( SELECT 1
           FROM "public"."profile_organizer_tags" "pot"
          WHERE (("pot"."profile_id" = "auth"."uid"()) AND ("pot"."tag" IS NOT NULL) AND ("c"."organizer" ~~* (('%'::"text" || "pot"."tag") || '%'::"text"))))) OR (EXISTS ( SELECT 1
           FROM "public"."profiles" "p"
          WHERE (("p"."id" = "auth"."uid"()) AND ("p"."role" = ANY (ARRAY['super_admin'::"public"."role_type", 'admin'::"public"."role_type"]))))))))));



CREATE POLICY "allow authenticated read custom_columns" ON "public"."custom_columns" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "allow authenticated read events" ON "public"."events" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "allow authenticated read field_permissions" ON "public"."data_access_field_permissions" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "allow authenticated read record_permissions" ON "public"."data_access_record_permissions" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "allow authenticated read view_column_visibility" ON "public"."view_column_visibility" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."views" "v"
  WHERE (("v"."id" = "view_column_visibility"."view_id") AND (("v"."is_default" = true) OR ("v"."is_shared" = true) OR ("v"."created_by" = "auth"."uid"()))))));



CREATE POLICY "allow authenticated read views" ON "public"."views" FOR SELECT TO "authenticated" USING ((("is_default" = true) OR ("is_shared" = true) OR ("created_by" = "auth"."uid"())));



CREATE POLICY "allow authenticated voting history by contact access" ON "public"."contact_voting_history" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."contact" "c"
  WHERE (("c"."id" = "contact_voting_history"."contact_id") AND ("c"."organizer" IS NOT NULL) AND ((EXISTS ( SELECT 1
           FROM "public"."profiles" "p"
          WHERE (("p"."id" = "auth"."uid"()) AND ("p"."organizer_tag" IS NOT NULL) AND ("c"."organizer" ~~* (('%'::"text" || "p"."organizer_tag") || '%'::"text"))))) OR (EXISTS ( SELECT 1
           FROM "public"."profile_organizer_tags" "pot"
          WHERE (("pot"."profile_id" = "auth"."uid"()) AND ("pot"."tag" IS NOT NULL) AND ("c"."organizer" ~~* (('%'::"text" || "pot"."tag") || '%'::"text"))))))))));



CREATE POLICY "allow public read events" ON "public"."events" FOR SELECT TO "anon", "authenticated" USING (true);



CREATE POLICY "allow service_role manage config" ON "public"."events_sync_config" TO "service_role" USING (true) WITH CHECK (true);



CREATE POLICY "allow users manage own column preferences" ON "public"."user_column_preferences" TO "authenticated" USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "allow users manage own expanded sections" ON "public"."user_expanded_sections" TO "authenticated" USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "allow users manage own filter defaults" ON "public"."user_filter_defaults" TO "authenticated" USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "allow users manage own preferences" ON "public"."user_preferences" TO "authenticated" USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "allow users manage own table preferences" ON "public"."user_table_preferences" TO "authenticated" USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));



ALTER TABLE "public"."api_logs" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."api_tokens" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."attachment_audit_log" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "attachment_audit_log_admin_select" ON "public"."attachment_audit_log" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "auth"."uid"()) AND ("p"."role" = ANY (ARRAY['super_admin'::"public"."role_type", 'admin'::"public"."role_type"]))))));



CREATE POLICY "attachment_audit_log_service_role_all" ON "public"."attachment_audit_log" TO "service_role" USING (true) WITH CHECK (true);



ALTER TABLE "public"."audiences" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."campaigns" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."column_visibility" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."contact" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."contact_attachment" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "contact_attachment_delete_uploader_or_admin" ON "public"."contact_attachment" FOR DELETE TO "authenticated" USING ((("uploaded_by" = "auth"."uid"()) OR (EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "auth"."uid"()) AND ("p"."role" = ANY (ARRAY['super_admin'::"public"."role_type", 'admin'::"public"."role_type"])))))));



CREATE POLICY "contact_attachment_insert_authenticated" ON "public"."contact_attachment" FOR INSERT TO "authenticated" WITH CHECK (("uploaded_by" = "auth"."uid"()));



CREATE POLICY "contact_attachment_select_non_deleted" ON "public"."contact_attachment" FOR SELECT TO "authenticated" USING ((("deleted_at" IS NULL) OR (EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "auth"."uid"()) AND ("p"."role" = ANY (ARRAY['super_admin'::"public"."role_type", 'admin'::"public"."role_type"])))))));



CREATE POLICY "contact_attachment_service_role_all" ON "public"."contact_attachment" TO "service_role" USING (true) WITH CHECK (true);



CREATE POLICY "contact_attachment_update_uploader_or_admin" ON "public"."contact_attachment" FOR UPDATE TO "authenticated" USING ((("uploaded_by" = "auth"."uid"()) OR (EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "auth"."uid"()) AND ("p"."role" = ANY (ARRAY['super_admin'::"public"."role_type", 'admin'::"public"."role_type"]))))))) WITH CHECK ((("uploaded_by" = "auth"."uid"()) OR (EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "auth"."uid"()) AND ("p"."role" = ANY (ARRAY['super_admin'::"public"."role_type", 'admin'::"public"."role_type"])))))));



ALTER TABLE "public"."contact_custom_fields" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."contact_enrichment" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "contact_enrichment_admin_all" ON "public"."contact_enrichment" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "auth"."uid"()) AND ("p"."role" = ANY (ARRAY['super_admin'::"public"."role_type", 'admin'::"public"."role_type"])))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "auth"."uid"()) AND ("p"."role" = ANY (ARRAY['super_admin'::"public"."role_type", 'admin'::"public"."role_type"]))))));



CREATE POLICY "contact_enrichment_service_role_all" ON "public"."contact_enrichment" TO "service_role" USING (true) WITH CHECK (true);



ALTER TABLE "public"."contact_note" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "contact_note_delete_creator_or_admin" ON "public"."contact_note" FOR DELETE TO "authenticated" USING ((("created_by" = "auth"."uid"()) OR (EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "auth"."uid"()) AND ("p"."role" = ANY (ARRAY['super_admin'::"public"."role_type", 'admin'::"public"."role_type"])))))));



CREATE POLICY "contact_note_insert_authenticated" ON "public"."contact_note" FOR INSERT TO "authenticated" WITH CHECK (("created_by" = "auth"."uid"()));



CREATE POLICY "contact_note_select_team_and_own" ON "public"."contact_note" FOR SELECT TO "authenticated" USING ((("visibility" = 'team'::"text") OR (("visibility" = 'private'::"text") AND ("created_by" = "auth"."uid"())) OR (EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "auth"."uid"()) AND ("p"."role" = ANY (ARRAY['super_admin'::"public"."role_type", 'admin'::"public"."role_type"])))))));



CREATE POLICY "contact_note_service_role_all" ON "public"."contact_note" TO "service_role" USING (true) WITH CHECK (true);



CREATE POLICY "contact_note_update_creator_or_admin" ON "public"."contact_note" FOR UPDATE TO "authenticated" USING ((("created_by" = "auth"."uid"()) OR (EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "auth"."uid"()) AND ("p"."role" = ANY (ARRAY['super_admin'::"public"."role_type", 'admin'::"public"."role_type"]))))))) WITH CHECK ((("updated_by" = "auth"."uid"()) AND (("created_by" = "auth"."uid"()) OR (EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "auth"."uid"()) AND ("p"."role" = ANY (ARRAY['super_admin'::"public"."role_type", 'admin'::"public"."role_type"]))))))));



ALTER TABLE "public"."contact_voting_history" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."custom_columns" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."data_access_field_permissions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."data_access_record_permissions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."division_electoral_district" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."events" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."events_sync_config" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."feature_permissions" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "feature_permissions_authenticated_read" ON "public"."feature_permissions" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "feature_permissions_service_role_all" ON "public"."feature_permissions" TO "service_role" USING (true) WITH CHECK (true);



ALTER TABLE "public"."features" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "features_authenticated_read" ON "public"."features" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "features_service_role_all" ON "public"."features" TO "service_role" USING (true) WITH CHECK (true);



ALTER TABLE "public"."organizer_tags" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."page_questions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."permission_audit_log" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "permission_audit_log_authenticated_read" ON "public"."permission_audit_log" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "permission_audit_log_service_role_all" ON "public"."permission_audit_log" TO "service_role" USING (true) WITH CHECK (true);



ALTER TABLE "public"."profile_campus_club_access" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."profile_organizer_tags" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."profile_region_access" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."profile_riding_access" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."profiles" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."request" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."roles" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "roles_authenticated_read" ON "public"."roles" FOR SELECT TO "authenticated" USING (true);



COMMENT ON POLICY "roles_authenticated_read" ON "public"."roles" IS 'System roles cannot be deleted (enforced by application logic)';



CREATE POLICY "roles_service_role_all" ON "public"."roles" TO "service_role" USING (true) WITH CHECK (true);



ALTER TABLE "public"."saved_filters" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."signup_requests" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."survey_column_update_rules" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "survey_column_update_rules_service_role_all" ON "public"."survey_column_update_rules" TO "service_role" USING (true) WITH CHECK (true);



ALTER TABLE "public"."survey_instances" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."survey_page_assignments" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."survey_pages" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."survey_questions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."survey_response_answers" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."survey_responses" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."surveys" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_column_preferences" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_expanded_sections" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_filter_defaults" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_preferences" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_table_preferences" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."view_column_visibility" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."views" ENABLE ROW LEVEL SECURITY;




ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";






ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."contact";



ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."profiles";



GRANT USAGE ON SCHEMA "__msar" TO PUBLIC;






GRANT USAGE ON SCHEMA "mathesar_types" TO PUBLIC;



GRANT USAGE ON SCHEMA "msar" TO PUBLIC;






GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";



GRANT ALL ON FUNCTION "public"."box2d_in"("cstring") TO "postgres";
GRANT ALL ON FUNCTION "public"."box2d_in"("cstring") TO "anon";
GRANT ALL ON FUNCTION "public"."box2d_in"("cstring") TO "authenticated";
GRANT ALL ON FUNCTION "public"."box2d_in"("cstring") TO "service_role";



GRANT ALL ON FUNCTION "public"."box2d_out"("public"."box2d") TO "postgres";
GRANT ALL ON FUNCTION "public"."box2d_out"("public"."box2d") TO "anon";
GRANT ALL ON FUNCTION "public"."box2d_out"("public"."box2d") TO "authenticated";
GRANT ALL ON FUNCTION "public"."box2d_out"("public"."box2d") TO "service_role";



GRANT ALL ON FUNCTION "public"."box2df_in"("cstring") TO "postgres";
GRANT ALL ON FUNCTION "public"."box2df_in"("cstring") TO "anon";
GRANT ALL ON FUNCTION "public"."box2df_in"("cstring") TO "authenticated";
GRANT ALL ON FUNCTION "public"."box2df_in"("cstring") TO "service_role";



GRANT ALL ON FUNCTION "public"."box2df_out"("public"."box2df") TO "postgres";
GRANT ALL ON FUNCTION "public"."box2df_out"("public"."box2df") TO "anon";
GRANT ALL ON FUNCTION "public"."box2df_out"("public"."box2df") TO "authenticated";
GRANT ALL ON FUNCTION "public"."box2df_out"("public"."box2df") TO "service_role";



GRANT ALL ON FUNCTION "public"."box3d_in"("cstring") TO "postgres";
GRANT ALL ON FUNCTION "public"."box3d_in"("cstring") TO "anon";
GRANT ALL ON FUNCTION "public"."box3d_in"("cstring") TO "authenticated";
GRANT ALL ON FUNCTION "public"."box3d_in"("cstring") TO "service_role";



GRANT ALL ON FUNCTION "public"."box3d_out"("public"."box3d") TO "postgres";
GRANT ALL ON FUNCTION "public"."box3d_out"("public"."box3d") TO "anon";
GRANT ALL ON FUNCTION "public"."box3d_out"("public"."box3d") TO "authenticated";
GRANT ALL ON FUNCTION "public"."box3d_out"("public"."box3d") TO "service_role";



GRANT ALL ON FUNCTION "public"."geography_analyze"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."geography_analyze"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."geography_analyze"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geography_analyze"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."geography_in"("cstring", "oid", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."geography_in"("cstring", "oid", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."geography_in"("cstring", "oid", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."geography_in"("cstring", "oid", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."geography_out"("public"."geography") TO "postgres";
GRANT ALL ON FUNCTION "public"."geography_out"("public"."geography") TO "anon";
GRANT ALL ON FUNCTION "public"."geography_out"("public"."geography") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geography_out"("public"."geography") TO "service_role";



GRANT ALL ON FUNCTION "public"."geography_recv"("internal", "oid", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."geography_recv"("internal", "oid", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."geography_recv"("internal", "oid", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."geography_recv"("internal", "oid", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."geography_send"("public"."geography") TO "postgres";
GRANT ALL ON FUNCTION "public"."geography_send"("public"."geography") TO "anon";
GRANT ALL ON FUNCTION "public"."geography_send"("public"."geography") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geography_send"("public"."geography") TO "service_role";



GRANT ALL ON FUNCTION "public"."geography_typmod_in"("cstring"[]) TO "postgres";
GRANT ALL ON FUNCTION "public"."geography_typmod_in"("cstring"[]) TO "anon";
GRANT ALL ON FUNCTION "public"."geography_typmod_in"("cstring"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."geography_typmod_in"("cstring"[]) TO "service_role";



GRANT ALL ON FUNCTION "public"."geography_typmod_out"(integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."geography_typmod_out"(integer) TO "anon";
GRANT ALL ON FUNCTION "public"."geography_typmod_out"(integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."geography_typmod_out"(integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_analyze"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_analyze"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_analyze"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_analyze"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_in"("cstring") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_in"("cstring") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_in"("cstring") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_in"("cstring") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_out"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_out"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_out"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_out"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_recv"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_recv"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_recv"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_recv"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_send"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_send"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_send"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_send"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_typmod_in"("cstring"[]) TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_typmod_in"("cstring"[]) TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_typmod_in"("cstring"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_typmod_in"("cstring"[]) TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_typmod_out"(integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_typmod_out"(integer) TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_typmod_out"(integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_typmod_out"(integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."gidx_in"("cstring") TO "postgres";
GRANT ALL ON FUNCTION "public"."gidx_in"("cstring") TO "anon";
GRANT ALL ON FUNCTION "public"."gidx_in"("cstring") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gidx_in"("cstring") TO "service_role";



GRANT ALL ON FUNCTION "public"."gidx_out"("public"."gidx") TO "postgres";
GRANT ALL ON FUNCTION "public"."gidx_out"("public"."gidx") TO "anon";
GRANT ALL ON FUNCTION "public"."gidx_out"("public"."gidx") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gidx_out"("public"."gidx") TO "service_role";



GRANT ALL ON FUNCTION "public"."spheroid_in"("cstring") TO "postgres";
GRANT ALL ON FUNCTION "public"."spheroid_in"("cstring") TO "anon";
GRANT ALL ON FUNCTION "public"."spheroid_in"("cstring") TO "authenticated";
GRANT ALL ON FUNCTION "public"."spheroid_in"("cstring") TO "service_role";



GRANT ALL ON FUNCTION "public"."spheroid_out"("public"."spheroid") TO "postgres";
GRANT ALL ON FUNCTION "public"."spheroid_out"("public"."spheroid") TO "anon";
GRANT ALL ON FUNCTION "public"."spheroid_out"("public"."spheroid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."spheroid_out"("public"."spheroid") TO "service_role";



GRANT ALL ON FUNCTION "public"."box3d"("public"."box2d") TO "postgres";
GRANT ALL ON FUNCTION "public"."box3d"("public"."box2d") TO "anon";
GRANT ALL ON FUNCTION "public"."box3d"("public"."box2d") TO "authenticated";
GRANT ALL ON FUNCTION "public"."box3d"("public"."box2d") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry"("public"."box2d") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry"("public"."box2d") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry"("public"."box2d") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry"("public"."box2d") TO "service_role";



GRANT ALL ON FUNCTION "public"."box"("public"."box3d") TO "postgres";
GRANT ALL ON FUNCTION "public"."box"("public"."box3d") TO "anon";
GRANT ALL ON FUNCTION "public"."box"("public"."box3d") TO "authenticated";
GRANT ALL ON FUNCTION "public"."box"("public"."box3d") TO "service_role";



GRANT ALL ON FUNCTION "public"."box2d"("public"."box3d") TO "postgres";
GRANT ALL ON FUNCTION "public"."box2d"("public"."box3d") TO "anon";
GRANT ALL ON FUNCTION "public"."box2d"("public"."box3d") TO "authenticated";
GRANT ALL ON FUNCTION "public"."box2d"("public"."box3d") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry"("public"."box3d") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry"("public"."box3d") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry"("public"."box3d") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry"("public"."box3d") TO "service_role";



GRANT ALL ON FUNCTION "public"."geography"("bytea") TO "postgres";
GRANT ALL ON FUNCTION "public"."geography"("bytea") TO "anon";
GRANT ALL ON FUNCTION "public"."geography"("bytea") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geography"("bytea") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry"("bytea") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry"("bytea") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry"("bytea") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry"("bytea") TO "service_role";



GRANT ALL ON FUNCTION "public"."bytea"("public"."geography") TO "postgres";
GRANT ALL ON FUNCTION "public"."bytea"("public"."geography") TO "anon";
GRANT ALL ON FUNCTION "public"."bytea"("public"."geography") TO "authenticated";
GRANT ALL ON FUNCTION "public"."bytea"("public"."geography") TO "service_role";



GRANT ALL ON FUNCTION "public"."geography"("public"."geography", integer, boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."geography"("public"."geography", integer, boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."geography"("public"."geography", integer, boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."geography"("public"."geography", integer, boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry"("public"."geography") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry"("public"."geography") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry"("public"."geography") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry"("public"."geography") TO "service_role";



GRANT ALL ON FUNCTION "public"."box"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."box"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."box"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."box"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."box2d"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."box2d"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."box2d"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."box2d"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."box3d"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."box3d"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."box3d"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."box3d"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."bytea"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."bytea"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."bytea"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."bytea"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."geography"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."geography"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."geography"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geography"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry"("public"."geometry", integer, boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry"("public"."geometry", integer, boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."geometry"("public"."geometry", integer, boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry"("public"."geometry", integer, boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."json"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."json"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."json"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."json"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."jsonb"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."jsonb"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."jsonb"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."jsonb"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."path"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."path"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."path"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."path"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."point"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."point"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."point"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."point"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."polygon"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."polygon"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."polygon"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."polygon"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."text"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."text"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."text"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."text"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry"("path") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry"("path") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry"("path") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry"("path") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry"("point") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry"("point") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry"("point") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry"("point") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry"("polygon") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry"("polygon") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry"("polygon") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry"("polygon") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry"("text") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry"("text") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry"("text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry"("text") TO "service_role";


















































































































































































































GRANT ALL ON FUNCTION "public"."_postgis_deprecate"("oldname" "text", "newname" "text", "version" "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."_postgis_deprecate"("oldname" "text", "newname" "text", "version" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."_postgis_deprecate"("oldname" "text", "newname" "text", "version" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_postgis_deprecate"("oldname" "text", "newname" "text", "version" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."_postgis_index_extent"("tbl" "regclass", "col" "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."_postgis_index_extent"("tbl" "regclass", "col" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."_postgis_index_extent"("tbl" "regclass", "col" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_postgis_index_extent"("tbl" "regclass", "col" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."_postgis_join_selectivity"("regclass", "text", "regclass", "text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."_postgis_join_selectivity"("regclass", "text", "regclass", "text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."_postgis_join_selectivity"("regclass", "text", "regclass", "text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_postgis_join_selectivity"("regclass", "text", "regclass", "text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."_postgis_pgsql_version"() TO "postgres";
GRANT ALL ON FUNCTION "public"."_postgis_pgsql_version"() TO "anon";
GRANT ALL ON FUNCTION "public"."_postgis_pgsql_version"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."_postgis_pgsql_version"() TO "service_role";



GRANT ALL ON FUNCTION "public"."_postgis_scripts_pgsql_version"() TO "postgres";
GRANT ALL ON FUNCTION "public"."_postgis_scripts_pgsql_version"() TO "anon";
GRANT ALL ON FUNCTION "public"."_postgis_scripts_pgsql_version"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."_postgis_scripts_pgsql_version"() TO "service_role";



GRANT ALL ON FUNCTION "public"."_postgis_selectivity"("tbl" "regclass", "att_name" "text", "geom" "public"."geometry", "mode" "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."_postgis_selectivity"("tbl" "regclass", "att_name" "text", "geom" "public"."geometry", "mode" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."_postgis_selectivity"("tbl" "regclass", "att_name" "text", "geom" "public"."geometry", "mode" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_postgis_selectivity"("tbl" "regclass", "att_name" "text", "geom" "public"."geometry", "mode" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."_postgis_stats"("tbl" "regclass", "att_name" "text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."_postgis_stats"("tbl" "regclass", "att_name" "text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."_postgis_stats"("tbl" "regclass", "att_name" "text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_postgis_stats"("tbl" "regclass", "att_name" "text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."_st_3ddfullywithin"("geom1" "public"."geometry", "geom2" "public"."geometry", double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."_st_3ddfullywithin"("geom1" "public"."geometry", "geom2" "public"."geometry", double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."_st_3ddfullywithin"("geom1" "public"."geometry", "geom2" "public"."geometry", double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."_st_3ddfullywithin"("geom1" "public"."geometry", "geom2" "public"."geometry", double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."_st_3ddwithin"("geom1" "public"."geometry", "geom2" "public"."geometry", double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."_st_3ddwithin"("geom1" "public"."geometry", "geom2" "public"."geometry", double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."_st_3ddwithin"("geom1" "public"."geometry", "geom2" "public"."geometry", double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."_st_3ddwithin"("geom1" "public"."geometry", "geom2" "public"."geometry", double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."_st_3dintersects"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."_st_3dintersects"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."_st_3dintersects"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_st_3dintersects"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."_st_asgml"(integer, "public"."geometry", integer, integer, "text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."_st_asgml"(integer, "public"."geometry", integer, integer, "text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."_st_asgml"(integer, "public"."geometry", integer, integer, "text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_st_asgml"(integer, "public"."geometry", integer, integer, "text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."_st_asx3d"(integer, "public"."geometry", integer, integer, "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."_st_asx3d"(integer, "public"."geometry", integer, integer, "text") TO "anon";
GRANT ALL ON FUNCTION "public"."_st_asx3d"(integer, "public"."geometry", integer, integer, "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_st_asx3d"(integer, "public"."geometry", integer, integer, "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."_st_bestsrid"("public"."geography") TO "postgres";
GRANT ALL ON FUNCTION "public"."_st_bestsrid"("public"."geography") TO "anon";
GRANT ALL ON FUNCTION "public"."_st_bestsrid"("public"."geography") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_st_bestsrid"("public"."geography") TO "service_role";



GRANT ALL ON FUNCTION "public"."_st_bestsrid"("public"."geography", "public"."geography") TO "postgres";
GRANT ALL ON FUNCTION "public"."_st_bestsrid"("public"."geography", "public"."geography") TO "anon";
GRANT ALL ON FUNCTION "public"."_st_bestsrid"("public"."geography", "public"."geography") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_st_bestsrid"("public"."geography", "public"."geography") TO "service_role";



GRANT ALL ON FUNCTION "public"."_st_contains"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."_st_contains"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."_st_contains"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_st_contains"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."_st_containsproperly"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."_st_containsproperly"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."_st_containsproperly"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_st_containsproperly"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."_st_coveredby"("geog1" "public"."geography", "geog2" "public"."geography") TO "postgres";
GRANT ALL ON FUNCTION "public"."_st_coveredby"("geog1" "public"."geography", "geog2" "public"."geography") TO "anon";
GRANT ALL ON FUNCTION "public"."_st_coveredby"("geog1" "public"."geography", "geog2" "public"."geography") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_st_coveredby"("geog1" "public"."geography", "geog2" "public"."geography") TO "service_role";



GRANT ALL ON FUNCTION "public"."_st_coveredby"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."_st_coveredby"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."_st_coveredby"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_st_coveredby"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."_st_covers"("geog1" "public"."geography", "geog2" "public"."geography") TO "postgres";
GRANT ALL ON FUNCTION "public"."_st_covers"("geog1" "public"."geography", "geog2" "public"."geography") TO "anon";
GRANT ALL ON FUNCTION "public"."_st_covers"("geog1" "public"."geography", "geog2" "public"."geography") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_st_covers"("geog1" "public"."geography", "geog2" "public"."geography") TO "service_role";



GRANT ALL ON FUNCTION "public"."_st_covers"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."_st_covers"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."_st_covers"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_st_covers"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."_st_crosses"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."_st_crosses"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."_st_crosses"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_st_crosses"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."_st_dfullywithin"("geom1" "public"."geometry", "geom2" "public"."geometry", double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."_st_dfullywithin"("geom1" "public"."geometry", "geom2" "public"."geometry", double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."_st_dfullywithin"("geom1" "public"."geometry", "geom2" "public"."geometry", double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."_st_dfullywithin"("geom1" "public"."geometry", "geom2" "public"."geometry", double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."_st_distancetree"("public"."geography", "public"."geography") TO "postgres";
GRANT ALL ON FUNCTION "public"."_st_distancetree"("public"."geography", "public"."geography") TO "anon";
GRANT ALL ON FUNCTION "public"."_st_distancetree"("public"."geography", "public"."geography") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_st_distancetree"("public"."geography", "public"."geography") TO "service_role";



GRANT ALL ON FUNCTION "public"."_st_distancetree"("public"."geography", "public"."geography", double precision, boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."_st_distancetree"("public"."geography", "public"."geography", double precision, boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."_st_distancetree"("public"."geography", "public"."geography", double precision, boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."_st_distancetree"("public"."geography", "public"."geography", double precision, boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."_st_distanceuncached"("public"."geography", "public"."geography") TO "postgres";
GRANT ALL ON FUNCTION "public"."_st_distanceuncached"("public"."geography", "public"."geography") TO "anon";
GRANT ALL ON FUNCTION "public"."_st_distanceuncached"("public"."geography", "public"."geography") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_st_distanceuncached"("public"."geography", "public"."geography") TO "service_role";



GRANT ALL ON FUNCTION "public"."_st_distanceuncached"("public"."geography", "public"."geography", boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."_st_distanceuncached"("public"."geography", "public"."geography", boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."_st_distanceuncached"("public"."geography", "public"."geography", boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."_st_distanceuncached"("public"."geography", "public"."geography", boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."_st_distanceuncached"("public"."geography", "public"."geography", double precision, boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."_st_distanceuncached"("public"."geography", "public"."geography", double precision, boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."_st_distanceuncached"("public"."geography", "public"."geography", double precision, boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."_st_distanceuncached"("public"."geography", "public"."geography", double precision, boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."_st_dwithin"("geom1" "public"."geometry", "geom2" "public"."geometry", double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."_st_dwithin"("geom1" "public"."geometry", "geom2" "public"."geometry", double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."_st_dwithin"("geom1" "public"."geometry", "geom2" "public"."geometry", double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."_st_dwithin"("geom1" "public"."geometry", "geom2" "public"."geometry", double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."_st_dwithin"("geog1" "public"."geography", "geog2" "public"."geography", "tolerance" double precision, "use_spheroid" boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."_st_dwithin"("geog1" "public"."geography", "geog2" "public"."geography", "tolerance" double precision, "use_spheroid" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."_st_dwithin"("geog1" "public"."geography", "geog2" "public"."geography", "tolerance" double precision, "use_spheroid" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."_st_dwithin"("geog1" "public"."geography", "geog2" "public"."geography", "tolerance" double precision, "use_spheroid" boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."_st_dwithinuncached"("public"."geography", "public"."geography", double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."_st_dwithinuncached"("public"."geography", "public"."geography", double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."_st_dwithinuncached"("public"."geography", "public"."geography", double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."_st_dwithinuncached"("public"."geography", "public"."geography", double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."_st_dwithinuncached"("public"."geography", "public"."geography", double precision, boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."_st_dwithinuncached"("public"."geography", "public"."geography", double precision, boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."_st_dwithinuncached"("public"."geography", "public"."geography", double precision, boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."_st_dwithinuncached"("public"."geography", "public"."geography", double precision, boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."_st_equals"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."_st_equals"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."_st_equals"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_st_equals"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."_st_expand"("public"."geography", double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."_st_expand"("public"."geography", double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."_st_expand"("public"."geography", double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."_st_expand"("public"."geography", double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."_st_geomfromgml"("text", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."_st_geomfromgml"("text", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."_st_geomfromgml"("text", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."_st_geomfromgml"("text", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."_st_intersects"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."_st_intersects"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."_st_intersects"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_st_intersects"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."_st_linecrossingdirection"("line1" "public"."geometry", "line2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."_st_linecrossingdirection"("line1" "public"."geometry", "line2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."_st_linecrossingdirection"("line1" "public"."geometry", "line2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_st_linecrossingdirection"("line1" "public"."geometry", "line2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."_st_longestline"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."_st_longestline"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."_st_longestline"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_st_longestline"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."_st_maxdistance"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."_st_maxdistance"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."_st_maxdistance"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_st_maxdistance"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."_st_orderingequals"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."_st_orderingequals"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."_st_orderingequals"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_st_orderingequals"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."_st_overlaps"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."_st_overlaps"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."_st_overlaps"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_st_overlaps"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."_st_pointoutside"("public"."geography") TO "postgres";
GRANT ALL ON FUNCTION "public"."_st_pointoutside"("public"."geography") TO "anon";
GRANT ALL ON FUNCTION "public"."_st_pointoutside"("public"."geography") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_st_pointoutside"("public"."geography") TO "service_role";



GRANT ALL ON FUNCTION "public"."_st_sortablehash"("geom" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."_st_sortablehash"("geom" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."_st_sortablehash"("geom" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_st_sortablehash"("geom" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."_st_touches"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."_st_touches"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."_st_touches"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_st_touches"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."_st_voronoi"("g1" "public"."geometry", "clip" "public"."geometry", "tolerance" double precision, "return_polygons" boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."_st_voronoi"("g1" "public"."geometry", "clip" "public"."geometry", "tolerance" double precision, "return_polygons" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."_st_voronoi"("g1" "public"."geometry", "clip" "public"."geometry", "tolerance" double precision, "return_polygons" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."_st_voronoi"("g1" "public"."geometry", "clip" "public"."geometry", "tolerance" double precision, "return_polygons" boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."_st_within"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."_st_within"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."_st_within"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."_st_within"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."addauth"("text") TO "postgres";
GRANT ALL ON FUNCTION "public"."addauth"("text") TO "anon";
GRANT ALL ON FUNCTION "public"."addauth"("text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."addauth"("text") TO "service_role";



GRANT ALL ON FUNCTION "public"."addgeometrycolumn"("table_name" character varying, "column_name" character varying, "new_srid" integer, "new_type" character varying, "new_dim" integer, "use_typmod" boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."addgeometrycolumn"("table_name" character varying, "column_name" character varying, "new_srid" integer, "new_type" character varying, "new_dim" integer, "use_typmod" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."addgeometrycolumn"("table_name" character varying, "column_name" character varying, "new_srid" integer, "new_type" character varying, "new_dim" integer, "use_typmod" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."addgeometrycolumn"("table_name" character varying, "column_name" character varying, "new_srid" integer, "new_type" character varying, "new_dim" integer, "use_typmod" boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."addgeometrycolumn"("schema_name" character varying, "table_name" character varying, "column_name" character varying, "new_srid" integer, "new_type" character varying, "new_dim" integer, "use_typmod" boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."addgeometrycolumn"("schema_name" character varying, "table_name" character varying, "column_name" character varying, "new_srid" integer, "new_type" character varying, "new_dim" integer, "use_typmod" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."addgeometrycolumn"("schema_name" character varying, "table_name" character varying, "column_name" character varying, "new_srid" integer, "new_type" character varying, "new_dim" integer, "use_typmod" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."addgeometrycolumn"("schema_name" character varying, "table_name" character varying, "column_name" character varying, "new_srid" integer, "new_type" character varying, "new_dim" integer, "use_typmod" boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."addgeometrycolumn"("catalog_name" character varying, "schema_name" character varying, "table_name" character varying, "column_name" character varying, "new_srid_in" integer, "new_type" character varying, "new_dim" integer, "use_typmod" boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."addgeometrycolumn"("catalog_name" character varying, "schema_name" character varying, "table_name" character varying, "column_name" character varying, "new_srid_in" integer, "new_type" character varying, "new_dim" integer, "use_typmod" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."addgeometrycolumn"("catalog_name" character varying, "schema_name" character varying, "table_name" character varying, "column_name" character varying, "new_srid_in" integer, "new_type" character varying, "new_dim" integer, "use_typmod" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."addgeometrycolumn"("catalog_name" character varying, "schema_name" character varying, "table_name" character varying, "column_name" character varying, "new_srid_in" integer, "new_type" character varying, "new_dim" integer, "use_typmod" boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."box3dtobox"("public"."box3d") TO "postgres";
GRANT ALL ON FUNCTION "public"."box3dtobox"("public"."box3d") TO "anon";
GRANT ALL ON FUNCTION "public"."box3dtobox"("public"."box3d") TO "authenticated";
GRANT ALL ON FUNCTION "public"."box3dtobox"("public"."box3d") TO "service_role";



GRANT ALL ON FUNCTION "public"."call_location_lookup_edge_function"("p_contact_id" bigint, "p_postcode" "text", "p_street_address" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."call_location_lookup_edge_function"("p_contact_id" bigint, "p_postcode" "text", "p_street_address" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."call_location_lookup_edge_function"("p_contact_id" bigint, "p_postcode" "text", "p_street_address" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."check_events_sync_cron"() TO "anon";
GRANT ALL ON FUNCTION "public"."check_events_sync_cron"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."check_events_sync_cron"() TO "service_role";



GRANT ALL ON FUNCTION "public"."check_feature_permission"("p_role_id" "text", "p_feature_id" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."check_feature_permission"("p_role_id" "text", "p_feature_id" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."check_feature_permission"("p_role_id" "text", "p_feature_id" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."check_survey_send_worker_cron"() TO "anon";
GRANT ALL ON FUNCTION "public"."check_survey_send_worker_cron"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."check_survey_send_worker_cron"() TO "service_role";



GRANT ALL ON FUNCTION "public"."checkauth"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."checkauth"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."checkauth"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."checkauth"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."checkauth"("text", "text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."checkauth"("text", "text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."checkauth"("text", "text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."checkauth"("text", "text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."checkauthtrigger"() TO "postgres";
GRANT ALL ON FUNCTION "public"."checkauthtrigger"() TO "anon";
GRANT ALL ON FUNCTION "public"."checkauthtrigger"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."checkauthtrigger"() TO "service_role";



GRANT ALL ON FUNCTION "public"."contains_2d"("public"."box2df", "public"."box2df") TO "postgres";
GRANT ALL ON FUNCTION "public"."contains_2d"("public"."box2df", "public"."box2df") TO "anon";
GRANT ALL ON FUNCTION "public"."contains_2d"("public"."box2df", "public"."box2df") TO "authenticated";
GRANT ALL ON FUNCTION "public"."contains_2d"("public"."box2df", "public"."box2df") TO "service_role";



GRANT ALL ON FUNCTION "public"."contains_2d"("public"."box2df", "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."contains_2d"("public"."box2df", "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."contains_2d"("public"."box2df", "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."contains_2d"("public"."box2df", "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."contains_2d"("public"."geometry", "public"."box2df") TO "postgres";
GRANT ALL ON FUNCTION "public"."contains_2d"("public"."geometry", "public"."box2df") TO "anon";
GRANT ALL ON FUNCTION "public"."contains_2d"("public"."geometry", "public"."box2df") TO "authenticated";
GRANT ALL ON FUNCTION "public"."contains_2d"("public"."geometry", "public"."box2df") TO "service_role";



GRANT ALL ON FUNCTION "public"."disablelongtransactions"() TO "postgres";
GRANT ALL ON FUNCTION "public"."disablelongtransactions"() TO "anon";
GRANT ALL ON FUNCTION "public"."disablelongtransactions"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."disablelongtransactions"() TO "service_role";



GRANT ALL ON FUNCTION "public"."dropgeometrycolumn"("table_name" character varying, "column_name" character varying) TO "postgres";
GRANT ALL ON FUNCTION "public"."dropgeometrycolumn"("table_name" character varying, "column_name" character varying) TO "anon";
GRANT ALL ON FUNCTION "public"."dropgeometrycolumn"("table_name" character varying, "column_name" character varying) TO "authenticated";
GRANT ALL ON FUNCTION "public"."dropgeometrycolumn"("table_name" character varying, "column_name" character varying) TO "service_role";



GRANT ALL ON FUNCTION "public"."dropgeometrycolumn"("schema_name" character varying, "table_name" character varying, "column_name" character varying) TO "postgres";
GRANT ALL ON FUNCTION "public"."dropgeometrycolumn"("schema_name" character varying, "table_name" character varying, "column_name" character varying) TO "anon";
GRANT ALL ON FUNCTION "public"."dropgeometrycolumn"("schema_name" character varying, "table_name" character varying, "column_name" character varying) TO "authenticated";
GRANT ALL ON FUNCTION "public"."dropgeometrycolumn"("schema_name" character varying, "table_name" character varying, "column_name" character varying) TO "service_role";



GRANT ALL ON FUNCTION "public"."dropgeometrycolumn"("catalog_name" character varying, "schema_name" character varying, "table_name" character varying, "column_name" character varying) TO "postgres";
GRANT ALL ON FUNCTION "public"."dropgeometrycolumn"("catalog_name" character varying, "schema_name" character varying, "table_name" character varying, "column_name" character varying) TO "anon";
GRANT ALL ON FUNCTION "public"."dropgeometrycolumn"("catalog_name" character varying, "schema_name" character varying, "table_name" character varying, "column_name" character varying) TO "authenticated";
GRANT ALL ON FUNCTION "public"."dropgeometrycolumn"("catalog_name" character varying, "schema_name" character varying, "table_name" character varying, "column_name" character varying) TO "service_role";



GRANT ALL ON FUNCTION "public"."dropgeometrytable"("table_name" character varying) TO "postgres";
GRANT ALL ON FUNCTION "public"."dropgeometrytable"("table_name" character varying) TO "anon";
GRANT ALL ON FUNCTION "public"."dropgeometrytable"("table_name" character varying) TO "authenticated";
GRANT ALL ON FUNCTION "public"."dropgeometrytable"("table_name" character varying) TO "service_role";



GRANT ALL ON FUNCTION "public"."dropgeometrytable"("schema_name" character varying, "table_name" character varying) TO "postgres";
GRANT ALL ON FUNCTION "public"."dropgeometrytable"("schema_name" character varying, "table_name" character varying) TO "anon";
GRANT ALL ON FUNCTION "public"."dropgeometrytable"("schema_name" character varying, "table_name" character varying) TO "authenticated";
GRANT ALL ON FUNCTION "public"."dropgeometrytable"("schema_name" character varying, "table_name" character varying) TO "service_role";



GRANT ALL ON FUNCTION "public"."dropgeometrytable"("catalog_name" character varying, "schema_name" character varying, "table_name" character varying) TO "postgres";
GRANT ALL ON FUNCTION "public"."dropgeometrytable"("catalog_name" character varying, "schema_name" character varying, "table_name" character varying) TO "anon";
GRANT ALL ON FUNCTION "public"."dropgeometrytable"("catalog_name" character varying, "schema_name" character varying, "table_name" character varying) TO "authenticated";
GRANT ALL ON FUNCTION "public"."dropgeometrytable"("catalog_name" character varying, "schema_name" character varying, "table_name" character varying) TO "service_role";



GRANT ALL ON FUNCTION "public"."enablelongtransactions"() TO "postgres";
GRANT ALL ON FUNCTION "public"."enablelongtransactions"() TO "anon";
GRANT ALL ON FUNCTION "public"."enablelongtransactions"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."enablelongtransactions"() TO "service_role";



GRANT ALL ON FUNCTION "public"."ensure_single_pinned_note"() TO "anon";
GRANT ALL ON FUNCTION "public"."ensure_single_pinned_note"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."ensure_single_pinned_note"() TO "service_role";



GRANT ALL ON FUNCTION "public"."equals"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."equals"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."equals"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."equals"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."find_srid"(character varying, character varying, character varying) TO "postgres";
GRANT ALL ON FUNCTION "public"."find_srid"(character varying, character varying, character varying) TO "anon";
GRANT ALL ON FUNCTION "public"."find_srid"(character varying, character varying, character varying) TO "authenticated";
GRANT ALL ON FUNCTION "public"."find_srid"(character varying, character varying, character varying) TO "service_role";



GRANT ALL ON FUNCTION "public"."geog_brin_inclusion_add_value"("internal", "internal", "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."geog_brin_inclusion_add_value"("internal", "internal", "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."geog_brin_inclusion_add_value"("internal", "internal", "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geog_brin_inclusion_add_value"("internal", "internal", "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."geography_cmp"("public"."geography", "public"."geography") TO "postgres";
GRANT ALL ON FUNCTION "public"."geography_cmp"("public"."geography", "public"."geography") TO "anon";
GRANT ALL ON FUNCTION "public"."geography_cmp"("public"."geography", "public"."geography") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geography_cmp"("public"."geography", "public"."geography") TO "service_role";



GRANT ALL ON FUNCTION "public"."geography_distance_knn"("public"."geography", "public"."geography") TO "postgres";
GRANT ALL ON FUNCTION "public"."geography_distance_knn"("public"."geography", "public"."geography") TO "anon";
GRANT ALL ON FUNCTION "public"."geography_distance_knn"("public"."geography", "public"."geography") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geography_distance_knn"("public"."geography", "public"."geography") TO "service_role";



GRANT ALL ON FUNCTION "public"."geography_eq"("public"."geography", "public"."geography") TO "postgres";
GRANT ALL ON FUNCTION "public"."geography_eq"("public"."geography", "public"."geography") TO "anon";
GRANT ALL ON FUNCTION "public"."geography_eq"("public"."geography", "public"."geography") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geography_eq"("public"."geography", "public"."geography") TO "service_role";



GRANT ALL ON FUNCTION "public"."geography_ge"("public"."geography", "public"."geography") TO "postgres";
GRANT ALL ON FUNCTION "public"."geography_ge"("public"."geography", "public"."geography") TO "anon";
GRANT ALL ON FUNCTION "public"."geography_ge"("public"."geography", "public"."geography") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geography_ge"("public"."geography", "public"."geography") TO "service_role";



GRANT ALL ON FUNCTION "public"."geography_gist_compress"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."geography_gist_compress"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."geography_gist_compress"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geography_gist_compress"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."geography_gist_consistent"("internal", "public"."geography", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."geography_gist_consistent"("internal", "public"."geography", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."geography_gist_consistent"("internal", "public"."geography", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."geography_gist_consistent"("internal", "public"."geography", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."geography_gist_decompress"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."geography_gist_decompress"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."geography_gist_decompress"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geography_gist_decompress"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."geography_gist_distance"("internal", "public"."geography", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."geography_gist_distance"("internal", "public"."geography", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."geography_gist_distance"("internal", "public"."geography", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."geography_gist_distance"("internal", "public"."geography", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."geography_gist_penalty"("internal", "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."geography_gist_penalty"("internal", "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."geography_gist_penalty"("internal", "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geography_gist_penalty"("internal", "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."geography_gist_picksplit"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."geography_gist_picksplit"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."geography_gist_picksplit"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geography_gist_picksplit"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."geography_gist_same"("public"."box2d", "public"."box2d", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."geography_gist_same"("public"."box2d", "public"."box2d", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."geography_gist_same"("public"."box2d", "public"."box2d", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geography_gist_same"("public"."box2d", "public"."box2d", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."geography_gist_union"("bytea", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."geography_gist_union"("bytea", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."geography_gist_union"("bytea", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geography_gist_union"("bytea", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."geography_gt"("public"."geography", "public"."geography") TO "postgres";
GRANT ALL ON FUNCTION "public"."geography_gt"("public"."geography", "public"."geography") TO "anon";
GRANT ALL ON FUNCTION "public"."geography_gt"("public"."geography", "public"."geography") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geography_gt"("public"."geography", "public"."geography") TO "service_role";



GRANT ALL ON FUNCTION "public"."geography_le"("public"."geography", "public"."geography") TO "postgres";
GRANT ALL ON FUNCTION "public"."geography_le"("public"."geography", "public"."geography") TO "anon";
GRANT ALL ON FUNCTION "public"."geography_le"("public"."geography", "public"."geography") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geography_le"("public"."geography", "public"."geography") TO "service_role";



GRANT ALL ON FUNCTION "public"."geography_lt"("public"."geography", "public"."geography") TO "postgres";
GRANT ALL ON FUNCTION "public"."geography_lt"("public"."geography", "public"."geography") TO "anon";
GRANT ALL ON FUNCTION "public"."geography_lt"("public"."geography", "public"."geography") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geography_lt"("public"."geography", "public"."geography") TO "service_role";



GRANT ALL ON FUNCTION "public"."geography_overlaps"("public"."geography", "public"."geography") TO "postgres";
GRANT ALL ON FUNCTION "public"."geography_overlaps"("public"."geography", "public"."geography") TO "anon";
GRANT ALL ON FUNCTION "public"."geography_overlaps"("public"."geography", "public"."geography") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geography_overlaps"("public"."geography", "public"."geography") TO "service_role";



GRANT ALL ON FUNCTION "public"."geography_spgist_choose_nd"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."geography_spgist_choose_nd"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."geography_spgist_choose_nd"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geography_spgist_choose_nd"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."geography_spgist_compress_nd"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."geography_spgist_compress_nd"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."geography_spgist_compress_nd"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geography_spgist_compress_nd"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."geography_spgist_config_nd"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."geography_spgist_config_nd"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."geography_spgist_config_nd"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geography_spgist_config_nd"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."geography_spgist_inner_consistent_nd"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."geography_spgist_inner_consistent_nd"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."geography_spgist_inner_consistent_nd"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geography_spgist_inner_consistent_nd"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."geography_spgist_leaf_consistent_nd"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."geography_spgist_leaf_consistent_nd"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."geography_spgist_leaf_consistent_nd"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geography_spgist_leaf_consistent_nd"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."geography_spgist_picksplit_nd"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."geography_spgist_picksplit_nd"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."geography_spgist_picksplit_nd"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geography_spgist_picksplit_nd"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."geom2d_brin_inclusion_add_value"("internal", "internal", "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."geom2d_brin_inclusion_add_value"("internal", "internal", "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."geom2d_brin_inclusion_add_value"("internal", "internal", "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geom2d_brin_inclusion_add_value"("internal", "internal", "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."geom3d_brin_inclusion_add_value"("internal", "internal", "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."geom3d_brin_inclusion_add_value"("internal", "internal", "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."geom3d_brin_inclusion_add_value"("internal", "internal", "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geom3d_brin_inclusion_add_value"("internal", "internal", "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."geom4d_brin_inclusion_add_value"("internal", "internal", "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."geom4d_brin_inclusion_add_value"("internal", "internal", "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."geom4d_brin_inclusion_add_value"("internal", "internal", "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geom4d_brin_inclusion_add_value"("internal", "internal", "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_above"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_above"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_above"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_above"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_below"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_below"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_below"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_below"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_cmp"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_cmp"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_cmp"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_cmp"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_contained_3d"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_contained_3d"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_contained_3d"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_contained_3d"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_contains"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_contains"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_contains"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_contains"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_contains_3d"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_contains_3d"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_contains_3d"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_contains_3d"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_contains_nd"("public"."geometry", "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_contains_nd"("public"."geometry", "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_contains_nd"("public"."geometry", "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_contains_nd"("public"."geometry", "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_distance_box"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_distance_box"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_distance_box"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_distance_box"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_distance_centroid"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_distance_centroid"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_distance_centroid"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_distance_centroid"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_distance_centroid_nd"("public"."geometry", "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_distance_centroid_nd"("public"."geometry", "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_distance_centroid_nd"("public"."geometry", "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_distance_centroid_nd"("public"."geometry", "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_distance_cpa"("public"."geometry", "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_distance_cpa"("public"."geometry", "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_distance_cpa"("public"."geometry", "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_distance_cpa"("public"."geometry", "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_eq"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_eq"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_eq"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_eq"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_ge"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_ge"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_ge"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_ge"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_gist_compress_2d"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_gist_compress_2d"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_gist_compress_2d"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_gist_compress_2d"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_gist_compress_nd"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_gist_compress_nd"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_gist_compress_nd"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_gist_compress_nd"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_gist_consistent_2d"("internal", "public"."geometry", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_gist_consistent_2d"("internal", "public"."geometry", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_gist_consistent_2d"("internal", "public"."geometry", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_gist_consistent_2d"("internal", "public"."geometry", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_gist_consistent_nd"("internal", "public"."geometry", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_gist_consistent_nd"("internal", "public"."geometry", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_gist_consistent_nd"("internal", "public"."geometry", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_gist_consistent_nd"("internal", "public"."geometry", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_gist_decompress_2d"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_gist_decompress_2d"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_gist_decompress_2d"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_gist_decompress_2d"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_gist_decompress_nd"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_gist_decompress_nd"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_gist_decompress_nd"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_gist_decompress_nd"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_gist_distance_2d"("internal", "public"."geometry", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_gist_distance_2d"("internal", "public"."geometry", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_gist_distance_2d"("internal", "public"."geometry", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_gist_distance_2d"("internal", "public"."geometry", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_gist_distance_nd"("internal", "public"."geometry", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_gist_distance_nd"("internal", "public"."geometry", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_gist_distance_nd"("internal", "public"."geometry", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_gist_distance_nd"("internal", "public"."geometry", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_gist_penalty_2d"("internal", "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_gist_penalty_2d"("internal", "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_gist_penalty_2d"("internal", "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_gist_penalty_2d"("internal", "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_gist_penalty_nd"("internal", "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_gist_penalty_nd"("internal", "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_gist_penalty_nd"("internal", "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_gist_penalty_nd"("internal", "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_gist_picksplit_2d"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_gist_picksplit_2d"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_gist_picksplit_2d"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_gist_picksplit_2d"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_gist_picksplit_nd"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_gist_picksplit_nd"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_gist_picksplit_nd"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_gist_picksplit_nd"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_gist_same_2d"("geom1" "public"."geometry", "geom2" "public"."geometry", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_gist_same_2d"("geom1" "public"."geometry", "geom2" "public"."geometry", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_gist_same_2d"("geom1" "public"."geometry", "geom2" "public"."geometry", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_gist_same_2d"("geom1" "public"."geometry", "geom2" "public"."geometry", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_gist_same_nd"("public"."geometry", "public"."geometry", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_gist_same_nd"("public"."geometry", "public"."geometry", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_gist_same_nd"("public"."geometry", "public"."geometry", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_gist_same_nd"("public"."geometry", "public"."geometry", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_gist_sortsupport_2d"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_gist_sortsupport_2d"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_gist_sortsupport_2d"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_gist_sortsupport_2d"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_gist_union_2d"("bytea", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_gist_union_2d"("bytea", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_gist_union_2d"("bytea", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_gist_union_2d"("bytea", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_gist_union_nd"("bytea", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_gist_union_nd"("bytea", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_gist_union_nd"("bytea", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_gist_union_nd"("bytea", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_gt"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_gt"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_gt"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_gt"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_hash"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_hash"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_hash"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_hash"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_le"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_le"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_le"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_le"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_left"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_left"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_left"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_left"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_lt"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_lt"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_lt"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_lt"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_overabove"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_overabove"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_overabove"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_overabove"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_overbelow"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_overbelow"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_overbelow"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_overbelow"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_overlaps"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_overlaps"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_overlaps"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_overlaps"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_overlaps_3d"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_overlaps_3d"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_overlaps_3d"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_overlaps_3d"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_overlaps_nd"("public"."geometry", "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_overlaps_nd"("public"."geometry", "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_overlaps_nd"("public"."geometry", "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_overlaps_nd"("public"."geometry", "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_overleft"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_overleft"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_overleft"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_overleft"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_overright"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_overright"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_overright"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_overright"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_right"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_right"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_right"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_right"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_same"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_same"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_same"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_same"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_same_3d"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_same_3d"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_same_3d"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_same_3d"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_same_nd"("public"."geometry", "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_same_nd"("public"."geometry", "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_same_nd"("public"."geometry", "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_same_nd"("public"."geometry", "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_sortsupport"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_sortsupport"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_sortsupport"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_sortsupport"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_spgist_choose_2d"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_spgist_choose_2d"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_spgist_choose_2d"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_spgist_choose_2d"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_spgist_choose_3d"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_spgist_choose_3d"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_spgist_choose_3d"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_spgist_choose_3d"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_spgist_choose_nd"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_spgist_choose_nd"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_spgist_choose_nd"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_spgist_choose_nd"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_spgist_compress_2d"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_spgist_compress_2d"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_spgist_compress_2d"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_spgist_compress_2d"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_spgist_compress_3d"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_spgist_compress_3d"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_spgist_compress_3d"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_spgist_compress_3d"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_spgist_compress_nd"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_spgist_compress_nd"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_spgist_compress_nd"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_spgist_compress_nd"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_spgist_config_2d"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_spgist_config_2d"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_spgist_config_2d"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_spgist_config_2d"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_spgist_config_3d"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_spgist_config_3d"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_spgist_config_3d"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_spgist_config_3d"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_spgist_config_nd"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_spgist_config_nd"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_spgist_config_nd"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_spgist_config_nd"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_spgist_inner_consistent_2d"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_spgist_inner_consistent_2d"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_spgist_inner_consistent_2d"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_spgist_inner_consistent_2d"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_spgist_inner_consistent_3d"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_spgist_inner_consistent_3d"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_spgist_inner_consistent_3d"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_spgist_inner_consistent_3d"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_spgist_inner_consistent_nd"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_spgist_inner_consistent_nd"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_spgist_inner_consistent_nd"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_spgist_inner_consistent_nd"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_spgist_leaf_consistent_2d"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_spgist_leaf_consistent_2d"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_spgist_leaf_consistent_2d"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_spgist_leaf_consistent_2d"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_spgist_leaf_consistent_3d"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_spgist_leaf_consistent_3d"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_spgist_leaf_consistent_3d"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_spgist_leaf_consistent_3d"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_spgist_leaf_consistent_nd"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_spgist_leaf_consistent_nd"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_spgist_leaf_consistent_nd"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_spgist_leaf_consistent_nd"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_spgist_picksplit_2d"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_spgist_picksplit_2d"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_spgist_picksplit_2d"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_spgist_picksplit_2d"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_spgist_picksplit_3d"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_spgist_picksplit_3d"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_spgist_picksplit_3d"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_spgist_picksplit_3d"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_spgist_picksplit_nd"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_spgist_picksplit_nd"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_spgist_picksplit_nd"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_spgist_picksplit_nd"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_within"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_within"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_within"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_within"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometry_within_nd"("public"."geometry", "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometry_within_nd"("public"."geometry", "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."geometry_within_nd"("public"."geometry", "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometry_within_nd"("public"."geometry", "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometrytype"("public"."geography") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometrytype"("public"."geography") TO "anon";
GRANT ALL ON FUNCTION "public"."geometrytype"("public"."geography") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometrytype"("public"."geography") TO "service_role";



GRANT ALL ON FUNCTION "public"."geometrytype"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."geometrytype"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."geometrytype"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geometrytype"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."geomfromewkb"("bytea") TO "postgres";
GRANT ALL ON FUNCTION "public"."geomfromewkb"("bytea") TO "anon";
GRANT ALL ON FUNCTION "public"."geomfromewkb"("bytea") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geomfromewkb"("bytea") TO "service_role";



GRANT ALL ON FUNCTION "public"."geomfromewkt"("text") TO "postgres";
GRANT ALL ON FUNCTION "public"."geomfromewkt"("text") TO "anon";
GRANT ALL ON FUNCTION "public"."geomfromewkt"("text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."geomfromewkt"("text") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_organizer_leaderboard"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_organizer_leaderboard"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_organizer_leaderboard"() TO "service_role";



GRANT ALL ON FUNCTION "public"."get_proj4_from_srid"(integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."get_proj4_from_srid"(integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_proj4_from_srid"(integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_proj4_from_srid"(integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_supabase_url"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_supabase_url"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_supabase_url"() TO "service_role";



GRANT ALL ON FUNCTION "public"."get_survey_previous_answers"("p_contact_id" bigint, "p_survey_id" bigint, "p_exclude_response_id" bigint, "p_question_ids" bigint[], "p_limit_responses" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_survey_previous_answers"("p_contact_id" bigint, "p_survey_id" bigint, "p_exclude_response_id" bigint, "p_question_ids" bigint[], "p_limit_responses" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_survey_previous_answers"("p_contact_id" bigint, "p_survey_id" bigint, "p_exclude_response_id" bigint, "p_question_ids" bigint[], "p_limit_responses" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_web_requests"("filter_success" boolean, "filter_status" "text", "filter_category" "text", "date_from" timestamp with time zone, "date_to" timestamp with time zone, "search_term" "text", "sort_by" "text", "sort_order" "text", "page_offset" integer, "page_limit" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_web_requests"("filter_success" boolean, "filter_status" "text", "filter_category" "text", "date_from" timestamp with time zone, "date_to" timestamp with time zone, "search_term" "text", "sort_by" "text", "sort_order" "text", "page_offset" integer, "page_limit" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_web_requests"("filter_success" boolean, "filter_status" "text", "filter_category" "text", "date_from" timestamp with time zone, "date_to" timestamp with time zone, "search_term" "text", "sort_by" "text", "sort_order" "text", "page_offset" integer, "page_limit" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_web_requests"("filter_success" boolean, "filter_status" "text", "filter_category" "text", "date_from" timestamp with time zone, "date_to" timestamp with time zone, "search_term" "text", "sort_by" "text", "sort_order" "text", "page_offset" integer, "page_limit" integer, "show_duplicates" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."get_web_requests"("filter_success" boolean, "filter_status" "text", "filter_category" "text", "date_from" timestamp with time zone, "date_to" timestamp with time zone, "search_term" "text", "sort_by" "text", "sort_order" "text", "page_offset" integer, "page_limit" integer, "show_duplicates" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_web_requests"("filter_success" boolean, "filter_status" "text", "filter_category" "text", "date_from" timestamp with time zone, "date_to" timestamp with time zone, "search_term" "text", "sort_by" "text", "sort_order" "text", "page_offset" integer, "page_limit" integer, "show_duplicates" boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."gettransactionid"() TO "postgres";
GRANT ALL ON FUNCTION "public"."gettransactionid"() TO "anon";
GRANT ALL ON FUNCTION "public"."gettransactionid"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."gettransactionid"() TO "service_role";



GRANT ALL ON FUNCTION "public"."gserialized_gist_joinsel_2d"("internal", "oid", "internal", smallint) TO "postgres";
GRANT ALL ON FUNCTION "public"."gserialized_gist_joinsel_2d"("internal", "oid", "internal", smallint) TO "anon";
GRANT ALL ON FUNCTION "public"."gserialized_gist_joinsel_2d"("internal", "oid", "internal", smallint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."gserialized_gist_joinsel_2d"("internal", "oid", "internal", smallint) TO "service_role";



GRANT ALL ON FUNCTION "public"."gserialized_gist_joinsel_nd"("internal", "oid", "internal", smallint) TO "postgres";
GRANT ALL ON FUNCTION "public"."gserialized_gist_joinsel_nd"("internal", "oid", "internal", smallint) TO "anon";
GRANT ALL ON FUNCTION "public"."gserialized_gist_joinsel_nd"("internal", "oid", "internal", smallint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."gserialized_gist_joinsel_nd"("internal", "oid", "internal", smallint) TO "service_role";



GRANT ALL ON FUNCTION "public"."gserialized_gist_sel_2d"("internal", "oid", "internal", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."gserialized_gist_sel_2d"("internal", "oid", "internal", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."gserialized_gist_sel_2d"("internal", "oid", "internal", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."gserialized_gist_sel_2d"("internal", "oid", "internal", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."gserialized_gist_sel_nd"("internal", "oid", "internal", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."gserialized_gist_sel_nd"("internal", "oid", "internal", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."gserialized_gist_sel_nd"("internal", "oid", "internal", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."gserialized_gist_sel_nd"("internal", "oid", "internal", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."increment_campaign_sent_count"("campaign_id_param" bigint, "increment_amount" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."increment_campaign_sent_count"("campaign_id_param" bigint, "increment_amount" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."increment_campaign_sent_count"("campaign_id_param" bigint, "increment_amount" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."is_contained_2d"("public"."box2df", "public"."box2df") TO "postgres";
GRANT ALL ON FUNCTION "public"."is_contained_2d"("public"."box2df", "public"."box2df") TO "anon";
GRANT ALL ON FUNCTION "public"."is_contained_2d"("public"."box2df", "public"."box2df") TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_contained_2d"("public"."box2df", "public"."box2df") TO "service_role";



GRANT ALL ON FUNCTION "public"."is_contained_2d"("public"."box2df", "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."is_contained_2d"("public"."box2df", "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."is_contained_2d"("public"."box2df", "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_contained_2d"("public"."box2df", "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."is_contained_2d"("public"."geometry", "public"."box2df") TO "postgres";
GRANT ALL ON FUNCTION "public"."is_contained_2d"("public"."geometry", "public"."box2df") TO "anon";
GRANT ALL ON FUNCTION "public"."is_contained_2d"("public"."geometry", "public"."box2df") TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_contained_2d"("public"."geometry", "public"."box2df") TO "service_role";



GRANT ALL ON FUNCTION "public"."lockrow"("text", "text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."lockrow"("text", "text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."lockrow"("text", "text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."lockrow"("text", "text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."lockrow"("text", "text", "text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."lockrow"("text", "text", "text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."lockrow"("text", "text", "text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."lockrow"("text", "text", "text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."lockrow"("text", "text", "text", timestamp without time zone) TO "postgres";
GRANT ALL ON FUNCTION "public"."lockrow"("text", "text", "text", timestamp without time zone) TO "anon";
GRANT ALL ON FUNCTION "public"."lockrow"("text", "text", "text", timestamp without time zone) TO "authenticated";
GRANT ALL ON FUNCTION "public"."lockrow"("text", "text", "text", timestamp without time zone) TO "service_role";



GRANT ALL ON FUNCTION "public"."lockrow"("text", "text", "text", "text", timestamp without time zone) TO "postgres";
GRANT ALL ON FUNCTION "public"."lockrow"("text", "text", "text", "text", timestamp without time zone) TO "anon";
GRANT ALL ON FUNCTION "public"."lockrow"("text", "text", "text", "text", timestamp without time zone) TO "authenticated";
GRANT ALL ON FUNCTION "public"."lockrow"("text", "text", "text", "text", timestamp without time zone) TO "service_role";



GRANT ALL ON FUNCTION "public"."log_attachment_deletion"() TO "anon";
GRANT ALL ON FUNCTION "public"."log_attachment_deletion"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."log_attachment_deletion"() TO "service_role";



GRANT ALL ON FUNCTION "public"."longtransactionsenabled"() TO "postgres";
GRANT ALL ON FUNCTION "public"."longtransactionsenabled"() TO "anon";
GRANT ALL ON FUNCTION "public"."longtransactionsenabled"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."longtransactionsenabled"() TO "service_role";



GRANT ALL ON FUNCTION "public"."mark_campaign_job_complete"("campaign_id_param" bigint, "instance_id_param" bigint, "success_param" boolean, "error_message" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."mark_campaign_job_complete"("campaign_id_param" bigint, "instance_id_param" bigint, "success_param" boolean, "error_message" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."mark_campaign_job_complete"("campaign_id_param" bigint, "instance_id_param" bigint, "success_param" boolean, "error_message" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."overlaps_2d"("public"."box2df", "public"."box2df") TO "postgres";
GRANT ALL ON FUNCTION "public"."overlaps_2d"("public"."box2df", "public"."box2df") TO "anon";
GRANT ALL ON FUNCTION "public"."overlaps_2d"("public"."box2df", "public"."box2df") TO "authenticated";
GRANT ALL ON FUNCTION "public"."overlaps_2d"("public"."box2df", "public"."box2df") TO "service_role";



GRANT ALL ON FUNCTION "public"."overlaps_2d"("public"."box2df", "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."overlaps_2d"("public"."box2df", "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."overlaps_2d"("public"."box2df", "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."overlaps_2d"("public"."box2df", "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."overlaps_2d"("public"."geometry", "public"."box2df") TO "postgres";
GRANT ALL ON FUNCTION "public"."overlaps_2d"("public"."geometry", "public"."box2df") TO "anon";
GRANT ALL ON FUNCTION "public"."overlaps_2d"("public"."geometry", "public"."box2df") TO "authenticated";
GRANT ALL ON FUNCTION "public"."overlaps_2d"("public"."geometry", "public"."box2df") TO "service_role";



GRANT ALL ON FUNCTION "public"."overlaps_geog"("public"."geography", "public"."gidx") TO "postgres";
GRANT ALL ON FUNCTION "public"."overlaps_geog"("public"."geography", "public"."gidx") TO "anon";
GRANT ALL ON FUNCTION "public"."overlaps_geog"("public"."geography", "public"."gidx") TO "authenticated";
GRANT ALL ON FUNCTION "public"."overlaps_geog"("public"."geography", "public"."gidx") TO "service_role";



GRANT ALL ON FUNCTION "public"."overlaps_geog"("public"."gidx", "public"."geography") TO "postgres";
GRANT ALL ON FUNCTION "public"."overlaps_geog"("public"."gidx", "public"."geography") TO "anon";
GRANT ALL ON FUNCTION "public"."overlaps_geog"("public"."gidx", "public"."geography") TO "authenticated";
GRANT ALL ON FUNCTION "public"."overlaps_geog"("public"."gidx", "public"."geography") TO "service_role";



GRANT ALL ON FUNCTION "public"."overlaps_geog"("public"."gidx", "public"."gidx") TO "postgres";
GRANT ALL ON FUNCTION "public"."overlaps_geog"("public"."gidx", "public"."gidx") TO "anon";
GRANT ALL ON FUNCTION "public"."overlaps_geog"("public"."gidx", "public"."gidx") TO "authenticated";
GRANT ALL ON FUNCTION "public"."overlaps_geog"("public"."gidx", "public"."gidx") TO "service_role";



GRANT ALL ON FUNCTION "public"."overlaps_nd"("public"."geometry", "public"."gidx") TO "postgres";
GRANT ALL ON FUNCTION "public"."overlaps_nd"("public"."geometry", "public"."gidx") TO "anon";
GRANT ALL ON FUNCTION "public"."overlaps_nd"("public"."geometry", "public"."gidx") TO "authenticated";
GRANT ALL ON FUNCTION "public"."overlaps_nd"("public"."geometry", "public"."gidx") TO "service_role";



GRANT ALL ON FUNCTION "public"."overlaps_nd"("public"."gidx", "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."overlaps_nd"("public"."gidx", "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."overlaps_nd"("public"."gidx", "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."overlaps_nd"("public"."gidx", "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."overlaps_nd"("public"."gidx", "public"."gidx") TO "postgres";
GRANT ALL ON FUNCTION "public"."overlaps_nd"("public"."gidx", "public"."gidx") TO "anon";
GRANT ALL ON FUNCTION "public"."overlaps_nd"("public"."gidx", "public"."gidx") TO "authenticated";
GRANT ALL ON FUNCTION "public"."overlaps_nd"("public"."gidx", "public"."gidx") TO "service_role";



GRANT ALL ON FUNCTION "public"."pgis_asflatgeobuf_finalfn"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."pgis_asflatgeobuf_finalfn"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."pgis_asflatgeobuf_finalfn"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."pgis_asflatgeobuf_finalfn"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."pgis_asflatgeobuf_transfn"("internal", "anyelement") TO "postgres";
GRANT ALL ON FUNCTION "public"."pgis_asflatgeobuf_transfn"("internal", "anyelement") TO "anon";
GRANT ALL ON FUNCTION "public"."pgis_asflatgeobuf_transfn"("internal", "anyelement") TO "authenticated";
GRANT ALL ON FUNCTION "public"."pgis_asflatgeobuf_transfn"("internal", "anyelement") TO "service_role";



GRANT ALL ON FUNCTION "public"."pgis_asflatgeobuf_transfn"("internal", "anyelement", boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."pgis_asflatgeobuf_transfn"("internal", "anyelement", boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."pgis_asflatgeobuf_transfn"("internal", "anyelement", boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."pgis_asflatgeobuf_transfn"("internal", "anyelement", boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."pgis_asflatgeobuf_transfn"("internal", "anyelement", boolean, "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."pgis_asflatgeobuf_transfn"("internal", "anyelement", boolean, "text") TO "anon";
GRANT ALL ON FUNCTION "public"."pgis_asflatgeobuf_transfn"("internal", "anyelement", boolean, "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."pgis_asflatgeobuf_transfn"("internal", "anyelement", boolean, "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."pgis_asgeobuf_finalfn"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."pgis_asgeobuf_finalfn"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."pgis_asgeobuf_finalfn"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."pgis_asgeobuf_finalfn"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."pgis_asgeobuf_transfn"("internal", "anyelement") TO "postgres";
GRANT ALL ON FUNCTION "public"."pgis_asgeobuf_transfn"("internal", "anyelement") TO "anon";
GRANT ALL ON FUNCTION "public"."pgis_asgeobuf_transfn"("internal", "anyelement") TO "authenticated";
GRANT ALL ON FUNCTION "public"."pgis_asgeobuf_transfn"("internal", "anyelement") TO "service_role";



GRANT ALL ON FUNCTION "public"."pgis_asgeobuf_transfn"("internal", "anyelement", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."pgis_asgeobuf_transfn"("internal", "anyelement", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."pgis_asgeobuf_transfn"("internal", "anyelement", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."pgis_asgeobuf_transfn"("internal", "anyelement", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."pgis_asmvt_combinefn"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."pgis_asmvt_combinefn"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."pgis_asmvt_combinefn"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."pgis_asmvt_combinefn"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."pgis_asmvt_deserialfn"("bytea", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."pgis_asmvt_deserialfn"("bytea", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."pgis_asmvt_deserialfn"("bytea", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."pgis_asmvt_deserialfn"("bytea", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."pgis_asmvt_finalfn"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."pgis_asmvt_finalfn"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."pgis_asmvt_finalfn"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."pgis_asmvt_finalfn"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."pgis_asmvt_serialfn"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."pgis_asmvt_serialfn"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."pgis_asmvt_serialfn"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."pgis_asmvt_serialfn"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."pgis_asmvt_transfn"("internal", "anyelement") TO "postgres";
GRANT ALL ON FUNCTION "public"."pgis_asmvt_transfn"("internal", "anyelement") TO "anon";
GRANT ALL ON FUNCTION "public"."pgis_asmvt_transfn"("internal", "anyelement") TO "authenticated";
GRANT ALL ON FUNCTION "public"."pgis_asmvt_transfn"("internal", "anyelement") TO "service_role";



GRANT ALL ON FUNCTION "public"."pgis_asmvt_transfn"("internal", "anyelement", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."pgis_asmvt_transfn"("internal", "anyelement", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."pgis_asmvt_transfn"("internal", "anyelement", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."pgis_asmvt_transfn"("internal", "anyelement", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."pgis_asmvt_transfn"("internal", "anyelement", "text", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."pgis_asmvt_transfn"("internal", "anyelement", "text", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."pgis_asmvt_transfn"("internal", "anyelement", "text", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."pgis_asmvt_transfn"("internal", "anyelement", "text", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."pgis_asmvt_transfn"("internal", "anyelement", "text", integer, "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."pgis_asmvt_transfn"("internal", "anyelement", "text", integer, "text") TO "anon";
GRANT ALL ON FUNCTION "public"."pgis_asmvt_transfn"("internal", "anyelement", "text", integer, "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."pgis_asmvt_transfn"("internal", "anyelement", "text", integer, "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."pgis_asmvt_transfn"("internal", "anyelement", "text", integer, "text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."pgis_asmvt_transfn"("internal", "anyelement", "text", integer, "text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."pgis_asmvt_transfn"("internal", "anyelement", "text", integer, "text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."pgis_asmvt_transfn"("internal", "anyelement", "text", integer, "text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."pgis_geometry_accum_transfn"("internal", "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."pgis_geometry_accum_transfn"("internal", "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."pgis_geometry_accum_transfn"("internal", "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."pgis_geometry_accum_transfn"("internal", "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."pgis_geometry_accum_transfn"("internal", "public"."geometry", double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."pgis_geometry_accum_transfn"("internal", "public"."geometry", double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."pgis_geometry_accum_transfn"("internal", "public"."geometry", double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."pgis_geometry_accum_transfn"("internal", "public"."geometry", double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."pgis_geometry_accum_transfn"("internal", "public"."geometry", double precision, integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."pgis_geometry_accum_transfn"("internal", "public"."geometry", double precision, integer) TO "anon";
GRANT ALL ON FUNCTION "public"."pgis_geometry_accum_transfn"("internal", "public"."geometry", double precision, integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."pgis_geometry_accum_transfn"("internal", "public"."geometry", double precision, integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."pgis_geometry_clusterintersecting_finalfn"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."pgis_geometry_clusterintersecting_finalfn"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."pgis_geometry_clusterintersecting_finalfn"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."pgis_geometry_clusterintersecting_finalfn"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."pgis_geometry_clusterwithin_finalfn"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."pgis_geometry_clusterwithin_finalfn"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."pgis_geometry_clusterwithin_finalfn"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."pgis_geometry_clusterwithin_finalfn"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."pgis_geometry_collect_finalfn"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."pgis_geometry_collect_finalfn"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."pgis_geometry_collect_finalfn"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."pgis_geometry_collect_finalfn"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."pgis_geometry_makeline_finalfn"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."pgis_geometry_makeline_finalfn"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."pgis_geometry_makeline_finalfn"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."pgis_geometry_makeline_finalfn"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."pgis_geometry_polygonize_finalfn"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."pgis_geometry_polygonize_finalfn"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."pgis_geometry_polygonize_finalfn"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."pgis_geometry_polygonize_finalfn"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."pgis_geometry_union_parallel_combinefn"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."pgis_geometry_union_parallel_combinefn"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."pgis_geometry_union_parallel_combinefn"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."pgis_geometry_union_parallel_combinefn"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."pgis_geometry_union_parallel_deserialfn"("bytea", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."pgis_geometry_union_parallel_deserialfn"("bytea", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."pgis_geometry_union_parallel_deserialfn"("bytea", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."pgis_geometry_union_parallel_deserialfn"("bytea", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."pgis_geometry_union_parallel_finalfn"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."pgis_geometry_union_parallel_finalfn"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."pgis_geometry_union_parallel_finalfn"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."pgis_geometry_union_parallel_finalfn"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."pgis_geometry_union_parallel_serialfn"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."pgis_geometry_union_parallel_serialfn"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."pgis_geometry_union_parallel_serialfn"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."pgis_geometry_union_parallel_serialfn"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."pgis_geometry_union_parallel_transfn"("internal", "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."pgis_geometry_union_parallel_transfn"("internal", "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."pgis_geometry_union_parallel_transfn"("internal", "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."pgis_geometry_union_parallel_transfn"("internal", "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."pgis_geometry_union_parallel_transfn"("internal", "public"."geometry", double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."pgis_geometry_union_parallel_transfn"("internal", "public"."geometry", double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."pgis_geometry_union_parallel_transfn"("internal", "public"."geometry", double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."pgis_geometry_union_parallel_transfn"("internal", "public"."geometry", double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."pgmq_archive_survey_job"("queue_name" "text", "msg_id_param" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."pgmq_archive_survey_job"("queue_name" "text", "msg_id_param" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."pgmq_archive_survey_job"("queue_name" "text", "msg_id_param" bigint) TO "service_role";



GRANT ALL ON FUNCTION "public"."pgmq_archive_webhook_job"("queue_name" "text", "msg_id_param" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."pgmq_archive_webhook_job"("queue_name" "text", "msg_id_param" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."pgmq_archive_webhook_job"("queue_name" "text", "msg_id_param" bigint) TO "service_role";



GRANT ALL ON FUNCTION "public"."pgmq_delete_survey_job"("queue_name" "text", "msg_id_param" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."pgmq_delete_survey_job"("queue_name" "text", "msg_id_param" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."pgmq_delete_survey_job"("queue_name" "text", "msg_id_param" bigint) TO "service_role";



GRANT ALL ON FUNCTION "public"."pgmq_delete_webhook_job"("queue_name" "text", "msg_id_param" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."pgmq_delete_webhook_job"("queue_name" "text", "msg_id_param" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."pgmq_delete_webhook_job"("queue_name" "text", "msg_id_param" bigint) TO "service_role";



GRANT ALL ON FUNCTION "public"."pgmq_read_survey_jobs"("queue_name" "text", "vt" integer, "qty" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."pgmq_read_survey_jobs"("queue_name" "text", "vt" integer, "qty" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."pgmq_read_survey_jobs"("queue_name" "text", "vt" integer, "qty" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."pgmq_read_webhook_jobs"("queue_name" "text", "vt" integer, "qty" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."pgmq_read_webhook_jobs"("queue_name" "text", "vt" integer, "qty" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."pgmq_read_webhook_jobs"("queue_name" "text", "vt" integer, "qty" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."pgmq_send_survey_job"("queue_name" "text", "message" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."pgmq_send_survey_job"("queue_name" "text", "message" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."pgmq_send_survey_job"("queue_name" "text", "message" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."pgmq_send_webhook_job"("queue_name" "text", "message" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."pgmq_send_webhook_job"("queue_name" "text", "message" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."pgmq_send_webhook_job"("queue_name" "text", "message" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."populate_geometry_columns"("use_typmod" boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."populate_geometry_columns"("use_typmod" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."populate_geometry_columns"("use_typmod" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."populate_geometry_columns"("use_typmod" boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."populate_geometry_columns"("tbl_oid" "oid", "use_typmod" boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."populate_geometry_columns"("tbl_oid" "oid", "use_typmod" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."populate_geometry_columns"("tbl_oid" "oid", "use_typmod" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."populate_geometry_columns"("tbl_oid" "oid", "use_typmod" boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."postgis_addbbox"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."postgis_addbbox"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."postgis_addbbox"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."postgis_addbbox"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."postgis_cache_bbox"() TO "postgres";
GRANT ALL ON FUNCTION "public"."postgis_cache_bbox"() TO "anon";
GRANT ALL ON FUNCTION "public"."postgis_cache_bbox"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."postgis_cache_bbox"() TO "service_role";



GRANT ALL ON FUNCTION "public"."postgis_constraint_dims"("geomschema" "text", "geomtable" "text", "geomcolumn" "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."postgis_constraint_dims"("geomschema" "text", "geomtable" "text", "geomcolumn" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."postgis_constraint_dims"("geomschema" "text", "geomtable" "text", "geomcolumn" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."postgis_constraint_dims"("geomschema" "text", "geomtable" "text", "geomcolumn" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."postgis_constraint_srid"("geomschema" "text", "geomtable" "text", "geomcolumn" "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."postgis_constraint_srid"("geomschema" "text", "geomtable" "text", "geomcolumn" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."postgis_constraint_srid"("geomschema" "text", "geomtable" "text", "geomcolumn" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."postgis_constraint_srid"("geomschema" "text", "geomtable" "text", "geomcolumn" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."postgis_constraint_type"("geomschema" "text", "geomtable" "text", "geomcolumn" "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."postgis_constraint_type"("geomschema" "text", "geomtable" "text", "geomcolumn" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."postgis_constraint_type"("geomschema" "text", "geomtable" "text", "geomcolumn" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."postgis_constraint_type"("geomschema" "text", "geomtable" "text", "geomcolumn" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."postgis_dropbbox"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."postgis_dropbbox"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."postgis_dropbbox"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."postgis_dropbbox"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."postgis_extensions_upgrade"() TO "postgres";
GRANT ALL ON FUNCTION "public"."postgis_extensions_upgrade"() TO "anon";
GRANT ALL ON FUNCTION "public"."postgis_extensions_upgrade"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."postgis_extensions_upgrade"() TO "service_role";



GRANT ALL ON FUNCTION "public"."postgis_full_version"() TO "postgres";
GRANT ALL ON FUNCTION "public"."postgis_full_version"() TO "anon";
GRANT ALL ON FUNCTION "public"."postgis_full_version"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."postgis_full_version"() TO "service_role";



GRANT ALL ON FUNCTION "public"."postgis_geos_noop"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."postgis_geos_noop"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."postgis_geos_noop"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."postgis_geos_noop"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."postgis_geos_version"() TO "postgres";
GRANT ALL ON FUNCTION "public"."postgis_geos_version"() TO "anon";
GRANT ALL ON FUNCTION "public"."postgis_geos_version"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."postgis_geos_version"() TO "service_role";



GRANT ALL ON FUNCTION "public"."postgis_getbbox"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."postgis_getbbox"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."postgis_getbbox"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."postgis_getbbox"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."postgis_hasbbox"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."postgis_hasbbox"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."postgis_hasbbox"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."postgis_hasbbox"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."postgis_index_supportfn"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."postgis_index_supportfn"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."postgis_index_supportfn"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."postgis_index_supportfn"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."postgis_lib_build_date"() TO "postgres";
GRANT ALL ON FUNCTION "public"."postgis_lib_build_date"() TO "anon";
GRANT ALL ON FUNCTION "public"."postgis_lib_build_date"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."postgis_lib_build_date"() TO "service_role";



GRANT ALL ON FUNCTION "public"."postgis_lib_revision"() TO "postgres";
GRANT ALL ON FUNCTION "public"."postgis_lib_revision"() TO "anon";
GRANT ALL ON FUNCTION "public"."postgis_lib_revision"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."postgis_lib_revision"() TO "service_role";



GRANT ALL ON FUNCTION "public"."postgis_lib_version"() TO "postgres";
GRANT ALL ON FUNCTION "public"."postgis_lib_version"() TO "anon";
GRANT ALL ON FUNCTION "public"."postgis_lib_version"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."postgis_lib_version"() TO "service_role";



GRANT ALL ON FUNCTION "public"."postgis_libjson_version"() TO "postgres";
GRANT ALL ON FUNCTION "public"."postgis_libjson_version"() TO "anon";
GRANT ALL ON FUNCTION "public"."postgis_libjson_version"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."postgis_libjson_version"() TO "service_role";



GRANT ALL ON FUNCTION "public"."postgis_liblwgeom_version"() TO "postgres";
GRANT ALL ON FUNCTION "public"."postgis_liblwgeom_version"() TO "anon";
GRANT ALL ON FUNCTION "public"."postgis_liblwgeom_version"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."postgis_liblwgeom_version"() TO "service_role";



GRANT ALL ON FUNCTION "public"."postgis_libprotobuf_version"() TO "postgres";
GRANT ALL ON FUNCTION "public"."postgis_libprotobuf_version"() TO "anon";
GRANT ALL ON FUNCTION "public"."postgis_libprotobuf_version"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."postgis_libprotobuf_version"() TO "service_role";



GRANT ALL ON FUNCTION "public"."postgis_libxml_version"() TO "postgres";
GRANT ALL ON FUNCTION "public"."postgis_libxml_version"() TO "anon";
GRANT ALL ON FUNCTION "public"."postgis_libxml_version"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."postgis_libxml_version"() TO "service_role";



GRANT ALL ON FUNCTION "public"."postgis_noop"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."postgis_noop"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."postgis_noop"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."postgis_noop"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."postgis_proj_version"() TO "postgres";
GRANT ALL ON FUNCTION "public"."postgis_proj_version"() TO "anon";
GRANT ALL ON FUNCTION "public"."postgis_proj_version"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."postgis_proj_version"() TO "service_role";



GRANT ALL ON FUNCTION "public"."postgis_scripts_build_date"() TO "postgres";
GRANT ALL ON FUNCTION "public"."postgis_scripts_build_date"() TO "anon";
GRANT ALL ON FUNCTION "public"."postgis_scripts_build_date"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."postgis_scripts_build_date"() TO "service_role";



GRANT ALL ON FUNCTION "public"."postgis_scripts_installed"() TO "postgres";
GRANT ALL ON FUNCTION "public"."postgis_scripts_installed"() TO "anon";
GRANT ALL ON FUNCTION "public"."postgis_scripts_installed"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."postgis_scripts_installed"() TO "service_role";



GRANT ALL ON FUNCTION "public"."postgis_scripts_released"() TO "postgres";
GRANT ALL ON FUNCTION "public"."postgis_scripts_released"() TO "anon";
GRANT ALL ON FUNCTION "public"."postgis_scripts_released"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."postgis_scripts_released"() TO "service_role";



GRANT ALL ON FUNCTION "public"."postgis_svn_version"() TO "postgres";
GRANT ALL ON FUNCTION "public"."postgis_svn_version"() TO "anon";
GRANT ALL ON FUNCTION "public"."postgis_svn_version"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."postgis_svn_version"() TO "service_role";



GRANT ALL ON FUNCTION "public"."postgis_transform_geometry"("geom" "public"."geometry", "text", "text", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."postgis_transform_geometry"("geom" "public"."geometry", "text", "text", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."postgis_transform_geometry"("geom" "public"."geometry", "text", "text", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."postgis_transform_geometry"("geom" "public"."geometry", "text", "text", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."postgis_type_name"("geomname" character varying, "coord_dimension" integer, "use_new_name" boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."postgis_type_name"("geomname" character varying, "coord_dimension" integer, "use_new_name" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."postgis_type_name"("geomname" character varying, "coord_dimension" integer, "use_new_name" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."postgis_type_name"("geomname" character varying, "coord_dimension" integer, "use_new_name" boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."postgis_typmod_dims"(integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."postgis_typmod_dims"(integer) TO "anon";
GRANT ALL ON FUNCTION "public"."postgis_typmod_dims"(integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."postgis_typmod_dims"(integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."postgis_typmod_srid"(integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."postgis_typmod_srid"(integer) TO "anon";
GRANT ALL ON FUNCTION "public"."postgis_typmod_srid"(integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."postgis_typmod_srid"(integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."postgis_typmod_type"(integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."postgis_typmod_type"(integer) TO "anon";
GRANT ALL ON FUNCTION "public"."postgis_typmod_type"(integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."postgis_typmod_type"(integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."postgis_version"() TO "postgres";
GRANT ALL ON FUNCTION "public"."postgis_version"() TO "anon";
GRANT ALL ON FUNCTION "public"."postgis_version"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."postgis_version"() TO "service_role";



GRANT ALL ON FUNCTION "public"."postgis_wagyu_version"() TO "postgres";
GRANT ALL ON FUNCTION "public"."postgis_wagyu_version"() TO "anon";
GRANT ALL ON FUNCTION "public"."postgis_wagyu_version"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."postgis_wagyu_version"() TO "service_role";



GRANT ALL ON FUNCTION "public"."prevent_sensitive_profile_updates"() TO "anon";
GRANT ALL ON FUNCTION "public"."prevent_sensitive_profile_updates"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."prevent_sensitive_profile_updates"() TO "service_role";



GRANT ALL ON FUNCTION "public"."schedule_events_sync_cron"("schedule_cron" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."schedule_events_sync_cron"("schedule_cron" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."schedule_events_sync_cron"("schedule_cron" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."set_events_sync_auth_token"("auth_token" "text", "project_ref" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."set_events_sync_auth_token"("auth_token" "text", "project_ref" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_events_sync_auth_token"("auth_token" "text", "project_ref" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_3dclosestpoint"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_3dclosestpoint"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_3dclosestpoint"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_3dclosestpoint"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_3ddfullywithin"("geom1" "public"."geometry", "geom2" "public"."geometry", double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_3ddfullywithin"("geom1" "public"."geometry", "geom2" "public"."geometry", double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_3ddfullywithin"("geom1" "public"."geometry", "geom2" "public"."geometry", double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_3ddfullywithin"("geom1" "public"."geometry", "geom2" "public"."geometry", double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_3ddistance"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_3ddistance"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_3ddistance"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_3ddistance"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_3ddwithin"("geom1" "public"."geometry", "geom2" "public"."geometry", double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_3ddwithin"("geom1" "public"."geometry", "geom2" "public"."geometry", double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_3ddwithin"("geom1" "public"."geometry", "geom2" "public"."geometry", double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_3ddwithin"("geom1" "public"."geometry", "geom2" "public"."geometry", double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_3dintersects"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_3dintersects"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_3dintersects"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_3dintersects"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_3dlength"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_3dlength"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_3dlength"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_3dlength"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_3dlineinterpolatepoint"("public"."geometry", double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_3dlineinterpolatepoint"("public"."geometry", double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_3dlineinterpolatepoint"("public"."geometry", double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_3dlineinterpolatepoint"("public"."geometry", double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_3dlongestline"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_3dlongestline"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_3dlongestline"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_3dlongestline"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_3dmakebox"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_3dmakebox"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_3dmakebox"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_3dmakebox"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_3dmaxdistance"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_3dmaxdistance"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_3dmaxdistance"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_3dmaxdistance"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_3dperimeter"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_3dperimeter"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_3dperimeter"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_3dperimeter"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_3dshortestline"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_3dshortestline"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_3dshortestline"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_3dshortestline"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_addmeasure"("public"."geometry", double precision, double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_addmeasure"("public"."geometry", double precision, double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_addmeasure"("public"."geometry", double precision, double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_addmeasure"("public"."geometry", double precision, double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_addpoint"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_addpoint"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_addpoint"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_addpoint"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_addpoint"("geom1" "public"."geometry", "geom2" "public"."geometry", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_addpoint"("geom1" "public"."geometry", "geom2" "public"."geometry", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_addpoint"("geom1" "public"."geometry", "geom2" "public"."geometry", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_addpoint"("geom1" "public"."geometry", "geom2" "public"."geometry", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_affine"("public"."geometry", double precision, double precision, double precision, double precision, double precision, double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_affine"("public"."geometry", double precision, double precision, double precision, double precision, double precision, double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_affine"("public"."geometry", double precision, double precision, double precision, double precision, double precision, double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_affine"("public"."geometry", double precision, double precision, double precision, double precision, double precision, double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_affine"("public"."geometry", double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_affine"("public"."geometry", double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_affine"("public"."geometry", double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_affine"("public"."geometry", double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_angle"("line1" "public"."geometry", "line2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_angle"("line1" "public"."geometry", "line2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_angle"("line1" "public"."geometry", "line2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_angle"("line1" "public"."geometry", "line2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_angle"("pt1" "public"."geometry", "pt2" "public"."geometry", "pt3" "public"."geometry", "pt4" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_angle"("pt1" "public"."geometry", "pt2" "public"."geometry", "pt3" "public"."geometry", "pt4" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_angle"("pt1" "public"."geometry", "pt2" "public"."geometry", "pt3" "public"."geometry", "pt4" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_angle"("pt1" "public"."geometry", "pt2" "public"."geometry", "pt3" "public"."geometry", "pt4" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_area"("text") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_area"("text") TO "anon";
GRANT ALL ON FUNCTION "public"."st_area"("text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_area"("text") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_area"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_area"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_area"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_area"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_area"("geog" "public"."geography", "use_spheroid" boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_area"("geog" "public"."geography", "use_spheroid" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."st_area"("geog" "public"."geography", "use_spheroid" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_area"("geog" "public"."geography", "use_spheroid" boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_area2d"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_area2d"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_area2d"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_area2d"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_asbinary"("public"."geography") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_asbinary"("public"."geography") TO "anon";
GRANT ALL ON FUNCTION "public"."st_asbinary"("public"."geography") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_asbinary"("public"."geography") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_asbinary"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_asbinary"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_asbinary"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_asbinary"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_asbinary"("public"."geography", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_asbinary"("public"."geography", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."st_asbinary"("public"."geography", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_asbinary"("public"."geography", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_asbinary"("public"."geometry", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_asbinary"("public"."geometry", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."st_asbinary"("public"."geometry", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_asbinary"("public"."geometry", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_asencodedpolyline"("geom" "public"."geometry", "nprecision" integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_asencodedpolyline"("geom" "public"."geometry", "nprecision" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_asencodedpolyline"("geom" "public"."geometry", "nprecision" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_asencodedpolyline"("geom" "public"."geometry", "nprecision" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_asewkb"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_asewkb"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_asewkb"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_asewkb"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_asewkb"("public"."geometry", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_asewkb"("public"."geometry", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."st_asewkb"("public"."geometry", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_asewkb"("public"."geometry", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_asewkt"("text") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_asewkt"("text") TO "anon";
GRANT ALL ON FUNCTION "public"."st_asewkt"("text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_asewkt"("text") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_asewkt"("public"."geography") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_asewkt"("public"."geography") TO "anon";
GRANT ALL ON FUNCTION "public"."st_asewkt"("public"."geography") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_asewkt"("public"."geography") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_asewkt"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_asewkt"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_asewkt"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_asewkt"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_asewkt"("public"."geography", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_asewkt"("public"."geography", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_asewkt"("public"."geography", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_asewkt"("public"."geography", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_asewkt"("public"."geometry", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_asewkt"("public"."geometry", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_asewkt"("public"."geometry", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_asewkt"("public"."geometry", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_asgeojson"("text") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_asgeojson"("text") TO "anon";
GRANT ALL ON FUNCTION "public"."st_asgeojson"("text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_asgeojson"("text") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_asgeojson"("geog" "public"."geography", "maxdecimaldigits" integer, "options" integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_asgeojson"("geog" "public"."geography", "maxdecimaldigits" integer, "options" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_asgeojson"("geog" "public"."geography", "maxdecimaldigits" integer, "options" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_asgeojson"("geog" "public"."geography", "maxdecimaldigits" integer, "options" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_asgeojson"("geom" "public"."geometry", "maxdecimaldigits" integer, "options" integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_asgeojson"("geom" "public"."geometry", "maxdecimaldigits" integer, "options" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_asgeojson"("geom" "public"."geometry", "maxdecimaldigits" integer, "options" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_asgeojson"("geom" "public"."geometry", "maxdecimaldigits" integer, "options" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_asgeojson"("r" "record", "geom_column" "text", "maxdecimaldigits" integer, "pretty_bool" boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_asgeojson"("r" "record", "geom_column" "text", "maxdecimaldigits" integer, "pretty_bool" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."st_asgeojson"("r" "record", "geom_column" "text", "maxdecimaldigits" integer, "pretty_bool" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_asgeojson"("r" "record", "geom_column" "text", "maxdecimaldigits" integer, "pretty_bool" boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_asgml"("text") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_asgml"("text") TO "anon";
GRANT ALL ON FUNCTION "public"."st_asgml"("text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_asgml"("text") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_asgml"("geom" "public"."geometry", "maxdecimaldigits" integer, "options" integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_asgml"("geom" "public"."geometry", "maxdecimaldigits" integer, "options" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_asgml"("geom" "public"."geometry", "maxdecimaldigits" integer, "options" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_asgml"("geom" "public"."geometry", "maxdecimaldigits" integer, "options" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_asgml"("geog" "public"."geography", "maxdecimaldigits" integer, "options" integer, "nprefix" "text", "id" "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_asgml"("geog" "public"."geography", "maxdecimaldigits" integer, "options" integer, "nprefix" "text", "id" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."st_asgml"("geog" "public"."geography", "maxdecimaldigits" integer, "options" integer, "nprefix" "text", "id" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_asgml"("geog" "public"."geography", "maxdecimaldigits" integer, "options" integer, "nprefix" "text", "id" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_asgml"("version" integer, "geog" "public"."geography", "maxdecimaldigits" integer, "options" integer, "nprefix" "text", "id" "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_asgml"("version" integer, "geog" "public"."geography", "maxdecimaldigits" integer, "options" integer, "nprefix" "text", "id" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."st_asgml"("version" integer, "geog" "public"."geography", "maxdecimaldigits" integer, "options" integer, "nprefix" "text", "id" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_asgml"("version" integer, "geog" "public"."geography", "maxdecimaldigits" integer, "options" integer, "nprefix" "text", "id" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_asgml"("version" integer, "geom" "public"."geometry", "maxdecimaldigits" integer, "options" integer, "nprefix" "text", "id" "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_asgml"("version" integer, "geom" "public"."geometry", "maxdecimaldigits" integer, "options" integer, "nprefix" "text", "id" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."st_asgml"("version" integer, "geom" "public"."geometry", "maxdecimaldigits" integer, "options" integer, "nprefix" "text", "id" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_asgml"("version" integer, "geom" "public"."geometry", "maxdecimaldigits" integer, "options" integer, "nprefix" "text", "id" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_ashexewkb"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_ashexewkb"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_ashexewkb"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_ashexewkb"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_ashexewkb"("public"."geometry", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_ashexewkb"("public"."geometry", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."st_ashexewkb"("public"."geometry", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_ashexewkb"("public"."geometry", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_askml"("text") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_askml"("text") TO "anon";
GRANT ALL ON FUNCTION "public"."st_askml"("text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_askml"("text") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_askml"("geog" "public"."geography", "maxdecimaldigits" integer, "nprefix" "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_askml"("geog" "public"."geography", "maxdecimaldigits" integer, "nprefix" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."st_askml"("geog" "public"."geography", "maxdecimaldigits" integer, "nprefix" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_askml"("geog" "public"."geography", "maxdecimaldigits" integer, "nprefix" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_askml"("geom" "public"."geometry", "maxdecimaldigits" integer, "nprefix" "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_askml"("geom" "public"."geometry", "maxdecimaldigits" integer, "nprefix" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."st_askml"("geom" "public"."geometry", "maxdecimaldigits" integer, "nprefix" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_askml"("geom" "public"."geometry", "maxdecimaldigits" integer, "nprefix" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_aslatlontext"("geom" "public"."geometry", "tmpl" "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_aslatlontext"("geom" "public"."geometry", "tmpl" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."st_aslatlontext"("geom" "public"."geometry", "tmpl" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_aslatlontext"("geom" "public"."geometry", "tmpl" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_asmarc21"("geom" "public"."geometry", "format" "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_asmarc21"("geom" "public"."geometry", "format" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."st_asmarc21"("geom" "public"."geometry", "format" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_asmarc21"("geom" "public"."geometry", "format" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_asmvtgeom"("geom" "public"."geometry", "bounds" "public"."box2d", "extent" integer, "buffer" integer, "clip_geom" boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_asmvtgeom"("geom" "public"."geometry", "bounds" "public"."box2d", "extent" integer, "buffer" integer, "clip_geom" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."st_asmvtgeom"("geom" "public"."geometry", "bounds" "public"."box2d", "extent" integer, "buffer" integer, "clip_geom" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_asmvtgeom"("geom" "public"."geometry", "bounds" "public"."box2d", "extent" integer, "buffer" integer, "clip_geom" boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_assvg"("text") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_assvg"("text") TO "anon";
GRANT ALL ON FUNCTION "public"."st_assvg"("text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_assvg"("text") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_assvg"("geog" "public"."geography", "rel" integer, "maxdecimaldigits" integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_assvg"("geog" "public"."geography", "rel" integer, "maxdecimaldigits" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_assvg"("geog" "public"."geography", "rel" integer, "maxdecimaldigits" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_assvg"("geog" "public"."geography", "rel" integer, "maxdecimaldigits" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_assvg"("geom" "public"."geometry", "rel" integer, "maxdecimaldigits" integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_assvg"("geom" "public"."geometry", "rel" integer, "maxdecimaldigits" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_assvg"("geom" "public"."geometry", "rel" integer, "maxdecimaldigits" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_assvg"("geom" "public"."geometry", "rel" integer, "maxdecimaldigits" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_astext"("text") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_astext"("text") TO "anon";
GRANT ALL ON FUNCTION "public"."st_astext"("text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_astext"("text") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_astext"("public"."geography") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_astext"("public"."geography") TO "anon";
GRANT ALL ON FUNCTION "public"."st_astext"("public"."geography") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_astext"("public"."geography") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_astext"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_astext"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_astext"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_astext"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_astext"("public"."geography", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_astext"("public"."geography", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_astext"("public"."geography", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_astext"("public"."geography", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_astext"("public"."geometry", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_astext"("public"."geometry", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_astext"("public"."geometry", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_astext"("public"."geometry", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_astwkb"("geom" "public"."geometry", "prec" integer, "prec_z" integer, "prec_m" integer, "with_sizes" boolean, "with_boxes" boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_astwkb"("geom" "public"."geometry", "prec" integer, "prec_z" integer, "prec_m" integer, "with_sizes" boolean, "with_boxes" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."st_astwkb"("geom" "public"."geometry", "prec" integer, "prec_z" integer, "prec_m" integer, "with_sizes" boolean, "with_boxes" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_astwkb"("geom" "public"."geometry", "prec" integer, "prec_z" integer, "prec_m" integer, "with_sizes" boolean, "with_boxes" boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_astwkb"("geom" "public"."geometry"[], "ids" bigint[], "prec" integer, "prec_z" integer, "prec_m" integer, "with_sizes" boolean, "with_boxes" boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_astwkb"("geom" "public"."geometry"[], "ids" bigint[], "prec" integer, "prec_z" integer, "prec_m" integer, "with_sizes" boolean, "with_boxes" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."st_astwkb"("geom" "public"."geometry"[], "ids" bigint[], "prec" integer, "prec_z" integer, "prec_m" integer, "with_sizes" boolean, "with_boxes" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_astwkb"("geom" "public"."geometry"[], "ids" bigint[], "prec" integer, "prec_z" integer, "prec_m" integer, "with_sizes" boolean, "with_boxes" boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_asx3d"("geom" "public"."geometry", "maxdecimaldigits" integer, "options" integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_asx3d"("geom" "public"."geometry", "maxdecimaldigits" integer, "options" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_asx3d"("geom" "public"."geometry", "maxdecimaldigits" integer, "options" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_asx3d"("geom" "public"."geometry", "maxdecimaldigits" integer, "options" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_azimuth"("geog1" "public"."geography", "geog2" "public"."geography") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_azimuth"("geog1" "public"."geography", "geog2" "public"."geography") TO "anon";
GRANT ALL ON FUNCTION "public"."st_azimuth"("geog1" "public"."geography", "geog2" "public"."geography") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_azimuth"("geog1" "public"."geography", "geog2" "public"."geography") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_azimuth"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_azimuth"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_azimuth"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_azimuth"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_bdmpolyfromtext"("text", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_bdmpolyfromtext"("text", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_bdmpolyfromtext"("text", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_bdmpolyfromtext"("text", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_bdpolyfromtext"("text", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_bdpolyfromtext"("text", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_bdpolyfromtext"("text", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_bdpolyfromtext"("text", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_boundary"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_boundary"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_boundary"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_boundary"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_boundingdiagonal"("geom" "public"."geometry", "fits" boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_boundingdiagonal"("geom" "public"."geometry", "fits" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."st_boundingdiagonal"("geom" "public"."geometry", "fits" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_boundingdiagonal"("geom" "public"."geometry", "fits" boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_box2dfromgeohash"("text", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_box2dfromgeohash"("text", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_box2dfromgeohash"("text", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_box2dfromgeohash"("text", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_buffer"("text", double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_buffer"("text", double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_buffer"("text", double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_buffer"("text", double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_buffer"("public"."geography", double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_buffer"("public"."geography", double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_buffer"("public"."geography", double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_buffer"("public"."geography", double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_buffer"("text", double precision, integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_buffer"("text", double precision, integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_buffer"("text", double precision, integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_buffer"("text", double precision, integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_buffer"("text", double precision, "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_buffer"("text", double precision, "text") TO "anon";
GRANT ALL ON FUNCTION "public"."st_buffer"("text", double precision, "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_buffer"("text", double precision, "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_buffer"("public"."geography", double precision, integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_buffer"("public"."geography", double precision, integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_buffer"("public"."geography", double precision, integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_buffer"("public"."geography", double precision, integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_buffer"("public"."geography", double precision, "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_buffer"("public"."geography", double precision, "text") TO "anon";
GRANT ALL ON FUNCTION "public"."st_buffer"("public"."geography", double precision, "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_buffer"("public"."geography", double precision, "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_buffer"("geom" "public"."geometry", "radius" double precision, "quadsegs" integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_buffer"("geom" "public"."geometry", "radius" double precision, "quadsegs" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_buffer"("geom" "public"."geometry", "radius" double precision, "quadsegs" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_buffer"("geom" "public"."geometry", "radius" double precision, "quadsegs" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_buffer"("geom" "public"."geometry", "radius" double precision, "options" "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_buffer"("geom" "public"."geometry", "radius" double precision, "options" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."st_buffer"("geom" "public"."geometry", "radius" double precision, "options" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_buffer"("geom" "public"."geometry", "radius" double precision, "options" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_buildarea"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_buildarea"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_buildarea"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_buildarea"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_centroid"("text") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_centroid"("text") TO "anon";
GRANT ALL ON FUNCTION "public"."st_centroid"("text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_centroid"("text") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_centroid"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_centroid"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_centroid"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_centroid"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_centroid"("public"."geography", "use_spheroid" boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_centroid"("public"."geography", "use_spheroid" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."st_centroid"("public"."geography", "use_spheroid" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_centroid"("public"."geography", "use_spheroid" boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_chaikinsmoothing"("public"."geometry", integer, boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_chaikinsmoothing"("public"."geometry", integer, boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."st_chaikinsmoothing"("public"."geometry", integer, boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_chaikinsmoothing"("public"."geometry", integer, boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_cleangeometry"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_cleangeometry"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_cleangeometry"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_cleangeometry"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_clipbybox2d"("geom" "public"."geometry", "box" "public"."box2d") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_clipbybox2d"("geom" "public"."geometry", "box" "public"."box2d") TO "anon";
GRANT ALL ON FUNCTION "public"."st_clipbybox2d"("geom" "public"."geometry", "box" "public"."box2d") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_clipbybox2d"("geom" "public"."geometry", "box" "public"."box2d") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_closestpoint"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_closestpoint"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_closestpoint"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_closestpoint"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_closestpointofapproach"("public"."geometry", "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_closestpointofapproach"("public"."geometry", "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_closestpointofapproach"("public"."geometry", "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_closestpointofapproach"("public"."geometry", "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_clusterdbscan"("public"."geometry", "eps" double precision, "minpoints" integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_clusterdbscan"("public"."geometry", "eps" double precision, "minpoints" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_clusterdbscan"("public"."geometry", "eps" double precision, "minpoints" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_clusterdbscan"("public"."geometry", "eps" double precision, "minpoints" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_clusterintersecting"("public"."geometry"[]) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_clusterintersecting"("public"."geometry"[]) TO "anon";
GRANT ALL ON FUNCTION "public"."st_clusterintersecting"("public"."geometry"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_clusterintersecting"("public"."geometry"[]) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_clusterkmeans"("geom" "public"."geometry", "k" integer, "max_radius" double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_clusterkmeans"("geom" "public"."geometry", "k" integer, "max_radius" double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_clusterkmeans"("geom" "public"."geometry", "k" integer, "max_radius" double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_clusterkmeans"("geom" "public"."geometry", "k" integer, "max_radius" double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_clusterwithin"("public"."geometry"[], double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_clusterwithin"("public"."geometry"[], double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_clusterwithin"("public"."geometry"[], double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_clusterwithin"("public"."geometry"[], double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_collect"("public"."geometry"[]) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_collect"("public"."geometry"[]) TO "anon";
GRANT ALL ON FUNCTION "public"."st_collect"("public"."geometry"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_collect"("public"."geometry"[]) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_collect"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_collect"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_collect"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_collect"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_collectionextract"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_collectionextract"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_collectionextract"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_collectionextract"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_collectionextract"("public"."geometry", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_collectionextract"("public"."geometry", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_collectionextract"("public"."geometry", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_collectionextract"("public"."geometry", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_collectionhomogenize"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_collectionhomogenize"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_collectionhomogenize"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_collectionhomogenize"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_combinebbox"("public"."box2d", "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_combinebbox"("public"."box2d", "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_combinebbox"("public"."box2d", "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_combinebbox"("public"."box2d", "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_combinebbox"("public"."box3d", "public"."box3d") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_combinebbox"("public"."box3d", "public"."box3d") TO "anon";
GRANT ALL ON FUNCTION "public"."st_combinebbox"("public"."box3d", "public"."box3d") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_combinebbox"("public"."box3d", "public"."box3d") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_combinebbox"("public"."box3d", "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_combinebbox"("public"."box3d", "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_combinebbox"("public"."box3d", "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_combinebbox"("public"."box3d", "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_concavehull"("param_geom" "public"."geometry", "param_pctconvex" double precision, "param_allow_holes" boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_concavehull"("param_geom" "public"."geometry", "param_pctconvex" double precision, "param_allow_holes" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."st_concavehull"("param_geom" "public"."geometry", "param_pctconvex" double precision, "param_allow_holes" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_concavehull"("param_geom" "public"."geometry", "param_pctconvex" double precision, "param_allow_holes" boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_contains"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_contains"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_contains"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_contains"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_containsproperly"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_containsproperly"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_containsproperly"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_containsproperly"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_convexhull"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_convexhull"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_convexhull"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_convexhull"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_coorddim"("geometry" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_coorddim"("geometry" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_coorddim"("geometry" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_coorddim"("geometry" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_coveredby"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_coveredby"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."st_coveredby"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_coveredby"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_coveredby"("geog1" "public"."geography", "geog2" "public"."geography") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_coveredby"("geog1" "public"."geography", "geog2" "public"."geography") TO "anon";
GRANT ALL ON FUNCTION "public"."st_coveredby"("geog1" "public"."geography", "geog2" "public"."geography") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_coveredby"("geog1" "public"."geography", "geog2" "public"."geography") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_coveredby"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_coveredby"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_coveredby"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_coveredby"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_covers"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_covers"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."st_covers"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_covers"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_covers"("geog1" "public"."geography", "geog2" "public"."geography") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_covers"("geog1" "public"."geography", "geog2" "public"."geography") TO "anon";
GRANT ALL ON FUNCTION "public"."st_covers"("geog1" "public"."geography", "geog2" "public"."geography") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_covers"("geog1" "public"."geography", "geog2" "public"."geography") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_covers"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_covers"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_covers"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_covers"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_cpawithin"("public"."geometry", "public"."geometry", double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_cpawithin"("public"."geometry", "public"."geometry", double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_cpawithin"("public"."geometry", "public"."geometry", double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_cpawithin"("public"."geometry", "public"."geometry", double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_crosses"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_crosses"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_crosses"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_crosses"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_curvetoline"("geom" "public"."geometry", "tol" double precision, "toltype" integer, "flags" integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_curvetoline"("geom" "public"."geometry", "tol" double precision, "toltype" integer, "flags" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_curvetoline"("geom" "public"."geometry", "tol" double precision, "toltype" integer, "flags" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_curvetoline"("geom" "public"."geometry", "tol" double precision, "toltype" integer, "flags" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_delaunaytriangles"("g1" "public"."geometry", "tolerance" double precision, "flags" integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_delaunaytriangles"("g1" "public"."geometry", "tolerance" double precision, "flags" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_delaunaytriangles"("g1" "public"."geometry", "tolerance" double precision, "flags" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_delaunaytriangles"("g1" "public"."geometry", "tolerance" double precision, "flags" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_dfullywithin"("geom1" "public"."geometry", "geom2" "public"."geometry", double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_dfullywithin"("geom1" "public"."geometry", "geom2" "public"."geometry", double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_dfullywithin"("geom1" "public"."geometry", "geom2" "public"."geometry", double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_dfullywithin"("geom1" "public"."geometry", "geom2" "public"."geometry", double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_difference"("geom1" "public"."geometry", "geom2" "public"."geometry", "gridsize" double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_difference"("geom1" "public"."geometry", "geom2" "public"."geometry", "gridsize" double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_difference"("geom1" "public"."geometry", "geom2" "public"."geometry", "gridsize" double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_difference"("geom1" "public"."geometry", "geom2" "public"."geometry", "gridsize" double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_dimension"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_dimension"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_dimension"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_dimension"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_disjoint"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_disjoint"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_disjoint"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_disjoint"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_distance"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_distance"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."st_distance"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_distance"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_distance"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_distance"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_distance"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_distance"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_distance"("geog1" "public"."geography", "geog2" "public"."geography", "use_spheroid" boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_distance"("geog1" "public"."geography", "geog2" "public"."geography", "use_spheroid" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."st_distance"("geog1" "public"."geography", "geog2" "public"."geography", "use_spheroid" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_distance"("geog1" "public"."geography", "geog2" "public"."geography", "use_spheroid" boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_distancecpa"("public"."geometry", "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_distancecpa"("public"."geometry", "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_distancecpa"("public"."geometry", "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_distancecpa"("public"."geometry", "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_distancesphere"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_distancesphere"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_distancesphere"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_distancesphere"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_distancesphere"("geom1" "public"."geometry", "geom2" "public"."geometry", "radius" double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_distancesphere"("geom1" "public"."geometry", "geom2" "public"."geometry", "radius" double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_distancesphere"("geom1" "public"."geometry", "geom2" "public"."geometry", "radius" double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_distancesphere"("geom1" "public"."geometry", "geom2" "public"."geometry", "radius" double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_distancespheroid"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_distancespheroid"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_distancespheroid"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_distancespheroid"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_distancespheroid"("geom1" "public"."geometry", "geom2" "public"."geometry", "public"."spheroid") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_distancespheroid"("geom1" "public"."geometry", "geom2" "public"."geometry", "public"."spheroid") TO "anon";
GRANT ALL ON FUNCTION "public"."st_distancespheroid"("geom1" "public"."geometry", "geom2" "public"."geometry", "public"."spheroid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_distancespheroid"("geom1" "public"."geometry", "geom2" "public"."geometry", "public"."spheroid") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_dump"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_dump"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_dump"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_dump"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_dumppoints"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_dumppoints"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_dumppoints"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_dumppoints"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_dumprings"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_dumprings"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_dumprings"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_dumprings"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_dumpsegments"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_dumpsegments"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_dumpsegments"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_dumpsegments"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_dwithin"("text", "text", double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_dwithin"("text", "text", double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_dwithin"("text", "text", double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_dwithin"("text", "text", double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_dwithin"("geom1" "public"."geometry", "geom2" "public"."geometry", double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_dwithin"("geom1" "public"."geometry", "geom2" "public"."geometry", double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_dwithin"("geom1" "public"."geometry", "geom2" "public"."geometry", double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_dwithin"("geom1" "public"."geometry", "geom2" "public"."geometry", double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_dwithin"("geog1" "public"."geography", "geog2" "public"."geography", "tolerance" double precision, "use_spheroid" boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_dwithin"("geog1" "public"."geography", "geog2" "public"."geography", "tolerance" double precision, "use_spheroid" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."st_dwithin"("geog1" "public"."geography", "geog2" "public"."geography", "tolerance" double precision, "use_spheroid" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_dwithin"("geog1" "public"."geography", "geog2" "public"."geography", "tolerance" double precision, "use_spheroid" boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_endpoint"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_endpoint"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_endpoint"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_endpoint"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_envelope"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_envelope"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_envelope"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_envelope"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_equals"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_equals"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_equals"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_equals"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_estimatedextent"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_estimatedextent"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."st_estimatedextent"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_estimatedextent"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_estimatedextent"("text", "text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_estimatedextent"("text", "text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."st_estimatedextent"("text", "text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_estimatedextent"("text", "text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_estimatedextent"("text", "text", "text", boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_estimatedextent"("text", "text", "text", boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."st_estimatedextent"("text", "text", "text", boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_estimatedextent"("text", "text", "text", boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_expand"("public"."box2d", double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_expand"("public"."box2d", double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_expand"("public"."box2d", double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_expand"("public"."box2d", double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_expand"("public"."box3d", double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_expand"("public"."box3d", double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_expand"("public"."box3d", double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_expand"("public"."box3d", double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_expand"("public"."geometry", double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_expand"("public"."geometry", double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_expand"("public"."geometry", double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_expand"("public"."geometry", double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_expand"("box" "public"."box2d", "dx" double precision, "dy" double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_expand"("box" "public"."box2d", "dx" double precision, "dy" double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_expand"("box" "public"."box2d", "dx" double precision, "dy" double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_expand"("box" "public"."box2d", "dx" double precision, "dy" double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_expand"("box" "public"."box3d", "dx" double precision, "dy" double precision, "dz" double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_expand"("box" "public"."box3d", "dx" double precision, "dy" double precision, "dz" double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_expand"("box" "public"."box3d", "dx" double precision, "dy" double precision, "dz" double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_expand"("box" "public"."box3d", "dx" double precision, "dy" double precision, "dz" double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_expand"("geom" "public"."geometry", "dx" double precision, "dy" double precision, "dz" double precision, "dm" double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_expand"("geom" "public"."geometry", "dx" double precision, "dy" double precision, "dz" double precision, "dm" double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_expand"("geom" "public"."geometry", "dx" double precision, "dy" double precision, "dz" double precision, "dm" double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_expand"("geom" "public"."geometry", "dx" double precision, "dy" double precision, "dz" double precision, "dm" double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_exteriorring"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_exteriorring"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_exteriorring"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_exteriorring"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_filterbym"("public"."geometry", double precision, double precision, boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_filterbym"("public"."geometry", double precision, double precision, boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."st_filterbym"("public"."geometry", double precision, double precision, boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_filterbym"("public"."geometry", double precision, double precision, boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_findextent"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_findextent"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."st_findextent"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_findextent"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_findextent"("text", "text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_findextent"("text", "text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."st_findextent"("text", "text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_findextent"("text", "text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_flipcoordinates"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_flipcoordinates"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_flipcoordinates"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_flipcoordinates"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_force2d"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_force2d"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_force2d"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_force2d"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_force3d"("geom" "public"."geometry", "zvalue" double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_force3d"("geom" "public"."geometry", "zvalue" double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_force3d"("geom" "public"."geometry", "zvalue" double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_force3d"("geom" "public"."geometry", "zvalue" double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_force3dm"("geom" "public"."geometry", "mvalue" double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_force3dm"("geom" "public"."geometry", "mvalue" double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_force3dm"("geom" "public"."geometry", "mvalue" double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_force3dm"("geom" "public"."geometry", "mvalue" double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_force3dz"("geom" "public"."geometry", "zvalue" double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_force3dz"("geom" "public"."geometry", "zvalue" double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_force3dz"("geom" "public"."geometry", "zvalue" double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_force3dz"("geom" "public"."geometry", "zvalue" double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_force4d"("geom" "public"."geometry", "zvalue" double precision, "mvalue" double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_force4d"("geom" "public"."geometry", "zvalue" double precision, "mvalue" double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_force4d"("geom" "public"."geometry", "zvalue" double precision, "mvalue" double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_force4d"("geom" "public"."geometry", "zvalue" double precision, "mvalue" double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_forcecollection"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_forcecollection"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_forcecollection"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_forcecollection"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_forcecurve"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_forcecurve"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_forcecurve"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_forcecurve"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_forcepolygonccw"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_forcepolygonccw"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_forcepolygonccw"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_forcepolygonccw"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_forcepolygoncw"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_forcepolygoncw"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_forcepolygoncw"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_forcepolygoncw"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_forcerhr"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_forcerhr"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_forcerhr"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_forcerhr"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_forcesfs"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_forcesfs"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_forcesfs"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_forcesfs"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_forcesfs"("public"."geometry", "version" "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_forcesfs"("public"."geometry", "version" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."st_forcesfs"("public"."geometry", "version" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_forcesfs"("public"."geometry", "version" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_frechetdistance"("geom1" "public"."geometry", "geom2" "public"."geometry", double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_frechetdistance"("geom1" "public"."geometry", "geom2" "public"."geometry", double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_frechetdistance"("geom1" "public"."geometry", "geom2" "public"."geometry", double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_frechetdistance"("geom1" "public"."geometry", "geom2" "public"."geometry", double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_fromflatgeobuf"("anyelement", "bytea") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_fromflatgeobuf"("anyelement", "bytea") TO "anon";
GRANT ALL ON FUNCTION "public"."st_fromflatgeobuf"("anyelement", "bytea") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_fromflatgeobuf"("anyelement", "bytea") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_fromflatgeobuftotable"("text", "text", "bytea") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_fromflatgeobuftotable"("text", "text", "bytea") TO "anon";
GRANT ALL ON FUNCTION "public"."st_fromflatgeobuftotable"("text", "text", "bytea") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_fromflatgeobuftotable"("text", "text", "bytea") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_generatepoints"("area" "public"."geometry", "npoints" integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_generatepoints"("area" "public"."geometry", "npoints" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_generatepoints"("area" "public"."geometry", "npoints" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_generatepoints"("area" "public"."geometry", "npoints" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_generatepoints"("area" "public"."geometry", "npoints" integer, "seed" integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_generatepoints"("area" "public"."geometry", "npoints" integer, "seed" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_generatepoints"("area" "public"."geometry", "npoints" integer, "seed" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_generatepoints"("area" "public"."geometry", "npoints" integer, "seed" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_geogfromtext"("text") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_geogfromtext"("text") TO "anon";
GRANT ALL ON FUNCTION "public"."st_geogfromtext"("text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_geogfromtext"("text") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_geogfromwkb"("bytea") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_geogfromwkb"("bytea") TO "anon";
GRANT ALL ON FUNCTION "public"."st_geogfromwkb"("bytea") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_geogfromwkb"("bytea") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_geographyfromtext"("text") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_geographyfromtext"("text") TO "anon";
GRANT ALL ON FUNCTION "public"."st_geographyfromtext"("text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_geographyfromtext"("text") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_geohash"("geog" "public"."geography", "maxchars" integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_geohash"("geog" "public"."geography", "maxchars" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_geohash"("geog" "public"."geography", "maxchars" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_geohash"("geog" "public"."geography", "maxchars" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_geohash"("geom" "public"."geometry", "maxchars" integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_geohash"("geom" "public"."geometry", "maxchars" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_geohash"("geom" "public"."geometry", "maxchars" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_geohash"("geom" "public"."geometry", "maxchars" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_geomcollfromtext"("text") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_geomcollfromtext"("text") TO "anon";
GRANT ALL ON FUNCTION "public"."st_geomcollfromtext"("text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_geomcollfromtext"("text") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_geomcollfromtext"("text", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_geomcollfromtext"("text", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_geomcollfromtext"("text", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_geomcollfromtext"("text", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_geomcollfromwkb"("bytea") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_geomcollfromwkb"("bytea") TO "anon";
GRANT ALL ON FUNCTION "public"."st_geomcollfromwkb"("bytea") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_geomcollfromwkb"("bytea") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_geomcollfromwkb"("bytea", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_geomcollfromwkb"("bytea", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_geomcollfromwkb"("bytea", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_geomcollfromwkb"("bytea", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_geometricmedian"("g" "public"."geometry", "tolerance" double precision, "max_iter" integer, "fail_if_not_converged" boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_geometricmedian"("g" "public"."geometry", "tolerance" double precision, "max_iter" integer, "fail_if_not_converged" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."st_geometricmedian"("g" "public"."geometry", "tolerance" double precision, "max_iter" integer, "fail_if_not_converged" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_geometricmedian"("g" "public"."geometry", "tolerance" double precision, "max_iter" integer, "fail_if_not_converged" boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_geometryfromtext"("text") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_geometryfromtext"("text") TO "anon";
GRANT ALL ON FUNCTION "public"."st_geometryfromtext"("text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_geometryfromtext"("text") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_geometryfromtext"("text", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_geometryfromtext"("text", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_geometryfromtext"("text", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_geometryfromtext"("text", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_geometryn"("public"."geometry", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_geometryn"("public"."geometry", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_geometryn"("public"."geometry", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_geometryn"("public"."geometry", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_geometrytype"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_geometrytype"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_geometrytype"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_geometrytype"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_geomfromewkb"("bytea") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_geomfromewkb"("bytea") TO "anon";
GRANT ALL ON FUNCTION "public"."st_geomfromewkb"("bytea") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_geomfromewkb"("bytea") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_geomfromewkt"("text") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_geomfromewkt"("text") TO "anon";
GRANT ALL ON FUNCTION "public"."st_geomfromewkt"("text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_geomfromewkt"("text") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_geomfromgeohash"("text", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_geomfromgeohash"("text", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_geomfromgeohash"("text", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_geomfromgeohash"("text", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_geomfromgeojson"(json) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_geomfromgeojson"(json) TO "anon";
GRANT ALL ON FUNCTION "public"."st_geomfromgeojson"(json) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_geomfromgeojson"(json) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_geomfromgeojson"("jsonb") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_geomfromgeojson"("jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."st_geomfromgeojson"("jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_geomfromgeojson"("jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_geomfromgeojson"("text") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_geomfromgeojson"("text") TO "anon";
GRANT ALL ON FUNCTION "public"."st_geomfromgeojson"("text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_geomfromgeojson"("text") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_geomfromgml"("text") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_geomfromgml"("text") TO "anon";
GRANT ALL ON FUNCTION "public"."st_geomfromgml"("text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_geomfromgml"("text") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_geomfromgml"("text", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_geomfromgml"("text", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_geomfromgml"("text", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_geomfromgml"("text", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_geomfromkml"("text") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_geomfromkml"("text") TO "anon";
GRANT ALL ON FUNCTION "public"."st_geomfromkml"("text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_geomfromkml"("text") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_geomfrommarc21"("marc21xml" "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_geomfrommarc21"("marc21xml" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."st_geomfrommarc21"("marc21xml" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_geomfrommarc21"("marc21xml" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_geomfromtext"("text") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_geomfromtext"("text") TO "anon";
GRANT ALL ON FUNCTION "public"."st_geomfromtext"("text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_geomfromtext"("text") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_geomfromtext"("text", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_geomfromtext"("text", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_geomfromtext"("text", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_geomfromtext"("text", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_geomfromtwkb"("bytea") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_geomfromtwkb"("bytea") TO "anon";
GRANT ALL ON FUNCTION "public"."st_geomfromtwkb"("bytea") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_geomfromtwkb"("bytea") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_geomfromwkb"("bytea") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_geomfromwkb"("bytea") TO "anon";
GRANT ALL ON FUNCTION "public"."st_geomfromwkb"("bytea") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_geomfromwkb"("bytea") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_geomfromwkb"("bytea", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_geomfromwkb"("bytea", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_geomfromwkb"("bytea", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_geomfromwkb"("bytea", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_gmltosql"("text") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_gmltosql"("text") TO "anon";
GRANT ALL ON FUNCTION "public"."st_gmltosql"("text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_gmltosql"("text") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_gmltosql"("text", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_gmltosql"("text", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_gmltosql"("text", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_gmltosql"("text", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_hasarc"("geometry" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_hasarc"("geometry" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_hasarc"("geometry" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_hasarc"("geometry" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_hausdorffdistance"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_hausdorffdistance"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_hausdorffdistance"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_hausdorffdistance"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_hausdorffdistance"("geom1" "public"."geometry", "geom2" "public"."geometry", double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_hausdorffdistance"("geom1" "public"."geometry", "geom2" "public"."geometry", double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_hausdorffdistance"("geom1" "public"."geometry", "geom2" "public"."geometry", double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_hausdorffdistance"("geom1" "public"."geometry", "geom2" "public"."geometry", double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_hexagon"("size" double precision, "cell_i" integer, "cell_j" integer, "origin" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_hexagon"("size" double precision, "cell_i" integer, "cell_j" integer, "origin" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_hexagon"("size" double precision, "cell_i" integer, "cell_j" integer, "origin" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_hexagon"("size" double precision, "cell_i" integer, "cell_j" integer, "origin" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_hexagongrid"("size" double precision, "bounds" "public"."geometry", OUT "geom" "public"."geometry", OUT "i" integer, OUT "j" integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_hexagongrid"("size" double precision, "bounds" "public"."geometry", OUT "geom" "public"."geometry", OUT "i" integer, OUT "j" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_hexagongrid"("size" double precision, "bounds" "public"."geometry", OUT "geom" "public"."geometry", OUT "i" integer, OUT "j" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_hexagongrid"("size" double precision, "bounds" "public"."geometry", OUT "geom" "public"."geometry", OUT "i" integer, OUT "j" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_interiorringn"("public"."geometry", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_interiorringn"("public"."geometry", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_interiorringn"("public"."geometry", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_interiorringn"("public"."geometry", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_interpolatepoint"("line" "public"."geometry", "point" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_interpolatepoint"("line" "public"."geometry", "point" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_interpolatepoint"("line" "public"."geometry", "point" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_interpolatepoint"("line" "public"."geometry", "point" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_intersection"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_intersection"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."st_intersection"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_intersection"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_intersection"("public"."geography", "public"."geography") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_intersection"("public"."geography", "public"."geography") TO "anon";
GRANT ALL ON FUNCTION "public"."st_intersection"("public"."geography", "public"."geography") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_intersection"("public"."geography", "public"."geography") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_intersection"("geom1" "public"."geometry", "geom2" "public"."geometry", "gridsize" double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_intersection"("geom1" "public"."geometry", "geom2" "public"."geometry", "gridsize" double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_intersection"("geom1" "public"."geometry", "geom2" "public"."geometry", "gridsize" double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_intersection"("geom1" "public"."geometry", "geom2" "public"."geometry", "gridsize" double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_intersects"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_intersects"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."st_intersects"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_intersects"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_intersects"("geog1" "public"."geography", "geog2" "public"."geography") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_intersects"("geog1" "public"."geography", "geog2" "public"."geography") TO "anon";
GRANT ALL ON FUNCTION "public"."st_intersects"("geog1" "public"."geography", "geog2" "public"."geography") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_intersects"("geog1" "public"."geography", "geog2" "public"."geography") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_intersects"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_intersects"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_intersects"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_intersects"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_isclosed"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_isclosed"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_isclosed"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_isclosed"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_iscollection"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_iscollection"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_iscollection"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_iscollection"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_isempty"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_isempty"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_isempty"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_isempty"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_ispolygonccw"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_ispolygonccw"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_ispolygonccw"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_ispolygonccw"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_ispolygoncw"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_ispolygoncw"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_ispolygoncw"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_ispolygoncw"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_isring"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_isring"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_isring"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_isring"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_issimple"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_issimple"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_issimple"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_issimple"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_isvalid"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_isvalid"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_isvalid"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_isvalid"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_isvalid"("public"."geometry", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_isvalid"("public"."geometry", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_isvalid"("public"."geometry", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_isvalid"("public"."geometry", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_isvaliddetail"("geom" "public"."geometry", "flags" integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_isvaliddetail"("geom" "public"."geometry", "flags" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_isvaliddetail"("geom" "public"."geometry", "flags" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_isvaliddetail"("geom" "public"."geometry", "flags" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_isvalidreason"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_isvalidreason"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_isvalidreason"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_isvalidreason"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_isvalidreason"("public"."geometry", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_isvalidreason"("public"."geometry", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_isvalidreason"("public"."geometry", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_isvalidreason"("public"."geometry", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_isvalidtrajectory"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_isvalidtrajectory"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_isvalidtrajectory"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_isvalidtrajectory"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_length"("text") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_length"("text") TO "anon";
GRANT ALL ON FUNCTION "public"."st_length"("text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_length"("text") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_length"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_length"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_length"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_length"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_length"("geog" "public"."geography", "use_spheroid" boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_length"("geog" "public"."geography", "use_spheroid" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."st_length"("geog" "public"."geography", "use_spheroid" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_length"("geog" "public"."geography", "use_spheroid" boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_length2d"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_length2d"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_length2d"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_length2d"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_length2dspheroid"("public"."geometry", "public"."spheroid") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_length2dspheroid"("public"."geometry", "public"."spheroid") TO "anon";
GRANT ALL ON FUNCTION "public"."st_length2dspheroid"("public"."geometry", "public"."spheroid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_length2dspheroid"("public"."geometry", "public"."spheroid") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_lengthspheroid"("public"."geometry", "public"."spheroid") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_lengthspheroid"("public"."geometry", "public"."spheroid") TO "anon";
GRANT ALL ON FUNCTION "public"."st_lengthspheroid"("public"."geometry", "public"."spheroid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_lengthspheroid"("public"."geometry", "public"."spheroid") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_letters"("letters" "text", "font" json) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_letters"("letters" "text", "font" json) TO "anon";
GRANT ALL ON FUNCTION "public"."st_letters"("letters" "text", "font" json) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_letters"("letters" "text", "font" json) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_linecrossingdirection"("line1" "public"."geometry", "line2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_linecrossingdirection"("line1" "public"."geometry", "line2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_linecrossingdirection"("line1" "public"."geometry", "line2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_linecrossingdirection"("line1" "public"."geometry", "line2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_linefromencodedpolyline"("txtin" "text", "nprecision" integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_linefromencodedpolyline"("txtin" "text", "nprecision" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_linefromencodedpolyline"("txtin" "text", "nprecision" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_linefromencodedpolyline"("txtin" "text", "nprecision" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_linefrommultipoint"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_linefrommultipoint"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_linefrommultipoint"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_linefrommultipoint"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_linefromtext"("text") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_linefromtext"("text") TO "anon";
GRANT ALL ON FUNCTION "public"."st_linefromtext"("text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_linefromtext"("text") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_linefromtext"("text", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_linefromtext"("text", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_linefromtext"("text", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_linefromtext"("text", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_linefromwkb"("bytea") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_linefromwkb"("bytea") TO "anon";
GRANT ALL ON FUNCTION "public"."st_linefromwkb"("bytea") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_linefromwkb"("bytea") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_linefromwkb"("bytea", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_linefromwkb"("bytea", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_linefromwkb"("bytea", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_linefromwkb"("bytea", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_lineinterpolatepoint"("public"."geometry", double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_lineinterpolatepoint"("public"."geometry", double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_lineinterpolatepoint"("public"."geometry", double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_lineinterpolatepoint"("public"."geometry", double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_lineinterpolatepoints"("public"."geometry", double precision, "repeat" boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_lineinterpolatepoints"("public"."geometry", double precision, "repeat" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."st_lineinterpolatepoints"("public"."geometry", double precision, "repeat" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_lineinterpolatepoints"("public"."geometry", double precision, "repeat" boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_linelocatepoint"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_linelocatepoint"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_linelocatepoint"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_linelocatepoint"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_linemerge"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_linemerge"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_linemerge"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_linemerge"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_linemerge"("public"."geometry", boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_linemerge"("public"."geometry", boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."st_linemerge"("public"."geometry", boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_linemerge"("public"."geometry", boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_linestringfromwkb"("bytea") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_linestringfromwkb"("bytea") TO "anon";
GRANT ALL ON FUNCTION "public"."st_linestringfromwkb"("bytea") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_linestringfromwkb"("bytea") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_linestringfromwkb"("bytea", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_linestringfromwkb"("bytea", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_linestringfromwkb"("bytea", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_linestringfromwkb"("bytea", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_linesubstring"("public"."geometry", double precision, double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_linesubstring"("public"."geometry", double precision, double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_linesubstring"("public"."geometry", double precision, double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_linesubstring"("public"."geometry", double precision, double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_linetocurve"("geometry" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_linetocurve"("geometry" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_linetocurve"("geometry" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_linetocurve"("geometry" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_locatealong"("geometry" "public"."geometry", "measure" double precision, "leftrightoffset" double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_locatealong"("geometry" "public"."geometry", "measure" double precision, "leftrightoffset" double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_locatealong"("geometry" "public"."geometry", "measure" double precision, "leftrightoffset" double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_locatealong"("geometry" "public"."geometry", "measure" double precision, "leftrightoffset" double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_locatebetween"("geometry" "public"."geometry", "frommeasure" double precision, "tomeasure" double precision, "leftrightoffset" double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_locatebetween"("geometry" "public"."geometry", "frommeasure" double precision, "tomeasure" double precision, "leftrightoffset" double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_locatebetween"("geometry" "public"."geometry", "frommeasure" double precision, "tomeasure" double precision, "leftrightoffset" double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_locatebetween"("geometry" "public"."geometry", "frommeasure" double precision, "tomeasure" double precision, "leftrightoffset" double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_locatebetweenelevations"("geometry" "public"."geometry", "fromelevation" double precision, "toelevation" double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_locatebetweenelevations"("geometry" "public"."geometry", "fromelevation" double precision, "toelevation" double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_locatebetweenelevations"("geometry" "public"."geometry", "fromelevation" double precision, "toelevation" double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_locatebetweenelevations"("geometry" "public"."geometry", "fromelevation" double precision, "toelevation" double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_longestline"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_longestline"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_longestline"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_longestline"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_m"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_m"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_m"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_m"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_makebox2d"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_makebox2d"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_makebox2d"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_makebox2d"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_makeenvelope"(double precision, double precision, double precision, double precision, integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_makeenvelope"(double precision, double precision, double precision, double precision, integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_makeenvelope"(double precision, double precision, double precision, double precision, integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_makeenvelope"(double precision, double precision, double precision, double precision, integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_makeline"("public"."geometry"[]) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_makeline"("public"."geometry"[]) TO "anon";
GRANT ALL ON FUNCTION "public"."st_makeline"("public"."geometry"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_makeline"("public"."geometry"[]) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_makeline"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_makeline"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_makeline"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_makeline"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_makepoint"(double precision, double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_makepoint"(double precision, double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_makepoint"(double precision, double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_makepoint"(double precision, double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_makepoint"(double precision, double precision, double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_makepoint"(double precision, double precision, double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_makepoint"(double precision, double precision, double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_makepoint"(double precision, double precision, double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_makepoint"(double precision, double precision, double precision, double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_makepoint"(double precision, double precision, double precision, double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_makepoint"(double precision, double precision, double precision, double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_makepoint"(double precision, double precision, double precision, double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_makepointm"(double precision, double precision, double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_makepointm"(double precision, double precision, double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_makepointm"(double precision, double precision, double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_makepointm"(double precision, double precision, double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_makepolygon"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_makepolygon"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_makepolygon"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_makepolygon"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_makepolygon"("public"."geometry", "public"."geometry"[]) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_makepolygon"("public"."geometry", "public"."geometry"[]) TO "anon";
GRANT ALL ON FUNCTION "public"."st_makepolygon"("public"."geometry", "public"."geometry"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_makepolygon"("public"."geometry", "public"."geometry"[]) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_makevalid"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_makevalid"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_makevalid"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_makevalid"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_makevalid"("geom" "public"."geometry", "params" "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_makevalid"("geom" "public"."geometry", "params" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."st_makevalid"("geom" "public"."geometry", "params" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_makevalid"("geom" "public"."geometry", "params" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_maxdistance"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_maxdistance"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_maxdistance"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_maxdistance"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_maximuminscribedcircle"("public"."geometry", OUT "center" "public"."geometry", OUT "nearest" "public"."geometry", OUT "radius" double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_maximuminscribedcircle"("public"."geometry", OUT "center" "public"."geometry", OUT "nearest" "public"."geometry", OUT "radius" double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_maximuminscribedcircle"("public"."geometry", OUT "center" "public"."geometry", OUT "nearest" "public"."geometry", OUT "radius" double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_maximuminscribedcircle"("public"."geometry", OUT "center" "public"."geometry", OUT "nearest" "public"."geometry", OUT "radius" double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_memsize"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_memsize"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_memsize"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_memsize"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_minimumboundingcircle"("inputgeom" "public"."geometry", "segs_per_quarter" integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_minimumboundingcircle"("inputgeom" "public"."geometry", "segs_per_quarter" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_minimumboundingcircle"("inputgeom" "public"."geometry", "segs_per_quarter" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_minimumboundingcircle"("inputgeom" "public"."geometry", "segs_per_quarter" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_minimumboundingradius"("public"."geometry", OUT "center" "public"."geometry", OUT "radius" double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_minimumboundingradius"("public"."geometry", OUT "center" "public"."geometry", OUT "radius" double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_minimumboundingradius"("public"."geometry", OUT "center" "public"."geometry", OUT "radius" double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_minimumboundingradius"("public"."geometry", OUT "center" "public"."geometry", OUT "radius" double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_minimumclearance"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_minimumclearance"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_minimumclearance"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_minimumclearance"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_minimumclearanceline"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_minimumclearanceline"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_minimumclearanceline"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_minimumclearanceline"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_mlinefromtext"("text") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_mlinefromtext"("text") TO "anon";
GRANT ALL ON FUNCTION "public"."st_mlinefromtext"("text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_mlinefromtext"("text") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_mlinefromtext"("text", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_mlinefromtext"("text", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_mlinefromtext"("text", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_mlinefromtext"("text", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_mlinefromwkb"("bytea") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_mlinefromwkb"("bytea") TO "anon";
GRANT ALL ON FUNCTION "public"."st_mlinefromwkb"("bytea") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_mlinefromwkb"("bytea") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_mlinefromwkb"("bytea", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_mlinefromwkb"("bytea", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_mlinefromwkb"("bytea", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_mlinefromwkb"("bytea", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_mpointfromtext"("text") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_mpointfromtext"("text") TO "anon";
GRANT ALL ON FUNCTION "public"."st_mpointfromtext"("text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_mpointfromtext"("text") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_mpointfromtext"("text", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_mpointfromtext"("text", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_mpointfromtext"("text", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_mpointfromtext"("text", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_mpointfromwkb"("bytea") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_mpointfromwkb"("bytea") TO "anon";
GRANT ALL ON FUNCTION "public"."st_mpointfromwkb"("bytea") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_mpointfromwkb"("bytea") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_mpointfromwkb"("bytea", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_mpointfromwkb"("bytea", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_mpointfromwkb"("bytea", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_mpointfromwkb"("bytea", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_mpolyfromtext"("text") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_mpolyfromtext"("text") TO "anon";
GRANT ALL ON FUNCTION "public"."st_mpolyfromtext"("text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_mpolyfromtext"("text") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_mpolyfromtext"("text", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_mpolyfromtext"("text", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_mpolyfromtext"("text", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_mpolyfromtext"("text", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_mpolyfromwkb"("bytea") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_mpolyfromwkb"("bytea") TO "anon";
GRANT ALL ON FUNCTION "public"."st_mpolyfromwkb"("bytea") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_mpolyfromwkb"("bytea") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_mpolyfromwkb"("bytea", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_mpolyfromwkb"("bytea", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_mpolyfromwkb"("bytea", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_mpolyfromwkb"("bytea", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_multi"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_multi"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_multi"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_multi"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_multilinefromwkb"("bytea") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_multilinefromwkb"("bytea") TO "anon";
GRANT ALL ON FUNCTION "public"."st_multilinefromwkb"("bytea") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_multilinefromwkb"("bytea") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_multilinestringfromtext"("text") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_multilinestringfromtext"("text") TO "anon";
GRANT ALL ON FUNCTION "public"."st_multilinestringfromtext"("text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_multilinestringfromtext"("text") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_multilinestringfromtext"("text", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_multilinestringfromtext"("text", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_multilinestringfromtext"("text", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_multilinestringfromtext"("text", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_multipointfromtext"("text") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_multipointfromtext"("text") TO "anon";
GRANT ALL ON FUNCTION "public"."st_multipointfromtext"("text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_multipointfromtext"("text") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_multipointfromwkb"("bytea") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_multipointfromwkb"("bytea") TO "anon";
GRANT ALL ON FUNCTION "public"."st_multipointfromwkb"("bytea") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_multipointfromwkb"("bytea") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_multipointfromwkb"("bytea", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_multipointfromwkb"("bytea", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_multipointfromwkb"("bytea", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_multipointfromwkb"("bytea", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_multipolyfromwkb"("bytea") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_multipolyfromwkb"("bytea") TO "anon";
GRANT ALL ON FUNCTION "public"."st_multipolyfromwkb"("bytea") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_multipolyfromwkb"("bytea") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_multipolyfromwkb"("bytea", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_multipolyfromwkb"("bytea", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_multipolyfromwkb"("bytea", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_multipolyfromwkb"("bytea", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_multipolygonfromtext"("text") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_multipolygonfromtext"("text") TO "anon";
GRANT ALL ON FUNCTION "public"."st_multipolygonfromtext"("text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_multipolygonfromtext"("text") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_multipolygonfromtext"("text", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_multipolygonfromtext"("text", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_multipolygonfromtext"("text", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_multipolygonfromtext"("text", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_ndims"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_ndims"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_ndims"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_ndims"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_node"("g" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_node"("g" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_node"("g" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_node"("g" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_normalize"("geom" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_normalize"("geom" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_normalize"("geom" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_normalize"("geom" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_npoints"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_npoints"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_npoints"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_npoints"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_nrings"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_nrings"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_nrings"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_nrings"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_numgeometries"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_numgeometries"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_numgeometries"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_numgeometries"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_numinteriorring"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_numinteriorring"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_numinteriorring"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_numinteriorring"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_numinteriorrings"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_numinteriorrings"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_numinteriorrings"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_numinteriorrings"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_numpatches"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_numpatches"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_numpatches"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_numpatches"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_numpoints"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_numpoints"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_numpoints"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_numpoints"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_offsetcurve"("line" "public"."geometry", "distance" double precision, "params" "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_offsetcurve"("line" "public"."geometry", "distance" double precision, "params" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."st_offsetcurve"("line" "public"."geometry", "distance" double precision, "params" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_offsetcurve"("line" "public"."geometry", "distance" double precision, "params" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_orderingequals"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_orderingequals"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_orderingequals"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_orderingequals"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_orientedenvelope"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_orientedenvelope"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_orientedenvelope"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_orientedenvelope"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_overlaps"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_overlaps"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_overlaps"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_overlaps"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_patchn"("public"."geometry", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_patchn"("public"."geometry", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_patchn"("public"."geometry", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_patchn"("public"."geometry", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_perimeter"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_perimeter"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_perimeter"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_perimeter"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_perimeter"("geog" "public"."geography", "use_spheroid" boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_perimeter"("geog" "public"."geography", "use_spheroid" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."st_perimeter"("geog" "public"."geography", "use_spheroid" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_perimeter"("geog" "public"."geography", "use_spheroid" boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_perimeter2d"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_perimeter2d"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_perimeter2d"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_perimeter2d"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_point"(double precision, double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_point"(double precision, double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_point"(double precision, double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_point"(double precision, double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_point"(double precision, double precision, "srid" integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_point"(double precision, double precision, "srid" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_point"(double precision, double precision, "srid" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_point"(double precision, double precision, "srid" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_pointfromgeohash"("text", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_pointfromgeohash"("text", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_pointfromgeohash"("text", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_pointfromgeohash"("text", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_pointfromtext"("text") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_pointfromtext"("text") TO "anon";
GRANT ALL ON FUNCTION "public"."st_pointfromtext"("text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_pointfromtext"("text") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_pointfromtext"("text", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_pointfromtext"("text", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_pointfromtext"("text", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_pointfromtext"("text", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_pointfromwkb"("bytea") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_pointfromwkb"("bytea") TO "anon";
GRANT ALL ON FUNCTION "public"."st_pointfromwkb"("bytea") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_pointfromwkb"("bytea") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_pointfromwkb"("bytea", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_pointfromwkb"("bytea", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_pointfromwkb"("bytea", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_pointfromwkb"("bytea", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_pointinsidecircle"("public"."geometry", double precision, double precision, double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_pointinsidecircle"("public"."geometry", double precision, double precision, double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_pointinsidecircle"("public"."geometry", double precision, double precision, double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_pointinsidecircle"("public"."geometry", double precision, double precision, double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_pointm"("xcoordinate" double precision, "ycoordinate" double precision, "mcoordinate" double precision, "srid" integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_pointm"("xcoordinate" double precision, "ycoordinate" double precision, "mcoordinate" double precision, "srid" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_pointm"("xcoordinate" double precision, "ycoordinate" double precision, "mcoordinate" double precision, "srid" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_pointm"("xcoordinate" double precision, "ycoordinate" double precision, "mcoordinate" double precision, "srid" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_pointn"("public"."geometry", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_pointn"("public"."geometry", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_pointn"("public"."geometry", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_pointn"("public"."geometry", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_pointonsurface"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_pointonsurface"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_pointonsurface"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_pointonsurface"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_points"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_points"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_points"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_points"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_pointz"("xcoordinate" double precision, "ycoordinate" double precision, "zcoordinate" double precision, "srid" integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_pointz"("xcoordinate" double precision, "ycoordinate" double precision, "zcoordinate" double precision, "srid" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_pointz"("xcoordinate" double precision, "ycoordinate" double precision, "zcoordinate" double precision, "srid" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_pointz"("xcoordinate" double precision, "ycoordinate" double precision, "zcoordinate" double precision, "srid" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_pointzm"("xcoordinate" double precision, "ycoordinate" double precision, "zcoordinate" double precision, "mcoordinate" double precision, "srid" integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_pointzm"("xcoordinate" double precision, "ycoordinate" double precision, "zcoordinate" double precision, "mcoordinate" double precision, "srid" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_pointzm"("xcoordinate" double precision, "ycoordinate" double precision, "zcoordinate" double precision, "mcoordinate" double precision, "srid" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_pointzm"("xcoordinate" double precision, "ycoordinate" double precision, "zcoordinate" double precision, "mcoordinate" double precision, "srid" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_polyfromtext"("text") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_polyfromtext"("text") TO "anon";
GRANT ALL ON FUNCTION "public"."st_polyfromtext"("text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_polyfromtext"("text") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_polyfromtext"("text", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_polyfromtext"("text", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_polyfromtext"("text", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_polyfromtext"("text", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_polyfromwkb"("bytea") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_polyfromwkb"("bytea") TO "anon";
GRANT ALL ON FUNCTION "public"."st_polyfromwkb"("bytea") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_polyfromwkb"("bytea") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_polyfromwkb"("bytea", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_polyfromwkb"("bytea", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_polyfromwkb"("bytea", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_polyfromwkb"("bytea", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_polygon"("public"."geometry", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_polygon"("public"."geometry", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_polygon"("public"."geometry", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_polygon"("public"."geometry", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_polygonfromtext"("text") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_polygonfromtext"("text") TO "anon";
GRANT ALL ON FUNCTION "public"."st_polygonfromtext"("text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_polygonfromtext"("text") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_polygonfromtext"("text", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_polygonfromtext"("text", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_polygonfromtext"("text", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_polygonfromtext"("text", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_polygonfromwkb"("bytea") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_polygonfromwkb"("bytea") TO "anon";
GRANT ALL ON FUNCTION "public"."st_polygonfromwkb"("bytea") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_polygonfromwkb"("bytea") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_polygonfromwkb"("bytea", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_polygonfromwkb"("bytea", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_polygonfromwkb"("bytea", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_polygonfromwkb"("bytea", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_polygonize"("public"."geometry"[]) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_polygonize"("public"."geometry"[]) TO "anon";
GRANT ALL ON FUNCTION "public"."st_polygonize"("public"."geometry"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_polygonize"("public"."geometry"[]) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_project"("geog" "public"."geography", "distance" double precision, "azimuth" double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_project"("geog" "public"."geography", "distance" double precision, "azimuth" double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_project"("geog" "public"."geography", "distance" double precision, "azimuth" double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_project"("geog" "public"."geography", "distance" double precision, "azimuth" double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_quantizecoordinates"("g" "public"."geometry", "prec_x" integer, "prec_y" integer, "prec_z" integer, "prec_m" integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_quantizecoordinates"("g" "public"."geometry", "prec_x" integer, "prec_y" integer, "prec_z" integer, "prec_m" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_quantizecoordinates"("g" "public"."geometry", "prec_x" integer, "prec_y" integer, "prec_z" integer, "prec_m" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_quantizecoordinates"("g" "public"."geometry", "prec_x" integer, "prec_y" integer, "prec_z" integer, "prec_m" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_reduceprecision"("geom" "public"."geometry", "gridsize" double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_reduceprecision"("geom" "public"."geometry", "gridsize" double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_reduceprecision"("geom" "public"."geometry", "gridsize" double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_reduceprecision"("geom" "public"."geometry", "gridsize" double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_relate"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_relate"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_relate"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_relate"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_relate"("geom1" "public"."geometry", "geom2" "public"."geometry", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_relate"("geom1" "public"."geometry", "geom2" "public"."geometry", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_relate"("geom1" "public"."geometry", "geom2" "public"."geometry", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_relate"("geom1" "public"."geometry", "geom2" "public"."geometry", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_relate"("geom1" "public"."geometry", "geom2" "public"."geometry", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_relate"("geom1" "public"."geometry", "geom2" "public"."geometry", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."st_relate"("geom1" "public"."geometry", "geom2" "public"."geometry", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_relate"("geom1" "public"."geometry", "geom2" "public"."geometry", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_relatematch"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_relatematch"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."st_relatematch"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_relatematch"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_removepoint"("public"."geometry", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_removepoint"("public"."geometry", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_removepoint"("public"."geometry", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_removepoint"("public"."geometry", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_removerepeatedpoints"("geom" "public"."geometry", "tolerance" double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_removerepeatedpoints"("geom" "public"."geometry", "tolerance" double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_removerepeatedpoints"("geom" "public"."geometry", "tolerance" double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_removerepeatedpoints"("geom" "public"."geometry", "tolerance" double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_reverse"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_reverse"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_reverse"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_reverse"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_rotate"("public"."geometry", double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_rotate"("public"."geometry", double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_rotate"("public"."geometry", double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_rotate"("public"."geometry", double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_rotate"("public"."geometry", double precision, "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_rotate"("public"."geometry", double precision, "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_rotate"("public"."geometry", double precision, "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_rotate"("public"."geometry", double precision, "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_rotate"("public"."geometry", double precision, double precision, double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_rotate"("public"."geometry", double precision, double precision, double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_rotate"("public"."geometry", double precision, double precision, double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_rotate"("public"."geometry", double precision, double precision, double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_rotatex"("public"."geometry", double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_rotatex"("public"."geometry", double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_rotatex"("public"."geometry", double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_rotatex"("public"."geometry", double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_rotatey"("public"."geometry", double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_rotatey"("public"."geometry", double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_rotatey"("public"."geometry", double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_rotatey"("public"."geometry", double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_rotatez"("public"."geometry", double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_rotatez"("public"."geometry", double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_rotatez"("public"."geometry", double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_rotatez"("public"."geometry", double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_scale"("public"."geometry", "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_scale"("public"."geometry", "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_scale"("public"."geometry", "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_scale"("public"."geometry", "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_scale"("public"."geometry", double precision, double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_scale"("public"."geometry", double precision, double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_scale"("public"."geometry", double precision, double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_scale"("public"."geometry", double precision, double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_scale"("public"."geometry", "public"."geometry", "origin" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_scale"("public"."geometry", "public"."geometry", "origin" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_scale"("public"."geometry", "public"."geometry", "origin" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_scale"("public"."geometry", "public"."geometry", "origin" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_scale"("public"."geometry", double precision, double precision, double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_scale"("public"."geometry", double precision, double precision, double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_scale"("public"."geometry", double precision, double precision, double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_scale"("public"."geometry", double precision, double precision, double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_scroll"("public"."geometry", "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_scroll"("public"."geometry", "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_scroll"("public"."geometry", "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_scroll"("public"."geometry", "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_segmentize"("geog" "public"."geography", "max_segment_length" double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_segmentize"("geog" "public"."geography", "max_segment_length" double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_segmentize"("geog" "public"."geography", "max_segment_length" double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_segmentize"("geog" "public"."geography", "max_segment_length" double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_segmentize"("public"."geometry", double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_segmentize"("public"."geometry", double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_segmentize"("public"."geometry", double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_segmentize"("public"."geometry", double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_seteffectivearea"("public"."geometry", double precision, integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_seteffectivearea"("public"."geometry", double precision, integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_seteffectivearea"("public"."geometry", double precision, integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_seteffectivearea"("public"."geometry", double precision, integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_setpoint"("public"."geometry", integer, "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_setpoint"("public"."geometry", integer, "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_setpoint"("public"."geometry", integer, "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_setpoint"("public"."geometry", integer, "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_setsrid"("geog" "public"."geography", "srid" integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_setsrid"("geog" "public"."geography", "srid" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_setsrid"("geog" "public"."geography", "srid" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_setsrid"("geog" "public"."geography", "srid" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_setsrid"("geom" "public"."geometry", "srid" integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_setsrid"("geom" "public"."geometry", "srid" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_setsrid"("geom" "public"."geometry", "srid" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_setsrid"("geom" "public"."geometry", "srid" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_sharedpaths"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_sharedpaths"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_sharedpaths"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_sharedpaths"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_shiftlongitude"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_shiftlongitude"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_shiftlongitude"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_shiftlongitude"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_shortestline"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_shortestline"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_shortestline"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_shortestline"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_simplify"("public"."geometry", double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_simplify"("public"."geometry", double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_simplify"("public"."geometry", double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_simplify"("public"."geometry", double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_simplify"("public"."geometry", double precision, boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_simplify"("public"."geometry", double precision, boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."st_simplify"("public"."geometry", double precision, boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_simplify"("public"."geometry", double precision, boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_simplifypolygonhull"("geom" "public"."geometry", "vertex_fraction" double precision, "is_outer" boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_simplifypolygonhull"("geom" "public"."geometry", "vertex_fraction" double precision, "is_outer" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."st_simplifypolygonhull"("geom" "public"."geometry", "vertex_fraction" double precision, "is_outer" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_simplifypolygonhull"("geom" "public"."geometry", "vertex_fraction" double precision, "is_outer" boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_simplifypreservetopology"("public"."geometry", double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_simplifypreservetopology"("public"."geometry", double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_simplifypreservetopology"("public"."geometry", double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_simplifypreservetopology"("public"."geometry", double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_simplifyvw"("public"."geometry", double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_simplifyvw"("public"."geometry", double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_simplifyvw"("public"."geometry", double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_simplifyvw"("public"."geometry", double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_snap"("geom1" "public"."geometry", "geom2" "public"."geometry", double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_snap"("geom1" "public"."geometry", "geom2" "public"."geometry", double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_snap"("geom1" "public"."geometry", "geom2" "public"."geometry", double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_snap"("geom1" "public"."geometry", "geom2" "public"."geometry", double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_snaptogrid"("public"."geometry", double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_snaptogrid"("public"."geometry", double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_snaptogrid"("public"."geometry", double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_snaptogrid"("public"."geometry", double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_snaptogrid"("public"."geometry", double precision, double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_snaptogrid"("public"."geometry", double precision, double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_snaptogrid"("public"."geometry", double precision, double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_snaptogrid"("public"."geometry", double precision, double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_snaptogrid"("public"."geometry", double precision, double precision, double precision, double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_snaptogrid"("public"."geometry", double precision, double precision, double precision, double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_snaptogrid"("public"."geometry", double precision, double precision, double precision, double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_snaptogrid"("public"."geometry", double precision, double precision, double precision, double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_snaptogrid"("geom1" "public"."geometry", "geom2" "public"."geometry", double precision, double precision, double precision, double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_snaptogrid"("geom1" "public"."geometry", "geom2" "public"."geometry", double precision, double precision, double precision, double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_snaptogrid"("geom1" "public"."geometry", "geom2" "public"."geometry", double precision, double precision, double precision, double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_snaptogrid"("geom1" "public"."geometry", "geom2" "public"."geometry", double precision, double precision, double precision, double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_split"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_split"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_split"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_split"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_square"("size" double precision, "cell_i" integer, "cell_j" integer, "origin" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_square"("size" double precision, "cell_i" integer, "cell_j" integer, "origin" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_square"("size" double precision, "cell_i" integer, "cell_j" integer, "origin" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_square"("size" double precision, "cell_i" integer, "cell_j" integer, "origin" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_squaregrid"("size" double precision, "bounds" "public"."geometry", OUT "geom" "public"."geometry", OUT "i" integer, OUT "j" integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_squaregrid"("size" double precision, "bounds" "public"."geometry", OUT "geom" "public"."geometry", OUT "i" integer, OUT "j" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_squaregrid"("size" double precision, "bounds" "public"."geometry", OUT "geom" "public"."geometry", OUT "i" integer, OUT "j" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_squaregrid"("size" double precision, "bounds" "public"."geometry", OUT "geom" "public"."geometry", OUT "i" integer, OUT "j" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_srid"("geog" "public"."geography") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_srid"("geog" "public"."geography") TO "anon";
GRANT ALL ON FUNCTION "public"."st_srid"("geog" "public"."geography") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_srid"("geog" "public"."geography") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_srid"("geom" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_srid"("geom" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_srid"("geom" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_srid"("geom" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_startpoint"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_startpoint"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_startpoint"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_startpoint"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_subdivide"("geom" "public"."geometry", "maxvertices" integer, "gridsize" double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_subdivide"("geom" "public"."geometry", "maxvertices" integer, "gridsize" double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_subdivide"("geom" "public"."geometry", "maxvertices" integer, "gridsize" double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_subdivide"("geom" "public"."geometry", "maxvertices" integer, "gridsize" double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_summary"("public"."geography") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_summary"("public"."geography") TO "anon";
GRANT ALL ON FUNCTION "public"."st_summary"("public"."geography") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_summary"("public"."geography") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_summary"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_summary"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_summary"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_summary"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_swapordinates"("geom" "public"."geometry", "ords" "cstring") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_swapordinates"("geom" "public"."geometry", "ords" "cstring") TO "anon";
GRANT ALL ON FUNCTION "public"."st_swapordinates"("geom" "public"."geometry", "ords" "cstring") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_swapordinates"("geom" "public"."geometry", "ords" "cstring") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_symdifference"("geom1" "public"."geometry", "geom2" "public"."geometry", "gridsize" double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_symdifference"("geom1" "public"."geometry", "geom2" "public"."geometry", "gridsize" double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_symdifference"("geom1" "public"."geometry", "geom2" "public"."geometry", "gridsize" double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_symdifference"("geom1" "public"."geometry", "geom2" "public"."geometry", "gridsize" double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_symmetricdifference"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_symmetricdifference"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_symmetricdifference"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_symmetricdifference"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_tileenvelope"("zoom" integer, "x" integer, "y" integer, "bounds" "public"."geometry", "margin" double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_tileenvelope"("zoom" integer, "x" integer, "y" integer, "bounds" "public"."geometry", "margin" double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_tileenvelope"("zoom" integer, "x" integer, "y" integer, "bounds" "public"."geometry", "margin" double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_tileenvelope"("zoom" integer, "x" integer, "y" integer, "bounds" "public"."geometry", "margin" double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_touches"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_touches"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_touches"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_touches"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_transform"("public"."geometry", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_transform"("public"."geometry", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_transform"("public"."geometry", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_transform"("public"."geometry", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_transform"("geom" "public"."geometry", "to_proj" "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_transform"("geom" "public"."geometry", "to_proj" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."st_transform"("geom" "public"."geometry", "to_proj" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_transform"("geom" "public"."geometry", "to_proj" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_transform"("geom" "public"."geometry", "from_proj" "text", "to_srid" integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_transform"("geom" "public"."geometry", "from_proj" "text", "to_srid" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_transform"("geom" "public"."geometry", "from_proj" "text", "to_srid" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_transform"("geom" "public"."geometry", "from_proj" "text", "to_srid" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_transform"("geom" "public"."geometry", "from_proj" "text", "to_proj" "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_transform"("geom" "public"."geometry", "from_proj" "text", "to_proj" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."st_transform"("geom" "public"."geometry", "from_proj" "text", "to_proj" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_transform"("geom" "public"."geometry", "from_proj" "text", "to_proj" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_translate"("public"."geometry", double precision, double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_translate"("public"."geometry", double precision, double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_translate"("public"."geometry", double precision, double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_translate"("public"."geometry", double precision, double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_translate"("public"."geometry", double precision, double precision, double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_translate"("public"."geometry", double precision, double precision, double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_translate"("public"."geometry", double precision, double precision, double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_translate"("public"."geometry", double precision, double precision, double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_transscale"("public"."geometry", double precision, double precision, double precision, double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_transscale"("public"."geometry", double precision, double precision, double precision, double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_transscale"("public"."geometry", double precision, double precision, double precision, double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_transscale"("public"."geometry", double precision, double precision, double precision, double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_triangulatepolygon"("g1" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_triangulatepolygon"("g1" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_triangulatepolygon"("g1" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_triangulatepolygon"("g1" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_unaryunion"("public"."geometry", "gridsize" double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_unaryunion"("public"."geometry", "gridsize" double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_unaryunion"("public"."geometry", "gridsize" double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_unaryunion"("public"."geometry", "gridsize" double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_union"("public"."geometry"[]) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_union"("public"."geometry"[]) TO "anon";
GRANT ALL ON FUNCTION "public"."st_union"("public"."geometry"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_union"("public"."geometry"[]) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_union"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_union"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_union"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_union"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_union"("geom1" "public"."geometry", "geom2" "public"."geometry", "gridsize" double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_union"("geom1" "public"."geometry", "geom2" "public"."geometry", "gridsize" double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_union"("geom1" "public"."geometry", "geom2" "public"."geometry", "gridsize" double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_union"("geom1" "public"."geometry", "geom2" "public"."geometry", "gridsize" double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_voronoilines"("g1" "public"."geometry", "tolerance" double precision, "extend_to" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_voronoilines"("g1" "public"."geometry", "tolerance" double precision, "extend_to" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_voronoilines"("g1" "public"."geometry", "tolerance" double precision, "extend_to" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_voronoilines"("g1" "public"."geometry", "tolerance" double precision, "extend_to" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_voronoipolygons"("g1" "public"."geometry", "tolerance" double precision, "extend_to" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_voronoipolygons"("g1" "public"."geometry", "tolerance" double precision, "extend_to" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_voronoipolygons"("g1" "public"."geometry", "tolerance" double precision, "extend_to" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_voronoipolygons"("g1" "public"."geometry", "tolerance" double precision, "extend_to" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_within"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_within"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_within"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_within"("geom1" "public"."geometry", "geom2" "public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_wkbtosql"("wkb" "bytea") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_wkbtosql"("wkb" "bytea") TO "anon";
GRANT ALL ON FUNCTION "public"."st_wkbtosql"("wkb" "bytea") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_wkbtosql"("wkb" "bytea") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_wkttosql"("text") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_wkttosql"("text") TO "anon";
GRANT ALL ON FUNCTION "public"."st_wkttosql"("text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_wkttosql"("text") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_wrapx"("geom" "public"."geometry", "wrap" double precision, "move" double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_wrapx"("geom" "public"."geometry", "wrap" double precision, "move" double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_wrapx"("geom" "public"."geometry", "wrap" double precision, "move" double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_wrapx"("geom" "public"."geometry", "wrap" double precision, "move" double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_x"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_x"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_x"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_x"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_xmax"("public"."box3d") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_xmax"("public"."box3d") TO "anon";
GRANT ALL ON FUNCTION "public"."st_xmax"("public"."box3d") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_xmax"("public"."box3d") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_xmin"("public"."box3d") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_xmin"("public"."box3d") TO "anon";
GRANT ALL ON FUNCTION "public"."st_xmin"("public"."box3d") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_xmin"("public"."box3d") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_y"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_y"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_y"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_y"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_ymax"("public"."box3d") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_ymax"("public"."box3d") TO "anon";
GRANT ALL ON FUNCTION "public"."st_ymax"("public"."box3d") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_ymax"("public"."box3d") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_ymin"("public"."box3d") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_ymin"("public"."box3d") TO "anon";
GRANT ALL ON FUNCTION "public"."st_ymin"("public"."box3d") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_ymin"("public"."box3d") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_z"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_z"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_z"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_z"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_zmax"("public"."box3d") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_zmax"("public"."box3d") TO "anon";
GRANT ALL ON FUNCTION "public"."st_zmax"("public"."box3d") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_zmax"("public"."box3d") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_zmflag"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_zmflag"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_zmflag"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_zmflag"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_zmin"("public"."box3d") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_zmin"("public"."box3d") TO "anon";
GRANT ALL ON FUNCTION "public"."st_zmin"("public"."box3d") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_zmin"("public"."box3d") TO "service_role";



GRANT ALL ON FUNCTION "public"."trigger_location_lookup"() TO "anon";
GRANT ALL ON FUNCTION "public"."trigger_location_lookup"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."trigger_location_lookup"() TO "service_role";



GRANT ALL ON FUNCTION "public"."unlockrows"("text") TO "postgres";
GRANT ALL ON FUNCTION "public"."unlockrows"("text") TO "anon";
GRANT ALL ON FUNCTION "public"."unlockrows"("text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."unlockrows"("text") TO "service_role";



GRANT ALL ON FUNCTION "public"."update_contact_custom_fields_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_contact_custom_fields_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_contact_custom_fields_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_contact_enrichment_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_contact_enrichment_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_contact_enrichment_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_contact_location"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_contact_location"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_contact_location"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_contact_note_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_contact_note_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_contact_note_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_custom_columns_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_custom_columns_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_custom_columns_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_survey_column_update_rules_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_survey_column_update_rules_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_survey_column_update_rules_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "service_role";



GRANT ALL ON FUNCTION "public"."updategeometrysrid"(character varying, character varying, integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."updategeometrysrid"(character varying, character varying, integer) TO "anon";
GRANT ALL ON FUNCTION "public"."updategeometrysrid"(character varying, character varying, integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."updategeometrysrid"(character varying, character varying, integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."updategeometrysrid"(character varying, character varying, character varying, integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."updategeometrysrid"(character varying, character varying, character varying, integer) TO "anon";
GRANT ALL ON FUNCTION "public"."updategeometrysrid"(character varying, character varying, character varying, integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."updategeometrysrid"(character varying, character varying, character varying, integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."updategeometrysrid"("catalogn_name" character varying, "schema_name" character varying, "table_name" character varying, "column_name" character varying, "new_srid_in" integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."updategeometrysrid"("catalogn_name" character varying, "schema_name" character varying, "table_name" character varying, "column_name" character varying, "new_srid_in" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."updategeometrysrid"("catalogn_name" character varying, "schema_name" character varying, "table_name" character varying, "column_name" character varying, "new_srid_in" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."updategeometrysrid"("catalogn_name" character varying, "schema_name" character varying, "table_name" character varying, "column_name" character varying, "new_srid_in" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."validate_attachment_update"() TO "anon";
GRANT ALL ON FUNCTION "public"."validate_attachment_update"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."validate_attachment_update"() TO "service_role";












GRANT ALL ON FUNCTION "public"."st_3dextent"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_3dextent"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_3dextent"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_3dextent"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_asflatgeobuf"("anyelement") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_asflatgeobuf"("anyelement") TO "anon";
GRANT ALL ON FUNCTION "public"."st_asflatgeobuf"("anyelement") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_asflatgeobuf"("anyelement") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_asflatgeobuf"("anyelement", boolean) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_asflatgeobuf"("anyelement", boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."st_asflatgeobuf"("anyelement", boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_asflatgeobuf"("anyelement", boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_asflatgeobuf"("anyelement", boolean, "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_asflatgeobuf"("anyelement", boolean, "text") TO "anon";
GRANT ALL ON FUNCTION "public"."st_asflatgeobuf"("anyelement", boolean, "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_asflatgeobuf"("anyelement", boolean, "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_asgeobuf"("anyelement") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_asgeobuf"("anyelement") TO "anon";
GRANT ALL ON FUNCTION "public"."st_asgeobuf"("anyelement") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_asgeobuf"("anyelement") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_asgeobuf"("anyelement", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_asgeobuf"("anyelement", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."st_asgeobuf"("anyelement", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_asgeobuf"("anyelement", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_asmvt"("anyelement") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_asmvt"("anyelement") TO "anon";
GRANT ALL ON FUNCTION "public"."st_asmvt"("anyelement") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_asmvt"("anyelement") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_asmvt"("anyelement", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_asmvt"("anyelement", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."st_asmvt"("anyelement", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_asmvt"("anyelement", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_asmvt"("anyelement", "text", integer) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_asmvt"("anyelement", "text", integer) TO "anon";
GRANT ALL ON FUNCTION "public"."st_asmvt"("anyelement", "text", integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_asmvt"("anyelement", "text", integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_asmvt"("anyelement", "text", integer, "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_asmvt"("anyelement", "text", integer, "text") TO "anon";
GRANT ALL ON FUNCTION "public"."st_asmvt"("anyelement", "text", integer, "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_asmvt"("anyelement", "text", integer, "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_asmvt"("anyelement", "text", integer, "text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_asmvt"("anyelement", "text", integer, "text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."st_asmvt"("anyelement", "text", integer, "text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_asmvt"("anyelement", "text", integer, "text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_clusterintersecting"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_clusterintersecting"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_clusterintersecting"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_clusterintersecting"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_clusterwithin"("public"."geometry", double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_clusterwithin"("public"."geometry", double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_clusterwithin"("public"."geometry", double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_clusterwithin"("public"."geometry", double precision) TO "service_role";



GRANT ALL ON FUNCTION "public"."st_collect"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_collect"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_collect"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_collect"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_extent"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_extent"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_extent"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_extent"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_makeline"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_makeline"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_makeline"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_makeline"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_memcollect"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_memcollect"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_memcollect"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_memcollect"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_memunion"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_memunion"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_memunion"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_memunion"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_polygonize"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_polygonize"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_polygonize"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_polygonize"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_union"("public"."geometry") TO "postgres";
GRANT ALL ON FUNCTION "public"."st_union"("public"."geometry") TO "anon";
GRANT ALL ON FUNCTION "public"."st_union"("public"."geometry") TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_union"("public"."geometry") TO "service_role";



GRANT ALL ON FUNCTION "public"."st_union"("public"."geometry", double precision) TO "postgres";
GRANT ALL ON FUNCTION "public"."st_union"("public"."geometry", double precision) TO "anon";
GRANT ALL ON FUNCTION "public"."st_union"("public"."geometry", double precision) TO "authenticated";
GRANT ALL ON FUNCTION "public"."st_union"("public"."geometry", double precision) TO "service_role";





















GRANT SELECT ON TABLE "msar"."expr_templates" TO PUBLIC;



GRANT SELECT ON TABLE "msar"."top_level_domains" TO PUBLIC;



GRANT ALL ON TABLE "public"."action_logs" TO "anon";
GRANT ALL ON TABLE "public"."action_logs" TO "authenticated";
GRANT ALL ON TABLE "public"."action_logs" TO "service_role";



GRANT ALL ON TABLE "public"."api_logs" TO "anon";
GRANT ALL ON TABLE "public"."api_logs" TO "authenticated";
GRANT ALL ON TABLE "public"."api_logs" TO "service_role";



GRANT ALL ON TABLE "public"."api_tokens" TO "anon";
GRANT ALL ON TABLE "public"."api_tokens" TO "authenticated";
GRANT ALL ON TABLE "public"."api_tokens" TO "service_role";



GRANT ALL ON TABLE "public"."attachment_audit_log" TO "anon";
GRANT ALL ON TABLE "public"."attachment_audit_log" TO "authenticated";
GRANT ALL ON TABLE "public"."attachment_audit_log" TO "service_role";



GRANT ALL ON SEQUENCE "public"."attachment_audit_log_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."attachment_audit_log_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."attachment_audit_log_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."audiences" TO "anon";
GRANT ALL ON TABLE "public"."audiences" TO "authenticated";
GRANT ALL ON TABLE "public"."audiences" TO "service_role";



GRANT ALL ON SEQUENCE "public"."audiences_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."audiences_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."audiences_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."campaigns" TO "anon";
GRANT ALL ON TABLE "public"."campaigns" TO "authenticated";
GRANT ALL ON TABLE "public"."campaigns" TO "service_role";



GRANT ALL ON SEQUENCE "public"."campaigns_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."campaigns_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."campaigns_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."column_visibility" TO "anon";
GRANT ALL ON TABLE "public"."column_visibility" TO "authenticated";
GRANT ALL ON TABLE "public"."column_visibility" TO "service_role";



GRANT ALL ON SEQUENCE "public"."column_visibility_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."column_visibility_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."column_visibility_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."contact" TO "anon";
GRANT ALL ON TABLE "public"."contact" TO "authenticated";
GRANT ALL ON TABLE "public"."contact" TO "service_role";



GRANT ALL ON TABLE "public"."contact_attachment" TO "anon";
GRANT ALL ON TABLE "public"."contact_attachment" TO "authenticated";
GRANT ALL ON TABLE "public"."contact_attachment" TO "service_role";



GRANT ALL ON SEQUENCE "public"."contact_attachment_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."contact_attachment_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."contact_attachment_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."contact_custom_fields" TO "anon";
GRANT ALL ON TABLE "public"."contact_custom_fields" TO "authenticated";
GRANT ALL ON TABLE "public"."contact_custom_fields" TO "service_role";



GRANT ALL ON SEQUENCE "public"."contact_custom_fields_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."contact_custom_fields_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."contact_custom_fields_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."contact_enrichment" TO "anon";
GRANT ALL ON TABLE "public"."contact_enrichment" TO "authenticated";
GRANT ALL ON TABLE "public"."contact_enrichment" TO "service_role";



GRANT ALL ON SEQUENCE "public"."contact_enrichment_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."contact_enrichment_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."contact_enrichment_id_seq" TO "service_role";



GRANT ALL ON SEQUENCE "public"."contact_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."contact_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."contact_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."contact_note" TO "anon";
GRANT ALL ON TABLE "public"."contact_note" TO "authenticated";
GRANT ALL ON TABLE "public"."contact_note" TO "service_role";



GRANT ALL ON SEQUENCE "public"."contact_note_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."contact_note_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."contact_note_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."contact_voting_history" TO "anon";
GRANT ALL ON TABLE "public"."contact_voting_history" TO "authenticated";
GRANT ALL ON TABLE "public"."contact_voting_history" TO "service_role";



GRANT ALL ON SEQUENCE "public"."contact_voting_history_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."contact_voting_history_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."contact_voting_history_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."custom_columns" TO "anon";
GRANT ALL ON TABLE "public"."custom_columns" TO "authenticated";
GRANT ALL ON TABLE "public"."custom_columns" TO "service_role";



GRANT ALL ON SEQUENCE "public"."custom_columns_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."custom_columns_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."custom_columns_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."data_access_field_permissions" TO "anon";
GRANT ALL ON TABLE "public"."data_access_field_permissions" TO "authenticated";
GRANT ALL ON TABLE "public"."data_access_field_permissions" TO "service_role";



GRANT ALL ON SEQUENCE "public"."data_access_field_permissions_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."data_access_field_permissions_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."data_access_field_permissions_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."data_access_record_permissions" TO "anon";
GRANT ALL ON TABLE "public"."data_access_record_permissions" TO "authenticated";
GRANT ALL ON TABLE "public"."data_access_record_permissions" TO "service_role";



GRANT ALL ON SEQUENCE "public"."data_access_record_permissions_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."data_access_record_permissions_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."data_access_record_permissions_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."division_electoral_district" TO "anon";
GRANT ALL ON TABLE "public"."division_electoral_district" TO "authenticated";
GRANT ALL ON TABLE "public"."division_electoral_district" TO "service_role";



GRANT ALL ON TABLE "public"."events" TO "anon";
GRANT ALL ON TABLE "public"."events" TO "authenticated";
GRANT ALL ON TABLE "public"."events" TO "service_role";



GRANT ALL ON TABLE "public"."events_sync_config" TO "anon";
GRANT ALL ON TABLE "public"."events_sync_config" TO "authenticated";
GRANT ALL ON TABLE "public"."events_sync_config" TO "service_role";



GRANT ALL ON TABLE "public"."feature_permissions" TO "anon";
GRANT ALL ON TABLE "public"."feature_permissions" TO "authenticated";
GRANT ALL ON TABLE "public"."feature_permissions" TO "service_role";



GRANT ALL ON SEQUENCE "public"."feature_permissions_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."feature_permissions_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."feature_permissions_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."features" TO "anon";
GRANT ALL ON TABLE "public"."features" TO "authenticated";
GRANT ALL ON TABLE "public"."features" TO "service_role";



GRANT ALL ON TABLE "public"."organizer_tags" TO "anon";
GRANT ALL ON TABLE "public"."organizer_tags" TO "authenticated";
GRANT ALL ON TABLE "public"."organizer_tags" TO "service_role";



GRANT ALL ON TABLE "public"."page_questions" TO "anon";
GRANT ALL ON TABLE "public"."page_questions" TO "authenticated";
GRANT ALL ON TABLE "public"."page_questions" TO "service_role";



GRANT ALL ON SEQUENCE "public"."page_questions_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."page_questions_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."page_questions_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."permission_audit_log" TO "anon";
GRANT ALL ON TABLE "public"."permission_audit_log" TO "authenticated";
GRANT ALL ON TABLE "public"."permission_audit_log" TO "service_role";



GRANT ALL ON SEQUENCE "public"."permission_audit_log_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."permission_audit_log_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."permission_audit_log_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."profile_campus_club_access" TO "anon";
GRANT ALL ON TABLE "public"."profile_campus_club_access" TO "authenticated";
GRANT ALL ON TABLE "public"."profile_campus_club_access" TO "service_role";



GRANT ALL ON TABLE "public"."profile_organizer_tags" TO "anon";
GRANT ALL ON TABLE "public"."profile_organizer_tags" TO "authenticated";
GRANT ALL ON TABLE "public"."profile_organizer_tags" TO "service_role";



GRANT ALL ON TABLE "public"."profile_region_access" TO "anon";
GRANT ALL ON TABLE "public"."profile_region_access" TO "authenticated";
GRANT ALL ON TABLE "public"."profile_region_access" TO "service_role";



GRANT ALL ON TABLE "public"."profile_riding_access" TO "anon";
GRANT ALL ON TABLE "public"."profile_riding_access" TO "authenticated";
GRANT ALL ON TABLE "public"."profile_riding_access" TO "service_role";



GRANT ALL ON TABLE "public"."profiles" TO "anon";
GRANT ALL ON TABLE "public"."profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."profiles" TO "service_role";



GRANT ALL ON TABLE "public"."request" TO "anon";
GRANT ALL ON TABLE "public"."request" TO "authenticated";
GRANT ALL ON TABLE "public"."request" TO "service_role";



GRANT ALL ON SEQUENCE "public"."requests_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."requests_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."requests_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."roles" TO "anon";
GRANT ALL ON TABLE "public"."roles" TO "authenticated";
GRANT ALL ON TABLE "public"."roles" TO "service_role";



GRANT ALL ON TABLE "public"."saved_filters" TO "anon";
GRANT ALL ON TABLE "public"."saved_filters" TO "authenticated";
GRANT ALL ON TABLE "public"."saved_filters" TO "service_role";



GRANT ALL ON SEQUENCE "public"."saved_filters_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."saved_filters_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."saved_filters_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."signup_requests" TO "anon";
GRANT ALL ON TABLE "public"."signup_requests" TO "authenticated";
GRANT ALL ON TABLE "public"."signup_requests" TO "service_role";



GRANT ALL ON SEQUENCE "public"."signup_requests_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."signup_requests_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."signup_requests_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."survey_column_update_rules" TO "anon";
GRANT ALL ON TABLE "public"."survey_column_update_rules" TO "authenticated";
GRANT ALL ON TABLE "public"."survey_column_update_rules" TO "service_role";



GRANT ALL ON SEQUENCE "public"."survey_column_update_rules_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."survey_column_update_rules_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."survey_column_update_rules_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."survey_instances" TO "anon";
GRANT ALL ON TABLE "public"."survey_instances" TO "authenticated";
GRANT ALL ON TABLE "public"."survey_instances" TO "service_role";



GRANT ALL ON SEQUENCE "public"."survey_instances_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."survey_instances_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."survey_instances_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."survey_page_assignments" TO "anon";
GRANT ALL ON TABLE "public"."survey_page_assignments" TO "authenticated";
GRANT ALL ON TABLE "public"."survey_page_assignments" TO "service_role";



GRANT ALL ON SEQUENCE "public"."survey_page_assignments_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."survey_page_assignments_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."survey_page_assignments_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."survey_pages" TO "anon";
GRANT ALL ON TABLE "public"."survey_pages" TO "authenticated";
GRANT ALL ON TABLE "public"."survey_pages" TO "service_role";



GRANT ALL ON SEQUENCE "public"."survey_pages_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."survey_pages_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."survey_pages_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."survey_questions" TO "anon";
GRANT ALL ON TABLE "public"."survey_questions" TO "authenticated";
GRANT ALL ON TABLE "public"."survey_questions" TO "service_role";



GRANT ALL ON SEQUENCE "public"."survey_questions_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."survey_questions_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."survey_questions_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."survey_response_answers" TO "anon";
GRANT ALL ON TABLE "public"."survey_response_answers" TO "authenticated";
GRANT ALL ON TABLE "public"."survey_response_answers" TO "service_role";



GRANT ALL ON SEQUENCE "public"."survey_response_answers_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."survey_response_answers_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."survey_response_answers_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."survey_responses" TO "anon";
GRANT ALL ON TABLE "public"."survey_responses" TO "authenticated";
GRANT ALL ON TABLE "public"."survey_responses" TO "service_role";



GRANT ALL ON SEQUENCE "public"."survey_responses_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."survey_responses_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."survey_responses_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."surveys" TO "anon";
GRANT ALL ON TABLE "public"."surveys" TO "authenticated";
GRANT ALL ON TABLE "public"."surveys" TO "service_role";



GRANT ALL ON SEQUENCE "public"."surveys_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."surveys_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."surveys_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."user_column_preferences" TO "anon";
GRANT ALL ON TABLE "public"."user_column_preferences" TO "authenticated";
GRANT ALL ON TABLE "public"."user_column_preferences" TO "service_role";



GRANT ALL ON SEQUENCE "public"."user_column_preferences_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."user_column_preferences_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."user_column_preferences_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."user_expanded_sections" TO "anon";
GRANT ALL ON TABLE "public"."user_expanded_sections" TO "authenticated";
GRANT ALL ON TABLE "public"."user_expanded_sections" TO "service_role";



GRANT ALL ON SEQUENCE "public"."user_expanded_sections_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."user_expanded_sections_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."user_expanded_sections_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."user_filter_defaults" TO "anon";
GRANT ALL ON TABLE "public"."user_filter_defaults" TO "authenticated";
GRANT ALL ON TABLE "public"."user_filter_defaults" TO "service_role";



GRANT ALL ON SEQUENCE "public"."user_filter_defaults_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."user_filter_defaults_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."user_filter_defaults_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."user_preferences" TO "anon";
GRANT ALL ON TABLE "public"."user_preferences" TO "authenticated";
GRANT ALL ON TABLE "public"."user_preferences" TO "service_role";



GRANT ALL ON SEQUENCE "public"."user_preferences_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."user_preferences_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."user_preferences_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."user_table_preferences" TO "anon";
GRANT ALL ON TABLE "public"."user_table_preferences" TO "authenticated";
GRANT ALL ON TABLE "public"."user_table_preferences" TO "service_role";



GRANT ALL ON SEQUENCE "public"."user_table_preferences_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."user_table_preferences_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."user_table_preferences_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."view_column_visibility" TO "anon";
GRANT ALL ON TABLE "public"."view_column_visibility" TO "authenticated";
GRANT ALL ON TABLE "public"."view_column_visibility" TO "service_role";



GRANT ALL ON SEQUENCE "public"."view_column_visibility_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."view_column_visibility_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."view_column_visibility_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."views" TO "anon";
GRANT ALL ON TABLE "public"."views" TO "authenticated";
GRANT ALL ON TABLE "public"."views" TO "service_role";



GRANT ALL ON SEQUENCE "public"."views_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."views_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."views_id_seq" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";






























