import path from "path";
import HttpError from "simple-http-error";
import logger from "simple-logs-sai-node";
import cleanString from "../scripts/cleanString.js";
import { combineCommaSeperate } from "../scripts/commaSeperateHelpers.js";

/*
const cleanString = (str) => {
  //If string is empty return undefined
  if (str === null || str === undefined) return undefined;
  //trim either side of string
  const s = collapseSpaces(String(str).trim());
  let cleaned = s.replace(/^,+|,+$/g, "").replace(/\\(?=['"])/g, "");
  return cleaned === "" ? undefined : cleaned;
};
*/
const cleanEmail = (str) => {
  if (typeof str !== "string") return str;

  // 1. Remove leading periods
  let cleaned = str.replace(/^\.+/, "");

  // 2. Remove trailing periods
  cleaned = cleaned.replace(/\.+$/, "");

  // 3. Remove all periods immediately before @
  cleaned = cleaned.replace(/\.+(?=@)/g, "");

  return cleaned;
};
//get value
export const getValue = (payload, key) => {
  // Check form fields format
  if (payload[`fields[${key}][value]`] !== undefined) {
    return payload[`fields[${key}][value]`];
  }
  // Check nested fields object
  if (payload.fields && payload.fields[key] !== undefined) {
    return payload.fields[key];
  }
  // Check direct properties
  if (payload[key] !== undefined) {
    return payload[key];
  }
  return undefined;
};

const shapeData = async (event) => {
  logger.dev.log("shaping", JSON.stringify(event, null, 2));
  if (!event.body) {
    throw new HttpError("Missing body", 422);
  }
  let body;
  try {
    body = JSON.parse(event.body);
  } catch (error) {
    body = event.body;
  }
  logger.log("body to shape", body);

  try {
    let shaped_data = {
      firstname: cleanString(getValue(body, "firstname")),
      surname: cleanString(getValue(body, "surname")),
      email: cleanEmail(cleanString(getValue(body, "email"))),
      phone: cleanString(getValue(body, "phone")),

      // Birth date information
      ...(() => {
        const birthData = {};
        const dob = cleanString(getValue(body, "dob"));
        let birthdate = parseInt(cleanString(getValue(body, "birthdate")));
        let birthmonth = parseInt(cleanString(getValue(body, "birthmonth")));
        let birthyear = parseInt(cleanString(getValue(body, "birthyear")));

        if (
          birthdate &&
          birthmonth &&
          birthyear &&
          !isNaN(Date.parse(`${birthyear}-${birthmonth}-${birthdate}`))
        ) {
          Object.assign(birthData, { birthyear, birthmonth, birthdate });
          if (dob) {
            birthData.broken_dob = dob;
          }
        } else if (dob) {
          const [birthyear, birthmonth, birthdate] = dob.split("-");
          if (!isNaN(Date.parse(`${birthyear}-${birthmonth}-${birthdate}`))) {
            Object.assign(birthData, { birthyear, birthmonth, birthdate });
          } else {
            birthData.broken_dob = dob;
          }
        }
        return birthData;
      })(),

      ...(() => {
        let addressData = {};

        let addressCat = getValue(body, "address");
        let isObject = addressCat && typeof addressCat === "object";

        logger.dev.log(
          isObject ? "addressCategoryExists" : "no address category",
        );

        let addressSource = isObject ? addressCat : body;

        addressData.street_address =
          cleanString(getValue(addressSource, "street_address")) ||
          cleanString(getValue(addressSource, "street")) ||
          (!isObject && cleanString(addressCat));

        addressData.municipality = cleanString(
          getValue(addressSource, "municipality"),
        )
          ? cleanString(getValue(addressSource, "municipality"))
          : cleanString(getValue(addressSource, "city"));

        addressData.division = cleanString(getValue(addressSource, "division"))
          ? cleanString(getValue(addressSource, "division"))
          : cleanString(getValue(addressSource, "province"))
            ? cleanString(getValue(addressSource, "province"))
            : cleanString(getValue(addressSource, "state"));

        addressData.region = cleanString(getValue(addressSource, "region"));
        addressData.county = cleanString(getValue(addressSource, "county"));
        addressData.country = cleanString(getValue(addressSource, "country"));

        addressData.postcode = cleanString(getValue(addressSource, "postcode"))
          ? cleanString(getValue(addressSource, "postcode"))
          : cleanString(getValue(addressSource, "postal"));
        logger.dev.log("addressData", addressData);

        return addressData;
      })(),
      federal_electoral_district: cleanString(
        getValue(body, "federal_electoral_district"),
      ),
      division_electoral_district: cleanString(
        getValue(body, "division_electoral_district"),
      ),
      municipal_electoral_district: cleanString(
        getValue(body, "municipal_electoral_district"),
      ),

      ballot1: cleanString(getValue(body, "ballot1")),
      ballot2: cleanString(getValue(body, "ballot2")),
      ballot3: cleanString(getValue(body, "ballot3")),
      campus_club: cleanString(
        getValue(body, "campus_club") ?? getValue(body, "campusClub"),
      ),
      womens_club: cleanString(
        getValue(body, "womens_club") ?? getValue(body, "womensClub"),
      ),

      comms_consent: cleanString(getValue(body, "comms_consent")),
      signup_consent: (() => {
        let val = cleanString(getValue(body, "signup_consent"));
        if (val && val != false && val != "false") {
          return true;
        }
        return undefined;
      })(),
      signup_submitted: cleanString(getValue(body, "signup_submitted")),
      member: cleanString(getValue(body, "member")),
      tags: cleanString(getValue(body, "tags")),
      ...(() => {
        let organizer = cleanString(getValue(body, "organizer"));

        let organizer_codes = getValue(body, "organizer_codes");

        console.log('combining', organizer, organizer_codes, typeof(organizer_codes))
        const combined = combineCommaSeperate(
          organizer,
          organizer_codes,
          "array",
        );
        if (combined) {
        organizer_codes = combined;
        organizer = combined.join(",");
        }
        return { organizer, organizer_codes };
      })(),
      language: cleanString(getValue(body, "language")),
      olp_van_id: cleanString(getValue(body, "olp_van_id")),
      lpc_van_id: cleanString(getValue(body, "lpc_van_id")),
      ...(() => {
        let o = { gender: cleanString(getValue(body, "gender")) };
        let g = cleanString(getValue(body, "gender"));
        if (
          o.gender &&
          (o.gender?.toUpperCase() == "M" || o.gender?.toUpperCase() == "MALE" || o.gender?.toUpperCase() == "MAN")
        ) {
          o.gender = "MALE";
        } else if (
          o.gender &&
          (o.gender?.toUpperCase() == "F" ||
            o.gender?.toUpperCase() == "FEMALE" || o.gender?.toUpperCase() == "WOMAN")
        ) {
          o.gender = "FEMALE";
        } else if (
          o.gender &&
          (o.gender?.toUpperCase() === "O" ||
            o.gender?.toUpperCase() === "OTHER")
        ) {
          o.gender = "OTHER";
        }
        return o;
      })(),

      olp23_ballot1: cleanString(getValue(body, "olp23_ballot1")),
      olp23_ballot2: cleanString(getValue(body, "olp23_ballot2")),
      olp23_ballot3: cleanString(getValue(body, "olp23_ballot3")),
      olp23_ballot4: cleanString(getValue(body, "olp23_ballot4")),

      olp23_comms_consent: cleanString(getValue(body, "olp23_comms_consent")),
      olp23_signup_consent: cleanString(getValue(body, "olp23_signup_consent")),
      olp23_volunteeer_status: cleanString(
        getValue(body, "olp23_volunteeer_status"),
      ),
      olp23_donor_status: cleanString(getValue(body, "olp23_donor_status")),
      olp23_donation_amount: cleanString(
        getValue(body, "olp23_donation_amount"),
      ),
      olp23_signup_submitted: cleanString(
        getValue(body, "olp23_signup_submitted"),
      ),
      olp23_organizer: cleanString(getValue(body, "olp23_organizer")),
      olp23_source: cleanString(getValue(body, "olp23_source")),
      olp23_member: cleanString(getValue(body, "olp23_member")),
      olp23_voted: cleanString(getValue(body, "olp23_voted")),
      olp23_voting_group: cleanString(getValue(body, "olp23_voting_group")),
      olp23_voting_location: cleanString(
        getValue(body, "olp23_voting_location"),
      ),
      olp23_voting_period: cleanString(getValue(body, "olp23_voting_period")),
      olp23_voting_assocation: cleanString(
        getValue(body, "olp23_voting_assocation"),
      ),
      olp23_nate_signup: cleanString(getValue(body, "olp23_nate_signup")),
      olp23_campus_club: cleanString(getValue(body, "olp23_campus_club")),
      olp23_callhub_notes: cleanString(getValue(body, "olp23_callhub_notes")),
      olp23_nes_support_level: cleanString(
        getValue(body, "olp23_nes_support_level"),
      ),
      olp23_gender: cleanString(getValue(body, "olp23_gender")),
      olp23_riding: cleanString(getValue(body, "olp23_riding")),
      olp23_organizer_ref_id: cleanString(
        getValue(body, "olp23_organizer_ref_id"),
      ),
      olp23_membership_status: cleanString(
        getValue(body, "olp23_membership_status"),
      ),
    };
    //console.log(shaped_data);
    const cleaned_data = Object.fromEntries(
      Object.entries(shaped_data).filter(([_, value]) => value !== undefined),
    );
    //console.log("cleaned_data", cleaned_data);
    //response.statusCode = 200;
    let output = { headers: event.headers, body: cleaned_data };
    logger.dev.log("shaped output", output);
    //console.log("shapeData response", JSON.stringify(response));
    return output;
  } catch (error) {
    throw new HttpError("", 422, { originalError: error });
  }
};
shapeData.__module = path.basename(import.meta.url);
export { shapeData, cleanString };
