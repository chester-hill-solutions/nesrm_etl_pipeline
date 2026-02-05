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

const shapeForMail = async (cleaned, groups=undefined) => {

  const body = {
    email: cleaned.email,
    fields: Object.fromEntries(
      Object.entries(cleaned).filter(([_, v]) => v !== null),
    ),
    groups: groups
  }
  const hasDoNotContact = Array.isArray(cleaned.tags)
      ? cleaned.tags.some(t => t.toUpperCase().includes("DO NOT CONTACT"))
      : typeof cleaned.tags === "string"
        ? cleaned.tags.toUpperCase().includes("DO NOT CONTACT")
        : false;

  hasDoNotContact ?? (body.status = 'unsubscribed');
  logger.log("dnc status", hasDoNotContact);
  if (groups){
    body.groups = groups
  }

  logger.dev.log("shaped mail payload", body);
  return body
}

const cleanForMail = async (data, groups=undefined) => {
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
  delete cleaned.groups;
  logger.dev.log("cleaned mail payload", cleaned);
  return cleaned;
};
const post = async (payload, id = undefined) => {
  try {
    let path = "/api/subscribers";
    id ? (path = path + "/" + id) : (path = path);
    console.log(HEADERS)
    const response = await fetch(
      "https://" + process.env.MAIL_HOSTNAME + path,
      {
        method: id ? "PUT" : "POST",
        headers: HEADERS,
        body: JSON.stringify(payload),
      },
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
        payload,
        null,
        2,
      ),
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
    console.log(HEADERS)
    const response = await fetch(
      "https://" + process.env.MAIL_HOSTNAME + "/api/subscribers/" + email,
      {
        method: "GET",
        headers: HEADERS,
      },
    );
    const out = await response.json();
    logger.log("Mailerlite get response", response.status);
    if (!response.ok) {
      throw new HttpError(
        out?.message ?? "Mailerlite request failed",
        response.status,
        { response: out, status: response.status },
      );
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
      dbData.last_name,
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
      { firstname: dbData.name, surname: dbData.last_name },
    );
    output.name = truthData.firstname;
    output.last_name = truthData.surname;
  }
  return output;
};
const mail = async (obj, reconcile = true) => {
  HEADERS.Authorization = "Bearer " + process.env.MAIL_BEARER
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
  let mailData;
  try {
    mailData = await get(data.email || data.mailerlite_id);
  } catch (error) {
    console.error("getMailData error", error);
    mailData = undefined
    if (error.StatusCode != 404) {
      throw new HttpError(error.message, error.statusCode ?? 500, {
        originalError: error,
      });
    }
  }
  let cleaned = await cleanForMail(data, data.groups ?? undefined);
  if (mailData?.data?.fields && mailData?.data?.email) {
    mailData.data.fields.email = mailData.data.email;
    try {
      cleaned =
        reconcile && process.env.RECONCILE != false
          ? await reconcileNames(mailData.data.fields, cleaned)
          : cleaned;
    } catch (e) { }
  }
  let payload = await shapeForMail(cleaned, data.groups ?? undefined)
  if (mailData?.data?.id) {
    console.log("post with id");
    return await post(payload, mailData?.data?.id);
  } else {
    return await post(payload);
  }
};

mail.__module = path.basename(import.meta.url);
export { mail, get, reconcileNames, post };
