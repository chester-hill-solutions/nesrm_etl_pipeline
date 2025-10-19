# NESRM Ingest

This is the lambda function to handle NES Relationship Manager Ingestion.

## Development

### Active

```bash
NODE_ENV=development
```

### Initial Setup

```bash
npm install -y
```

#### Setup DB

```bash
npx supabase init
npx supabase start --debug
psql "postgresql://postgres:postgres@localhost:54322/postgres" -f ./supabase/roles/<PICK THE LATEST ONE>roles.sql
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

blah blah blah
/\*
const client = new SFNClient();
const command = new StartExecutionCommand({
stateMachineArn: process.env.STATE_MACHINE,
input: JSON.stringify(event),
});

const result = await client.send(command);
let response = {
statusCode: 200,
body: JSON.stringify({
ingestionStatus: data,
pipelineStatus: result,
}),
};\*/
