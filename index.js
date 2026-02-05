import { performance } from "perf_hooks";
//import AWS from "aws-sdk";
import { SFNClient, StartExecutionCommand } from "@aws-sdk/client-sfn";

import "./loadEnv.js";
import ingest from "./src/ingest.js";
import { getValue, shapeData } from "./src/shape.js";
import { statusCodeMonad as scMonad } from "./scripts/monads/monad.js";
import { sbPatch } from "./scripts/quickSbPatch/index.js";
import { upsertData } from "./src/upsert.js";
import logger from "simple-logs-sai-node";
import { mail } from "./src/mail.js";
import { createClient } from "@supabase/supabase-js";

import { sendTeamWelcome } from "./src/mailWelcome.js";
import appendToSheet from "./src/appendToSheet.js";

let REQUEST_BACKUP_ID;
let REQUEST_CREATED_AT;

async function storeRequestReturnPayload(payload, storeData, supabase) {
  logger.dev.log("await storeRequestReturnPayload()");
  logger.dev.log("payload", payload);
  logger.dev.log("dataStore", storeData);
  const data = await ingest.storeRequest({ input: storeData, supabase });
  payload.response.body.request_backup_id = data.id;
  payload.response.body = JSON.stringify(payload.response.body);
  logger.log("payload", payload);
  logger.log("payload.response", payload.response);
  return payload.response;
}

export const handler = async (event) => {
  const start = performance.now();
  let payload;

  try {
    const supabase = createClient(
      process.env.DATABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY,
    );

    logger.log("event triggered");
    logger.log("event triggered", JSON.stringify(event, null, 2));
    const event_body =
      typeof event.body === "string" ? JSON.parse(event.body) : event.body;
    logger.log("event.body", event_body);
    //Ingest param check
    payload = await scMonad.bindMonad(scMonad.unit(event), ingest.headerCheck);
    logger.dev.log("payload respone trace", payload.response.body.trace);
    if (payload.response.statusCode != 200) {
      return await storeRequestReturnPayload(
        payload,
        { payload: event, logs: payload, success: false },
        supabase,
      );
    } else {
      payload.input = payload.trace[0].output;
    }
    //Ingest store event
    payload = await scMonad.bindMonad(
      scMonad.unit(payload),
      ingest.storeEvent,
      supabase,
    );
    logger.dev.log("payload respone trace", payload.response.body.trace);
    if (payload.response.statusCode != 200) {
      return await storeRequestReturnPayload(
        payload,
        { payload: event, logs: payload, success: false },
        supabase,
      );
    } else {
      payload.input = payload.trace[0].output;
      REQUEST_BACKUP_ID = payload.trace[0].output.headers.request_backup_id;
      REQUEST_CREATED_AT = payload.trace[0].output.headers.request_created_at;
    }
    if (event.headers.throw) {
      return await storeRequestReturnPayload(
        payload,
        { id: REQUEST_BACKUP_ID, logs: payload, success: false },
        supabase,
      );
    }
    //Shape
    let shaped_data;
    payload = await scMonad.bindMonad(scMonad.unit(payload), shapeData);
    logger.dev.log("payload respone trace", payload.response.body.trace);
    if (payload.response.statusCode != 200) {
      return await storeRequestReturnPayload(
        payload,
        { id: REQUEST_BACKUP_ID, logs: payload, success: false },
        supabase,
      );
    } else {
      shaped_data = structuredClone(payload.trace[0].output);
      payload.input = {
        payload: event,
        created_at: REQUEST_CREATED_AT,
        request_id: REQUEST_BACKUP_ID,
        body: event["body"],
        shaped_data,
      };
    }
    logger.log("shaped_data", shaped_data);

    //Append to Sheet
    payload = await scMonad.bindMonad(
      scMonad.unit(payload),
      appendToSheet,
      supabase,
    );
    logger.dev.log("payload respone trace", payload.response.body.trace);
    if (payload.response.statusCode != 200) {
      await storeRequestReturnPayload(
        payload,
        { id: REQUEST_BACKUP_ID, logs: payload, success: false },
        supabase,
      );
    }
    payload.input = shaped_data;

    //Upsert
    let upserted_data;
    payload = await scMonad.bindMonad(
      scMonad.unit(payload),
      upsertData,
      supabase,
    );
    logger.dev.log("payload respone trace", payload.response.body.trace);
    if (payload.response.statusCode != 200) {
      return await storeRequestReturnPayload(
        payload,
        { id: REQUEST_BACKUP_ID, logs: payload, success: false },
        supabase,
      );
    } else {
      upserted_data = structuredClone(payload.trace[0].output);
      payload.input = { id: REQUEST_BACKUP_ID, contact_id: upserted_data.id };
    }

    payload = await scMonad.bindMonad(
      scMonad.unit(payload),
      ingest.storeRequest,
      supabase,
    );
    if (payload.response.statusCode != 200) {
      return await storeRequestReturnPayload(
        payload,
        { id: REQUEST_BACKUP_ID, logs: payload, success: false },
        supabase,
      );
    } else {
      payload.input = upserted_data;
    }

    //send team welcome
    try {
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
          return await storeRequestReturnPayload(
            welcomeResponse,
            { id: REQUEST_BACKUP_ID, logs: welcomeResponse, success: false },
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
    if (event_body._meta.submission_source == "organic"){payload.input.groups=['178500154540689118'];}
    if (payload.input.comms_consent) {
      payload = await scMonad.bindMonad(scMonad.unit(payload), mail);
      if (payload.response.statusCode != 200) {
        return await storeRequestReturnPayload(
          payload,
          { id: REQUEST_BACKUP_ID, logs: payload, success: false },
          supabase,
        );
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
          payload = await scMonad.bindMonad(
            scMonad.unit(payload),
            sbPatch,
            supabase,
          );
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

    //Response
    logger.log("total time duration", performance.now() - start);
    logger.dev.log(
      "index.js response",
      JSON.stringify(payload.response, null, 2),
    );
    return await storeRequestReturnPayload(
      payload,
      { id: REQUEST_BACKUP_ID, logs: payload, success: true },
      supabase,
    );
  } catch (error) {
    logger.log(error);
    console.error(error);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: error, payload: payload }),
    };
  }
};
