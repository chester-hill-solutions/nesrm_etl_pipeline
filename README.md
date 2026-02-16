# NESRM Ingest

This is the lambda function to handle NES Relationship Manager Ingestion.

## runner.js quickstart

```bash
node runner.js <input-path> > <output-path>

```

`runner.js` can run payloads locally (`--local`, default) or via API Gateway (`--gateway`). Add `--slow` to pause between requests. By default it forces `body._meta.submission_source = "cli-runner"` (logged at start and per payload); keep existing values with `--keep-source_submission` (or `-k`). Enable nested body fixups with `--unwrap-body` (or `-u`). Log-only dry runs with `--dry-run` (or `-d`).

- CSV file (raw columns): `node runner.js path/to/file.csv --gateway`
  - Each row becomes the request body; default headers applied.
- CSV file with `payload` JSONB column (e.g., `public.request` export): `node runner.js path/to/export.csv`
  - `payload` is parsed (even if stringified); inner `headers`/`body` strings are parsed; default headers applied if missing. Top-level CSV columns are ignored when `payload` exists (payload is authoritative).
- JSON file (single object): `node runner.js path/to/payload.json`
  - Treated as one payload; wraps with default headers if none.
- JSON file (array of objects): `node runner.js path/to/payloads.json`
  - Each array item is sent in order.

### Headers

- If your JSON includes `headers` and `body`, `runner.js` uses them as-is.
- If your JSON lacks `headers`, `runner.js` wraps the object with default headers from `runner.js` (includes `Authorization` using `AWS_API_GATEWAY_BEARER`).
- CSV rows are treated as bodies without headers; default headers are applied.
- `payload` columns in CSV exports are parsed; if they contain `headers` as strings, those are parsed too.
- Optional: `--unwrap-body`/`-u` will try to unwrap nested `body`, `body.value`, or `body.values` keys inside a payload body and merge them (useful for malformed exports). Off by default.
- Optional: `--dry-run`/`-d` logs the final event (headers + body) that would be sent, without sending.

### Examples

```bash
# Local lambda handler, CSV input
node runner.js data/upload.csv --local

# Gateway with provided headers in JSON objects
node runner.js data/payloads_with_headers.json --gateway

# Disable submission_source override
node runner.js data/upload.csv --keep-source_submission

# Unwrap nested body/body.value(s) in malformed payloads
node runner.js data/export.csv --unwrap-body

# Dry run to inspect final payloads without sending
node runner.js data/export.csv --dry-run
```

## Development

```bash
npm install -y
```

### Setup DB

```bash
npx supabase init
npx supabase start --debug
```












# OLD
#### Setup roles

Make sure there's a geo_role_passwords.sql file with every riding and region and corresponding passwords

```bash
cp supabase/20251023_create_riding_region_roles.sql supabase/roles/20251023_create_riding_region_with_passwords_roles.sql
node scripts/updateRolePasswords.js
```

```bash
psql "postgresql://postgres:postgres@localhost:54322/postgres" -f ./supabase/roles/init_sys_roles.sql
psql "postgresql://postgres:postgres@localhost:54322/postgres" -f ./supabase/roles/20251023_create_riding_region_roles_with_passwords.sql
npx supabase migration up --debug
```

You may also need `touch ./supabase/.temp/profile` and `echo "supabase" > ./supabase/.temp/profile`

**Sync local db to cloud schema if not included**

```bash
# BEFORE YOU DELETE make some sort of backup for the migration folder and copy contents there then
rm -rf ./supabase/migrations && mkdir ./supabase/migrations
rm -rf ./supabase/roles && mkdir ./supabase/roles
npx supabase login --debug
npx supabase link --project-ref <SUPABASE-PROJECT-REF> --debug
npx supabase db dump -f supabase/roles/<TODAYS-YYYY><MM><DD><HH><MN>00roles.sql --role-only --debug
# note that supabase defaults to using UTC time. So if you put your current time, it might run earlier or later in order then you expect
psql "postgresql://postgres:postgres@localhost:54322/postgres" -f ./supabase/roles/<TODAYS-YYYY><MM><DD><HH><MN>roles.sql
npx supabase db pull --debug
npx supabase migration up --debug
```

#### Environment

Navigate to `http://localhost:54323/project/default/editor/18509?schema=public&showConnect=true&framework=nextjs&tab=frameworks` and copy the `DATABASE_URL` and `KEY` in `.env.local`

Setup the rest of `.env.local` based on `.env.template`

### Active Development

```bash
npx supabase start
```

## Deploy

Upload from > .zip file > Upload > Navigate to `deploy.zip` > Save

# TODO:

## SWE / DE

## Dev Ops

- [ ] sort local trial flow
- [x] configure aws cli
- [x] configure lambda build Upload
- [x] configure github CD process
- [ ] develop tests
  - [ ] ingest.storeEvent tests
- [ ] configure test CI process
