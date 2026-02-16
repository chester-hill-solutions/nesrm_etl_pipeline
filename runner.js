import { handler } from "./index.js";
import path from "path";
import fs from "fs/promises";
import { csvToJson, attachHeader } from "./scripts/shapeData/index.js";
import logger from "simple-logs-sai-node";
import { performance } from "perf_hooks";

const HEADERS = {
  Origin: "www.meetsai.ca",
  "X-Forwarded-For": "124.0.0.1",
  Authorization: "Bearer " + process.env.AWS_API_GATEWAY_BEARER,
};
const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

function parseMaybeJson(value) {
  if (typeof value !== "string") return value;
  try {
    return JSON.parse(value);
  } catch {
    return value;
  }
}

function normalizePayload(input, headersDefault) {
  let headers;
  let body;

  const parseHeaders = (h) => {
    const parsed = parseMaybeJson(h);
    return parsed && typeof parsed === "object" && !Array.isArray(parsed)
      ? parsed
      : undefined;
  };
  const parseBody = (b) => {
    const parsed = parseMaybeJson(b);
    return parsed ?? b;
  };

  if (input && typeof input === "object" && !Array.isArray(input)) {
    if ("payload" in input) {
      const parsedPayload = parseMaybeJson(input.payload);
      if (parsedPayload && typeof parsedPayload === "object" && !Array.isArray(parsedPayload)) {
        headers = parseHeaders(parsedPayload.headers);
        if (parsedPayload.body !== undefined) {
          body = parseBody(parsedPayload.body);
        } else {
          body = parsedPayload;
        }
      } else {
        body = parseBody(parsedPayload);
      }
    } else if ("body" in input) {
      body = parseBody(input.body);
      headers = parseHeaders(input.headers);
    } else {
      body = input;
    }
  } else {
    body = parseBody(input);
  }

  if (body === undefined || body === null) {
    body = {};
  }

  return {
    headers: headers ?? headersDefault,
    body,
  };
}

function applySubmissionSource(body, force) {
  if (!force) return false;
  if (!body || typeof body !== "object") return false;
  if (!body._meta || typeof body._meta !== "object") {
    body._meta = {};
  }
  body._meta.submission_source = "cli-runner";
  return true;
}

function unwrapBody(body) {
  if (!body || typeof body !== "object") return { body, changed: false, detail: null };
  let changed = false;
  let detail = null;

  const maybeParse = (val) => {
    if (typeof val === "string") {
      try {
        return JSON.parse(val);
      } catch {
        return val;
      }
    }
    return val;
  };

  if (body.body) {
    const inner = maybeParse(body.body);
    if (inner && typeof inner === "object") {
      body = { ...body, ...inner };
      delete body.body;
      changed = true;
      detail = "body.body";
    }
  } else if (body.value || body.values) {
    const innerVal = maybeParse(body.value ?? body.values);
    if (innerVal && typeof innerVal === "object") {
      body = { ...body, ...innerVal };
      delete body.value;
      delete body.values;
      changed = true;
      detail = body.value ? "body.value" : "body.values";
    }
  }

  return { body, changed, detail };
}
async function runner(payload) {
  if (process.env.PIPELINE == "gateway") {
    console.log("gateway");
    try {
      const response = await fetch(process.env.AWS_API_GATEWAY_ENDPOINT, {
        method: "POST",
        headers: payload.headers,
        body: JSON.stringify(payload.body),
      });
      const data = await response.json();
      console.log(
        "response",
        response.status,
        response.status < 300 ? "" : JSON.stringify(data, null, 2)
      );
      return response;
    } catch (error) {
      console.log(error);
      console.log(JSON.stringify(payload));
    }
  } else if (process.env.PIPELINE == "local") {
    console.log("local");
    return await handler(payload);
  }
}
const JSON_FILE = "failedUploads.json";

async function logEvent(data, response) {
  // Only log successful responses
  if (!response.statusCode || response.statusCode <= 300) return;
  logger.log(response.statusCode);
  logger.log("logEvent", data, response);
  const dataToWrite = {
    ...data,
    statusCode: response.statusCode,
    response_object: JSON.stringify(response),
  };
  logger.log(dataToWrite);
  // Include request_backup_id if it exists
  if (response.body?.request_backup_id) {
    dataToWrite.request_backup_id = response.body.request_backup_id;
  }

  let existingData = [];

  // Read existing JSON array if file exists
  try {
    const fileContent = await fs.readFile(JSON_FILE, "utf-8");
    existingData = JSON.parse(fileContent);
    if (!Array.isArray(existingData)) existingData = [];
  } catch {
    // File does not exist or is invalid → start with empty array
    existingData = [];
  }

  // Append new entry
  existingData.push(dataToWrite);

  // Write back to file
  await fs.writeFile(JSON_FILE, JSON.stringify(existingData, null, 2), "utf-8");
}
async function runOverArray(dataArray, callback, options) {
  const { forceSubmissionSource, unwrapBodies, dryRun } = options;
  if (process.env.SLOW === "true") {
    console.log("Estimated execution time: ", 2 * dataArray.length);
  }
  for (const dataIndex in dataArray) {
    if (Array.isArray(dataArray[dataIndex])) {
      console.log("File", dataIndex);
      await runOverArray(dataArray[dataIndex], callback, options);
    } else {
      const normalized = normalizePayload(dataArray[dataIndex], HEADERS);
      if (unwrapBodies) {
        const { body, changed, detail } = unwrapBody(normalized.body);
        normalized.body = body;
        if (changed) {
          console.log(`unwrapped nested ${detail} for payload`, dataIndex);
        }
      }
      if (applySubmissionSource(normalized.body, forceSubmissionSource)) {
        console.log("submission_source set to cli-runner for payload", dataIndex);
      }
      const event = normalized.headers ? normalized : attachHeader(normalized, HEADERS);
      console.log(
        "\nPayload",
        dataIndex,
        event.body?.email || event.body?.phone || event.body?.firstname
      );
      if (dryRun) {
        console.log("[dry-run] would send:", JSON.stringify(event, null, 2));
      } else {
        try {
          const response = await callback(event);
          console.log(
            "response",
            response.statusCode,
            response.statusCode < 300
              ? ""
              : JSON.stringify(dataArray[dataIndex], null, 2)
          );
          await logEvent(event, response);
        } catch (error) {
          console.error(error);
          await logEvent(event, {
            statusCode: 500,
            body: "{message: failure on runner.js side}",
          });
        }
      }

      if (process.env.SLOW === "true") {
        console.log("waiting...");
        await sleep(1500);
        console.log("...starting");
      }
    }
  }
}
async function parseDir(pathLike) {
  try {
    const stats = await fs.stat(pathLike);

    if (stats.isFile()) {
      const ext = path.extname(pathLike).toLowerCase();
      if (ext === ".csv") return await csvToJson(pathLike);
      if (ext === ".json") {
        const content = await fs.readFile(pathLike, "utf8");
        return [JSON.parse(content)];
      }
      return [];
    }

    // if it's a directory
    const files = await fs.readdir(pathLike);
    let allData = [];
    for (const file of files) {
      const filePath = path.join(pathLike, file);
      const fileData = await parseDir(filePath); // recursive
      allData.push(...fileData);
    }
    return allData;
  } catch (err) {
    console.error("Error:", err);
    return [];
  }
}

async function main() {
  const start = performance.now();
  if (!process.env.PIPELINE) {
    process.env.PIPELINE = "local";
  }
  const argv = process.argv.slice(2);
  let forceSubmissionSource = true;
  let unwrapBodies = false;
  let dryRun = false;
  const inputPaths = [];

  for (const arg of argv) {
    if (arg.startsWith("--")) {
      const flag = arg.slice(2);
      switch (flag) {
        case "local":
          process.env.PIPELINE = "local";
          break;
        case "gateway":
          process.env.PIPELINE = "gateway";
          break;
        case "slow":
          process.env.SLOW = "true";
          break;
        case "keep-source_submission":
          forceSubmissionSource = false;
          break;
        case "unwrap-body":
          unwrapBodies = true;
          break;
        case "dry-run":
          dryRun = true;
          break;
        default:
          break;
      }
    } else if (arg.startsWith("-")) {
      const flags = arg.slice(1);
      for (const flag of flags) {
        switch (flag) {
          case "l":
            process.env.PIPELINE = "local";
            break;
          case "g":
            process.env.PIPELINE = "gateway";
            break;
          case "s":
            process.env.SLOW = "true";
            break;
          case "k":
            forceSubmissionSource = false;
            break;
          case "u":
            unwrapBodies = true;
            break;
          case "d":
            dryRun = true;
            break;
          default:
            break;
        }
      }
    } else {
      inputPaths.push(arg);
    }
  }

  if (forceSubmissionSource) {
    console.log(
      'submission_source override is ON (cli-runner). Use --keep-source_submission / -k to keep existing values.'
    );
  } else {
    console.log(
      'submission_source override is OFF (flag --keep-source_submission / -k). Existing values will be preserved.'
    );
  }

  if (unwrapBodies) {
    console.log('unwrap-body is ON (--unwrap-body / -u). Nested body/body.value/body.values will be merged.');
  } else {
    console.log('unwrap-body is OFF by default. Use --unwrap-body / -u to enable nested body fixes.');
  }

  if (dryRun) {
    console.log('dry-run is ON (--dry-run / -d). Payloads will be logged but not sent.');
  }

  for (const pathArg of inputPaths) {
    const dataArray = await parseDir(pathArg);
    await runOverArray(dataArray, runner, { forceSubmissionSource, unwrapBodies, dryRun });
  }
  console.log("duration", performance.now() - start);
}

main();
