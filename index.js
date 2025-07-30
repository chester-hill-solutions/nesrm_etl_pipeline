import { createClient } from "@supabase/supabase-js";
import "dotenv/config";
//import AWS from "aws-sdk";
import { SFNClient, StartExecutionCommand } from "@aws-sdk/client-sfn";

export const handler = async (event) => {
  const headers = event.headers;
  if (!headers) {
    return {
      statusCode: 400,
      body: JSON.stringify("Missing any headers"),
    };
  }
  if (!headers["origin"] || !headers["x-forwarded-for"]) {
    return {
      statusCode: 400,
      body: JSON.stringify(
        `Event missing headers: {${!headers["origin"] ? " origin" : ""} ${
          !headers["x-forwarded-for"] ? " x-forwarded-for" : ""
        } }`
      ),
    };
  }

  if (
    !process.env.ORIGIN_WHITELIST.split(",").some((item) =>
      headers.origin.includes(item)
    )
  ) {
    console.log("Header.origin:", headers.origin);
    console.log("Accepted:", process.env.ORIGIN_WHITELIST.split(","));
    return {
      statusCode: 401,
    };
  }

  //connect to supabase client
  const supabase = createClient(process.env.DATABASE_URL, process.env.KEY);

  //store request in supabase
  const { data, requestStorageError } = await supabase.from("request").insert({
    event: event,
    origin: event.headers["origin"],
    ip: event.headers["x-forwarded-for"],
  });

  if (requestStorageError) {
    let response = {
      statusCode: 400,
      body: JSON.stringify({ errorType: "supabase", ...requestStorageError }),
    };
    console.log(data, requestStorageError);
    return response;
  }
  console.log("Event storage success");

  /*
  const stepFunctions = new AWS.StepFunctions();
  const result = await stepFunctions
    .startExecution({
      stateMachineArn: process.env.STATE_MACHINE,
      input: event,
    })
    .promise();
*/
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
  };

  return response;
};
