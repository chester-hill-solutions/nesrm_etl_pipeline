import { describe, it } from "node:test";
import assert from "node:assert";
import { pick } from "../scripts/pickKeys/index.js";
import { shapeData } from "../src/shape.js";
const HEADERS = {
  origin: "www.meetsai.ca",
  "x-forwarded-for": "124.0.0.1",
};
describe("shapeData tests", () => {
  it("should return statusCode 422 if missing body", async () => {
    const payload = {
      headers: { origin: "meetsai.ca", "x-forwarded-for": "124.0.0.1" },
    };
    //const result = await shapeData(payload);
    //assert.strictEqual(result.statusCode, 422, JSON.stringify(result));
    assert.rejects(shapeData(payload), (err) => {
      assert.strictEqual(err.statusCode, 422);
      return true;
    });
  });
  it("should return the full person data when provided with a structured input", async () => {
    const payload = {
      body: {
        step: 2,
        email: "saihaansyedprofiles@gmail.com",
        address: {
          street: "123 Street Rd",
          city: "Scarborough",
          state: "Ontario",
          postal: "K1A 0A9",
          country: "CA",
        },
        firstname: "Saihaan",
        surname: "Syed",
        dob: "2003-08-29",
        isVerified: true,
        isSubscribed: true,
      },
      headers: {
        origin: "www.meetsai.ca",
        "x-forwarded-for": "124.0.0.1",
        request_backup_id: 265,
      },
    };

    const expected = {
      firstname: "Saihaan",
      surname: "Syed",
      email: "saihaansyedprofiles@gmail.com",
      birthyear: "2003",
      birthmonth: "08",
      birthdate: "29",
      street_address: "123 Street Rd",
      municipality: "Scarborough",
      division: "Ontario",
      postcode: "K1A 0A9",
      country: "CA",
    };
    const result = await shapeData(payload);
    assert.deepStrictEqual(result.body, expected);
  });
});

describe("gender test", () => {
  it("should test that m gets registered as MALE", async () => {
    const p1 = {
      headers: HEADERS,
      body: {
        firstname: "fname",
        surname: "sname",
        phone: "123456",
        gender: "m",
      },
    };
    const p1e = {
      headers: HEADERS,
      body: {
        firstname: "fname",
        surname: "sname",
        phone: "123456",
        gender: "MALE",
      },
    };
    const p1r = await shapeData(p1);
    assert.deepStrictEqual(pick(p1r, Object.keys(p1e)), p1e);
  });
  it("should test that F gets registered as FEMALE", async () => {
    const p1 = {
      headers: HEADERS,
      body: {
        firstname: "fname",
        surname: "sname",
        phone: "123456",
        gender: "f",
      },
    };
    const p1e = {
      headers: HEADERS,
      body: {
        firstname: "fname",
        surname: "sname",
        phone: "123456",
        gender: "FEMALE",
      },
    };
    const p1r = await shapeData(p1);
    assert.deepStrictEqual(pick(p1r, Object.keys(p1e)), p1e);
  });
  it("should test that male gets registered as MALE", async () => {
    const p1 = {
      headers: HEADERS,
      body: {
        firstname: "fname",
        surname: "sname",
        phone: "123456",
        gender: "male",
      },
    };
    const p1e = {
      headers: HEADERS,
      body: {
        firstname: "fname",
        surname: "sname",
        phone: "123456",
        gender: "MALE",
      },
    };
    const p1r = await shapeData(p1);
    assert.deepStrictEqual(pick(p1r, Object.keys(p1e)), p1e);
  });
  it("should test that female gets registered as FEMALE", async () => {
    const p1 = {
      headers: HEADERS,
      body: {
        firstname: "fname",
        surname: "sname",
        phone: "123456",
        gender: "female",
      },
    };
    const p1e = {
      headers: HEADERS,
      body: {
        firstname: "fname",
        surname: "sname",
        phone: "123456",
        gender: "FEMALE",
      },
    };
    const p1r = await shapeData(p1);
    assert.deepStrictEqual(pick(p1r, Object.keys(p1e)), p1e);
  });
  it("should test that MALE gets registered as MALE", async () => {
    const p1 = {
      headers: HEADERS,
      body: {
        firstname: "fname",
        surname: "sname",
        phone: "123456",
        gender: "MALE",
      },
    };
    const p1e = {
      headers: HEADERS,
      body: {
        firstname: "fname",
        surname: "sname",
        phone: "123456",
        gender: "MALE",
      },
    };
    const p1r = await shapeData(p1);
    assert.deepStrictEqual(pick(p1r, Object.keys(p1e)), p1e);
  });
  it("should test that FEMALE gets registered as FEMALE", async () => {
    const p1 = {
      headers: HEADERS,
      body: {
        firstname: "fname",
        surname: "sname",
        phone: "123456",
        gender: "FEMALE",
      },
    };
    const p1e = {
      headers: HEADERS,
      body: {
        firstname: "fname",
        surname: "sname",
        phone: "123456",
        gender: "FEMALE",
      },
    };
    const p1r = await shapeData(p1);
    assert.deepStrictEqual(pick(p1r, Object.keys(p1e)), p1e);
  });
});
