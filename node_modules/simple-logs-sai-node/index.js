// index.js

function isProd() {
  const env = (
    process.env.ENVIRONMENT ||
    process.env.NODE_ENV ||
    ""
  ).toLowerCase();
  return env === "production" || env === "prod";
}

const dev = new Proxy(
  {},
  {
    get(_, method) {
      return (...args) => {
        if (isProd()) return;

        if (console[method]) {
          console[method](...args);
        } else {
          console.log(...args);
        }
      };
    },
  }
);

const logger = {
  dev,

  log: (...args) => console.log(...args),
  error: (...args) => console.error(...args),
  /**
   * Logs messages differently depending on environment and arguments.
   *
   * Usage:
   *   logger.logd("prod message", ["dev message"]);
   *
   * Behavior:
   *   - If the last argument is an array:
   *       • In DEV mode: logs the contents of the array (dev-only output).
   *       • In PROD mode: logs everything except the last array (prod output).
   *   - If there is only a single argument (not an array):
   *       • Logs it normally in both DEV and PROD.
   *   - Otherwise:
   *       • Logs all arguments as-is in both environments.
   *
   * Examples:
   *   // ENVIRONMENT=DEVELOPMENT
   *   logger.logd("hello", ["debug details"]); // prints: debug details
   *   logger.logd("hello");                    // prints: hello
   *
   *   // ENVIRONMENT=PRODUCTION
   *   logger.logd("hello", ["debug details"]); // prints: hello
   *   logger.logd("hello");                    // prints: hello
   */
  logd: (...args) => {
    if (args.length === 0) return;

    const lastArg = args[args.length - 1];

    if (Array.isArray(lastArg)) {
      const prodArgs = args.slice(0, -1);
      const devArgs = lastArg;

      if (isProd()) {
        console.log(...prodArgs);
      } else {
        console.log(...devArgs);
      }
    } else {
      console.log(...args);
    }
  },
};

export default logger;
