import fs from "fs";
import { parse } from "csv-parse/sync";

function attachHeader(obj, headers, force=false) {
  let result;
  if (obj.body) {
    result = { headers: (obj.headers && force != true) ? obj.headers : headers, body: obj.body };
  } else {
    return {
      headers: headers,
      body: obj,
    };
  }
  return result;
}

async function csvToJson(filePath) {
  const data = await fs.promises.readFile(filePath, "utf8");

  const records = parse(data, {
    columns: true, // first row as headers
    skip_empty_lines: true,
    trim: true,
  });

  return records;
}
export { attachHeader, csvToJson };
