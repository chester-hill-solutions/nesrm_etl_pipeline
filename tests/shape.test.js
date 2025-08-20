import { describe, it } from "node:test";
import assert from "node:assert";

import { handler } from "../index.js";

describe("shapeData tests", () => {
  it("should return statusCode 422 if missing body", async () => {
    const payload = {
      headers: { origin: "meetsai.ca", "x-forwarded-for": "124.0.0.1" },
    };
    const result = await handler(payload);
    assert.strictEqual(result.statusCode, 422, JSON.stringify(result));
  });
});
