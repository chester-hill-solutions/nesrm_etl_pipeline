import { createClient } from "@supabase/supabase-js";
import shapeData from "./shapeData.js";
import "dotenv/config";

function validatePayload(payload) {
  const errors = [];
  if (!payload.event) {
    errors.push("Missing event key");
  } else {
    if (!payload.event.body) {
      errors.push("Missing event.body key");
    }
  }
  if (!payload.context) {
    errors.push("Missing context key");
  } else {
    if (!payload.context.source_url) {
      errors.push("Missing context.source_url");
    }
  }

  return errors;
}

export const handler = async (event) => {
  //check empty
  if (!event) {
    let response = {
      statusCode: 400,
      body: JSON.stringify("Missing payload"),
    };
    return response;
  }

  //parse event
  let payload = {};
  if (typeof event === "string") {
    console.log("Event is a string");
    payload = JSON.parse(event);
  } else {
    console.log("Event is not a string");
    payload = event;
  }
  console.log("Event: ", payload);

  //validate
  const validationErrors = validatePayload(payload);
  if (validationErrors.length > 0) {
    let response = {
      statusCode: 422,
      body: JSON.stringify(validationErrors),
    };
    return response;
  }
  console.log("Initial Validation Passed");

  //connect to supabase
  const supabase = createClient(process.env.DATABASE_URL, process.env.KEY);

  //store request in supabase
  const { data, requestStorageError } = await supabase
    .from("request")
    .insert({ payload: payload, source_url: payload.event.body.source_url });

  if (requestStorageError) {
    let response = {
      statusCode: 400,
      body: JSON.stringify({ errorType: "supabase", ...requestStorageError }),
    };
    console.log(data, requestStorageError);
    return response;
  }
  console.log("Event storage success");

  //const shapedData = shapeData(payload);

  let response = {
    statusCode: 200,
    body: JSON.stringify("Data ingested and backed up"),
  };

  return response;
};
