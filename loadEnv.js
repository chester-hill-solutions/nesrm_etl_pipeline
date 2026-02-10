// loadEnv.js
import fs from "fs";
import dotenv from "dotenv";

const envFiles = [".env." + process.env.ENVIRONMENT, ".env", ".env.local"];
for (let index = 0; index < envFiles.length; index++) {
  if (fs.existsSync(envFiles[index])) {
    dotenv.config({ path: envFiles[index] });
    console.log(`✅ Loaded ${envFiles[index]}`);
    break;
  } else {
    console.warn(`⚠️ ${envFiles[index]} not found`);
  }
}
