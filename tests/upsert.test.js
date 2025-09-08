import { describe, it } from "node:test";
import assert from "node:assert";

import { upsertData } from "../src/upsert.js";

describe("upsertData tests", () => {
  it("should return upserted payload", async () => {
    const payload = {
      headers: {
        origin: "www.meetsai.ca",
        "x-forwarded-for": "124.0.0.1",
        request_backup_id: 289,
      },
      body: {
        firstname: "Saihaan",
        surname: "Syed",
        email: "saihaansyedprofiles@gmail.com",
        birthyear: "2003",
        birthmonth: "08",
        birthdate: "29",
        street_address: "442 Pharmacy Ave",
        municipality: "Scarborough",
        country: "CA",
        postcode: "M1L 3G6",
      },
    };
    const expected = {
      ballot1: null,
      ballot2: null,
      ballot3: null,
      ballot4: null,
      birthdate: 29,
      birthmonth: 8,
      birthyear: 2003,
      comms_consent: true,
      country: "CA",
      division: "Ontario",
      division_electoral_district: "Scarborough Southwest",
      email: "saihaansyedprofiles@gmail.com",
      federal_electoral_district: "Scarborough Southwest",
      firstname: "Saihaan",
      id: 87,
      language: null,
      member: null,
      municipal_electoral_district: null,
      municipality: "Scarborough",
      olp23_ballot1: null,
      olp23_ballot2: null,
      olp23_ballot3: null,
      olp23_ballot4: null,
      olp23_callhub_notes: null,
      olp23_campus_club: null,
      olp23_comms_consent: null,
      olp23_donation_amount: null,
      olp23_donor_status: null,
      olp23_gender: null,
      olp23_member: null,
      olp23_membership_status: null,
      olp23_nate_signup: null,
      olp23_nes_support_level: null,
      olp23_organizer: null,
      olp23_organizer_ref_id: null,
      olp23_riding: null,
      olp23_signup_consent: null,
      olp23_signup_submitted: null,
      olp23_source: null,
      olp23_volunteer_status: null,
      olp23_voted: null,
      olp23_voting_association: null,
      olp23_voting_group: null,
      olp23_voting_location: null,
      olp23_voting_period: null,
      organizer: null,
      phone: null,
      postcode: "M1L 3G6",
      region: null,
      signup_consent: null,
      signup_submitted: null,
      street_address: "442 Pharmacy Ave",
      surname: "Syed",
      van_id: null,
    };
    const result = await upsertData(payload);
    delete result.created_at;
    delete result.updated_at;
    assert.deepStrictEqual(result, expected);
  });
});
