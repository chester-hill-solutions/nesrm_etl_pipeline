import { handler } from "./index.js";
import { readFile } from "fs/promises";
import fs from "fs";
import "dotenv/config";
import {
  attachHeader,
  getTestData,
  runOnPayloads,
} from "./tests/payload.test.js";

async function post(payload, num = 0) {
  console.log("payloadIndex", num);
  let payloadWiHeader = await attachHeader(payload);
  try {
    const response = await fetch(process.env.AWS_API_GATEWAY_ENDPOINT, {
      method: "POST",
      headers: payloadWiHeader.headers,
      body: JSON.stringify(payloadWiHeader.body),
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
    console.log(JSON.stringify(payloadWiHeader));
  }
}
async function csvToJson(filePath) {
  const data = await fs.promises.readFile(filePath, "utf8");

  const [headerLine, ...lines] = data.trim().split("\n");
  const headers = headerLine.split(",");

  const result = lines.map((line) => {
    const values = line.split(",");
    return headers.reduce((obj, header, i) => {
      obj[header.trim()] = values[i]?.trim() ?? null;
      return obj;
    }, {});
  });

  return result;
}
const main = async () => {
  //const testDataArray = await getTestData("../supporterData.csv");
  const testDataArray = await csvToJson("../supporterDataSample.csv");
  for (const testDataIndex in testDataArray) {
    let response;
    console.log("testDataIndex:", testDataIndex);
    if (Array.isArray(testDataArray[testDataIndex])) {
      for (const payloadIndex in testDataArray[testDataIndex]) {
        response = await post(
          testDataArray[testDataIndex][payloadIndex],
          payloadIndex
        );
      }
    } else {
      response = await post(testDataArray[testDataIndex]);
    }
  }
};
//console.log(await csvToJson("./tests/test_payloads/csv_test/dummy_csv.csv"));
main();
