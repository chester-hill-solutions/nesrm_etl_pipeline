// loadEnv.js
import fs from "fs";
import dotenv from "dotenv";

const envFile = process.env.ENVIRONMENT ? ".env"+"."+process.env.ENVIRONMENT : ".env" ?? ".env.local" ;

if (fs.existsSync(envFile)) {
  dotenv.config({ path: envFile });
  console.log(`✅ Loaded ${envFile}`);
} else {
  console.warn(`⚠️ ${envFile} not found, using process defaults`);
}
