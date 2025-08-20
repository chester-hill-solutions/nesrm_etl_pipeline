# NESRM Ingest

This is the lambda function to handle NES Relationship Manager Ingestion.

## Develop

```bash
NODE_ENV=development
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
