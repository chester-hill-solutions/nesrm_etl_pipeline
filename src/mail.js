import HttpError from "simple-http-error";
import logger from "simple-logs-sai-node";
//import "dotenv/config";
import path from "node:path";
import { bestMatch } from "../scripts/mailReconcile/index.js";

const HEADERS = {
  Authorization: "Bearer " + process.env.MAIL_BEARER,
  "Content-Type": "application/json",
};

const replaceKey = async (obj, old, n) => {
  if (old in obj) obj[n] = obj[old];
  delete obj[old];
  return obj;
};

const shapeForMail = async (data) => {
  let cleaned = structuredClone(data);
  logger.dev.log("dirty mail payload", data);
  replaceKey(cleaned, "surname", "last_name");
  replaceKey(cleaned, "division", "state");
  replaceKey(cleaned, "firstname", "name");
  replaceKey(cleaned, "postcode", "z_i_p");
  replaceKey(cleaned, "municipality", "city");
  delete cleaned.created_at;
  delete cleaned.updated_at;
  delete cleaned.id;
  logger.dev.log("clean mail payload", cleaned);
  return cleaned;
};
const post = async (payload, id = undefined) => {
  try {
    let path = "/api/subscribers";
    id ? (path = path + "/" + id) : (path = path);
    const response = await fetch(
      "https://" + process.env.MAIL_HOSTNAME + path,
      {
        method: id ? "PUT" : "POST",
        headers: HEADERS,
        body: JSON.stringify({
          email: payload.email,
          fields: Object.fromEntries(
            Object.entries(payload).filter(([_, v]) => v !== null)
          ),
        }),
      }
    );
    const out = await response.json();
    logger.log("post status", response.status);
    if (response.status >= 300) {
      throw new HttpError(out.message, response.status, {
        originalError: out,
      });
    }
    logger.dev.log(out);
    return out;
  } catch (error) {
    logger.log(
      "post payload",
      JSON.stringify(
        {
          email: payload.email,
          fields: Object.fromEntries(
            Object.entries(payload).filter(([_, v]) => v !== null)
          ),
        },
        null,
        2
      )
    );
    logger.error(error);
    throw new HttpError(error.message, error.statusCode ?? 500, {
      originalError: error,
    });
  }
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
const reconcileNames = async (mailData, dbData) => {
  let output = structuredClone(dbData);
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
    logger.dev.error("mailData", mailData);
    logger.dev.error("dbData", dbData);
    output.name = dbData.name ?? mailData.name ?? null;
    output.last_name = dbData.last_name ?? mailData.last_name ?? null;
  } else {
    logger.dev.log("original output", output);
    const truthData = await bestMatch(
      mailData.email,
      { firstname: mailData.name, surname: mailData.last_name },
      { firstname: dbData.name, surname: dbData.last_name }
    );
    output.name = truthData.firstname;
    output.last_name = truthData.surname;
  }
  return output;
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
        throw new HttpError("Missing email or id to upload", 422);
      })();
  let payload = await shapeForMail(data);
  let mailData;
  try {
    mailData = await get(data.email || data.mailerlite_id);
  } catch (error) {
    console.error("getMailData error", error);
    throw new HttpError(error.message, error.statusCode ?? 500, {
      originalError: error,
    });
  }
  if (mailData?.data?.fields && mailData?.data?.email) {
    mailData.data.fields.email = mailData.data.email;
    try {
      payload =
        reconcile && process.env.RECONCILE != false
          ? await reconcileNames(mailData.data.fields, payload)
          : payload;
    } catch (e) {}
  }
  if (mailData?.data?.id) {
    console.log("post with id");
    return await post(payload, mailData?.data?.id);
  } else {
    return await post(payload);
  }
};

mail.__module = path.basename(import.meta.url);
export { mail, get, reconcileNames, post };
