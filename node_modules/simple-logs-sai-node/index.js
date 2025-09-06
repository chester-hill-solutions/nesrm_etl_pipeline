// logger.js

// Helper to wrap console methods dynamically
const dev = new Proxy(
  {},
  {
    get(_, method) {
      return (...args) => {
        // Evaluate environment at call time
        const isDev =
          !process.env.ENVIRONMENT ||
          process.env.ENVIRONMENT === "DEVELOPMENT" ||
          process.env.ENVIRONMENT === "DEV";

        if (!isDev) return; // skip logging in production

        if (console[method]) {
          console[method](...args);
        } else {
          console.log(...args);
        }
      };
    },
  }
);

// Regular log that always logs
function log(...args) {
  console.log(...args);
}

export default { dev, log };
