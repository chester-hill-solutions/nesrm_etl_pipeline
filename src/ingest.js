import { createClient } from "@supabase/supabase-js";
import "dotenv/config";
import path from "path";
import HttpError from "simple-http-error";
import logger from "simple-logs-sai-node";

const ingest = {
  headerCheck: (event) => {
    let headers = event.headers;
    let response = {
      body: {
        trace: [
          {
            step: "ingest",
            task: "headerCheck",
          },
        ],
      },
    };
    if (!headers) {
      throw new HttpError("Missing headers", 400);
    }
    if (!headers["Origin"] || !headers["X-Forwarded-For"]) {
      throw new HttpError(
        `Event missing headers: {${!headers["origin"] ? " origin" : ""} ${
          !headers["x-forwarded-for"] ? " x-forwarded-for" : ""
        } }`,
        400
      ); /*
      throw new Error(
        `Event missing headers: {${!headers["origin"] ? " origin" : ""} ${
          !headers["x-forwarded-for"] ? " x-forwarded-for" : ""
        } }`,
        { statusCode: 400 }
      ); /*
      return {
        statusCode: 400,
        body: {
          error: `Event missing headers: {${
            !headers["origin"] ? " origin" : ""
          } ${!headers["x-forwarded-for"] ? " x-forwarded-for" : ""} }`,
          ...response.body,
        },
      };*/
    }
    if (
      !process.env.ORIGIN_WHITELIST.split(",").some((item) =>
        headers.Origin.includes(item)
      )
    ) {
      throw new Error("Unauthorized", { statusCode: 401 });
      /*return {
        statusCode: 401,
        body: {
          error: `Unauthorized`,
          ...response.body,
        },
      };*/
    }
    return event;
  },
  storeEvent: async (event) => {
    //connect to supabase client
    const supabase = createClient(process.env.DATABASE_URL, process.env.KEY);

    //store request in supabase
    const { data, requestStorageError } = await supabase
      .from("request")
      .insert({
        payload: event,
        origin: event.headers["origin"],
        ip: event.headers["x-forwarded-for"],
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
    ret.headers.request_backup_id = data[0].id;
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
