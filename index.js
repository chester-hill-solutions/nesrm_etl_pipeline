import "dotenv/config";
//import AWS from "aws-sdk";
import { SFNClient, StartExecutionCommand } from "@aws-sdk/client-sfn";

import ingest from "./src/ingest.js";
import { shapeData } from "./src/shape.js";
import { statusCodeMonad as scMonad } from "./scripts/monads/monad.js";
import { upsertData } from "./src/upsert.js";
import logger from "simple-logs-sai-node";

export const handler = async (event) => {
  try {
    logger.log("event triggered" /*, JSON.stringify(event, null, 2)*/);
    let funcOutput;
    //Ingest
    let payload = await scMonad.bindMonad(
      scMonad.unit(event),
      ingest.headerCheck
    );
    if (payload.response.statusCode != 200) {
      return payload.response;
    } else {
      payload.input = payload.trace[0].output;
    }
    //payload.input = event;
    payload = await scMonad.bindMonad(scMonad.unit(payload), ingest.storeEvent);
    if (payload.response.statusCode != 200) {
      return payload.response;
    } else {
      payload.input = payload.trace[0].output;
    }

    //Shape
    //payload.input = event;
    let cleaned_data;
    payload = await scMonad.bindMonad(scMonad.unit(payload), shapeData);
    if (payload.response.statusCode != 200) {
      return payload.response;
    } else {
      payload.input = payload.trace[0].output;
    }
    cleaned_data = payload.input;

    //Upsert
    let updated_data;
    payload = await scMonad.bindMonad(scMonad.unit(payload), upsertData);
    if (payload.response.statusCode != 200) {
      return payload.response;
    } else {
      payload.input = payload.trace[0].output;
    }
    //console.log("compare", payload.trace[0].output == payload.input);
    updated_data = payload.trace[0].output;

    //Reponse
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
