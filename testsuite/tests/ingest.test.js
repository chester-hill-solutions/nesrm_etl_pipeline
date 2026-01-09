import { describe, it } from "node:test";
import assert from "node:assert";

import { handler } from "../../index.js";
import ingest from "../../src/ingest.js";
import oneStepArray from "../test_payloads/oneStepArray.json" with { type: "json" };

import { createWriteStream } from "fs";
import { createClient } from "@supabase/supabase-js";

console.log = async (message) => {
  const tty = createWriteStream("/dev/tty");
  const msg =
    typeof message === "string" ? message : JSON.stringify(message, null, 2);
  return tty.write(msg + "\n");
};

describe("headerCheck tests", () => {
  it("should return statusCode 400 if missing headers", async () => {
    const result = await handler({ body: { random: "1" } });
    assert.strictEqual(result.statusCode, 400, JSON.stringify(result));
  });
  it("should return statusCode 400 if missing Origin headers", async () => {
    const result = await handler({
      headers: { "X-Forwarded-For": "124.0.0.1" },
      body: { random: "1" },
    });
    assert.strictEqual(result.statusCode, 400, JSON.stringify(result));
  });
  it("should return statusCode 400 if missing X-Forwarded-For headers", async () => {
    const result = await handler({
      headers: { Origin: "meetsai.ca" },
      body: { random: "1" },
    });
    assert.strictEqual(result.statusCode, 400, JSON.stringify(result));
  });
  it("should return statusCode 400 if missing both headers", async () => {
    const result = await handler({
      headers: {},
      body: { random: "1" },
    });
    assert.strictEqual(result.statusCode, 400, JSON.stringify(result));
  });
  it("should return statusCode 401 if wrong Origin", async () => {
    const result = await handler({
      headers: { Origin: "blahblah.ca", "X-Forwarded-For": "124.0.0.1" },
      body: { random: "1" },
    });
    assert.strictEqual(result.statusCode, 401, JSON.stringify(result));
  });
});

describe("storeRequest()", () => {
  let supabase = createClient(process.env.DATABASE_URL, process.env.KEY);
  it("should return the correct posted row", async () => {
    const expected = oneStepArray[0];
    const headerCheckResponse = await ingest.headerCheck(expected);
    const storeData = {
      payload:
        typeof headerCheckResponse === "string"
          ? JSON.parse(headerCheckResponse)
          : headerCheckResponse,
      origin: headerCheckResponse.headers?.Origin,
      ip: headerCheckResponse.headers?.["X-Forwarded-For"],
      email: headerCheckResponse.body?.email,
      step: headerCheckResponse.body?._meta?.step?.index,
    };

    const storeRequestResponse = await ingest.storeRequest(storeData);
    const result = storeRequestResponse[0];
    assert.strictEqual(
      result.origin,
      expected.headers.Origin,
      "Origin mismatch",
    );
    assert.strictEqual(
      result.ip,
      expected.headers["X-Forwarded-For"],
      "X-Forwarded-For mismatch",
    );
    assert.strictEqual(result.email, expected.body.email, "email mismatch");

    if (oneStepArray[0]?._meta?.step?.index !== undefined) {
      assert.strictEqual(
        result.step,
        oneStepArray[0]._meta.step.index,
        "step mismatch",
      );
    }
  });
});
describe("storeEvent()", () => {
  let supabase = createClient(process.env.DATABASE_URL, process.env.KEY);
  it("should return the correct posted row", async () => {
    const expected = oneStepArray[0];
    const headerCheckResponse = await ingest.headerCheck(expected);
    console.log("storeEvent() test headerCheckResponse", headerCheckResponse);
    console.log(headerCheckResponse);
    const storeData = {
      payload:
        typeof headerCheckResponse === "string"
          ? JSON.parse(headerCheckResponse)
          : headerCheckResponse,
      origin: headerCheckResponse.headers?.Origin,
      ip: headerCheckResponse.headers?.["X-Forwarded-For"],
      email: headerCheckResponse.body?.email,
      step: headerCheckResponse.body?._meta?.step?.index,
    };

    const storeEventResponse = await ingest.storeEvent(headerCheckResponse);
    const result = storeEventResponse[0];
    console.log("storeEvent() result:", result);
    console.log(result);

    assert.strictEqual(
      result.origin,
      expected.headers.Origin,
      "Origin mismatch",
    );
    assert.strictEqual(
      result.ip,
      expected.headers["X-Forwarded-For"],
      "X-Forwarded-For mismatch",
    );
    assert.strictEqual(result.email, expected.body.email, "email mismatch");

    if (oneStepArray[0]?._meta?.step?.index !== undefined) {
      assert.strictEqual(
        result.step,
        oneStepArray[0]._meta.step.index,
        "step mismatch",
      );
    }
  });
});
/*
describe("storeEvent()", () => {
  let supabase = createClient(process.env.DATABASE_URL, process.env.KEY);

  it("should return the correct posted row", async () => {
    const headerCheckResponse = await ingest.headerCheck(oneStepArray[0]);
    console.log(headerCheckResponse);
    const storeData = {
      payload:
        typeof headerCheckResponse === "string"
          ? JSON.parse(headerCheckResponse)
          : headerCheckResponse,
      origin: headerCheckResponse.headers?.origin,
      ip: headerCheckResponse.headers?.["x-forwarded-for"],
      email: headerCheckResponse.body?.email,
      step: headerCheckResponse.body?._meta?.step?.index,
    };

    const result = await ingest.storeEvent(headerCheckResponse, supabase);
    console.log("result:", result);
    console.log("🔎 Comparing values:");
    console.log("Origin:", {
      result: result.Origin,
      expected: oneStepArray[0].Origin,
    });
    console.log("X-Forwarded-For:", {
      result: result["X-Forwarded-For"],
      expected: oneStepArray[0]["X-Forwarded-For"],
    });
    console.log("ip:", {
      result: result.ip,
      expected: oneStepArray[0].ip,
    });
    console.log("email:", {
      result: result.email,
      expected: oneStepArray[0].email,
    });
    console.log("step:", {
      result: result.step,
      expected: oneStepArray[0]?._meta?.step?.index,
    });
    const expected = oneStepArray[0];
    const keysToCheck = ["Origin", "X-Forwarded-For", "ip", "email"];

    for (const key of keysToCheck) {
      if (expected[key] !== undefined) {
        assert.strictEqual(
          result[key],
          expected[key],
          `Mismatch at key "${key}". Full result: ${JSON.stringify(result)}`,
        );
      }
    }
    if (
      expected._meta &&
      expected._meta.step &&
      typeof expected._meta.step.index !== "undefined"
    ) {
      assert.strictEqual(
        result.step,
        expected._meta.step.index,
        `Mismatch at nested key "_meta.step.index". Full result: ${JSON.stringify(result)}`,
      );
    }
  });
});*/
