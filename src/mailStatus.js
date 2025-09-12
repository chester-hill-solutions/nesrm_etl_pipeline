import HttpError from "simple-http-error";
import logger from "simple-logs-sai-node";
import "dotenv/config";
import path from "node:path";

const post = async (obj) => {
  let data = structuredClone(obj);
  let payload = {};
  if (data.email) {
    payload.email = data.email;
    delete data.email;
    data.city = data.municipality;
    delete data.municipality;
    data.state = data.division;
    delete data.division;
    data.last_name = data.surname;
    delete data.surname;
    data.name = data.firstname;
    delete data.firstname;
    data["z_i_p"] = data.postcode;
    let headers = {
      Authorization: "Bearer " + process.env.MAIL_BEARER,
      "Content-Type": "application/json",
    };
    try {
      const response = await fetch(
        "https://" + process.env.MAIL_HOSTNAME + "/api/subscribers",
        {
          method: "POST",
          headers: headers,
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

const mailStatus = async (data) => {
  return await post(data);
};

mailStatus.__module = path.basename(import.meta.url);
export { mailStatus };
