import test, { describe, it } from "node:test";
import assert from "node:assert";
import "dotenv/config";
import { pick, keyCompare } from "../../scripts/pickKeys/index.js";
import { mail, get, reconcileNames, post } from "../../src/mail.js";
import logger from "simple-logs-sai-node";

describe("mail get tests", () => {
  it("should return undefined since email doesn't exist", async () => {
    const r = await get("shjkfsdjksdfbn");
    assert.strictEqual(r, undefined);
  });
  it("should return sai's data", async () => {
    const r = await get("saihaansyedprofiles@gmail.com");
    const e = {
      data: {
        email: "saihaansyedprofiles@gmail.com",
      },
    };
    assert.deepStrictEqual(keyCompare(r, e), e);
  });
});

describe("reconcileNames test", () => {
  it("it should return the p2 names since p2 has the right name", async () => {
    const p1 = {
      email: "kebbieq@sympatico.com",
      name: "Jen",
      last_name: "Myers",
    };
    const p2 = {
      email: "kebbieq@sympatico.com",
      name: "Kebra",
      last_name: "Queen",
      otherData: "blah",
    };
    assert.deepStrictEqual(await reconcileNames(p1, p2), p2);
  });
});

describe("post test", () => {
  it("should change sai's address data", async () => {
    const p1 = {
      email: "saihaansyedprofiles@gmail.com",
      street_address: "552 Road Ave",
    };
    const p1r = await post(p1);
    assert.strictEqual(p1r.data.fields.street_address, p1.street_address);
    const p2 = {
      email: "saihaansyedprofiles@gmail.com",
      street_address: "553 Road Ave",
    };
    const p2r = await post(p2);
    assert.deepStrictEqual(
      { sa: p2r.data.fields.street_address, id: p2r.data.id },
      { sa: p2.street_address, id: p1r.data.id }
    );
  });
  it("should return safely if hits 429", async () => {
    let response = 429;
    const p1 = {
      email: "saihaansyedprofiles@gmail.com",
      street_address: "552 Road Ave",
    };
    let index = 0;
    process.env.ENVIRONMENT = "PRODUCTION";
    while (response != 429) {
      index++;
      console.log(index);
      try {
        response = await post(p1);
      } catch (error) {
        console.log(error);
        assert.strictEqual(error.statusCode, 429);
      }
      if (index > 240) {
        break;
      }
    }
    process.env.ENVIRONMENT = "DEVELOPMENT";
    const p2 = {
      email: "saihaansyedprofiles@gmail.com",
      street_address: "553 Road Ave",
    };
  });
});
