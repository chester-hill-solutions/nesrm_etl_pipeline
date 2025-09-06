import path from "path";

const cleanString = (str) => {
  //If string is empty return undefined
  if (str === null || str === undefined) return undefined;
  //trim either side of string
  const cleaned = String(str).trim();
  return cleaned === "" ? undefined : cleaned;
};
//get value
const getValue = (payload, key) => {
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
  let response = { body: { trace: [{ step: "shape", task: "shapeData" }] } };
  if (!event.body) {
    throw new Error("Missing body", { statusCode: 422 });
  }
  const body = event.body;
  try {
    let shaped_data = {
      firstname: cleanString(getValue(body, "firstname")),
      surname: cleanString(getValue(body, "surname")),
      email: cleanString(getValue(body, "email")),
      phone: cleanString(getValue(body, "phone")),

      // Birth date information
      ...(() => {
        const birthData = {};
        const dob = cleanString(getValue(body, "dob"));
        let birthdate = cleanString(getValue(body, "birthdate"));
        let birthmonth = cleanString(getValue(body, "birthmonth"));
        let birthyear = cleanString(getValue(body, "birthyear"));

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

      ...() => {
        let addressData = {};
        let addressCat = getValue(body, "address");
        if (addressCat) {
          let addressSource = addressCat;
          addressData.street_address = cleanString(
            getValue(addressSource, "street_address")
          );
          addressData.municipality = cleanString(
            getValue(addressSource, "municipality")
          );
          addressData.district = cleanString(
            getValue(addressSource, "district")
          );
          addressData.region = cleanString(getValue(addressSource, "region"));
          addressData.county = cleanString(getValue(addressSource, "county"));
          addressData.country = cleanString(getValue(addressSource, "country"));
          addressData.postcode = cleanString(
            getValue(addressSource, "postcode")
          );
        } else {
          let addressSource = addressCat;
          addressData.street_address = cleanString(
            getValue(addressSource, "street_address")
          );
          addressData.municipality = cleanString(
            getValue(addressSource, "municipality")
          );
          addressData.district = cleanString(
            getValue(addressSource, "district")
          );
          addressData.region = cleanString(getValue(addressSource, "region"));
          addressData.county = cleanString(getValue(addressSource, "county"));
          addressData.country = cleanString(getValue(addressSource, "country"));
          addressData.postcode = cleanString(
            getValue(addressSource, "postcode")
          );
        }
        return addressData;
      },
      federal_electoral_district: cleanString(
        getValue(body, "federal_electoral_district")
      ),
      division_electoral_district: cleanString(
        getValue(body, "division_electoral_district")
      ),
      municipal_electoral_district: cleanString(
        getValue(body, "municipal_electoral_district")
      ),

      ballot1: cleanString(getValue(body, "ballot1")),
      ballot2: cleanString(getValue(body, "ballot2")),
      ballot3: cleanString(getValue(body, "ballot3")),

      comms_consent: cleanString(getValue(body, "comms_consent")),
      signup_consent: cleanString(getValue(body, "signup_consent")),
      signup_submitted: cleanString(getValue(body, "signup_submitted")),
      member: cleanString(getValue(body, "member")),

      organizer: cleanString(getValue(body, "organizer")),
      language: cleanString(getValue(body, "language")),
      van_id: cleanString(getValue(body, "van_id")),

      olp23_ballot1: cleanString(getValue(body, "olp23_ballot1")),
      olp23_ballot2: cleanString(getValue(body, "olp23_ballot2")),
      olp23_ballot3: cleanString(getValue(body, "olp23_ballot3")),
      olp23_ballot4: cleanString(getValue(body, "olp23_ballot4")),

      olp23_comms_consent: cleanString(getValue(body, "olp23_comms_consent")),
      olp23_signup_consent: cleanString(getValue(body, "olp23_signup_consent")),
      olp23_volunteeer_status: cleanString(
        getValue(body, "olp23_volunteeer_status")
      ),
      olp23_donor_status: cleanString(getValue(body, "olp23_donor_status")),
      olp23_donation_amount: cleanString(
        getValue(body, "olp23_donation_amount")
      ),
      olp23_signup_submitted: cleanString(
        getValue(body, "olp23_signup_submitted")
      ),
      olp23_organizer: cleanString(getValue(body, "olp23_organizer")),
      olp23_source: cleanString(getValue(body, "olp23_source")),
      olp23_member: cleanString(getValue(body, "olp23_member")),
      olp23_voted: cleanString(getValue(body, "olp23_voted")),
      olp23_voting_group: cleanString(getValue(body, "olp23_voting_group")),
      olp23_voting_location: cleanString(
        getValue(body, "olp23_voting_location")
      ),
      olp23_voting_period: cleanString(getValue(body, "olp23_voting_period")),
      olp23_voting_assocation: cleanString(
        getValue(body, "olp23_voting_assocation")
      ),
      olp23_nate_signup: cleanString(getValue(body, "olp23_nate_signup")),
      olp23_campus_club: cleanString(getValue(body, "olp23_campus_club")),
      olp23_callhub_notes: cleanString(getValue(body, "olp23_callhub_notes")),
      olp23_nes_support_level: cleanString(
        getValue(body, "olp23_nes_support_level")
      ),
      olp23_gender: cleanString(getValue(body, "olp23_gender")),
      olp23_riding: cleanString(getValue(body, "olp23_riding")),
      olp23_organizer_ref_id: cleanString(
        getValue(body, "olp23_organizer_ref_id")
      ),
      olp23_membership_status: cleanString(
        getValue(body, "olp23_membership_status")
      ),
    };
    //console.log(shaped_data);
    const cleaned_data = Object.fromEntries(
      Object.entries(shaped_data).filter(([_, value]) => value !== undefined)
    );
    //console.log("cleaned_data", cleaned_data);
    //response.statusCode = 200;
    let output = { headers: event.headers, body: cleaned_data };
    //console.log("shapeData response", JSON.stringify(response));
    return output;
  } catch (error) {
    throw new Error("", { statusCode: 422, cause: error });
  }
};
shapeData.__module = path.basename(import.meta.url);
export { shapeData };
