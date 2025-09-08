import { handler } from "./index.js";
import { readFile } from "fs/promises";
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
    console.log(JSON.stringify(response));
    return response;
  } catch (error) {
    console.log(error);
    console.log(JSON.stringify(payloadWiHeader));
  }
}

const main = async () => {
  const testDataArray = await getTestData("uncommons");
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

main();
