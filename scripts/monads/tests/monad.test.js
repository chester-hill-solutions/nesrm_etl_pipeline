import { describe, it } from "node:test";
import assert from "node:assert";

import { statusCodeMonad } from "../monad.js";

describe("new unit tests", () => {
  let unit = statusCodeMonad.newunit
    ? statusCodeMonad.newunit
    : statusCodeMonad.unit;
  it("should return full monadic value if given empty object ", async () => {
    const expected = { statusCode: 200, body: { trace: [] } };
    const actual = await unit({});
    assert.deepEqual(actual, expected);
  });
  it("should return a full monadic value with the statusCode intact if given an object with only statusCode", async () => {
    const expected = { statusCode: 500, body: { trace: [] } };
    const actual = unit({ statusCode: 500 });
    assert.deepEqual(actual, expected);
  });
  it("should return a full monadic value with the if given non array trace", async () => {
    const expected = { statusCode: 500, body: { trace: ["blah blah"] } };
    const actual = unit({ statusCode: 500, body: { trace: "blah blah" } });
    assert.deepEqual(actual, expected);
  });
  it("should return a full monadic value with the if given no trace but keep body intact", async () => {
    const expected = {
      statusCode: 500,
      body: { error: "this is error", trace: [] },
    };
    const actual = unit({ statusCode: 500, body: { error: "this is error" } });
    assert.deepEqual(actual, expected);
  });
  it("should return a full monadic value with the if given perfect value", async () => {
    const expected = {
      statusCode: 500,
      body: { error: "this is error", trace: ["blah", "bloo"] },
    };
    const actual = unit({
      statusCode: 500,
      body: { error: "this is error", trace: ["blah", "bloo"] },
    });
    assert.deepEqual(actual, expected);
  });
});
