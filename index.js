import { performance } from "perf_hooks";
//import AWS from "aws-sdk";
import { SFNClient, StartExecutionCommand } from "@aws-sdk/client-sfn";

import ingest from "./src/ingest.js";
import { getValue, shapeData } from "./src/shape.js";
import { statusCodeMonad as scMonad } from "./scripts/monads/monad.js";
import { sbPatch } from "./scripts/quickSbPatch/index.js";
import { upsertData } from "./src/upsert.js";
import logger from "simple-logs-sai-node";
import { mail } from "./src/mail.js";
import { createClient } from "@supabase/supabase-js";

import "./loadEnv.js";
import { sendTeamWelcome } from "./src/mailWelcome.js";
import appendToSheet from "./src/appendToSheet.js";

let REQUEST_BACKUP_ID;
let REQUEST_CREATED_AT;
//comment
async function storeSuccess(logs, success) {
  if (REQUEST_BACKUP_ID) {
    try {
      const supabase = await createClient(
        process.env.DATABASE_URL,
        process.env.KEY,
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

async function storeRequestReturnPayload(payload, dataStore, supabase) {
  const data = ingest.storeRequest(dataStore, supabase);
  payload.response.body.request_backup_id = data.id;
  return payload.response;
}

export const handler = async (event) => {
  const start = performance.now();

  try {
    const supabase = createClient(process.env.DATABASE_URL, process.env.KEY);

    logger.log("event triggered");
    logger.log("event triggered", JSON.stringify(event, null, 2));
    //Ingest param check
    let payload = await scMonad.bindMonad(
      scMonad.unit(event),
      ingest.headerCheck,
    );
    if (payload.response.statusCode != 200) {
      return storeRequestReturnPayload(
        payload,
        { logs: payload, success: false },
        supabase,
      );
    } else {
      payload.input = payload.trace[0].output;
    }
    //Ingest store event
    payload = await scMonad.bindMonad(scMonad.unit(payload), ingest.storeEvent);
    if (payload.response.statusCode != 200) {
      return storeRequestReturnPayload(
        payload,
        { logs: payload, success: false },
        supabase,
      );
    } else {
      payload.input = payload.trace[0].output;
      REQUEST_BACKUP_ID = payload.trace[0].output.headers.request_backup_id;
      REQUEST_CREATED_AT = payload.trace[0].output.headers.request_created_at;
    }
    if (event.headers.throw) {
      return storeRequestReturnPayload(
        payload,
        { logs: payload, success: false },
        supabase,
      );
    }
    //Shape
    let shaped_data;
    payload = await scMonad.bindMonad(scMonad.unit(payload), shapeData);
    if (payload.response.statusCode != 200) {
      return storeRequestReturnPayload(
        payload,
        { logs: payload, success: false },
        supabase,
      );
    } else {
      payload.input = payload.trace[0].output;
    }
    shaped_data = payload.input;

    //Append to Sheet    
    payload = await scMonad.bindMonad(scMonad.unit({
            payload: event,
            created_at: REQUEST_CREATED_AT,
            request_id: REQUEST_BACKUP_ID,
            body: event["body"],
            shaped_data
        }),appendToSheet);
    if (payload.response.statusCode != 200) {
      return storeRequestReturnPayload(
        payload,
        { logs: payload, success: false },
        supabase,
      );
    } else {
      payload.input = shaped_data
    }
    

    //Upsert
    let upserted_data;
    payload = await scMonad.bindMonad(scMonad.unit(payload), upsertData);
    if (payload.response.statusCode != 200) {
      return storeRequestReturnPayload(
        payload,
        { logs: payload, success: false },
        supabase,
      );
    } else {
      payload.input = payload.trace[0].output;
      upserted_data = payload.trace[0].output;
    }

    payload = await scMonad.bindMonad(
      scMonad.unit({
        id: REQUEST_BACKUP_ID,
        contact_id: upserted_data.id,
      }),
      ingest.storeRequest,
    );
    if (payload.response.statusCode != 200) {
      return storeRequestReturnPayload(
        payload,
        { logs: payload, success: false },
        supabase,
      );
    } else {
      payload.input = upserted_data;
    }

    //send team welcome
    try {
      const event_body =
        typeof event.body === "string" ? JSON.parse(event.body) : event.body;
      if (
        event_body._status == "complete" &&
        event_body._meta.submission_source == "organic"
      ) {
        const welcomeResponse = await scMonad.bindMonad(
          scMonad.unit(upserted_data),
          sendTeamWelcome,
        );
        logger.log("welcomeResponse", welcomeResponse);
        if (welcomeResponse.response.statusCode != 200) {
          return storeRequestReturnPayload(
            welcomeResponse,
            { logs: welcomeResponse, success: false },
            supabase,
          );
        } else {
          payload.input = upserted_data;
        }
      } else {
        logger.log(
          "not sending welcomeResponse",
          event_body._status,
          event_body._meta.submission_source,
        );
      }
    } catch (error) {
      logger.log(error);
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
            payload.input.data.id,
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
    logger.log("time duration", performance.now() - start);
    logger.dev.log(
      "index.js response",
      JSON.stringify(payload.response, null, 2),
    );
    return storeRequestReturnPayload(
      payload,
      { logs: payload, status: true },
      supabase,
    );
    return s(payload, true);
  } catch (error) {
    logger.log(error);
    console.error(error);
    return {
      statusCode: 500,
    };
  }
};
