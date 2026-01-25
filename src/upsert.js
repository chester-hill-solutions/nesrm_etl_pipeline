//import "dotenv/config";
import { createClient } from "@supabase/supabase-js";
import path from "path";
import HttpError from "simple-http-error";
import logger from "simple-logs-sai-node";
import { bestMatch } from "../scripts/mailReconcile/index.js";

const PROVINCES = {
  AB: "Alberta",
  BC: "British Columbia",
  MB: "Manitoba",
  NB: "New Brunswick",
  NL: "Newfoundland and Labrador",
  NS: "Nova Scotia",
  NT: "Northwest Territories",
  NU: "Nunavut",
  ON: "Ontario",
  PE: "Prince Edward Island",
  QC: "Quebec",
  SK: "Saskatchewan",
  YT: "Yukon",
};
const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

// Normalize phone numbers
const normalizePhone = (phone) => phone?.replace(/\D/g, "").slice(-10);

// Normalize postal codes
const normalizePostal = (postal) => postal?.replace(/\W/g, "").toUpperCase();

// Normalize names
const normalizeName = (name) => name?.toLowerCase().trim();

async function findProfile(supabaseClient, shapedData) {
  if (!supabaseClient || !shapedData)
    throw new HttpError("Invalid parameters", 500);

  try {
    const shapedDataFirstName = normalizeName(shapedData.firstname);
    const shapedDataLastName = normalizeName(shapedData.surname);
    console.log("shapedDataLastName",shapedDataLastName)
    const shapedDataAddress = normalizeName(shapedData.address);
    const shapedDataEmail = normalizeName(shapedData.email);
    logger.dev.log("shapedDataEmail", shapedDataEmail);
    const shapedDataEmailPrefix = normalizeName(shapedData.email)?.split(
      "@"
    )[0];
    const shapedDataPostal = normalizePostal(shapedData.postcode);
    const shapedDataPhone = normalizePhone(shapedData.phone);
    const shapedDataRiding = normalizeName(
      shapedData.division_electoral_district
    );

    // Search conditions in order of reliability
    const searchConditions = [
      // Exact VAN ID match
      shapedData.olp_van_id && {
        query: (q) => q.eq("olp_van_id", shapedData.olp_van_id),
      },
      // Exact VAN ID match
      shapedData.lpc_van_id && {
        query: (q) => q.eq("lpc_van_id", shapedData.lpc_van_id),
      },
      // Same name + email
      shapedDataFirstName &&
        shapedDataLastName &&
        shapedDataEmail && {
          query: (q) =>
            q
              .ilike("firstname", `%${shapedDataFirstName}%,`)
              .ilike("surname", `%${shapedDataLastName}%`)
              .ilike("email", `%${shapedDataEmail}%`),
        },
      // Same name + phone
      shapedDataFirstName &&
        shapedDataLastName &&
        shapedDataPhone && {
          query: (q) =>
            q
              .ilike("firstname", `%${shapedDataFirstName}%`)
              .ilike("surname", `%${shapedDataLastName}%`)
              .ilike("phone", `%${shapedDataPhone}%`),
        },
      // Same name + address
      shapedDataFirstName &&
        shapedDataLastName &&
        shapedDataAddress && {
          query: (q) =>
            q
              .ilike("firstname", `%${shapedDataFirstName}%`)
              .ilike("surname", `%${shapedDataLastName}%`)
              .ilike("street_address", `%${shapedDataLastName}%`),
        },
      // Same name + postal
      shapedDataFirstName &&
        shapedDataLastName &&
        shapedDataPostal && {
          query: (q) =>
            q
              .ilike("firstname", `%${shapedDataFirstName}%`)
              .ilike("surname", `%${shapedDataLastName}%`)
              .ilike("postcode", shapedDataPostal),
        },
      // Same name + same email prefix
      shapedDataFirstName &&
        shapedDataLastName &&
        shapedData.email && {
          query: (q) =>
            q
              .ilike("firstname", `%${shapedDataFirstName}%`)
              .ilike("surname", `%${shapedDataLastName}%`)
              .ilike("email", `%${shapedDataEmailPrefix}%`),
        },
      // Same name and nothing else in db
      shapedDataFirstName &&
        shapedDataLastName && {
          query: (q) =>
            q
              .ilike("firstname", `%${shapedDataFirstName}%`)
              .ilike("surname", `%${shapedDataLastName}%`)
              .is("street_address", null)
              .is("email", null)
              .is("phone", null)
              .is("postcode", null),
        },
      // Same email and nothing else in db
      shapedDataEmail && {
        query: (q) =>
          q
            .ilike("email", `%${shapedDataEmail}`)
            .is("firstname", null)
            .is("surname", null)
            .is("street_address", null)
            .is("phone", null)
            .is("postcode", null),
      },
      // Same email prefix and nothing else in db
      shapedDataEmailPrefix && {
        query: (q) =>
          q
            .ilike("email", `%${shapedDataEmailPrefix}`)
            .is("firstname", null)
            .is("surname", null)
            .is("street_address", null)
            .is("phone", null)
            .is("postcode", null),
      },
      // Same phone and nothing else in db
      shapedDataPhone && {
        query: (q) =>
          q
            .ilike("phone", `%${shapedDataPhone}`)
            .is("firstname", null)
            .is("surname", null)
            .is("street_address", null)
            .is("email", null)
            .is("postcode", null),
      },
      // Same email prefix and new data is null nothing else in db
      shapedDataPhone &&
        !shapedDataEmail &&
        !shapedDataFirstName &&
        !shapedDataLastName && {
          query: (q) => q.ilike("phone", `%${shapedDataPhone}`),
        },
      !shapedDataPhone &&
        shapedDataEmail &&
        !shapedDataFirstName &&
        !shapedDataLastName && {
          query: (q) => q.ilike("phone", `%${shapedDataPhone}`),
        },
      /*
      // Same email (maybe should check if everything else in new data is null as to not overwrite? or maybe overwrite in this situation fine?)
      shapedDataEmail && {
        query: (q) => q.ilike("email", `%${shapedDataEmail}`),
      },
      // Same email prefix
      shapedDataEmailPrefix && {
        query: (q) => q.ilike("email", `%${shapedDataEmailPrefix}`),
      },*/
    ]; //.filter(Boolean);
    // Try each condition in sequence
    let index = 0;
    for (const condition of searchConditions) {
      index++;
      logger.dev.log("try condition", index);
      if (!condition) continue;
      const query = supabaseClient.from("contact").select();
      condition.query(query);

      const { data, error } = await query;
      if (error) {
        logger.dev.log("supabase search error", error);
        throw new HttpError("Find Profile Condition Check Failed", 500, {
          originalError: error,
        });
      }

      if (data?.length > 0) {
        logger.dev.log("found condition", index);
        logger.log("Found Matching Profile ID:", data[0].id);
        // If multiple matches, use most recently updated record
        const sorted = data.sort((a, b) =>
          (b.updated_at || b.created_at || "").localeCompare(
            a.updated_at || a.created_at || ""
          )
        );
        //logger.log("Found Matching Profile", data[0].id);
        return sorted[0];
      }
    }
    logger.log("No matching profile found");
    return null;
  } catch (error) {
    console.error("Profile lookup error:", error);
    throw new HttpError("Profile lookup error", 500, { originalError: error });
  }
}

const opennorth_postcode = async (postcode, sets) => {
  const response = await fetch(
    `https://represent.opennorth.ca/postcodes/${postcode.replace(
      " ",
      ""
    )}${sets}`,
    {
      headers: {
        "Content-Type": "application/json",
      },
    }
  );
  let bodyText = await response.text();
  let body;
  try {
    body = JSON.parse(bodyText);
  } catch {
    body = bodyText;
  }
  if (!response.ok) {
    logger.log("opennorth fetch code", response.status);
    throw new HttpError(
      `HTTP error! status: ${response.status}`,
      response.status,
      { originalError: body }
    );
  }

  return body;
};

const get_opennorth = async (postcode) => {
  let municipality = undefined;
  let division = undefined;
  let ded = undefined;
  let fed = undefined;
  try {
    logger.log("get_opennorth", postcode);
    const data = await opennorth_postcode(postcode, "");
    logger.log("got_opennorth", postcode);
    logger.dev.log("fed", data?.boundaries_centroid?.[0]?.name);
    logger.dev.log("ded", data?.boundaries_centroid?.[0]?.name);
    logger.dev.log("municipality", data?.boundaries_centroid?.[0]?.name);
    logger.dev.log("division", data?.boundaries_centroid?.[0]?.name);
    municipality = data?.city;
    division = data?.province;
    fed = data?.boundaries_centroid.find(
      (item) =>
        item.related?.boundary_set_url ===
        "/boundary-sets/federal-electoral-districts-2023-representation-order/"
    )?.name;
    ded = data?.boundaries_centroid.find(
      (item) =>
        item.related?.boundary_set_url ===
        "/boundary-sets/ontario-electoral-districts-representation-act-2015/"
    )?.name;
    return { municipality, division, fed, ded };
  } catch (error) {
    if (error.statusCode == 429) {
      //add exponential backoff eventually
      //{ municipality, division, fed, ded } = ;
      return { municipality, division, fed, ded };
    } else if (error.statusCode == 404)
      return { municipality, division, fed, ded };
    console.error(error);
    throw new HttpError(
      `upsert.js/electoral district lookup error ${postcode}`,
      error.statusCode ?? 500,
      {
        originalError: error,
      }
    );
  }
};

function commaSeperate(profileValue, shapedDataValue) {
  if (shapedDataValue && profileValue) {
    const shapedLower = shapedDataValue.toLowerCase();
    const values = profileValue.split(",").map((v) => v.trim().toLowerCase());

    if (values.includes(shapedLower)) {
      return profileValue;
    } else {
      return profileValue + "," + shapedDataValue;
    }
  }
  return shapedDataValue;
}
function commaSeperateUpdateLogic(updateData, profile, shapedData, key) {
  if (shapedData[key] && profile[key]) {
    updateData[key] = commaSeperate(profile[key], shapedData[key]); /*
    if (profile[key].split(",").includes(shapedData[key])) {
      updateData[key] = profile[key];
    } else {
      updateData[key] = profile[key] + "," + shapedData[key];
    }
  } else if (shapedData[key]) {
    updateData[key] = shapedData[key];*/
  }
  return updateData;
}
async function consolidateData(profile, shapedData) {
  const updateData = {};
  if (!profile) {
    return shapedData;
  }
  logger.dev.log("profile", profile);
  logger.dev.log("shapedData", shapedData);
  for (const key in shapedData) {
    if (key.includes("olp23")) {
      await commaSeperateUpdateLogic(updateData, profile, shapedData, key);
    } else if (profile[key]) {
      if (profile[key] === shapedData[key]) {
        updateData[key] = shapedData[key];
      } else if (
        typeof profile[key] === "string" &&
        profile[key].includes(shapedData[key])
      ) {
        updateData[key] = profile[key];
      } else if (
        typeof shapedData[key] === "string" &&
        shapedData[key].includes(profile[key])
      ) {
        updateData[key] = shapedData[key];
      } else {
        updateData[key] = shapedData[key];
      }
    } else {
      updateData[key] = shapedData[key];
    }
  }
  logger.dev.log("updateData iter 1", updateData);

  if (
    shapedData.email &&
    shapedData.firstname &&
    shapedData.surname &&
    profile.firstname &&
    profile.surname
  ) {
    const { ufirstname, usurname } = bestMatch(
      shapedData.email,
      { firstname: shapedData.firstname, surname: shapedData.surname },
      { firstname: profile.firstname, surname: profile.surname }
    );
    updateData.firstname = ufirstname;
    updateData.surname = usurname;
  }

  if (shapedData.ballot1 && profile.ballot1) {
    if (
      //if ballot 1 is the candidate, accept the new data
      shapedData.ballot1 == process.env.CANDIDATE
    ) {
      logger.dev.log("1");
      updateData.ballot1 = shapedData.ballot1;
    } else if (shapedData.ballot1 == process.env.NOT_CANDIDATE) {
      logger.dev.log("2");
      //if ballot1 is Not Candidate, accept the new data
      updateData.ballot1 = process.env.NOT_CANDIDATE;
    } else if (
      process.env.CANDIDATES.split(",").includes(shapedData.ballot1) &&
      shapedData.ballot1 != process.env.CANDIDATE &&
      (profile.ballot1 == process.env.CANDIDATE ||
        profile.ballot1 == process.env.POSSIBLY_CANDIDATE)
    ) {
      logger.dev.log("3");
      //if ballot1 is another candidate but old data is our candidate, turn old data as possibly our canddate
      updateData.ballot1 = process.env.POSSIBLY_CANDIDATE;
    } else if (profile.ballot1 == process.env.CANDIDATE) {
      logger.dev.log("4");
      //if ballot1 is not another candiddate and not explicitly not our candidate, but we already have the profile stored as our candidate, don't accept new data
      updateData.ballot1 = profile.ballot1;
    } else {
      logger.dev.log("5");
      updateData.ballot1 = shapedData.ballot1;
    }
  }

  if (profile.organizer && shapedData.organizer) {
    updateData.organizer = commaSeperate(
      profile.organizer,
      shapedData.organizer
    );
  }
  if (profile.tags && shapedData.tags) {
    updateData.tags = commaSeperate(profile.tags, shapedData.tags);
  }
  if (profile.language && shapedData.language) {
    updateData.language = commaSeperate(profile.language, shapedData.language);
  }

  let today = new Date();
  if (
    shapedData.birthyear &&
    (today.getFullYear() - shapedData.birthyear < 5 ||
      today.getFullYear() - shapedData.birthyear > 112)
    /* && today.getFullYear() - shapedData.birthyear <
      parseInt(process.env.SIGNUP_AGE_LIMIT, 10) /*||
    (shapedData.birthyear &&
      shapedData.birthmonth &&
      shapedData.birthyear === today.getFullYear() &&
      today.getMonth() + 1 - shapedData.birthmonth < 0) ||
    (shapedData.birthyear &&
      shapedData.birthmonth &&
      shapedData.birthyear === today.getFullYear() &&
      shapedData.birthmonth === today.getMonth() + 1 &&
      today.getDate() - shapedData.birthdate < 0)*/
  ) {
    logger.dev.log("Invalid birthdate");
    updateData.birthyear = profile.birthyear ? profile.birthyear : null;
    updateData.birthmonth = profile.birthmonth ? profile.birthmonth : null;
    updateData.birthdate = profile.birthdate ? profile.birthdate : null;
  }
  updateData.id = profile.id;
  return updateData;
}

const upsertData = async ({input, supabase=null}) => {
  let payload = input;
  const shapedData = payload.body ? payload.body : payload;
  supabase = supabase ?? createClient(
    process.env.DATABASE_URL,
    process.env.KEY
  );
  const foundProfile = await findProfile(supabase, shapedData);
  const updateData = await consolidateData(foundProfile, shapedData);

  if (updateData.postcode || shapedData.postcode) {
    logger.dev.log("postcode found");
    const postcode = updateData.postcode
      ? updateData.postcode
      : shapedData.postcode;

    let { municipality, division, fed, ded } = await get_opennorth(postcode);

    logger.dev.log("getRidings", fed, ded, municipality, division);
    updateData.federal_electoral_district = fed ?? undefined;
    updateData.division_electoral_district = ded ?? undefined;
    //const geo = await get_geo(postcode);
    updateData.division = division
      ? PROVINCES[division.toUpperCase()]
      : undefined;
    updateData.municipality = municipality ?? undefined;
  }

  updateData.last_request = payload.headers?.request_backup_id
    ? payload.headers.request_backup_id
    : undefined;
  logger.dev.log("paylllooaad", JSON.stringify(payload, null, 2));
  logger.log("About to upsert");
  const cleaned_data = Object.fromEntries(
    Object.entries(updateData).filter(([_, value]) => value !== undefined)
  );
  logger.dev.log(JSON.stringify(cleaned_data));
  let query = supabase.from("contact");
  const {
    data: person,
    status,
    error: personError,
  } = await query
    .upsert(cleaned_data, {
      onConflict: "id",
    })
    .select();

  if (personError) {
    console.error("Upsert error:", personError);
    throw new HttpError("Upsert error", 500, { originalError: personError });
  }

  logger.log("Successfully upserted", status);
  logger.dev.log("Successfully upserted:", JSON.stringify(person[0]));
  return person[0];
};

upsertData.__module = path.basename(import.meta.url);
export { upsertData };
