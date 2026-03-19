import { createClient } from "@supabase/supabase-js";
//import "dotenv/config";
import path from "path";
import HttpError from "simple-http-error";
import logger from "simple-logs-sai-node";
import { parseQueryParams } from "../scripts/parseQueryParams/index.js";

const toTextArray = (val) => {
  if (val == null) return null;

  if (Array.isArray(val)) {
    return val.map(String);
  }

  if (typeof val === "string") {
    return [val];
  }

  return [String(val)];
};

async function storeRequest({ input, supabase = null }) {
  logger.log("storeRequest()");
  let storeData = input;
  supabase =
    supabase ?? createClient(process.env.DATABASE_URL, process.env.KEY);
  console.log('storeData:', JSON.stringify(storeData, null, 2))
  const { data, error: sbError } = await supabase
    .from("request")
    .upsert(storeData)
    .select();
  if (sbError) {
    logger.log("sbError:", sbError);
    logger.log("storeRequest output", data);
    throw new HttpError(sbError, 500, { originalError: sbError });
  }
  logger.log("storeRequest output", data);
  return data;
}
async function parseEvent(input) {
  const event = input
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
  let storeData = {
    payload: typeof event === "string" ? JSON.parse(event) : event,
    origin: headers?.origin,
    ip: headers?.["x-forwarded-for"],
    email: body?.email,
    step: body?._meta?.step?.index,
  };
  storeData.referer = body?._meta?.referer ?? headers?.referer ?? undefined;
  if (storeData.referer) {
    let searchParams;
    try {
      searchParams = parseQueryParams(storeData.referer, { coerce: true });
      let urlParams = {
        search_params: searchParams,
        utm_source: searchParams.utm_source,
        utm_medium: searchParams.utm_medium,
        utm_campaign: searchParams.utm_campaign,
        utm_term: toTextArray(searchParams.utm_term),
        utm_content: searchParams.utm_content,
      };
      storeData = { ...storeData, ...urlParams };
      logger.log("storeData w urlParams", JSON.stringify(storeData, null, 2));
    } catch (error) {
      logger.log(error);
    }
    logger.log(
      "typeof search params",
      typeof searchParams,
      "searchParams",
      searchParams,
    );
  }
  return storeData
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
        `Event missing headers: {${!headers["origin"] ? " Origin" : ""} ${!headers["x-forwarded-for"] ? " x-forwarded-for" : ""
        } }`,
        400,
      );
    }
    if (
      !process.env.ORIGIN_WHITELIST.split(",").some((item) =>
        (headers.origin).includes(item),
      )
    ) {
      throw new HttpError("Unauthorized", 401);
    }
    return event;
  },
  storeEvent: async ({ input, supabase }) => {
    //connect to supabase client
    supabase =
      supabase ?? createClient(process.env.DATABASE_URL, process.env.KEY);
    let data;
    try {
      data = await storeRequest({ input: input, supabase });
    } catch (e) {
      logger.log(e);
      throw new HttpError("error on storeRequest within storeEvent", 500, {
        orginalError: e,
      });
    }
    let ret = structuredClone(input);
    if (data) {
      return data
      ret.request_backup_id = data[0].id;
      ret.request_created_at = data[0].created_at;
    } else {
      logger.log("data", data);
      throw new HttpError("Failed to store request");
    }
    return ret;
  },
  storeRequest,
  parseEvent,
};

const moduleName = path.basename(import.meta.url);
for (const [key, value] of Object.entries(ingest)) {
  if (typeof value === "function") {
    value.__module = moduleName;
  }
}

export default ingest;
