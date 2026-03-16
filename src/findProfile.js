import { createClient } from "@supabase/supabase-js";
import HttpError from "simple-http-error";

// Normalize phone numbers
const normalizePhone = (phone) => phone?.replace(/\D/g, "").slice(-10);

// Normalize postal codes
const normalizePostal = (postal) => postal?.replace(/\W/g, "").toUpperCase();

// Normalize names
const normalizeName = (name) => name?.toLowerCase().trim();


async function findProfile({input, supabase=null}) {
  let shapedData = input;
  supabase =
    supabase ?? createClient(process.env.DATABASE_URL, process.env.KEY);

  if (!supabaseClient || !shapedData)
    throw new HttpError("Invalid parameters", 500);

  try {
    const shapedDataFirstName = normalizeName(shapedData.firstname);
    const shapedDataLastName = normalizeName(shapedData.surname);
    const shapedDataAddress = normalizeName(shapedData.address);
    const shapedDataEmail = normalizeName(shapedData.email);
    logger.dev.log("shapedDataEmail", shapedDataEmail);
    const shapedDataEmailPrefix = normalizeName(shapedData.email)?.split(
      "@",
    )[0];
    const shapedDataPostal = normalizePostal(shapedData.postcode);
    const shapedDataPhone = normalizePhone(shapedData.phone);
    const shapedDataRiding = normalizeName(
      shapedData.division_electoral_district,
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
            a.updated_at || a.created_at || "",
          ),
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

findProfile.__module = path.basename(import.meta.url);
export { findProfile };
