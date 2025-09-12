import fs from "fs";

function attachHeader(obj, headers) {
  //logger.dev.log("attachHeader", obj);
  if (obj.body) {
    obj.headers = headers;
  } else {
    return {
      headers: headers,
      body: obj,
    };
  }
  return obj;
}

async function csvToJson(filePath) {
  const data = await fs.promises.readFile(filePath, "utf8");

  const [headerLine, ...lines] = data.trim().split("\n");
  const headers = headerLine.split(",");

  const result = lines.map((line) => {
    const values = line.split(",");
    return headers.reduce((obj, header, i) => {
      obj[header.trim()] = values[i]?.trim() ?? null;
      return obj;
    }, {});
  });

  return result;
}
export { attachHeader, csvToJson };
