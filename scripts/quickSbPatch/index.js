import { createClient } from "@supabase/supabase-js";
import HttpError from "simple-http-error";
import logger from "simple-logs-sai-node";

async function sbPatch({input={}, supabase=null }) {
  let {table, id, field, value} = input;
  logger.dev.log("sbPatch", table, id, field, value);
  supabase = supabase ?? createClient(
    process.env.DATABASE_URL,
    process.env.KEY
  );
  const u = {};
  u[field] = value;
  const { error: sbError } = await supabase.from(table).update(u).eq("id", id);
  if (sbError) {
    console.log("sbError");
    logger.error(sbError);
    throw new HttpError(sbError.message, 500, { originalError: sbError });
  }
}

export { sbPatch };
