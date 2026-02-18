import { describe, it } from "node:test";
import assert from "node:assert";
import { handler } from "../../index.js";
import fulsome from "../test_payloads/fulsome.json" with { type: "json" };

describe("full submission test", () => {
  it("full submission should 200 or 401", async () => {
    const response = await handler(fulsome);

    const allowed = [200, 401];

    assert.ok(
      allowed.includes(response.statusCode),
      `Expected 200 or 401 but got ${response.statusCode}\nResponse:\n${JSON.stringify(response, null, 2)}`
    );
  });
});

/*
  upserted_data: {
    id: 1151,
    created_at: '2026-02-16T16:08:29.208083+00:00',
    updated_at: '2026-02-18T00:09:50.256581+00:00',
    firstname: 'Jimtester',
    surname: 'Green',
    email: 'jimtesterson@gmail.com',
    phone: '6478657811',
    birthdate: null,
    birthmonth: null,
    birthyear: null,
    street_address: '83-85 Silver Birch',
    municipality: 'TORONTO',
    division: 'Ontario',
    region: null,
    country: null,
    postcode: 'M4E 3L2',
    federal_electoral_district: 'Beaches—East York',
    division_electoral_district: 'Beaches—East York',
    municipal_electoral_district: null,
    ballot1: null,
    ballot2: null,
    ballot3: null,
    ballot4: null,
    comms_consent: true,
    signup_consent: true,
    signup_submitted: null,
    member: null,
    organizer: 'saihaansyed',
    language: null,
    olp23_ballot1: null,
    olp23_ballot2: null,
    olp23_ballot3: null,
    olp23_ballot4: null,
    olp23_comms_consent: null,
    olp23_signup_consent: null,
    olp23_volunteer_status: null,
    olp23_donor_status: null,
    olp23_donation_amount: null,
    olp23_signup_submitted: null,
    olp23_organizer: null,
    olp23_source: null,
    olp23_member: null,
    olp23_voted: null,
    olp23_voting_group: null,
    olp23_voting_location: null,
    olp23_voting_period: null,
    olp23_voting_association: null,
    olp23_nate_signup: null,
    olp23_campus_club: null,
    olp23_callhub_notes: null,
    olp23_nes_support_level: null,
    olp23_gender: null,
    olp23_riding: null,
    olp23_organizer_ref_id: null,
    olp23_membership_status: null,
    olp_van_id: null,
    lpc_van_id: null,
    last_request: 64,
    tags: 'delete,utm_medium:social,utm_source:twitter,utm_campaign:bio',
    gender: null,
    mailerlite_id: '179577596781003934',
    campus_club: 'McMaster University',
    ride_request_status: null,
    contact_status: null,
    latitude: null,
    longitude: null,
    location: null,
    research_data: null,
    research_updated_at: null,
    research_status: null,
    organizer_codes: [ 'saihaansyed' ],
    submission_confirmed: false,
    womens_club: null,
    groups: [ '178500154540689118' ]
  }
}

 */
