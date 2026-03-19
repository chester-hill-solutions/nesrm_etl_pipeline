import { describe, it } from "node:test";
import assert from "node:assert";

import { statusCodeMonad } from "../monad.js";

describe("statusCodeMonad.unit", () => {
  it("returns default monadic value for undefined", () => {
    const actual = statusCodeMonad.unit(undefined);
    assert.deepEqual(actual, {
      response: { statusCode: 200, body: { trace: [] } },
      input: undefined,
      trace: [],
    });
  });

  it("returns default monadic value for null", () => {
    const actual = statusCodeMonad.unit(null);
    assert.deepEqual(actual, {
      response: { statusCode: 200, body: { trace: [] } },
      input: null,
      trace: [],
    });
  });

  it("wraps non-monadic objects as input", () => {
    const input = { foo: "bar" };
    const actual = statusCodeMonad.unit(input);

    assert.deepEqual(actual.response, {
      statusCode: 200,
      body: { trace: [] },
    });
    assert.deepEqual(actual.input, input);
    assert.deepEqual(actual.trace, []);
  });

  it("adds body.trace when response.body is missing", () => {
    const actual = statusCodeMonad.unit({ response: { statusCode: 201 } });

    assert.equal(actual.response.statusCode, 201);
    assert.deepEqual(actual.response.body, { trace: [] });
    assert.deepEqual(actual.trace, []);
  });

  it("coerces response.body.trace into an array", () => {
    const actual = statusCodeMonad.unit({
      response: { statusCode: 500, body: { trace: "single" } },
    });

    assert.deepEqual(actual.response.body.trace, ["single"]);
    assert.deepEqual(actual.trace, ["single"]);
  });

  it("uses provided trace over derived response trace", () => {
    const actual = statusCodeMonad.unit({
      response: { statusCode: 500, body: { trace: ["derived"] } },
      trace: ["override"],
      input: "payload",
    });

    assert.deepEqual(actual.response.body.trace, ["derived"]);
    assert.deepEqual(actual.trace, ["override"]);
    assert.equal(actual.input, "payload");
  });
});

describe("statusCodeMonad.bindMonad", () => {
  it("appends trace on success without supabase", async () => {
    const monadic = {
      input: { value: 1 },
      response: { statusCode: 200, body: { trace: [{ step: "prior" }] } },
      trace: [
        {
          step: "prior",
          task: "previousTask",
          input: "old-input",
          output: "old-output",
          duration: 1,
        },
      ],
    };

    let capturedInput;
    const successFunc = (input) => {
      capturedInput = input;
      return { ok: true };
    };
    successFunc.__module = "test-module";

    const actual = await statusCodeMonad.bindMonad(monadic, successFunc);

    assert.deepEqual(capturedInput, monadic.input);
    assert.equal(actual.response.statusCode, 200);
    assert.equal(actual.trace.length, 2);
    assert.deepEqual(actual.trace[1], monadic.trace[0]);
    assert.deepEqual(actual.trace[0].input, monadic.input);
    assert.deepEqual(actual.trace[0].output, { ok: true });
    assert.ok(typeof actual.trace[0].duration === "number");

    assert.equal(actual.response.body.trace.length, 3);
    assert.equal(actual.response.body.trace[0].step, "test-module");
    assert.equal(actual.response.body.trace[0].task, "successFunc");
    assert.ok(!("input" in actual.response.body.trace[0]));
    assert.ok(!("output" in actual.response.body.trace[0]));
    assert.equal(actual.response.body.trace[1].step, "prior");
    assert.equal(actual.response.body.trace[2].step, "prior");
  });

  it("appends trace on success with supabase", async () => {
    const monadic = {
      input: { value: 2 },
      response: { statusCode: 200, body: { trace: [] } },
      trace: [],
    };

    const supabase = { id: "sb" };
    let capturedArg;
    const successFunc = (arg) => {
      capturedArg = arg;
      return { ok: true };
    };
    successFunc.__module = "test-module";

    const actual = await statusCodeMonad.bindMonad(monadic, successFunc, supabase);

    assert.deepEqual(capturedArg, { input: monadic.input, supabase });
    assert.equal(actual.trace.length, 1);
    assert.equal(actual.response.body.trace.length, 1);
    assert.equal(actual.response.body.trace[0].step, "test-module");
  });

  it("sets message and status for non-429 errors", async () => {
    const monadic = {
      input: { value: 3 },
      response: { statusCode: 200, body: { trace: [] } },
      trace: [],
    };

    const errorFunc = () => {
      const error = new Error("boom");
      error.statusCode = 503;
      throw error;
    };
    errorFunc.__module = "test-module";

    const actual = await statusCodeMonad.bindMonad(monadic, errorFunc);

    assert.equal(actual.response.statusCode, 503);
    assert.equal(actual.response.body.message, "boom");
    assert.equal(actual.trace.length, 1);
    assert.equal(actual.trace[0].output.message, "boom");
    assert.equal(actual.response.body.trace.length, 1);
  });

  it("keeps status 200 for 429 errors", async () => {
    const monadic = {
      input: { value: 4 },
      response: { statusCode: 200, body: { trace: [] } },
      trace: [],
    };

    const errorFunc = () => {
      const error = new Error("rate limited");
      error.statusCode = 429;
      throw error;
    };
    errorFunc.__module = "test-module";

    const actual = await statusCodeMonad.bindMonad(monadic, errorFunc);

    assert.equal(actual.response.statusCode, 200);
    assert.ok(!("message" in actual.response.body));
    assert.equal(actual.trace.length, 1);
  });

  it("handles empty monadic.trace and empty response body trace", async () => {
    const monadic = {
      input: { value: 5 },
      response: { statusCode: 200, body: { trace: [] } },
      trace: [],
    };

    const successFunc = () => ({ ok: true });
    successFunc.__module = "test-module";

    const actual = await statusCodeMonad.bindMonad(monadic, successFunc);

    assert.equal(actual.trace.length, 1);
    assert.equal(actual.response.body.trace.length, 1);
    assert.equal(actual.response.body.trace[0].step, "test-module");
  });

  it("appends undefined when response.body.trace is missing", async () => {
    const monadic = {
      input: { value: 6 },
      response: { statusCode: 200, body: {} },
      trace: [],
    };

    const successFunc = () => ({ ok: true });
    successFunc.__module = "test-module";

    const actual = await statusCodeMonad.bindMonad(monadic, successFunc);

    assert.equal(actual.response.body.trace.length, 2);
    assert.equal(actual.response.body.trace[0].step, "test-module");
    assert.equal(actual.response.body.trace[1], undefined);
  });

  it("chains 4 binds and logs trace shapes", async () => {
    const monadic = statusCodeMonad.unit({ start: true });

    const stepOne = (input) => ({ step: "one", input });
    stepOne.__module = "mod-one";
    const stepTwo = (input) => ({ step: "two", input });
    stepTwo.__module = "mod-two";
    const stepThree = (input) => ({ step: "three", input });
    stepThree.__module = "mod-three";
    const stepFour = (input) => ({ step: "four", input });
    stepFour.__module = "mod-four";

    const first = await statusCodeMonad.bindMonad(monadic, stepOne);
    const second = await statusCodeMonad.bindMonad(first, stepTwo);
    const third = await statusCodeMonad.bindMonad(second, stepThree);
    const fourth = await statusCodeMonad.bindMonad(third, stepFour);

    const expectedShape = {
      trace: {
        mustHave: ["step", "task", "input", "output", "duration"],
        mustNotHave: [],
      },
      responseBodyTrace: {
        mustHave: ["step", "task", "duration"],
        mustNotHave: ["input", "output"],
      },
      expectedLength: 4,
    };

    console.log("chained bind trace", JSON.stringify(fourth.trace, null, 2));
    console.log(
      "chained bind response.body.trace",
      JSON.stringify(fourth.response.body.trace, null, 2)
    );
    console.log("expected shape", JSON.stringify(expectedShape, null, 2));

    assert.equal(fourth.trace.length, 4);
    assert.equal(fourth.response.body.trace.length, 4);

    assert.ok("input" in fourth.trace[0]);
    assert.ok("output" in fourth.trace[0]);
    assert.ok(!("input" in fourth.response.body.trace[0]));
    assert.ok(!("output" in fourth.response.body.trace[0]));

    assert.equal(fourth.trace[0].step, "mod-four");
    assert.equal(fourth.trace[1].step, "mod-three");
    assert.equal(fourth.trace[2].step, "mod-two");
    assert.equal(fourth.trace[3].step, "mod-one");

    assert.equal(fourth.response.body.trace[0].step, "mod-four");
    assert.equal(fourth.response.body.trace[1].step, "mod-three");
    assert.equal(fourth.response.body.trace[2].step, "mod-two");
    assert.equal(fourth.response.body.trace[3].step, "mod-one");
  });
});
