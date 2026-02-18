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
  logger.dev.log("await storeRequestReturnPayload()", JSON.stringify({payload, storeData}, null, 2));
  const data = await ingest.storeRequest({ input: storeData, supabase });
  payload.response.body.request_backup_id = data.id;
  payload.response.body.message = payload.trace[0].output;
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
    logger.log("event typeof", typeof event);
    logger.log("event body typeof", typeof event?.body);
    logger.log("event payload", JSON.stringify(event, null, 2));
    const event_body =
      typeof event.body === "string" ? JSON.parse(event.body) : event.body;
    logger.log("event.body", JSON.stringify(event_body, null, 2));

    //header check
    payload = await scMonad.bindMonad(scMonad.unit(event), ingest.headerCheck);
    logger.dev.log("payload respone trace", payload.response.body.trace);
    let headerCheckOutput;
    if (payload.response.statusCode != 200) {
      return await storeRequestReturnPayload(
        payload,
        { payload: event, logs: payload, success: false },
        supabase,
      );
    } else {
      headerCheckOutput = payload.trace[0].output;
      payload.input = headerCheckOutput;
    }
    //parse event
    payload = await scMonad.bindMonad(scMonad.unit(payload), ingest.parseEvent);
    let parseEventOutput;
    if (payload.response.statusCode != 200) {
      return await storeRequestReturnPayload(
        payload,
        { payload: event, logs: payload, success: false },
        supabase,
      );
    } else {
      parseEventOutput = payload.trace[0].output;
      payload.input = parseEventOutput;
    }
    //store event
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
      REQUEST_BACKUP_ID = payload.trace[0].output[0].id;
      REQUEST_CREATED_AT = payload.trace[0].output[0].created_at;
      const search_params = payload.trace[0].output[0].search_params;
      payload.input = headerCheckOutput;
      headerCheckOutput.headers.request_backup_id = REQUEST_BACKUP_ID;
      headerCheckOutput.headers.request_created_at = REQUEST_CREATED_AT;
      headerCheckOutput.headers.search_params = search_params;
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
    const shape_out = payload?.trace?.[0]?.output ?? {};

    const missingAllIdentity =
      !shape_out?.body?.email &&
      !shape_out?.body?.phone &&
      !shape_out?.body?.firstname &&
      !shape_out?.body?.surname;

    if (payload.response.statusCode != 200 || missingAllIdentity || !shape_out) {
      if (payload.response.statusCode == 200 && missingAllIdentity) {
        payload.response.statusCode = 422;
        payload.response.message = "Missing all identity values after shape"
      }
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

    if (shaped_data.profile_id) {
      payload = await scMonad.bindMonad(
        scMonad.unit({
          table: "profiles",
          id: shaped_data.profile_id,
          field: "contact_id",
          value: upserted_data.id,
        }),
        sbPatch,
        supabase,
      );
    }

    //send team welcome
    try {
      if (
        event_body._status == "complete" &&
        event_body._meta.submission_source == "organic"
      ) {
        payload = await scMonad.bindMonad(
          scMonad.unit(upserted_data),
          sendTeamWelcome,
        );
        logger.log("welcomeResponse", payload.trace[0].output);
      } else {
        logger.log(
          "not sending welcomeResponse",
          event_body._status,
          event_body._meta.submission_source,
        );
      }
          payload.input = upserted_data;
      //console.log("compare", payload.trace[0].output == payload.input);
      if (event_body._meta.submission_source == "organic") {
        payload.input.groups = ["178500154540689118"];
      }
      if (payload.input.comms_consent) {
        payload = await scMonad.bindMonad(scMonad.unit(payload), mail);
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
          }
      }
    } catch (error) {
      logger.log(error);
    }
    try {
    payload.upserted_data = upserted_data;
    } catch (error){ logger.log('upserted_data', upserted_data) }

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
