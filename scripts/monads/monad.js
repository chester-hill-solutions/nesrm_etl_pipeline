import logger from "simple-logs-sai-node";

const newExampleUnit = {
  response: {
    statusCode: 400,
    body: {
      trace: [],
    },
  },
  input: {},
  trace: [],
};

export const statusCodeMonad = {
  unit: (nonUnit) => {
    //logger.dev.log("nonUnit:", nonUnit);
    let ret = {};
    if (!nonUnit) {
      ret = {
        response: { statusCode: 200, body: { trace: [] } },
        input: nonUnit,
        trace: [],
      };
    } else if (!(nonUnit.input || nonUnit.response || nonUnit.trace)) {
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
    //logger.dev.log("monadic unit", JSON.stringify(ret, null, 2));
    return ret;
  },
  bindMonad: async (monadic, func) => {
    logger.log("\nbind", "to", func.name);
    logger.dev.log("monadic input", JSON.stringify(monadic.input, null, 2));
    let t = [{ step: func.__module, task: func.name }];
    let ret = {
      response: {
        statusCode: 200,
        body: {
          /*trace: t.map(({ output, ...rest }) => ({ ...rest }))*/
        },
      },
      //trace: t.map((obj) => ({ ...obj })),
    };
    //logger.dev.log("base ret", JSON.stringify(ret, null, 2));
    try {
      const rawFuncResponse = await func(monadic.input);
      if (rawFuncResponse) {
        //logger.dev.log("rawFuncResponse", rawFuncResponse);
        t[0].output = rawFuncResponse;
        //ret.input = rawFuncResponse ? rawFuncResponse : ret.input;
      }
    } catch (error) {
      console.error("caught", error);
      ret.response.statusCode = error.statusCode ? error.statusCode : 500;
      ret.response.body.message = error.message;
      t[0].output = error;
    }
    //ret.trace[0].input = monadic.input;
    t = t.concat(monadic.trace);
    ret.response.body.trace = t.map(({ output, ...rest }) => ({ ...rest }));
    ret.trace = t.map((obj) => ({ ...obj }));
    /*
    ret.response.body.trace = ret.response.body.trace.concat(
      monadic.response.body.trace
    );*/
    /*logger.dev.log(
      "Monadic",
      func.name,
      "return",
      JSON.stringify(ret, null, 2)
    );
    logger.log(
      "Monadic",
      func.name,
      "response",
      JSON.stringify(ret.response, null, 2)
    );
    logger.dev.log(
      "Monadic",
      func.name,
      "output",
      JSON.stringify(ret, null, 2)
    );*/
    logger.log(
      func.name,
      "bindMonad output",
      ret.response.statusCode === 200
        ? JSON.stringify(ret.response.statusCode, null, 2)
        : JSON.stringify(ret),
      "\n"
    );
    logger.dev.log("Full output", JSON.stringify(ret, null, 2));
    return ret;
  },
};
