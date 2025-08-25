const exampleUnit = {
  statusCode: 400,
  body: {
    trace: [],
  },
};

const newExampleUnit = {
  response: {
    statusCode: 400,
    body: {
      trace: [],
    },
  },
  input: {},
};
const removeKey = (obj, key) => {
  const { [key]: _, ...rest } = obj;
  return rest;
};
export const statusCodeMonad = {
  unit: (nonUnit) => {
    console.log("nonUnit:", nonUnit);
    let ret = {};
    if (!(nonUnit.input || nonUnit.response || nonUnit.trace)) {
      ret = {
        response: { statusCode: 200, body: { trace: [] } },
        input: nonUnit,
        trace: [],
      };
    } else {
      if (!nonUnit.response) {
        ret.response = {
          statusCode: 200,
          body: { trace: [] },
        };
      } else {
        ret.response = {};
        ret.response.statusCode = nonUnit.response.statusCode
          ? nonUnit.response.statusCode
          : 200;
        if (!nonUnit.response.body) {
          ret.response.body = { trace: [] };
        } else {
          ret.response.body = {};
          if (!nonUnit.response.body.trace) {
            ret.response.body.trace = [];
          } else {
            ret.response.body.trace = Array.isArray(nonUnit.response.body.trace)
              ? nonUnit.response.body.trace
              : [nonUnit.response.body.trace];
          }
        }

        if (!nonUnit.trace) {
          ret.trace = [...ret.response.body.trace];
        } else {
          ret.trace = nonUnit.trace;
        }
      }
      if (!nonUnit.input) {
        ret.input = undefined;
      } else {
        ret.input = nonUnit.input;
      }
    }
    console.log("monadic unit", JSON.stringify(ret));
    return ret;
  },
  bindMonad: async (monadic, func) => {
    console.log("\nbind", "to", func.name);
    let t = [{ step: func.__module, task: func.name }];
    let ret = {
      response: {
        statusCode: 200,
        body: { trace: t.map((obj) => ({ ...obj })) },
      },
      trace: t.map((obj) => ({ ...obj })),
    };
    try {
      const rawFuncResponse = await func(monadic.input);
      if (rawFuncResponse) {
        console.log("rawFuncResponse", rawFuncResponse);
        ret.trace[0].output = rawFuncResponse;
        ret.input = rawFuncResponse ? rawFuncResponse : ret.input;
      }
    } catch (error) {
      console.error(error);
      ret.response.statusCode = error.statusCode ? error.statusCode : 500;
      ret.response.trace[0].output = error;
    }
    //ret.trace[0].input = monadic.input;
    ret.trace = ret.trace.concat(monadic.trace);
    ret.response.body.trace = ret.response.body.trace.concat(
      monadic.response.body.trace
    );
    console.log("Monadic", func.name, "return", ret);
    console.log(
      "Monadic",
      func.name,
      "response body",
      JSON.stringify(ret.response.body)
    );
    console.log("Monadic", func.name, "output", ret.input);
    return ret;
  },
  middleunit: (response) => {
    //console.log("Unit", response);
    let result = {
      statusCode: response.statusCode ? response.statusCode : 200,
      body: {
        trace: [],
      },
    };
    if (response.body) {
      let body;
      if (
        typeof response.body === "string" ||
        response.body instanceof String
      ) {
        body = JSON.parse(response.body);
      } else {
        body = response.body;
      }
      if (body.trace) {
        if (!Array.isArray(body.trace)) {
          body.trace = [body.trace];
        }
      } else {
        body.trace = [];
      }
      result.body = body;
    }
    //console.log("unit result", result);
    return result;
  },
  middlebindMonad: async (response, input, func) => {
    if (func.__module) {
      console.log(func.__module);
    }
    console.log("\nbindMonad", func.name, JSON.stringify(response));
    let unit = statusCodeMonad.newunit
      ? statusCodeMonad.newunit
      : statusCodeMonad.unit;
    const unitResponse = unit(response);
    //console.log("unit response", JSON.stringify(unitResponse));
    const funcResult = await func(input);
    console.log(func.name, "result", JSON.stringify(funcResult));
    const funcOutput = funcResult.output ? funcResult.output : {};
    console.log(func.name, "output", JSON.stringify(funcOutput));
    const funcResponse = funcResult.response
      ? unit(funcResult.response)
      : unit(funcResult);
    console.log(func.name, "response", JSON.stringify(funcResponse), "\n");

    /*
    //console.log("funcResponse", funcResponse);
    //console.log("funcResponse body", funcResponse.body);
    //console.log("funcResponse body trace", funcResponse.body.trace);
    //console.log("funcResponse body trace first", funcResponse.body.trace[0]);*/
    funcResponse.body.trace = funcResponse.body.trace.concat(
      unitResponse.body.trace
    );
    //console.log(func.name, "concated", JSON.stringify(funcResponse), "\n");
    let result = {
      statusCode: funcResponse.statusCode
        ? funcResponse.statusCode
        : unitResponse.statusCode,
      body: funcResponse.body,
    };
    //console.log("bindMonad result", result);
    return { funcResponse, funcOutput };
  },
};
