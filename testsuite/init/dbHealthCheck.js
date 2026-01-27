import { describe, it } from "node:test";
import assert from "node:assert";
import { createClient } from "@supabase/supabase-js";

describe("Testing DB", () => {
  let supabase;
  it("creates client without throwing", async () => {
    assert.doesNotThrow(() => {
      supabase = createClient(process.env.DATABASE_URL, process.env.KEY);
    });
  });
});
