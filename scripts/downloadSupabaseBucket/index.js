import fs from "node:fs";
import path from "node:path";
import os from "node:os";
import { createClient } from "@supabase/supabase-js";

/**
 * Download a file from a Supabase Storage bucket and write it to disk.
 *
 * @param {object} deps
 * @param {import('@supabase/supabase-js').SupabaseClient} deps.supabase
 * @param {string} deps.bucket
 * @param {string} deps.filename
 * @param {string} [deps.outDir]
 * @param {NodeJS.ProcessEnv} [deps.env]
 *
 * @returns {Promise<string>} absolute path to downloaded file
 */
export async function downloadFromSupabaseBucket({
  supabase//=createClient(process.env.DATABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY)
  ,env = process.env,
  bucket=env.SB_BUCKET,
  filename=env.GOOGLE_SERVICE_ACCOUNT_KEY_FILE_NAME_SB_BUCKET,
  outDir = os.tmpdir(),
}) {
  console.log("downloadFromSupabaseBucket typeof supabase", typeof supabase)
  if (!supabase) {
    throw new Error("Missing required dependency: supabase client");
  }
  if (!bucket) {
    throw new Error("Missing required parameter: bucket");
  }
  if (!filename) {
    throw new Error("Missing required parameter: filename");
  }

  const outPath = path.join(outDir, filename);

  // Idempotent: reuse if already downloaded
  if (fs.existsSync(outPath)) {
    env.GOOGLE_SERVICE_ACCOUNT_KEY_FILE = outPath;
    return outPath;
  }

  const { data, error } = await supabase
    .storage
    .from(bucket)
    .download(filename);

  if (error) {
    throw new Error(
      `Failed to download ${filename} from bucket ${bucket}: ${error}`
    );
  }

  const buffer = Buffer.from(await data.arrayBuffer());
  fs.writeFileSync(outPath, buffer, { mode: 0o600 });

  // Optional convenience: set env var if this is a Google key
  env.GOOGLE_SERVICE_ACCOUNT_KEY_FILE = outPath;

  return outPath;
}

