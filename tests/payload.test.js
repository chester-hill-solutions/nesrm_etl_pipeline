import fs from "fs/promises";
import path from "path";
import { fileURLToPath } from "url";
import logger from "simple-logs-sai-node";
import { describe, it } from "node:test";
import assert from "node:assert";

import { handler } from "../index.js";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

function attachHeader(obj) {
  let ret = {
    headers: { origin: "www.meetsai.ca", "x-forwarded-for": "124.0.0.1" },
    body: obj,
  };
  return ret;
}

async function getTestData(dir_name) {
  const subdir = "test_payloads/" + dir_name;
  const dirPath = path.join(__dirname, subdir);
  const jsonArray = [];

  try {
    const files = await fs.readdir(dirPath);

    for (const file of files) {
      const filePath = path.join(dirPath, file);
      if (path.extname(file).toLowerCase() === ".json") {
        try {
          const content = await fs.readFile(filePath, "utf8");
          const jsonData = JSON.parse(content);
          let jsonDataWiHeader;
          //logger.dev.log("jsonData", jsonData);
          if (Array.isArray(jsonData)) {
            jsonDataWiHeader = jsonData.map((obj) => attachHeader(obj));
          } else {
            jsonDataWiHeader = attachHeader(jsonData);
          }
          //logger.dev.log("jsonDataWiHeader", jsonDataWiHeader);
          jsonArray.push(jsonDataWiHeader);
        } catch (err) {
          console.error(
            `Error reading or parsing JSON file ${file}: ${err.message}`
          );
        }
      }
      //logger.dev.log("jsonArray", jsonArray);
    }
    //logger.dev.log("final jsonArray", jsonArray);

    return jsonArray;
  } catch (err) {
    console.error(`Error reading directory ${dirPath}: ${err.message}`);
    return [];
  }
}

async function runOnPayloads(testDataArray, operator) {
  let fileCount = 0;
  testDataArray.forEach(async (testData) => {
    fileCount++;
    logger.dev.log("file", fileCount);
    let payloadCount = 0;
    if (Array.isArray(testData)) {
      testData.forEach(async (payload) => {
        payloadCount++;
        logger.dev.log("payload", payloadCount);
        await operator(payload);
      });
    } else {
      payloadCount = 1;
      logger.dev.log("payload", payloadCount);
      await operator(testData);
    }
  });
}

/*
describe("uncommons.ca paylod tests", () => {
  let testDataArray = getTestData("uncommons");
  testDataArray.forEach((testData) => {
    if (Array.isArray(testData)) {
      testData.forEach((element) => {
        it("output", async () => {
          assert;
        });
      });
    }
  });
});*/

async function main() {
  runOnPayloads(await getTestData("uncommons1"), async (payload) => {
    let response = await handler(payload);
    response.body = JSON.parse(response.body);
    console.log("Handler output", JSON.stringify(response, null, 2));
  });
  //console.log(JSON.stringify(await getTestData("uncommons"), null, 2));
}
main();
