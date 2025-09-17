import { createClient } from "@supabase/supabase-js";
import HttpError from "simple-http-error";

async function sbPatch(table, id, field, value) {
  try {
    const supabase = await createClient(
      process.env.DATABASE_URL,
      process.env.KEY
    );
    const u = {};
    u[field] = value;
    const { error: sbError } = await supabase
      .from(table)
      .update(u)
      .eq("id", id);
    if (sbError) {
      logger.error(sbError);
      throw new HttpError(sbError.message, 500, { originalCause: error });
    }
  } catch (error) {
    console.error(error);
  }
}

export { sbPatch };
