import { describe, it } from "node:test";
import assert from "node:assert";

import { shapeData } from "../src/shape.js";

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
          street: "442 Pharmacy Ave",
          city: "Scarborough",
          state: "Ontario",
          postal: "M1L 3G6",
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
      street_address: "442 Pharmacy Ave",
      municipality: "Scarborough",
      district: "Ontario",
      postcode: "M1L 3G6",
      country: "CA",
    };
    const result = await shapeData(payload);
    assert.deepStrictEqual(result.body, expected);
  });
});
