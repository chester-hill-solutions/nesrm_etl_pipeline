import { cleanString } from "../../../src/shape.js";
import { describe, it } from "node:test";
import assert from "node:assert";

describe("cleanString", () => {
  it('should remove one backslash', async () => {
    const ret = cleanString("O\'Marrow");
    console.log("input", "O\'Marrow", "ret", ret)
    assert.strictEqual(ret,"O'Marrow"); 
  })
  it('should remove two backslash', async () => {
    const ret = cleanString("O\\'Marrow");
    console.log("input", "O\\'Marrow", "ret", ret)
    assert.strictEqual(ret,"O'Marrow"); 
  })
  it('should remove three backslash', async () => {
    const ret = cleanString("O\\\'Marrow");
    console.log("input", "O\\\'Marrow", "ret", ret)
    assert.strictEqual(ret,"O'Marrow"); 
  })
});
