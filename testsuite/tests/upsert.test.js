import test, { describe, it } from "node:test";
import assert from "node:assert";
import "dotenv/config";
import { pick, keyCompare } from "../../scripts/pickKeys/index.js";
import { upsertData } from "../../src/upsert.js";
import logger from "simple-logs-sai-node";

const HEADERS = {
  origin: "www.meetsai.ca",
  "x-forwarded-for": "124.0.0.1",
};

describe("Condition Match Test", () => {
  it("should return a person with the email only given in a second payload since the second payload's match value is a substring of the db value match value", async () => {
    const p1 = {
      headers: HEADERS,
      body: {
        firstname: "fname",
        surname: "sname",
        phone: "123456",
        municipality: "Toronto",
      },
    };
    const p2 = {
      headers: HEADERS,
      body: {
        firstname: "fname",
        surname: "sname",
        phone: "2345",
        email: "testEmail@gmail.com",
      },
    };
    logger.dev.log("first");
    const first = await upsertData({input:p1});
    logger.dev.log("second");
    const second = await upsertData({input:p2});
    logger.dev.log("second data", JSON.stringify(second, null, 2));
    assert.strictEqual(second.municipality, p1.body.municipality);
  });
  it("should return a person with the new data because I only passed a phone number", async () => {
    const p1 = {
      headers: HEADERS,
      body: {
        firstname: "only",
        surname: "phone",
        phone: "378468436",
        email: "onlyphone@gmail.com",
      },
    };
    const p1r = await upsertData({input:p1});
    const p2 = {
      headers: HEADERS,
      body: {
        phone: "378468436",
        gender: "f",
      },
    };
    const p2e = {
      firstname: "only",
      surname: "phone",
      phone: "378468436",
      email: "onlyphone@gmail.com",
      gender: "f",
    };
    const p2r = await upsertData({input:p2});
    assert.deepStrictEqual(keyCompare(p2r, p2e), p2e);
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
    const first = await upsertData({input:p1});
    const second = await upsertData({input:p2});
    const third = await upsertData({input:p3});
    assert.strictEqual;
    third.birthyear, p1.body.birthyear;
  });
});

describe("Ballot sequence tests", () => {
  const jt = {
    body: { olp_van_id: "test123", ballot1: process.env.CANDIDATE },
  };
  const pp = {
    body: {
      olp_van_id: "test123",
      ballot1: process.env.CANDIDATES.split(",")[1],
    },
  };
  const js = {
    body: {
      olp_van_id: "test123",
      ballot1: process.env.CANDIDATES.split(",")[2],
    },
  };
  const njt = {
    body: { olp_van_id: "test123", ballot1: process.env.NOT_CANDIDATE },
  };
  const pjt = {
    body: { olp_van_id: "test123", ballot1: process.env.POSSIBLY_CANDIDATE },
  };
  const random = {
    body: { olp_van_id: "test123", ballot1: "random" },
  };
  it("should allow the ballot to pass", async () => {
    const expected = { ballot1: process.env.CANDIDATE };
    await upsertData({input:{ body: { olp_van_id: "test123", ballot1: null }} });

    const result = await upsertData({input:jt});
    const diff = pick(result, Object.keys(expected));
    assert.deepStrictEqual(diff, expected);
  });
  it("should allow the ballot to pass from not candidate to candidate", async () => {
    const expected = { ballot1: process.env.CANDIDATE };
    await upsertData({input:njt});

    const result = await upsertData({input:jt});
    const diff = pick(result, Object.keys(expected));
    assert.deepStrictEqual(diff, expected);
  });
  it("should allow the ballot to pass from not candidate to opposing candidate", async () => {
    const expected = { ballot1: process.env.CANDIDATES.split(",")[1] };
    await upsertData({input:jt});
    await upsertData({input:njt});
    const result = await upsertData({input:pp});
    const diff = pick(result, Object.keys(expected));
    assert.deepStrictEqual(diff, expected);
  });
  it("should change old data to possible if we try to replace candidate with opposing candidate", async () => {
    const expected = { ballot1: process.env.POSSIBLY_CANDIDATE };
    await upsertData({input:jt});

    const result = await upsertData({input:pp});
    const diff = pick(result, Object.keys(expected));
    assert.deepStrictEqual(diff, expected);
  });
  it("should not change old data", async () => {
    const expected = { ballot1: process.env.CANDIDATE };
    await upsertData({input:jt});

    const result = await upsertData({input:random});
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
      },
      body: {
        firstname: "Saihaan",
        surname: "Syed",
        email: "saitesteremail@test.com",
        birthyear: "1990",
        birthmonth: "09",
        birthdate: "30",
        street_address: "123 Street Rd",
        municipality: "Scarborough",
        country: "CA",
        postcode: "K1A 0A9",
      },
    };
    const expected = {
      country: "CA",
      division: "Ontario",
      division_electoral_district: "Ottawa Centre",
      email: "saitesteremail@test.com",
      federal_electoral_district: "Ottawa Centre",
      firstname: "Saihaan",
      municipality: "OTTAWA",
      postcode: "K1A 0A9",
      street_address: "123 Street Rd",
      surname: "Syed",
      birthyear: 1990,
      birthmonth: 9,
      birthdate: 30,
    };
    const result = await upsertData({input:payload});
    const filteredResult = pick(result, Object.keys(expected));
    assert.deepStrictEqual(filteredResult, expected);
  });
});

describe("comma seperated values test", () => {
  it("should return a single organizer since comma seperated fields should not allow duplicates", async () => {
    const p1 = {
      headers: HEADERS,
      body: {
        firstname: "fname",
        surname: "sname",
        phone: "123456",
      },
    };
    const p1e = {
      firstname: "fname",
      surname: "sname",
      phone: "123456",
    };
    const p1r = await upsertData({input:p1});
    assert.deepStrictEqual(pick(p1r, Object.keys(p1e)), p1e);
    const p2 = {
      headers: HEADERS,
      body: {
        firstname: "fname",
        surname: "sname",
        phone: "123456",
        organizer: "sai",
      },
    };
    const p2e = {
      firstname: "fname",
      surname: "sname",
      phone: "123456",
      organizer: "sai",
    };
    const p2r = await upsertData({input:p2});
    assert.deepStrictEqual(pick(p2r, Object.keys(p2e)), p2e);
    const p3 = {
      headers: HEADERS,
      body: {
        firstname: "fname",
        surname: "sname",
        phone: "123456",
        organizer: "sai",
      },
    };
    const p3e = {
      firstname: "fname",
      surname: "sname",
      phone: "123456",
      organizer: "sai",
    };
    const p3r = await upsertData({input:p3});
    assert.deepStrictEqual(pick(p3r, Object.keys(p3e)), p3e);
  });
  it("should return an untouched array since this comma seperated fields should not be destroyed from null inserts", async () => {
    const p1 = {
      headers: HEADERS,
      body: {
        firstname: "fname",
        surname: "sname",
        phone: "123456",
      },
    };
    const p1e = {
      firstname: "fname",
      surname: "sname",
      phone: "123456",
      organizer: "sai",
    };
    const p1r = await upsertData({input:p1});
    assert.deepStrictEqual(pick(p1r, Object.keys(p1e)), p1e);
  });
  it("should return an array with multiple values", async () => {
    const p1 = {
      headers: HEADERS,
      body: {
        firstname: "fname",
        surname: "sname",
        phone: "123456",
        tags: "best guy",
      },
    };
    const p1e = {
      firstname: "fname",
      surname: "sname",
      phone: "123456",
      tags: "best guy",
    };
    const p1r = await upsertData({input:p1});
    //assert.deepStrictEqual(pick(p1r, Object.keys(p1e)), p1e);
    const p2 = {
      headers: HEADERS,
      body: {
        firstname: "fname",
        surname: "sname",
        phone: "123456",
        tags: "nice dude",
      },
    };
    const p2e = {
      firstname: "fname",
      surname: "sname",
      phone: "123456",
      tags: "best guy,nice dude",
    };
    const p2r = await upsertData({input:p2});
    assert.deepStrictEqual(pick(p2r, Object.keys(p2e)), p2e);
  });
  it("should return an unchanged array of multiple values since now adding in duplicates should not affect it", async () => {
    const p2 = {
      headers: HEADERS,
      body: {
        firstname: "fname",
        surname: "sname",
        phone: "123456",
        tags: "nice dude",
      },
    };
    const p2e = {
      firstname: "fname",
      surname: "sname",
      phone: "123456",
      tags: "best guy,nice dude",
    };
    const p2r = await upsertData({input:p2});
    assert.deepStrictEqual(pick(p2r, Object.keys(p2e)), p2e);
  });
});
