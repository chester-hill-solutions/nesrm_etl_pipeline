
import dotenv from "dotenv";
import path from "node:path";
import { fileURLToPath } from "node:url";

import {
    createGoogleAuth,
    createSheetsClient,
    appendRow,
    objectToAppendRow, // uncomment if you want header-based mapping
} from "../scripts/sheetsAppend/index.js";
import logger from "simple-logs-sai-node";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Load .env from project root (2 levels up from scripts/sheetsAppend)
dotenv.config({ path: path.resolve(__dirname, "../../.env") });

// Optional: make key file path work even if .env uses a relative path
function resolveFromProjectRoot(p) {
    if (!p) return p;
    return path.isAbsolute(p) ? p : path.resolve(__dirname, "../", p);
}

function safeStringify(v) {
  if (v === undefined) return "";
  if (v === null) return "";
  if (typeof v === "string") return v;
  if (typeof v === "number" || typeof v === "boolean") return v;
  try {
    return JSON.stringify(v);
  } catch {
    return String(v);
  }
}

/**
 * Build a flat object that:
 *  - includes each top-level key it receives (payload, created_at, request_id, body, shaped_data, etc.)
 *  - ALSO includes each key inside shaped_data at the top level (so Sheets headers can match them)
 *
 * Note: if shaped_data has keys that collide with top-level keys, shaped_data wins by default below.
 * Flip spread order if you want the opposite.
 */
function buildRowObject(input = {}) {
  const { shaped_data = {}, ...topLevel } = input;

  const hasShapedBodyObject =
    shaped_data &&
    typeof shaped_data === "object" &&
    shaped_data.body &&
    typeof shaped_data.body === "object" &&
    shaped_data.body !== null;

  // Expand ONLY one of these:
  const expanded = hasShapedBodyObject
    ? shaped_data.body
    : (shaped_data && typeof shaped_data === "object" ? shaped_data : {});

  return {
    // Keep every top-level key you received (payload, created_at, request_id, body, etc.)
    ...topLevel,

    // Keep the blob too (optional but usually useful for debugging / audits)
    shaped_data,

    // Mutually exclusive expansion
    ...expanded,
  };
}

export default async function appendToSheet({
  payload,
  created_at,
  request_id,
  body,
  shaped_data,
  ...rest
} = {}) {
  // Ensure keyfile path is absolute (so GoogleAuth can always find it)
  if (process.env.GOOGLE_SERVICE_ACCOUNT_KEY_FILE) {
    process.env.GOOGLE_SERVICE_ACCOUNT_KEY_FILE = resolveFromProjectRoot(
      process.env.GOOGLE_SERVICE_ACCOUNT_KEY_FILE
    );
  }

  const auth = createGoogleAuth();
  const sheets = createSheetsClient({ auth });

  // Default created_at if not provided
  const createdAt = created_at ?? new Date().toISOString();

  // Build the object we want to map to the sheet headers
  const rowObj = buildRowObject({
    payload,
    created_at: createdAt,
    request_id,
    body,
    shaped_data,
  });
    logger.dev.log("rowObj",rowObj);

  // If your sheet stores payload/body/shaped_data as text columns, stringify them
  // (Keeps normal scalar fields as-is)
  const { rowValues } = await objectToAppendRow({
    sheets,
    spreadsheetId: process.env.SPREADSHEET_ID,
    sheetName: (process.env.SHEET_RANGE || "Sheet1!A:Z").split("!")[0] || "Sheet1",
    obj: rowObj,
    // Make header matching forgiving if you want (optional):
    // normalizeHeader: (h) => String(h ?? "").trim().toLowerCase(),
    transformValue: (v, header) => {
      // Common pattern: stringify nested objects for Sheets
      if (header === "payload" || header === "body" || header === "shaped_data") {
        return safeStringify(v);
      }
      return safeStringify(v);
    },
    missingValue: "",
  });

  const res = await appendRow({ sheets, rowValues });
  return res;
}

appendToSheet.__module = path.basename(import.meta.url);
export { appendToSheet };
