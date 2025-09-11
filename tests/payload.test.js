import fs from "fs/promises";
import path from "path";
import { fileURLToPath } from "url";
import logger from "simple-logs-sai-node";
import test, { describe, it } from "node:test";
import assert from "node:assert";

import { handler } from "../index.js";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

function attachHeader(obj) {
  //logger.dev.log("attachHeader", obj);
  const headers = { Origin: "www.meetsai.ca", "X-Forwarded-For": "124.0.0.1" };
  if (obj.body) {
    obj.headers = headers;
  } else {
    return {
      headers: headers,
      body: obj,
    };
  }
  return obj;
}

async function getTestData(dir_name, prefix) {
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
            //logger.dev.log(jsonData[0]);
            //logger.dev.log("jsonData Array", JSON.stringify(jsonData, null, 2));
            /*
            for (const jsonDataElem of jsonData) {
              logger.dev.log("jsonDataWiOutHeader", jsonDataElem);
              jsonDataWiHeader = await attachHeader(jsonDataElem);
              logger.dev.log("jsonDataWiHeader", jsonDataWiHeader);
              jsonArray.push(jsonDataWiHeader);
            }*/

            jsonDataWiHeader = jsonData.map((jsonDataElem) => {
              return attachHeader(jsonDataElem);
            });
          } else {
            jsonDataWiHeader = await attachHeader(jsonData);
            //logger.dev.log("jsonDataWiHeader", jsonDataWiHeader);
          }
          jsonArray.push(jsonDataWiHeader);

          //logger.dev.log("jsonDataWiHeader", jsonDataWiHeader);
          //logger.dev.log("jsonArray", JSON.stringify(jsonArray, null, 2));
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
  logger.dev.log("testDataArray", testDataArray);
  let fileCount = 0;
  for (const testData of testDataArray) {
    fileCount++;
    logger.dev.log("file", fileCount);
    logger.dev.log("file content", testData);
    let payloadCount = 0;
    if (Array.isArray(testData)) {
      for (const payload of testData) {
        payloadCount++;
        logger.dev.log("payload", payloadCount);
        await operator(payload);
      }
    } else {
      payloadCount = 1;
      logger.dev.log("payload", payloadCount);
      await operator(testData);
    }
  }
}

async function main() {
  await runOnPayloads(await getTestData("uncommons"), async (payload) => {
    let response = await handler(payload);
    logger.dev.log("Ran handler", response.statusCode);
    response.body = JSON.parse(response.body);
    console.log("Handler output", JSON.stringify(response, null, 2));
  });
  //console.log(JSON.stringify(await getTestData("uncommons"), null, 2));
}
main();

describe("general test", () => {
  it("should fail", () => {
    let payload = attachHeader({});
    payload.headers.throw = true;
    handler(payload);
  });
});

/*
describe("uncommons payload test", async () => {
  let testDataArray = await getTestData("uncommons");
  for (const payload of object) {
  }
});*/

export { attachHeader, getTestData, runOnPayloads };
