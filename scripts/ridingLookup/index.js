// ridingLookup.js (ESM)

/**
 * Build a URL like:
 *   <endpoint>?postal=<value>
 *   <endpoint>?address=<value>
 *
 * @param {string} endpoint - Base endpoint URL (e.g. "https://api.example.com/lookup")
 * @param {{ postcode?: string, postal?: string, address?: string }} input
 * @returns {Promise<any>} Parsed JSON response (or text if not JSON)
 */
export async function ridingLookup(
  endpoint = process.env.RIDING_LOOKUP_ENDPOINT,
  input,
) {
  if (!endpoint) {
    throw new Error(
      "ridingLookup: endpoint not provided and RIDING_LOOKUP_ENDPOINT is not set", process.env.RIDING_LOOKUP_ENDPOINT,
    );
  }
  if (typeof endpoint !== "string" || !endpoint.trim()) {
    throw new TypeError("ridingLookup: endpoint must be a non-empty string");
  }

  const obj = input ?? {};
  const postalRaw = obj.postcode ?? obj.postal;
  const addressRaw = obj.address;

  const hasPostal =
    typeof postalRaw === "string" && postalRaw.trim().length > 0;
  const hasAddress =
    typeof addressRaw === "string" && addressRaw.trim().length > 0;

  if (hasPostal && hasAddress) {
    throw new Error(
      "ridingLookup: provide either postcode/postal OR address, not both",
    );
  }
  if (!hasPostal && !hasAddress) {
    throw new Error("ridingLookup: provide a postcode/postal or an address");
  }

  const url = new URL(endpoint);

  if (hasPostal) {
    const normalizedPostal = normalizePostal(postalRaw);
    url.searchParams.set("postal", normalizedPostal);
  }

  if (hasAddress) {
    url.searchParams.set("address", addressRaw.trim());
  }

  const res = await fetch(url.toString(), {
    method: "GET",
    headers: {
      Accept: "application/json, text/plain;q=0.9, */*;q=0.8",
    },
  });

  if (!res.ok) {
    const body = await safeReadText(res);
    throw new Error(
      `ridingLookup: ${res.status} ${res.statusText}${body ? ` - ${body}` : ""}`,
    );
  }

  const contentType = res.headers.get("content-type") || "";
  if (contentType.includes("application/json")) return res.json();

  const text = await res.text();
  try {
    return JSON.parse(text);
  } catch {
    return text;
  }
}

function normalizePostal(value) {
  return String(value)
    .replace(/\s+/g, "") // remove all whitespace
    .toUpperCase();
}

async function safeReadText(res) {
  try {
    return (await res.text()).slice(0, 2000);
  } catch {
    return "";
  }
}

/* Example usage:
import { ridingLookup } from "./ridingLookup.js";

const data1 = await ridingLookup("https://api.example.com/riding", { postcode: "M5V 2T6" });
const data2 = await ridingLookup("https://api.example.com/riding", { address: "123 Queen St W, Toronto, ON" });
console.log({ data1, data2 });
*/
