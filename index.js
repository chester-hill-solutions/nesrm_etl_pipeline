import { createClient } from "@supabase/supabase-js";
import 'dotenv/config';

function validatePayload(payload) {
  const errors = [];
  if (!payload.event){
    errors.push("Missing body key")
    return errors;
  };
  if (!payload.event.body){
    errors.push("Missing body key")
    return errors;
  };
  if (!payload.event.body.source_url) {
    errors.push("Missing source_url");
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

  //connect to supabase
  const supabase = createClient(process.env.DATABASE_URL, process.env.KEY);

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

  //store request in supabase
  const { data, requestStorageError } = await supabase
    .from("request")
    .insert({ payload: payload, source_url: payload.event.body.source_url });

  if (requestStorageError) {
    let response = {
      statusCode: 400,
      body: JSON.stringify({ errorType: "supabase", ...requestStorageError }),
    };
    return response;
  }

  console.log(data, requestStorageError);

  let response = {
    statusCode: 200,
    body: JSON.stringify("ahfbskbf"),
  };

  return response;
};

