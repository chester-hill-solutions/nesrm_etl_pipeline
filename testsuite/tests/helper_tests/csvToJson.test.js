import assert from "node:assert";
import { mkdtemp, rm, writeFile } from "node:fs/promises";
import { describe, it } from "node:test";
import { tmpdir } from "node:os";
import path from "node:path";

import { csvToJson } from "../../../scripts/shapeData/index.js";

async function withCsv(content, run) {
  const dir = await mkdtemp(path.join(tmpdir(), "csvToJson-"));
  const file = path.join(dir, "sample.csv");
  await writeFile(file, content, "utf8");
  try {
    return await run(file);
  } finally {
    await rm(dir, { recursive: true, force: true });
  }
}

describe("csvToJson tags folding", () => {
  it("turns tags:<key> columns into tags entries", async () => {
    const csv = "email,tags:culture\nuser@example.com,arts\n";
    const records = await withCsv(csv, csvToJson);
    assert.deepStrictEqual(records, [{ email: "user@example.com", tags: "culture:arts" }]);
  });

  it("combines multiple tag columns into one tags field", async () => {
    const csv = "email,tags:culture,tags:interest\nuser@example.com,arts,history\n";
    const records = await withCsv(csv, csvToJson);
    assert.deepStrictEqual(records, [
      { email: "user@example.com", tags: "culture:arts,interest:history" },
    ]);
  });

  it("merges existing tags column with tags:<key> columns", async () => {
    const csv = "email,tags,tags:topic\nuser@example.com,base1,topicA\n";
    const records = await withCsv(csv, csvToJson);
    assert.deepStrictEqual(records, [
      { email: "user@example.com", tags: "base1,topic:topicA" },
    ]);
  });

  it("splits multi-value cells and de-duplicates case-insensitively", async () => {
    const csv = "email,tags,tags:culture\nuser@example.com,\"Art,art\",Arts\n";
    const records = await withCsv(csv, csvToJson);
    assert.deepStrictEqual(records, [
      { email: "user@example.com", tags: "Art,culture:Arts" },
    ]);
  });
});

describe("csvToJson organizer folding", () => {
  it("combines organizer columns into a de-duped array", async () => {
    const csv = "email,organizer,organizer_2\nuser@example.com,Alpha,Beta\n";
    const records = await withCsv(csv, csvToJson);
    assert.deepStrictEqual(records, [
      { email: "user@example.com", organizer: ["Alpha", "Beta"] },
    ]);
  });

  it("splits comma-separated organizer cells and de-dupes", async () => {
    const csv = "email,organizer,organizer_extra\nuser@example.com,\"Alpha,alpha\",Alpha\n";
    const records = await withCsv(csv, csvToJson);
    assert.deepStrictEqual(records, [
      { email: "user@example.com", organizer: ["Alpha"] },
    ]);
  });

  it("ignores olp23_organizer while folding other organizer fields", async () => {
    const csv = "email,organizer,olp23_organizer\nuser@example.com,Alpha,Special\n";
    const records = await withCsv(csv, csvToJson);
    assert.deepStrictEqual(records, [
      { email: "user@example.com", organizer: ["Alpha"], olp23_organizer: "Special" },
    ]);
  });
});
