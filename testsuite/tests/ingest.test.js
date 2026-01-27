import { describe, it } from "node:test";
import assert from "node:assert";
import { handler } from "../../index.js";
import ingest from "../../src/ingest.js";
import oneStepArray from "../test_payloads/oneStepArray.json" with { type: "json" };
import { createClient } from "@supabase/supabase-js";

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
  it("should return the correct posted row from storeReq", async () => {
    const expected = structuredClone(oneStepArray[0]);
    expected.body.email = "storereq@gmail.com"
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

    const storeRequestResponse = await ingest.storeRequest({input:storeData, supabase:supabase});
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

    if (expected?._meta?.step?.index !== undefined) {
      assert.strictEqual(
        result.step,
        expected._meta.step.index,
        "step mismatch",
      );
    }
  });
});
describe("storeEvent()", () => {
  let supabase = createClient(process.env.DATABASE_URL, process.env.KEY);
  it("should return the correct posted row", async () => {
    console.log("storeEventTest console 1");
    const expected = structuredClone(oneStepArray[0]);
    expected.body.email = "storeevent@gmail.com"
    const headerCheckResponse = await ingest.headerCheck(expected);
    console.log("storeEventTest console 2");
    const storeEventResponse = await ingest.storeEvent({
      input: headerCheckResponse,
      supabase: supabase
    });
    console.log("storeEventTest console 3");
    const result = storeEventResponse;

    assert.strictEqual(
      result.headers?.Origin,
      expected.headers.Origin,
      "Origin mismatch",
    );
    assert.strictEqual(
      result.headers["X-Forwarded-For"],
      expected.headers["X-Forwarded-For"],
      "X-Forwarded-For mismatch",
    );
    assert.strictEqual(result.body.email, expected.body.email, "email mismatch");
    assert.ok(result.headers?.request_backup_id, "request body id exists")

    if (expected?._meta?.step?.index !== undefined) {
      assert.strictEqual(
        result.step,
        expected._meta.step.index,
        "step mismatch",
      );
    }
  });
});
