// scripts/sheetsAppend/index.js
import path from "node:path";
import { auth, sheets } from "@googleapis/sheets";
import HttpError from "simple-http-error";
import logger from "simple-logs-sai-node";

/**
 * 1) Create GoogleAuth (service account key file)
 */
export function createGoogleAuth({
  env = process.env,
  keyFile = env.GOOGLE_SERVICE_ACCOUNT_KEY_FILE,
  credentials_env_str = env.GOOGLE_SERVICE_ACCOUNT_KEY_JSON,
  scopes = ["https://www.googleapis.com/auth/spreadsheets"],
  resolvePath = path.resolve,
  googleApi = {auth,sheets},
} = {}) {

  return new googleApi.auth.GoogleAuth({
    keyFile: resolvePath(keyFile),
    scopes,
  });
}

/**
 * 2) Create Sheets client
 */
export function createSheetsClient({ auth, googleApi = {auth,sheets} } = {}) {
  if (!auth) throw new Error("auth is required");
  return googleApi.sheets({ version: "v4", auth });
}

/**
 * 3) Append a row
 */
export async function appendRow({
  sheets,
  env = process.env,
  spreadsheetId = env.SPREADSHEET_ID,
  range = env.SHEET_RANGE || "Sheet1!A:Z",
  rowValues,
  valueInputOption = "USER_ENTERED",
} = {}) {
  if (!sheets) throw new Error("sheets is required");
  if (!spreadsheetId) throw new Error("Missing SPREADSHEET_ID");
  if (!Array.isArray(rowValues)) throw new Error("rowValues must be an array");

  const res = await sheets.spreadsheets.values.append({
    spreadsheetId,
    range,
    valueInputOption,
    insertDataOption: "INSERT_ROWS",
    requestBody: { values: [rowValues] },
  });

  return res.data;
}

/**
 * Optional helper: map an object to a row based on header order in row 1
 */
export async function objectToAppendRow({
  sheets,
  spreadsheetId,
  sheetName = "Sheet1",
  obj,
  normalizeHeader = (s) => String(s ?? "").trim(),
  transformValue = (v) => v,
  missingValue = "",
} = {}) {
  if (!sheets) throw new Error("sheets is required");
  if (!spreadsheetId) throw new Error("spreadsheetId is required");
  if (!obj || typeof obj !== "object") throw new Error("obj must be an object");

  const headerRange = `${sheetName}!1:1`;
  console.log("objectToAppendRow");
  const res = await sheets.spreadsheets.values.get({
    spreadsheetId,
    range: headerRange,
    majorDimension: "ROWS",
  });
  logger.dev.log("objectToAppendRow res", res);

  const headersRaw = (res.data.values?.[0] ?? []).filter(
    (h) => h !== null && h !== undefined && String(h).trim() !== ""
  );

  if (headersRaw.length === 0) {
    throw new Error(`No headers found in ${sheetName} row 1`);
  }

  const headers = headersRaw.map((h) => String(h));
  const normalized = headers.map(normalizeHeader);

  // Build a case-insensitive lookup of object keys
  const normalizedObj = Object.entries(obj).reduce((map, [key, value]) => {
    map[normalizeHeader(key).toLowerCase()] = value;
    return map;
  }, {});

  const rowValues = normalized.map((hdrNorm, i) => {
    const originalHeader = headers[i];
    const keyNorm = hdrNorm.toLowerCase();
    const val = Object.prototype.hasOwnProperty.call(normalizedObj, keyNorm)
      ? normalizedObj[keyNorm]
      : missingValue;

    return transformValue(val, originalHeader);
  });
  logger.log("objectToAppendRow headers", headers);
  logger.log("objectToAppendRow rowValues", rowValues);
  return { headers, rowValues };
}

