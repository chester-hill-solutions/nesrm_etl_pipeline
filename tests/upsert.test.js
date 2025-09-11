import test, { describe, it } from "node:test";
import assert from "node:assert";

import { upsertData } from "../src/upsert.js";
import logger from "simple-logs-sai-node";

const HEADERS = {
  origin: "www.meetsai.ca",
  "x-forwarded-for": "124.0.0.1",
  request_backup_id: 289,
};

function pick(obj, keys) {
  return Object.fromEntries(keys.map((k) => [k, obj[k]]));
}

describe("Condition Match Test", () => {
  it("should return a person with the email only given in a second payload since the second payload's match value is a substring of the db value match value", async () => {
    const p1 = {
      headers: HEADERS,
      body: {
        firstname: "Saihaan",
        surname: "Syed",
        phone: "123456",
        municipality: "Toronto",
      },
    };
    const p2 = {
      headers: HEADERS,
      body: {
        firstname: "Sai",
        surname: "Syed",
        phone: "123456",
        email: "testEmail@gmail.com",
      },
    };
    logger.dev.log("first");
    const first = await upsertData(p1);
    logger.dev.log("second");
    const second = await upsertData(p2);
    logger.dev.log("second data", JSON.stringify(second, null, 2));
    assert.strictEqual(second.municipality, p1.body.municipality);
  });
});

describe("birthday field tests", () => {
  it("should return with the first payloads birthday since the others are invalid", async () => {
    const p1 = {
      headers: HEADERS,
      body: {
        olp_van_id: "test123",
        birthyear: 2003,
        birthmonth: 8,
        birthdate: 29,
      },
    };
    const p2 = {
      body: {
        olp_van_id: "test123",
        birthyear: 2021,
      },
    };
    const p3 = {
      body: {
        olp_van_id: "test123",
        birthyear: 1913,
      },
    };
    const first = await upsertData(p1);
    const second = await upsertData(p2);
    const third = await upsertData(p3);
    assert.strictEqual;
    third.birthyear, p1.body.birthyear;
  });
});

describe("Ballot sequence tests", () => {
  const jt = {
    body: { olp_van_id: "test123", ballot1: "Justin Trudeau" },
  };
  const pp = {
    body: { olp_van_id: "test123", ballot1: "Pierre Pollievre" },
  };
  const js = {
    body: { olp_van_id: "test123", ballot1: "Jagmeet Singh" },
  };
  const njt = {
    body: { olp_van_id: "test123", ballot1: "Not Justin" },
  };
  const pjt = {
    body: { olp_van_id: "test123", ballot1: "Possibly Justin" },
  };
  const random = {
    body: { olp_van_id: "test123", ballot1: "random" },
  };
  it("should allow the ballot to pass", async () => {
    const expected = { ballot1: "Justin Trudeau" };
    await upsertData({ body: { olp_van_id: "test123", ballot1: null } });

    const result = await upsertData(jt);
    const diff = pick(result, Object.keys(expected));
    assert.deepStrictEqual(diff, expected);
  });
  it("should allow the ballot to pass from not candidate to candidate", async () => {
    const expected = { ballot1: "Justin Trudeau" };
    await upsertData(jt);
    await upsertData(njt);

    const result = await upsertData(jt);
    const diff = pick(result, Object.keys(expected));
    assert.deepStrictEqual(diff, expected);
  });
  it("should allow the ballot to pass from not candidate to opposing candidate", async () => {
    const expected = { ballot1: "Pierre Pollievre" };
    await upsertData(jt);
    await upsertData(njt);
    const result = await upsertData(pp);
    const diff = pick(result, Object.keys(expected));
    assert.deepStrictEqual(diff, expected);
  });
  it("should change old data to possible if we try to replace candidate with opposing candidate", async () => {
    const expected = { ballot1: "Possibly Justin" };
    await upsertData(jt);

    const result = await upsertData(pp);
    const diff = pick(result, Object.keys(expected));
    assert.deepStrictEqual(diff, expected);
  });
  it("should not change old data", async () => {
    const expected = { ballot1: "Justin Trudeau" };
    await upsertData(jt);

    const result = await upsertData(random);
    const diff = pick(result, Object.keys(expected));
    assert.deepStrictEqual(diff, expected);
  });
});

describe("upsertData tests", () => {
  it("should return upserted payload", async () => {
    const payload = {
      headers: {
        origin: "www.meetsai.ca",
        "x-forwarded-for": "124.0.0.1",
        request_backup_id: 289,
      },
      body: {
        firstname: "Saihaan",
        surname: "Syed",
        email: "saihaansyedprofiles@gmail.com",
        birthyear: "2003",
        birthmonth: "08",
        birthdate: "29",
        street_address: "442 Pharmacy Ave",
        municipality: "Scarborough",
        country: "CA",
        postcode: "M1L 3G6",
      },
    };
    const expected = {
      country: "CA",
      division: "Ontario",
      division_electoral_district: "Scarborough Southwest",
      email: "saihaansyedprofiles@gmail.com",
      federal_electoral_district: "Scarborough Southwest",
      firstname: "Saihaan",
      municipality: "Scarborough",
      postcode: "M1L 3G6",
      street_address: "442 Pharmacy Ave",
      surname: "Syed",
    };
    const result = await upsertData(payload);
    const filteredResult = pick(result, Object.keys(expected));
    assert.deepStrictEqual(filteredResult, expected);
  });
});
