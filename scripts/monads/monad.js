import logger from "simple-logs-sai-node";
import { performance } from "perf_hooks";

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
    logger.log("nonUnit:", nonUnit);
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
    logger.log("monadic unit", JSON.stringify(ret, null, 2));
    return ret;
  },
  bindMonad: async (monadic, func) => {
    logger.log("bind", "to", func.name);
    logger.dev.log("monadic input", JSON.stringify(monadic.input, null, 2));
    let t = [{ step: func.__module, task: func.name, input: monadic.input }];
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
    const start = performance.now();
    try {
      const rawFuncResponse = await func(monadic.input);

      if (rawFuncResponse) {
        //logger.dev.log("rawFuncResponse", rawFuncResponse);
        t[0].output = rawFuncResponse;
        //ret.input = rawFuncResponse ? rawFuncResponse : ret.input;
        logger.dev.log("bind no error t", t)
        logger.dev.og("bind no error ret", ret)
        logger.dev.log("bind no error monadic", monadic);
      }
    } catch (error) {
      logger.log("bind error", error);
      t[0].output = error;
      if (error.statusCode === 429) {
        ret.response.statusCode = 200;
        t[0].statusCode === 429;
      } else {
        console.error("monadic input", monadic.input);
        console.error("caught", error);
        ret.response.statusCode = error.statusCode ? error.statusCode : 500;
        ret.response.body.message = error.message;
      }
      logger.log("bind error t", t);
      logger.log("bind error ret", ret);
      logger.dev.log("bind error monadic", monadic);
    }
    const end = performance.now();
    t[0].duration = end - start;
    //ret.trace[0].input = monadic.input;
    t = t.concat(monadic.trace);
    ret.response.body.trace = t.map(({ input, output, ...rest }) => ({
      ...rest,
    }));
    ret.trace = t.map((obj) => ({ ...obj }));
    
    ret.response.body.trace = ret.response.body.trace.concat(
      monadic.response.body.trace
    );
    ret.response.statusCode === 200 ? logger.log(
      "Monadic",
      func.name,
      "output",
      JSON.stringify(ret, null, 2)
    ) : null;
    logger.log(
      func.name,
      "bindMonad output",
      ret.response.statusCode === 200
        ? JSON.stringify(ret.response.statusCode, null, 2)
        : JSON.stringify(ret, null, 2)
    );
    //logger.dev.log("Full output", JSON.stringify(ret, null, 2));
    return ret;
  },
};
