// scripts/sheetsAppend/runner.js
import dotenv from "dotenv";
import path from "node:path";
import { fileURLToPath } from "node:url";

import {
    createGoogleAuth,
    createSheetsClient,
    appendRow,
    objectToAppendRow, // uncomment if you want header-based mapping
} from "./index.js";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Load .env from project root (2 levels up from scripts/sheetsAppend)
dotenv.config({ path: path.resolve(__dirname, "../../.env") });

// Optional: make key file path work even if .env uses a relative path
function resolveFromProjectRoot(p) {
    if (!p) return p;
    return path.isAbsolute(p) ? p : path.resolve(__dirname, "../../", p);
}

async function main() {
    // Ensure the key file path is absolute for GoogleAuth
    if (process.env.GOOGLE_SERVICE_ACCOUNT_KEY_FILE) {
        process.env.GOOGLE_SERVICE_ACCOUNT_KEY_FILE = resolveFromProjectRoot(
            process.env.GOOGLE_SERVICE_ACCOUNT_KEY_FILE,
        );
    }

    const auth = createGoogleAuth(); // uses process.env (now loaded)
    const sheets = createSheetsClient({ auth });

    // Simple manual row
    /*const rowValues = [
      new Date().toISOString(),
      "Ada Lovelace",
      "ada@example.com",
      "lead, website",
    ];
  
    const res = await appendRow({ sheets, rowValues });
    console.log("Appended:", res.updates?.updatedRange);
  */
    // --- If you want object -> header mapping instead ---
    const { headers, rowValues } = await objectToAppendRow({
        sheets,
        spreadsheetId: process.env.SPREADSHEET_ID,
        sheetName: "Sheet1",
        obj: {
            "Created At": new Date().toISOString(),
            surname: "Lovelace",
            firstname: "Ada",
            Email: "ada@example.com",
            Tags: "lead, website",
        },
    });
    const res2 = await appendRow({ sheets, rowValues });
    console.log("Headers:", headers);
    console.log("Appended:", res2.updates?.updatedRange);
}

main().catch((err) => {
    console.error(err);
    process.exit(1);
});
