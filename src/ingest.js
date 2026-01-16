import { createClient } from "@supabase/supabase-js";
//import "dotenv/config";
import path from "path";
import HttpError from "simple-http-error";
import logger from "simple-logs-sai-node";

async function storeRequest(
  storeData,
  supabase = createClient(process.env.DATABASE_URL, process.env.KEY),
) {
  const { data, error: sbError } = await supabase
    .from("request")
    .upsert(storeData).select();
  if (sbError) {
    logger.log("sbError:", sbError);
    throw new HttpError(sbError, 500, { originalError: sbError });
  }
  return data;
}

const ingest = {
  headerCheck: (event) => {
    if (!event.headers) {
      throw new HttpError("Missing headers", 400);
    }
    let rawHeaders = event.headers;
    const headers = Object.fromEntries(
      Object.entries(rawHeaders).map(([k, v]) => [k.toLowerCase(), v]),
    );
    if (!headers["origin"] || !headers["x-forwarded-for"]) {
      throw new HttpError(
        `Event missing headers: {${!headers["origin"] ? " Origin" : ""} ${
          !headers["x-forwarded-for"] ? " x-forwarded-for" : ""
        } }`,
        400,
      );
    }
    if (
      !process.env.ORIGIN_WHITELIST.split(",").some((item) =>
        headers.origin.includes(item),
      )
    ) {
      throw new HttpError("Unauthorized", 401);
    }
    return event;
  },
  storeEvent: async (event) => {
    //connect to supabase client
    const supabase = createClient(process.env.DATABASE_URL, process.env.KEY);

    //store request in supabase
    const headers = Object.fromEntries(
      Object.entries(event.headers).map(([k, v]) => [k.toLowerCase(), v]),
    );
    const body = (() => {
      try {
        return JSON.parse(event?.body);
      } catch {
        return event?.body;
      }
    })();
    const storeData = {
      payload: typeof event === "string" ? JSON.parse(event) : event,
      origin: headers?.origin,
      ip: headers?.["x-forwarded-for"],
      email: body?.email,
      step: body?._meta?.step?.index,
    };
    let data = await storeRequest(storeData, supabase);

    let ret = structuredClone(event);
    if (data) {
      ret.headers.request_backup_id = data[0].id;
      ret.headers.request_created_at = data[0].created_at;      
    } else {
      logger.log("data", data);
      throw new HttpError("Failed to store request");
    }
    return ret;

    const { data: sbData, requestStorageError } = await supabase
      .from("request")
      .insert(storeData)
      .select();

    if (requestStorageError) {
      console.log("storage error", requestStorageError);
      //response.body.trace[0].data = data;
      throw new HttpError("Supabase Error", 400, {
        originalError: requestStorageError,
      });
    }
    //logger.log("sb data", data);
    //let ret = structuredClone(event);
    if (data) {
      ret.headers.request_backup_id = data[0].id;
    } else {
      logger.log("data", data);
      throw new HttpError("Failed to store request");
    }
    return ret;
  },
  storeRequest,
};

const moduleName = path.basename(import.meta.url);
for (const [key, value] of Object.entries(ingest)) {
  if (typeof value === "function") {
    value.__module = moduleName;
  }
}

export default ingest;
