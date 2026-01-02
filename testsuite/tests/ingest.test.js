import { describe, it } from "node:test";
import assert from "node:assert";

import { handler } from "../../index.js";

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
