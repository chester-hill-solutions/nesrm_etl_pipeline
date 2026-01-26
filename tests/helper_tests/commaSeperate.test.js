import { commaSeperate, commaSeperateUpdateLogic } from "../../src/upsert.js";
import { describe, it } from "node:test";
import assert from "node:assert";

describe("commaSeperateUpdateLogic with csv string", () => {
  it("should merge one", async () => {
    const upsertData = {
      firstname: "John",
      surname: "Kennedy",
    };
    const profile = {
      firstname: "John",
      surname: "Kennedy",
      organizer: "LBJ",
      email: "jfk@convertible.ca",
    };
    const shapedData = {
      firstname: "Jack",
      surname: "Kennedy",
      organizer: "LBJ",
    };
    const expected = { ...upsertData, organizer: shapedData.organizer };
    const ret = commaSeperateUpdateLogic(
      upsertData,
      profile,
      shapedData,
      "organizer",
    );
    console.log("ret", ret);
    assert.deepEqual(ret, expected);
  });
  it("should merge one in the middle", async () => {
    const upsertData = {
      firstname: "John",
      surname: "Kennedy",
    };
    const profile = {
      firstname: "John",
      surname: "Kennedy",
      organizer: "RFK, LBJ,JackieKennedy",
      email: "jfk@convertible.ca",
    };
    const shapedData = {
      firstname: "Jack",
      surname: "Kennedy",
      organizer: "LBJ",
    };
    const expected = { ...upsertData, organizer: "RFK,LBJ,JackieKennedy" };
    const ret = commaSeperateUpdateLogic(
      upsertData,
      profile,
      shapedData,
      "organizer",
    );
    console.log("ret", ret);
    assert.deepEqual(ret, expected);
  });
    it("should merge many when shapedData is csv string", async () => {
    const upsertData = {
      firstname: "John",
      surname: "Kennedy",
    };
    const profile = {
      firstname: "John",
      surname: "Kennedy",
      organizer: "RFK,LBJ,JackieKennedy",
      email: "jfk@convertible.ca",
    };
    const shapedData = {
      firstname: "Jack",
      surname: "Kennedy",
      organizer: "RFK,LBJ,JackieKennedy",
    };
    const expected = { ...upsertData, organizer: shapedData.organizer };
    const ret = commaSeperateUpdateLogic(
      upsertData,
      profile,
      shapedData,
      "organizer",
    );
    console.log("ret", ret);
    assert.deepEqual(ret, expected);
  });
    it("should combine when shapedData is csv string", async () => {
    const upsertData = {
      firstname: "John",
      surname: "Kennedy",
    };
    const profile = {
      firstname: "John",
      surname: "Kennedy",
      organizer: "RFK,LBJ,JackieKennedy",
      email: "jfk@convertible.ca",
    };
    const shapedData = {
      firstname: "Jack",
      surname: "Kennedy",
      organizer: "Obamna,RFK,Eisenpower",
    };
    const expected = { ...upsertData, organizer: "RFK,LBJ,JackieKennedy,Obamna,Eisenpower" };
    const ret = commaSeperateUpdateLogic(
      upsertData,
      profile,
      shapedData,
      "organizer",
    );
    console.log("ret", ret);
    assert.deepEqual(ret, expected);
  });

});
describe("commaSeperateUpdateLogic with profile array", () => {
  it("should merge one", async () => {
    const upsertData = {
      firstname: "John",
      surname: "Kennedy",
    };
    const profile = {
      firstname: "John",
      surname: "Kennedy",
      organizer: ["LBJ"],
      email: "jfk@convertible.ca",
    };
    const shapedData = {
      firstname: "Jack",
      surname: "Kennedy",
      organizer: "LBJ",
    };
    const expected = { ...upsertData, organizer: shapedData.organizer };
    const ret = commaSeperateUpdateLogic(
      upsertData,
      profile,
      shapedData,
      "organizer",
    );
    console.log("ret", ret);
    assert.deepEqual(ret, expected);
  });
  it("should merge one in the middle", async () => {
    const upsertData = {
      firstname: "John",
      surname: "Kennedy",
    };
    const profile = {
      firstname: "John",
      surname: "Kennedy",
      organizer: ["RFK"," LBJ","JackieKennedy"],
      email: "jfk@convertible.ca",
    };
    const shapedData = {
      firstname: "Jack",
      surname: "Kennedy",
      organizer: "LBJ",
    };
    const expected = { ...upsertData, organizer: "RFK,LBJ,JackieKennedy" };
    const ret = commaSeperateUpdateLogic(
      upsertData,
      profile,
      shapedData,
      "organizer",
    );
    console.log("ret", ret);
    assert.deepEqual(ret, expected);
  });
    it("should merge many when shapedData is csv string", async () => {
    const upsertData = {
      firstname: "John",
      surname: "Kennedy",
    };
    const profile = {
      firstname: "John",
      surname: "Kennedy",
      organizer: ["RFK","LBJ","JackieKennedy"],
      email: "jfk@convertible.ca",
    };
    const shapedData = {
      firstname: "Jack",
      surname: "Kennedy",
      organizer: "RFK,LBJ,JackieKennedy",
    };
    const expected = { ...upsertData, organizer: shapedData.organizer };
    const ret = commaSeperateUpdateLogic(
      upsertData,
      profile,
      shapedData,
      "organizer",
    );
    console.log("ret", ret);
    assert.deepEqual(ret, expected);
  });
    it("should combine when shapedData is csv string", async () => {
    const upsertData = {
      firstname: "John",
      surname: "Kennedy",
    };
    const profile = {
      firstname: "John",
      surname: "Kennedy",
      organizer: ["RFK","LBJ","JackieKennedy"],
      email: "jfk@convertible.ca",
    };
    const shapedData = {
      firstname: "Jack",
      surname: "Kennedy",
      organizer: "Obamna,RFK,Eisenpower",
    };
    const expected = { ...upsertData, organizer: "RFK,LBJ,JackieKennedy,Obamna,Eisenpower" };
    const ret = commaSeperateUpdateLogic(
      upsertData,
      profile,
      shapedData,
      "organizer",
    );
    console.log("ret", ret);
    assert.deepEqual(ret, expected);
  });
});

describe("commaSeperateUpdateLogic with shapedData array", () => {
  it("should merge one", async () => {
    const upsertData = {
      firstname: "John",
      surname: "Kennedy",
    };
    const profile = {
      firstname: "John",
      surname: "Kennedy",
      organizer: "LBJ",
      email: "jfk@convertible.ca",
    };
    const shapedData = {
      firstname: "Jack",
      surname: "Kennedy",
      organizer: ["LBJ"],
    };
    const expected = { ...upsertData, organizer: profile.organizer };
    const ret = commaSeperateUpdateLogic(
      upsertData,
      profile,
      shapedData,
      "organizer",
    );
    console.log("ret", ret);
    assert.deepEqual(ret, expected);
  });
  it("should merge one in the middle", async () => {
    const upsertData = {
      firstname: "John",
      surname: "Kennedy",
    };
    const profile = {
      firstname: "John",
      surname: "Kennedy",
      organizer: "RFK, LBJ,JackieKennedy",
      email: "jfk@convertible.ca",
    };
    const shapedData = {
      firstname: "Jack",
      surname: "Kennedy",
      organizer: ["LBJ"],
    };
    const expected = { ...upsertData, organizer: "RFK,LBJ,JackieKennedy" };
    const ret = commaSeperateUpdateLogic(
      upsertData,
      profile,
      shapedData,
      "organizer",
    );
    console.log("ret", ret);
    assert.deepEqual(ret, expected);
  });
    it("should merge many when shapedData is csv string", async () => {
    const upsertData = {
      firstname: "John",
      surname: "Kennedy",
    };
    const profile = {
      firstname: "John",
      surname: "Kennedy",
      organizer: "RFK,LBJ,JackieKennedy",
      email: "jfk@convertible.ca",
    };
    const shapedData = {
      firstname: "Jack",
      surname: "Kennedy",
      organizer: ["RFK","LBJ","JackieKennedy"],
    };
    const expected = { ...upsertData, organizer: profile.organizer };
    const ret = commaSeperateUpdateLogic(
      upsertData,
      profile,
      shapedData,
      "organizer",
    );
    console.log("ret", ret);
    assert.deepEqual(ret, expected);
  });
    it("should combine when shapedData is csv string", async () => {
    const upsertData = {
      firstname: "John",
      surname: "Kennedy",
    };
    const profile = {
      firstname: "John",
      surname: "Kennedy",
      organizer: "RFK,LBJ,JackieKennedy",
      email: "jfk@convertible.ca",
    };
    const shapedData = {
      firstname: "Jack",
      surname: "Kennedy",
      organizer: ["Obamna","RFK","Eisenpower"],
    };
    const expected = { ...upsertData, organizer: "RFK,LBJ,JackieKennedy,Obamna,Eisenpower" };
    const ret = commaSeperateUpdateLogic(
      upsertData,
      profile,
      shapedData,
      "organizer",
    );
    console.log("ret", ret);
    assert.deepEqual(ret, expected);
  });

});

