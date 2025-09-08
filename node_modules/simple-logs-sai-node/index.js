// index.js

const dev = new Proxy(
  {},
  {
    get(_, method) {
      return (...args) => {
        const isDev =
          !process.env.ENVIRONMENT ||
          process.env.ENVIRONMENT === "DEVELOPMENT" ||
          process.env.ENVIRONMENT === "DEV";

        if (!isDev) return;

        if (console[method]) {
          console[method](...args);
        } else {
          console.log(...args);
        }
      };
    },
  }
);

function log(...args) {
  console.log(...args);
}

function logd(...args) {
  const isDev =
    !process.env.ENVIRONMENT ||
    process.env.ENVIRONMENT === "DEVELOPMENT" ||
    process.env.ENVIRONMENT === "DEV";

  if (args.length === 0) return;

  const lastArg = args[args.length - 1];

  if (Array.isArray(lastArg)) {
    const prodArgs = args.slice(0, -1);
    const devArgs = lastArg;

    if (isDev) {
      console.log(...devArgs);
    } else {
      console.log(...prodArgs);
    }
  } else {
    console.log(...args);
  }
}

const logger = { dev, log, logd };
export default logger;
