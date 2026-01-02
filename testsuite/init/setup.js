import "../../loadEnv.js";
console.log("NODE_ENV", process.env.NODE_ENV);
console.log("ENVIRONMENT", process.env.ENVIRONMENT);
const originalLog = console.log;
const buffer = [];

console.log = (...args) => buffer.push(args.join(" "));
console.info = console.log;
console.error = console.log;

// Re-enable logging if a test fails
process.on("test:fail", () => {
  for (const msg of buffer) originalLog(msg);
});

// Clean buffer when test passes
process.on("test:pass", () => (buffer.length = 0));
