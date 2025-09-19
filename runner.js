import { handler } from "./index.js";
import path from "path";
import fs from "fs/promises";
import { createObjectCsvWriter } from "csv-writer";
import { csvToJson, attachHeader } from "./scripts/shapeData/index.js";
import logger from "simple-logs-sai-node";
const HEADERS = {
  Origin: "www.meetsai.ca",
  "X-Forwarded-For": "124.0.0.1",
  Authorization: "Bearer " + process.env.AWS_API_GATEWAY_BEARER,
};
const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
async function runner(payload) {
  if (process.env.PIPELINE == "gateway") {
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
async function runOverArray(dataArray, callback) {
  if (process.env.SLOW === "true") {
    console.log("Estimated execution time: ", 2 * dataArray.length);
  }
  for (const dataIndex in dataArray) {
    if (Array.isArray(dataArray[dataIndex])) {
      console.log("File", dataIndex);
      await runOverArray(dataArray[dataIndex], callback);
    } else {
      const event = await attachHeader(dataArray[dataIndex], HEADERS);
      console.log(
        "\nPayload",
        dataIndex,
        event.body?.email || event.body?.phone || event.body?.firstname
      );
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
  const argv = process.argv.slice(2);
  for (const arg of argv) {
    if (arg.startsWith("--")) {
      // Long form: --flag
      const flag = arg.slice(2);
      switch (flag) {
        case "local":
          process.env.PIPELINE = "local";
          break;
        case "gateway":
          process.env.PIPELINE = "gateway";
        case "slow":
          process.env.SLOW = "true";
        default:
          break;
      }
    } else if (arg.startsWith("-")) {
      // Short form: -f, -abc
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
          // add more short options here
        }
      }
    } else {
      const dataArray = await parseDir(arg);
      await runOverArray(dataArray, runner);
    }
  }
}

main();
