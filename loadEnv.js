// loadEnv.js
import fs from "fs";
import dotenv from "dotenv";

const envFile = ".env"+process.env.ENVIRONMENT;

if (fs.existsSync(envFile)) {
  dotenv.config({ path: envFile });
  console.log(`✅ Loaded ${envFile}`);
} else {
  console.warn(`⚠️ ${envFile} not found, using process defaults`);
}
