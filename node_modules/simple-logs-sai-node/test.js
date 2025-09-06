import cons from "./index.js";

function testList(text) {
  cons.log("prod log", text);
  cons.dev.log("dev log", text);
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
}
main();
