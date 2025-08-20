const exampleUnit = {
  statusCode: 400,
  body: {
    trace: [],
  },
};

export const statusCodeMonad = {
  unit: (response) => {
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
  oldunit: (response) => {
    //console.log("pre change", response);
    let res = {
      statusCode: response.statusCode ? response.statusCode : null,
      body: JSON.stringify([{ ...response.body }]),
    };
    //console.log("Unit,", res);
    return res;
  },
  bindMonad: async (response, input, func) => {
    //console.log("bindMonad");
    let unit = statusCodeMonad.newunit
      ? statusCodeMonad.newunit
      : statusCodeMonad.unit;
    const unitResponse = unit(response);
    const funcResult = unit(await func(input));
    const funcResponse = funcResult.response ? funcResult.response : funcResult;
    const funcOutput = funcResult.output ? funcResult.ouput : {};

    /*
    console.log("funcResponse", funcResponse);
    console.log("funcResponse body", funcResponse.body);
    console.log("funcResponse body trace", funcResponse.body.trace);
    console.log("funcResponse body trace first", funcResponse.body.trace[0]);*/
    funcResponse.body.trace.concat(unitResponse.body.trace);
    let result = {
      statusCode: funcResponse.statusCode
        ? funcResponse.statusCode
        : unitResponse.statusCode,
      body: funcResponse.body,
    };
    //console.log("bindMonad result", result);
    return { funcResponse, funcOutput };
  },
  oldbindMonad: async (response, input, func) => {
    //console.log(response);
    const result = await func(input);
    //console.log("Func result:", result);
    return {
      statusCode: result.statusCode,
      body: JSON.stringify(
        JSON.parse(statusCodeMonad.unit(result).body).concat(
          JSON.parse(response.body)
        )
      ),
    };
  },
};
