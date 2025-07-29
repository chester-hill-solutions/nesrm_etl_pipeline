import { createClient } from "@supabase/supabase-js";
import "dotenv/config";

export const handler = async (payload) => {
  //connect to supabase
  const supabase = createClient(process.env.DATABASE_URL, process.env.KEY);

  //store request in supabase
  const { data, requestStorageError } = await supabase.from("request").insert({
    payload: payload,
    source_url: payload.haeder[`access-control-allow-origin`],
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

  //const shapedData = shapeData(payload);

  let response = {
    statusCode: 200,
    body: JSON.stringify("Payload ingested and backed up"),
    payload: payload,
  };

  return response;
};
