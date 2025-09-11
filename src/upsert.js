import "dotenv/config";
import { createClient } from "@supabase/supabase-js";
import path from "path";
import HttpError from "simple-http-error";
import logger from "simple-logs-sai-node";

const provinces = {
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
    const shapedDataAddress = normalizeName(shapedData.address);
    const shapedDataEmail = normalizeName(shapedData.email);
    logger.dev.log(shapedDataEmail);
    const shapedDataEmailPrefix = normalizeName(shapedData.email).split("@")[0];
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
              .ilike("firstname", `%${shapedDataFirstName}%`)
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
      // Same name and nothing else exists
      shapedDataFirstName &&
        shapedDataLastName && {
          query: (q) =>
            q
              .ilike("firstname", `%${shapedDataFirstName}%`)
              .ilike("surname", `%${shapedDataLastName}%`)
              .is("street_address", null)
              .is("email", null)
              .is("phone", null)
              .is("postcode", null)
              .is("division_electoral_district", null),
        },
      // Same email and nothing else
      shapedDataEmail && {
        query: (q) =>
          q
            .ilike("email", `%${shapedDataEmail}`)
            .is("firstname", null)
            .is("surname", null)
            .is("street_address", null)
            .is("phone", null)
            .is("postcode", null)
            .is("division_electoral_district", null),
      },
      // Same email prefix and nothing else
      shapedDataEmailPrefix && {
        query: (q) =>
          q
            .ilike("email", `%${shapedDataEmail}`)
            .is("firstname", null)
            .is("surname", null)
            .is("street_address", null)
            .is("phone", null)
            .is("postcode", null)
            .is("division_electoral_district", null),
      },
      // Same email (maybe should check if everything else in new data is null as to not overwrite? or maybe overwrite in this situation fine?)
      shapedDataEmail && {
        query: (q) => q.ilike("email", `%${shapedDataEmail}`),
      },
      // Same email prefix
      shapedDataEmailPrefix && {
        query: (q) => q.ilike("email", `%${shapedDataEmailPrefix}`),
      },
    ].filter(Boolean);
    logger.dev.log("shapedDataEmail", shapedDataEmail);
    // Try each condition in sequence
    for (const condition of searchConditions) {
      logger.dev.log("enter", condition);
      const query = supabaseClient.from("contact").select();
      condition.query(query);

      const { data, error } = await query;
      if (error)
        throw new Error("Find Profile Condition Check Failed", {
          statusCode: 500,
          cause: error,
        });

      if (data?.length > 0) {
        logger.log("Found Matching Profile", data[0].id);
        // If multiple matches, use most recently updated record
        const sorted = data.sort((a, b) =>
          (b.updated_at || b.created_at || "").localeCompare(
            a.updated_at || a.created_at || ""
          )
        );
        logger.log("Found Matching Profile", data[0].id);
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
  try {
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

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    return await response.json();
  } catch (error) {
    throw new Error("Opennorth lookup error", {
      statusCode: 500,
      cause: error,
    });
  }
};
const get_fed = async (postcode) => {
  try {
    logger.dev.log("get_fed", postcode);
    const data = await opennorth_postcode(
      postcode,
      "/?sets=federal-electoral-districts-2023-representation-order"
    );
    logger.dev.log("fed", data?.boundaries_centroid?.[0]?.name);
    return data?.boundaries_centroid?.[0]?.name || null;
  } catch (error) {
    throw new Error("federal electoral district lookup error", {
      statusCode: 500,
      cause: error,
    });
  }
};
const get_ded = async (postcode) => {
  try {
    logger.dev.log("get_ded", postcode);
    const data = await opennorth_postcode(
      postcode,
      "/?sets=ontario-electoral-districts-representation-act-2015"
    );
    logger.dev.log("ded", data?.boundaries_centroid?.[0]?.name);
    return data?.boundaries_centroid?.[0]?.name || null;
  } catch (error) {
    throw new Error("upsert.js/district electoral district lookup error", {
      statusCode: 500,
      cause: error,
    });
  }
};
const get_geo = async (postcode) => {
  try {
    const data = await opennorth_postcode(postcode, "");
    const municipality = data?.city;
    const division = data?.province;
    return { municipality, division };
  } catch (error) {}
};
const getRidings = async (postcode) => {
  try {
    const fed = await get_fed(postcode);
    const ded = await get_ded(postcode);
    const geo = await get_geo(postcode);
    return { fed, ded, geo };
  } catch (error) {
    console.log("riding search error:", error);
    throw new Error("upsert.js/getRidings() error", {
      statusCode: 500,
      cause: error,
    });
  }
};
function commaSeperate(profileValue, shapedDataValue) {
  if (shapedDataValue && profileValue) {
    if (profileValue.split(",").includes(shapedDataValue)) {
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
  logger.dev.log(profile);
  logger.dev.log(shapedData);
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

  if (updateData.postcode || shapedData.postcode) {
    const postcode = updateData.postcode
      ? updateData.postcode
      : shapedData.postcode;
    const ridings = await getRidings(postcode);
    logger.dev.log(ridings);
    updateData.federal_electoral_district = ridings.fed;
    updateData.division_electoral_district = ridings.ded;
    //const geo = await get_geo(postcode);
    updateData.division = provinces[ridings.geo.division.toUpperCase()];
    updateData.municipality =
      ridings.geo.municipality[0].toUpperCase() +
      ridings.geo.municipality.slice(1).toLowerCase();
  }

  if (shapedData.ballot1 && profile.ballot1) {
    if (
      //if ballot 1 is the candidate, accept the new data
      shapedData.ballot1 == process.env.CANDIDATE
    ) {
      updateData.ballot1 = shapedData.ballot1;
    } else if (shapedData.ballot1 == process.env.NOT_CANDIDATE) {
      //if ballot1 is Not Candidate, accept the new data
      updateData.ballot1 = process.env.NOT_CANDIDATE;
    } else if (
      process.env.CANDIDATES.split(",").includes(shapedData.ballot1) &&
      shapedData.ballot1 != process.env.CANDIDATE &&
      profile.ballot1 == process.env.CANDIDATE
    ) {
      //if ballot1 is another candidate but old data is our candidate, turn old data as possibly our canddate
      updateData.ballot1 = process.env.POSSIBLE_CANDIDATE;
    } else if (profile.ballot1 == process.env.CANDIDATE) {
      //if ballot1 is not another candiddate and not explicitly not our candidate, but we already have the profile stored as our candidate, don't accept new data
      updateData.ballot1 = profile.ballot1;
    } else {
      updateData.ballot1 = shapedData.ballot1;
    }
  }

  if (profile.organizer && shapedData.organizer) {
    updateData.organizer = commaSeperate(
      profile.organizer,
      shapedData.organizer
    );
  }

  if (profile.language && shapedData.language) {
    updateData.language = commaSeperate(profile.language, shapedData.language);
  }
  updateData.id = profile.id;
  return updateData;
}

const upsertData = async (payload) => {
  const shapedData = payload.body;
  const supabase = await createClient(
    process.env.DATABASE_URL,
    process.env.KEY
  );
  const foundProfile = await findProfile(supabase, shapedData);
  const updateData = await consolidateData(foundProfile, shapedData);

  logger.log("About to upsert");
  logger.dev.log(JSON.stringify(updateData));
  let query = supabase.from("contact");
  const {
    data: person,
    status,
    error: personError,
  } = await query
    .upsert(updateData, {
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
