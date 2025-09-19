import HttpError from "simple-http-error";
import logger from "simple-logs-sai-node";
import "dotenv/config";
import path from "node:path";
import { bestMatch } from "../scripts/mailReconcile/index.js";

const HEADERS = {
  Authorization: "Bearer " + process.env.MAIL_BEARER,
  "Content-Type": "application/json",
};

const easyPost = async (obj) => {
  let data = structuredClone(obj);
  let payload = {};
  if (data.email) {
    payload.email = data.email;
    delete data.email;
    let headers = {
      Authorization: "Bearer " + process.env.MAIL_BEARER,
      "Content-Type": "application/json",
    };
    try {
      const response = await fetch(
        "https://" + process.env.MAIL_HOSTNAME + "/api/subscribers",
        {
          method: "POST",
          headers: HEADERS,
          body: JSON.stringify({ email: payload.email, fields: data }),
        }
      );
      const out = await response.json();
      console.log(response.status);
      console.log(out);
    } catch (error) {
      console.log("data", data);
      console.error(error);
      throw new error();
    }
  }
};

const old = async (data) => {
  return await easyPost(data);
};

const replaceKey = async (obj, old, n) => {
  if (old in obj) obj[n] = obj[old];
  delete obj[old];
  return obj;
};

const shapeForMail = async (data) => {
  let cleaned = structuredClone(data);
  replaceKey(cleaned, "surname", "last_name");
  replaceKey(cleaned, "division", "state");
  replaceKey(cleaned, "firstname", "name");
  replaceKey(cleaned, "postcode", "z_i_p");
  replaceKey(cleaned, "municipality", "city");
  return cleaned;
};
const post = async (payload) => {
  try {
    const response = await fetch(
      "https://" + process.env.MAIL_HOSTNAME + "/api/subscribers",
      {
        method: "POST",
        headers: HEADERS,
        body: JSON.stringify({ email: payload.email, fields: payload }),
      }
    );
    const out = await response.json();
    console.log(response.status);
    if (response.status >= 300) {
      throw new HttpError(out.message, response.status);
    }
    logger.dev.log(out);
    return out;
  } catch (error) {
    console.log("data", payload);
    console.error(error);
    throw new HttpError(error.message, error.statusCode ?? 500, {
      originalError: error,
    });
  }
};
const mail = async (obj, reconcile = true) => {
  let data = obj.mailerlite_id
    ? structuredClone(obj)
    : obj.body?.mailerlite_id
    ? structuredClone(obj.body)
    : obj.email
    ? structuredClone(obj)
    : obj.body?.email
    ? structuredClone(obj.body)
    : (() => {
        throw new HttpError("Missing email or id to upload", 500);
      })();
  let payload = await shapeForMail(data);
  let mailData;
  try {
    mailData = await get(data.mailerlite_id || data.email);
  } catch (error) {
    console.error(error);
    throw new HttpError(error.message, error.statusCode ?? 500, {
      originalError: error,
    });
  }
  if (mailData?.data?.fields && mailData?.data?.email) {
    mailData.data.fields.email = mailData.data.email;
    try {
      payload = reconcile
        ? await reconcileNames(mailData.data.fields, payload)
        : payload;
    } catch (e) {}
  }
  return await post(payload);
};

const get = async (email) => {
  try {
    logger.dev.log("get", email);
    const response = await fetch(
      "https://" + process.env.MAIL_HOSTNAME + "/api/subscribers/" + email,
      {
        method: "GET",
        headers: HEADERS,
      }
    );
    const out = await response.json();
    logger.log("Mailerlite get response", response.status);
    if (response.status === 404) {
      return undefined;
    }
    logger.dev.log("response", out);
    return out;
  } catch (error) {
    logger.log("email", email);
    logger.error(error);
    throw new HttpError(`Error GET ${email}`, 500, { originalError: error });
  }
};

async function longestSubstringMatch(text, word) {
  text = text.toLowerCase();
  word = word.toLowerCase();

  let maxLen = 0;
  for (let i = 0; i < word.length; i++) {
    for (let j = i + 1; j <= word.length; j++) {
      const sub = word.slice(i, j);
      if (text.includes(sub)) {
        maxLen = Math.max(maxLen, sub.length);
      }
    }
  }
  return maxLen;
}

async function scoreNameSet(email, { firstname, surname }) {
  logger.dev.log("scoreNameSet", email, firstname, surname);
  const firstScore = await longestSubstringMatch(email, firstname);
  const lastScore = await longestSubstringMatch(email, surname);
  logger.dev.log("scores", firstScore + lastScore);
  return firstScore + lastScore;
}

async function oldbestMatch(email, setA, setB) {
  logger.dev.log("bestMatch", email, setA, setB);
  if (setA.firstname == setB.firstname && setA.surname == setB.surname)
    return setA;
  const scoreA = await scoreNameSet(email, setA);
  const scoreB = await scoreNameSet(email, setB);
  if (scoreA > scoreB) return setA;
  if (scoreB > scoreA) return setB;

  return setB;
}

const reconcileNames = async (mailData, dbData) => {
  logger.dev.log("reconcileNames");
  if (
    !mailData.email ||
    !mailData.name ||
    !mailData.last_name ||
    !dbData.name ||
    !dbData.last_name
  ) {
    logger.dev.log("missing fields");
    logger.dev.log(
      mailData.email,
      mailData.name,
      mailData.last_name,
      dbData.name,
      dbData.last_name
    );
    logger.dev.error(mailData);
    logger.dev.error(dbData);
    throw new Error("Missing fields");
  }
  let output = structuredClone(dbData);
  logger.dev.log("original output", output);
  const truthData = await bestMatch(
    mailData.email,
    { firstname: mailData.name, surname: mailData.last_name },
    { firstname: dbData.name, surname: dbData.last_name }
  );
  output.name = truthData.firstname;
  output.last_name = truthData.surname;
  return output;
};

mail.__module = path.basename(import.meta.url);
export { mail, get, reconcileNames, post };
