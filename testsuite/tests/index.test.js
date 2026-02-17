import { describe, it } from "node:test";
import assert from "node:assert";
import { handler } from "../../index.js";
import fulsome from "../test_payloads/fulsome.json" with { type: "json" };
import { createClient } from "@supabase/supabase-js";

describe("full submission test", () => {
  it("full submission should 200", async () => {
    const response = await handler(fulsome);
    console.log('full sub output', response)
    assert.equal(response.statusCode, 200)
  });
});
