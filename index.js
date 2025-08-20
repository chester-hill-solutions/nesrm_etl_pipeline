import "dotenv/config";
//import AWS from "aws-sdk";
import { SFNClient, StartExecutionCommand } from "@aws-sdk/client-sfn";

import ingest from "./src/ingest.js";
import { shape } from "./src/shape.js";
import { statusCodeMonad as scMonad } from "./scripts/monads/monad.js";

export const handler = async (event) => {
  console.log("payload", event);

  let response = {};
  let funcOutput;

  //Ingest
  ({ funcResponse: response, funcOutput } = {
    ...(await scMonad.bindMonad(response, event.headers, ingest.headerCheck)),
  });
  //console.log(response);
  if (response.statusCode != 200) {
    return response;
  }
  ({ funcResponse: response, funcOutput } = {
    ...(await scMonad.bindMonad(response, event, ingest.storeEvent)),
  });
  if (response.statusCode != 200) {
    return response;
  }

  //Shape
  let cleaned_data;
  ({ funcResponse: response, funcOutput: cleaned_data } =
    await scMonad.bindMonad(response, event, shape));
  if (response.statusCode != 200) {
    return response;
  }

  response = JSON.stringify(response.body);
  console.log("response", response);
  return response;
};
