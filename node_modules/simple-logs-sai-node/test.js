import logger from "./index.js";

function testList(text) {
  logger.log("prod log", text);
  logger.dev.log("dev log", text);
}

function main() {
  console.log("Enter simple-logs-sai-node");
  testList(process.env.ENVIRONMENT);
  process.env.ENVIRONMENT = "DEV";
  testList(process.env.ENVIRONMENT);
  process.env.ENVIRONMENT = "PRODUCTION";
  testList(process.env.ENVIRONMENT);
  process.env.ENVIRONMENT = "DEVELOPMENT";
  testList(process.env.ENVIRONMENT);
  logger.log("logger.log", "one", "two", "tree");
  logger.dev.log("logger.dev.log", "one", "two", "tree");
}
main();
