import { createClient } from "@supabase/supabase-js";
//import "dotenv/config";
import path from "path";
import HttpError from "simple-http-error";
import logger from "simple-logs-sai-node";

const ingest = {
  headerCheck: (event) => {
    if (!event.headers) {
      throw new HttpError("Missing headers", 400);
    }
    let rawHeaders = event.headers;
    const headers = Object.fromEntries(
      Object.entries(rawHeaders).map(([k, v]) => [k.toLowerCase(), v])
    );
    if (!headers["origin"] || !headers["x-forwarded-for"]) {
      throw new HttpError(
        `Event missing headers: {${!headers["origin"] ? " Origin" : ""} ${
          !headers["x-forwarded-for"] ? " x-forwarded-for" : ""
        } }`,
        400
      );
    }
    if (
      !process.env.ORIGIN_WHITELIST.split(",").some((item) =>
        headers.origin.includes(item)
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
      Object.entries(event.headers).map(([k, v]) => [k.toLowerCase(), v])
    );
    const { data, requestStorageError } = await supabase
      .from("request")
      .insert({
        payload: event.body ? event.body : event,
        origin: headers["origin"],
        ip: headers["x-forwarded-for"],
        email: event.body
          ? event.body.email
            ? event.body.email
            : undefined
          : undefined,
      })
      .select();

    if (requestStorageError) {
      console.log("storage error", requestStorageError);
      //response.body.trace[0].data = data;
      throw new HttpError("Supabase Error", 400, {
        originalError: requestStorageError,
      });
    }
    //logger.log("sb data", data);
    let ret = structuredClone(event);
    if (data) {
      ret.headers.request_backup_id = data[0].id;
    } else {
      logger.log("data", data);
      throw new HttpError("Failed to store request");
    }
    return ret;
  },
};

const moduleName = path.basename(import.meta.url);
for (const [key, value] of Object.entries(ingest)) {
  if (typeof value === "function") {
    value.__module = moduleName;
  }
}

export default ingest;
