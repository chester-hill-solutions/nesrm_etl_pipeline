import { createClient } from "@supabase/supabase-js";
import "dotenv/config";

export default {
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
      return {
        statusCode: 400,
        body: {
          error: "Missing headers",
          ...response.body,
        },
      };
    }
    if (!headers["origin"] || !headers["x-forwarded-for"]) {
      return {
        statusCode: 400,
        body: {
          error: `Event missing headers: {${
            !headers["origin"] ? " origin" : ""
          } ${!headers["x-forwarded-for"] ? " x-forwarded-for" : ""} }`,
          ...response.body,
        },
      };
    }
    if (
      !process.env.ORIGIN_WHITELIST.split(",").some((item) =>
        headers.origin.includes(item)
      )
    ) {
      return {
        statusCode: 401,
        body: {
          error: `Unauthorized`,
          ...response.body,
        },
      };
    }
    return {
      statusCode: 200,
      body: { ...response.body },
    };
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
      return {
        statusCode: 400,
        body: {
          error: requestStorageError,
          ...response.body,
        },
      };
    }
    return {
      statusCode: 200,
      body: response.body,
    };
  },
};
