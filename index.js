import "dotenv/config";
//import AWS from "aws-sdk";
import { SFNClient, StartExecutionCommand } from "@aws-sdk/client-sfn";

import ingest from "./src/ingest.js";
import { shapeData } from "./src/shape.js";
import { statusCodeMonad as scMonad } from "./scripts/monads/monad.js";
import { sbPatch } from "./scripts/quickSbPatch/index.js";
import { upsertData } from "./src/upsert.js";
import logger from "simple-logs-sai-node";
import { mail } from "./src/mail.js";
import { createClient } from "@supabase/supabase-js";

let REQUEST_BACKUP_ID;

async function storeSuccess(logs, success) {
  if (REQUEST_BACKUP_ID) {
    try {
      const supabase = await createClient(
        process.env.DATABASE_URL,
        process.env.KEY
      );
      const { error: sbError } = await supabase
        .from("request")
        .update({ success: success, logs: logs })
        .eq("id", REQUEST_BACKUP_ID);
      if (sbError) {
        console.error(sbError);
        throw new Error(sbError);
      }
    } catch (error) {
      console.error(error);
    }
  }
}

async function s(payload, success = false) {
  storeSuccess(payload, success);
  payload.response.body.request_backup_id = REQUEST_BACKUP_ID
    ? REQUEST_BACKUP_ID
    : undefined;
  payload.response.body = JSON.stringify(payload.response.body);
  return payload.response;
}

export const handler = async (event) => {
  try {
    logger.log("event triggered");
    logger.dev.log("event triggered", JSON.stringify(event, null, 2));
    let funcOutput;
    //Ingest param check
    let payload = await scMonad.bindMonad(
      scMonad.unit(event),
      ingest.headerCheck
    );
    if (payload.response.statusCode != 200) {
      return s(payload);
    } else {
      payload.input = payload.trace[0].output;
    }
    //Ingest store event
    payload = await scMonad.bindMonad(scMonad.unit(payload), ingest.storeEvent);
    if (payload.response.statusCode != 200) {
      return s(payload);
    } else {
      payload.input = payload.trace[0].output;
      REQUEST_BACKUP_ID = payload.trace[0].output.headers.request_backup_id;
    }
    if (event.headers.throw) {
      return s(payload);
    }
    //Shape
    //let cleaned_data;
    payload = await scMonad.bindMonad(scMonad.unit(payload), shapeData);
    if (payload.response.statusCode != 200) {
      return s(payload);
    } else {
      payload.input = payload.trace[0].output;
    }
    //cleaned_data = payload.input;

    //Upsert
    let upserted_data;
    payload = await scMonad.bindMonad(scMonad.unit(payload), upsertData);
    if (payload.response.statusCode != 200) {
      return s(payload);
    } else {
      payload.input = payload.trace[0].output;
      upserted_data = payload.trace[0].output;
    }
    //console.log("compare", payload.trace[0].output == payload.input);
    if (payload.input.comms_consent) {
      payload = await scMonad.bindMonad(scMonad.unit(payload), mail);
      if (payload.response.statusCode != 200) {
        return s(payload);
      } else {
        payload.input = payload.trace[0].output;
        if (payload.input?.data?.id) {
          console.log(
            "index/handler/sbPatch contact",
            upserted_data.id,
            "mailerlite_id",
            payload.input.data.id
          );
          payload.input = {
            table: "contact",
            id: upserted_data.id,
            field: "mailerlite_id",
            value: payload.input.data.id,
          };
          payload = await scMonad.bindMonad(scMonad.unit(payload), sbPatch);
          /*
          sbPatch(
            "contact",
          upserted_data.id,
            "mailerlite_id",
            payload.input.data.id
          );*/
        }
        //updated_data = payload.trace[0].output;
      }
    }

    //Reponse
    logger.dev.log("index.js response", payload.response);
    return s(payload, true);
  } catch (error) {
    console.error(error);
    return {
      statusCode: 500,
    };
  }
};
