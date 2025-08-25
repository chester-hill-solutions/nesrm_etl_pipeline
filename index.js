import "dotenv/config";
//import AWS from "aws-sdk";
import { SFNClient, StartExecutionCommand } from "@aws-sdk/client-sfn";

import ingest from "./src/ingest.js";
import { shapeData } from "./src/shape.js";
import { statusCodeMonad as scMonad } from "./scripts/monads/monad.js";
import { upsertData } from "./src/upsert.js";
import { json } from "stream/consumers";

export const handler = async (event) => {
  try {
    console.log("event", event);
    let funcOutput;
    //Ingest
    let payload = await scMonad.bindMonad(
      scMonad.unit(event.headers),
      ingest.headerCheck
    );
    if (payload.response.statusCode != 200) {
      return response;
    }
    payload.input = event;
    payload = await scMonad.bindMonad(scMonad.unit(payload), ingest.storeEvent);
    if (payload.response.statusCode != 200) {
      return response;
    }

    //Shape
    payload.input = event;
    let cleaned_data;
    payload = await scMonad.bindMonad(scMonad.unit(payload), shapeData);
    if (payload.response.statusCode != 200) {
      return response;
    }
    cleaned_data = payload.input;

    let updated_data;
    payload = await scMonad.bindMonad(scMonad.unit(payload), upsertData);
    if (payload.response.statusCode != 200) {
      return response;
    }
    updated_data = payload.input;

    console.log("index.js response", payload.response);
    payload.response.body = JSON.stringify(payload.response.body);
    return payload.response;
  } catch (error) {
    console.error(error);
    return {
      statusCode: 500,
    };
  }
};
