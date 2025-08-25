import { createClient } from "@supabase/supabase-js";
import "dotenv/config";
import path from "path";

const ingest = {
  headerCheck: (headers) => {
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
      throw new Error("Missing headers", { statusCode: 400 });
    }
    if (!headers["origin"] || !headers["x-forwarded-for"]) {
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
        headers.origin.includes(item)
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
    return undefined;
  },
  storeEvent: async (event) => {
    let response = {
      body: {
        trace: [
          {
            step: "ingest",
            task: "storeEvent",
          },
        ],
      },
    };
    //connect to supabase client
    const supabase = createClient(process.env.DATABASE_URL, process.env.KEY);

    //store request in supabase
    const { data, requestStorageError } = await supabase
      .from("request")
      .insert({
        event: event,
        origin: event.headers["origin"],
        ip: event.headers["x-forwarded-for"],
      });

    if (requestStorageError) {
      console.log("storage error", requestStorageError);
      response.body.trace[0].data = data;
      throw new Error("Supabase Error", {
        statusCode: 400,
        cause: requestStorageError,
      });
    }
    return undefined;
  },
};

const moduleName = path.basename(import.meta.url);
for (const [key, value] of Object.entries(ingest)) {
  if (typeof value === "function") {
    value.__module = moduleName;
  }
}

export default ingest;
