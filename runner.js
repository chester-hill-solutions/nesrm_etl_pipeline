import { handler } from "./index.js";
import path from "path";
import fs from "fs/promises";
import { csvToJson, attachHeader } from "./scripts/shapeData/index.js";
import logger from "simple-logs-sai-node";
import { performance } from "perf_hooks";

const HEADERS = {
  Origin: "www.meetsai.ca",
  Referer: "www.meetsai.ca",
  "X-Forwarded-For": "124.0.0.1",
  Authorization: "Bearer " + process.env.AWS_API_GATEWAY_BEARER,
};
const LOG_DIR = process.env.LOG_DIR || "runner_logs";
const FAIL_DIR = process.env.FAIL_DIR || "failedUploads";
const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

const RUN_FAILURE_LOG_TS = new Date().toISOString().replace(/[:.]/g, "-");
let failureLogState = {
  path: null,
  entryCount: 0,
  promise: Promise.resolve(),
  initialized: false,
};

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

  const addReferer = (h) => {
    if (!h) return h;
    const origin = h.Origin || h.origin;
    if (origin && h.Referer === undefined && h.referer === undefined) {
      h.Referer = origin;
    }
    return h;
  };

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
    headers: addReferer(headers ?? headersDefault),
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

function applyCommsConsent(body, force) {
  if (!force) return false;
  if (!body || typeof body !== "object") return false;
  body.comms_consent = true;
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

let logDirReady = false;
let failDirReady = false;
async function ensureLogDir() {
  if (logDirReady) return true;
  try {
    await fs.mkdir(LOG_DIR, { recursive: true });
    logDirReady = true;
    return true;
  } catch (err) {
    console.warn(`Could not create log directory ${LOG_DIR}:`, err?.message || err);
    logDirReady = false;
    return false;
  }
}

async function ensureFailDir() {
  if (failDirReady) return true;
  try {
    await fs.mkdir(FAIL_DIR, { recursive: true });
    failDirReady = true;
    return true;
  } catch (err) {
    console.warn(`Could not create failed-upload directory ${FAIL_DIR}:`, err?.message || err);
    failDirReady = false;
    return false;
  }
}

async function ensureFailureLogStream() {
  if (failureLogState.initialized) return true;
  if (!(await ensureLogDir())) return false;
  failureLogState.path = path.join(LOG_DIR, `${RUN_FAILURE_LOG_TS}_row_failures.json`);
  try {
    await fs.writeFile(failureLogState.path, "[\n", "utf8");
    failureLogState.initialized = true;
    return true;
  } catch (err) {
    console.warn(
      `Could not initialize runner failure log ${failureLogState.path}:`,
      err?.message || err
    );
    failureLogState.initialized = false;
    return false;
  }
}

function appendFailureLogEntry(entry) {
  failureLogState.promise = failureLogState.promise
    .then(async () => {
      if (!(await ensureFailureLogStream())) return;
      const prefix = failureLogState.entryCount > 0 ? ",\n" : "";
      const entryText = JSON.stringify(entry, null, 2);
      await fs.appendFile(failureLogState.path, prefix + entryText, "utf8");
      failureLogState.entryCount += 1;
      const requestId = entry?._runner_failure?.request_backup_id;
      const requestIdStr = requestId ? ` request_backup_id=${requestId}` : "";
      console.log(
        `runner_logs failure entry ${failureLogState.entryCount} appended to ${failureLogState.path}${requestIdStr}`
      );
    })
    .catch((err) => {
      console.warn("Could not append runner failure entry:", err?.message || err);
    });
  return failureLogState.promise;
}

async function finalizeFailureLogStream() {
  await failureLogState.promise;
  if (!failureLogState.initialized) return;
  try {
    await fs.appendFile(failureLogState.path, "\n]\n", "utf8");
  } catch (err) {
    console.warn(
      `Could not finalize runner failure log ${failureLogState.path}:`,
      err?.message || err
    );
  }
  if (failureLogState.entryCount > 0) {
    console.log(
      `${failureLogState.entryCount} runner_logs failures saved to ${failureLogState.path}`
    );
  }
  failureLogState.initialized = false;
}

function serializeResponse(res) {
  if (!res) return res;
  if (typeof res === "object") {
    // Handle fetch Response
    if (typeof res.status === "number" && typeof res.statusText === "string") {
      return {
        status: res.status,
        statusText: res.statusText,
        statusCode: res.statusCode ?? res.status,
      };
    }
    if (res.statusCode) return res;
  }
  return res;
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
      let data;
      try {
        data = await response.clone().json();
      } catch {
        try {
          data = await response.clone().text();
        } catch {
          data = null;
        }
      }
      console.log(
        "response",
        response.status,
        response.status < 300 ? "" : JSON.stringify(data, null, 2)
      );
      const headers = {};
      try {
        response.headers.forEach((v, k) => {
          headers[k] = v;
        });
      } catch {
        // ignore
      }
      return { statusCode: response.status, body: data, headers };
    } catch (error) {
      console.log(error);
      console.log(JSON.stringify(payload));
    }
  } else if (process.env.PIPELINE == "local") {
    console.log("local");
    return await handler(payload);
  }
}
async function logEvent(data, response) {
  if (!response?.statusCode || response.statusCode <= 300) return null;
  logger.log(response.statusCode);
  logger.log("logEvent", data, response);
  const failure = {
    ...data,
    _runner_failure: {
      statusCode: response.statusCode,
      response: serializeResponse(response),
      request_backup_id: response.body?.request_backup_id,
    },
  };
  return failure;
}
async function runOverArray(dataArray, callback, options) {
  const {
    forceSubmissionSource,
    forceCommsConsent,
    unwrapBodies,
    dryRun,
    failures,
    concurrency = 1,
  } = options;
  if (process.env.SLOW === "true") {
    console.log("Estimated execution time: ", 2 * dataArray.length);
  }
  let nextIndex = 0;

  const processRow = async (dataIndex) => {
    const item = dataArray[dataIndex];
    if (Array.isArray(item)) {
      console.log("File", dataIndex);
      await runOverArray(item, callback, options);
      return;
    }

    const normalized = normalizePayload(item, HEADERS);
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
    if (applyCommsConsent(normalized.body, forceCommsConsent)) {
      console.log("comms_consent set to true for payload", dataIndex);
    }
    const event = normalized.headers ? normalized : attachHeader(normalized, HEADERS);
    const summary = event.body?.email || event.body?.phone || event.body?.firstname || event.body?.id || "";
    console.log(`row ${dataIndex}: ${dryRun ? "dry-run" : "sending"} ${summary}`);
    if (dryRun) {
      console.log("[dry-run] event:", JSON.stringify(event, null, 2));
    } else {
      try {
        const response = await callback(event);
        const statusCode = response?.statusCode ?? response?.status;
        console.log(`row ${dataIndex}: status ${statusCode}`);
        const failure = await logEvent(event, response);
        if (failure && failures) {
          failures.push(failure);
          appendFailureLogEntry(failure);
        }
      } catch (error) {
        console.error(error);
        const failure = await logEvent(event, {
          statusCode: 500,
          body: "{message: failure on runner.js side}",
        });
        if (failure && failures) {
          failures.push(failure);
          appendFailureLogEntry(failure);
        }
      }
    }

    if (process.env.SLOW === "true") {
      console.log("waiting...");
      await sleep(1500);
      console.log("...starting");
    }
  };

  const worker = async () => {
    while (nextIndex < dataArray.length) {
      const currentIndex = nextIndex++;
      await processRow(currentIndex);
    }
  };

  const poolSize = Math.max(1, Math.floor(concurrency));
  const workers = Array.from({ length: Math.min(poolSize, dataArray.length || 1) }, () => worker());
  await Promise.all(workers);
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
  let forceCommsConsent = false;
  let unwrapBodies = false;
  let dryRun = false;
  let concurrency = 1;
  const inputPaths = [];
  const failures = [];

  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    if (arg.startsWith("--")) {
      const [flag, inlineVal] = arg.slice(2).split("=");
      const nextVal = argv[i + 1] && !argv[i + 1].startsWith("-") ? argv[i + 1] : undefined;
      const getVal = () => {
        if (inlineVal !== undefined && inlineVal !== "") return inlineVal;
        if (nextVal !== undefined) {
          i += 1;
          return nextVal;
        }
        return undefined;
      };

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
        case "force-comms-consent":
          forceCommsConsent = true;
          break;
        case "unwrap-body":
          unwrapBodies = true;
          break;
        case "dry-run":
          dryRun = true;
          break;
        case "concurrency": {
          const val = getVal();
          const parsed = Number.parseInt(val, 10);
          if (Number.isFinite(parsed) && parsed >= 1) {
            concurrency = parsed;
          } else {
            console.warn(`Ignoring invalid concurrency value: ${val}`);
          }
          break;
        }
        default:
          break;
      }
    } else if (arg.startsWith("-")) {
      if (arg.startsWith("-p")) {
        const valPart = arg.slice(2);
        let val = valPart;
        if (!val) {
          const nextVal = argv[i + 1] && !argv[i + 1].startsWith("-") ? argv[i + 1] : undefined;
          if (nextVal !== undefined) {
            val = nextVal;
            i += 1;
          }
        }
        const parsed = Number.parseInt(val, 10);
        if (Number.isFinite(parsed) && parsed >= 1) {
          concurrency = parsed;
        } else {
          console.warn(`Ignoring invalid concurrency value: ${val}`);
        }
      } else {
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
            case "c":
              forceCommsConsent = true;
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
      }
    } else {
      inputPaths.push(arg);
    }
  }

  await ensureLogDir();
  await ensureFailDir();

  if (forceSubmissionSource) {
    console.log(
      'submission_source override is ON (cli-runner). Use --keep-source_submission / -k to keep existing values.'
    );
  } else {
    console.log(
      'submission_source override is OFF (flag --keep-source_submission / -k). Existing values will be preserved.'
    );
  }

  if (forceCommsConsent) {
    console.log(
      'comms_consent forcing is ON (--force-comms-consent / -c). Payload body will set comms_consent=true.'
    );
  } else {
    console.log('comms_consent forcing is OFF by default. Use --force-comms-consent / -c to enable.');
  }

  if (concurrency > 1) {
    console.log(`concurrency is ${concurrency} (--concurrency / -p). Up to ${concurrency} rows in flight.`);
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
    await runOverArray(dataArray, runner, {
      forceSubmissionSource,
      forceCommsConsent,
      unwrapBodies,
      dryRun,
      failures,
      concurrency,
    });
  }

  if (failures.length) {
    const ts = new Date().toISOString().replace(/[:.]/g, "-");
    const filename = `${ts}_failures.json`;
    const filePath = path.join(FAIL_DIR, filename);
    try {
      await fs.writeFile(filePath, JSON.stringify(failures, null, 2), "utf8");
      console.log(`${failures.length} failed uploads saved to ${filePath}`);
      console.log(`Re-run failed items with: node runner.js ${filePath}`);
    } catch (err) {
      console.warn(`Could not write failed uploads file ${filePath}:`, err?.message || err);
    }
  }
  await finalizeFailureLogStream();
  console.log("duration", performance.now() - start);
}

main();
