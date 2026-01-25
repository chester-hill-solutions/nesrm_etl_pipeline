#!/usr/bin/env node
/**
 * parse-query-params.js
 *
 * - Importable: const { parseQueryParams, normalizeUrl } = require("./parse-query-params");
 * - CLI: node parse-query-params.js "<url-or-query>"
 * - Standalone test: node parse-query-params.js --test
 *
 * Features:
 * - Accepts full URLs WITH or WITHOUT http(s)
 * - Accepts raw query strings like "?a=1&b=2" or "a=1&b=2"
 * - Preserves repeated keys as arrays: ?tag=a&tag=b -> { tag: ["a","b"] }
 * - Optional coercion (numbers/booleans/null) via --coerce (CLI) or { coerce: true }
 */

"use strict";

import logger from "simple-logs-sai-node";
import { fileURLToPath } from "node:url";
import path from "node:path";

/** Detects if something starts with a URI scheme like "http://" or "custom-scheme://" */
function hasScheme(s) {
  return /^[a-zA-Z][a-zA-Z\d+\-.]*:\/\//.test(s);
}

/** Normalize input into something URL() can parse safely. */
function normalizeUrl(input, { defaultScheme = "https" } = {}) {
  logger.dev.log("normalizeUrl input:", input)
  const raw = String(input ?? "").trim();
  if (!raw) throw new Error("Empty input");

  // Raw query input (no host/path)
  if (raw.startsWith("?")) return `http://localhost/${raw}`;
  if (!raw.includes("://") && !raw.includes("/") && raw.includes("=") && raw.includes("&")) {
    // e.g. "a=1&b=2"
    return `http://localhost/?${raw}`;
  }

  // Protocol-relative URL: //example.com?a=1
  if (raw.startsWith("//")) return `${defaultScheme}:${raw}`;

  // If it already has a scheme, good.
  if (hasScheme(raw)) return raw;

  // Looks like "example.com?x=1" or "localhost:3000?x=1"
  return `${defaultScheme}://${raw}`;
}

function coerceValue(v) {
  const s = String(v);

  // Keep empty string as empty string (common for flags like "?debug=")
  if (s === "") return s;

  // null-ish
  if (s === "null") return null;

  // booleans
  if (s === "true") return true;
  if (s === "false") return false;

  // numbers (int/float). Avoid coercing leading-zero strings like "00123"
  if (/^-?\d+(\.\d+)?$/.test(s) && !/^0\d+/.test(s.replace(/^-/, ""))) {
    const n = Number(s);
    if (!Number.isNaN(n)) return n;
  }

  return s;
}

/**
 * Parse query params from a URL or query string.
 * @param {string} input
 * @param {{ coerce?: boolean, defaultScheme?: string }} [opts]
 * @returns {Record<string, any>}
 */
export function parseQueryParams(input, opts = {}) {
  logger.log("parseQueryParams", input);
  const { coerce = false, defaultScheme = "https" } = opts;
  const normalized = normalizeUrl(input, { defaultScheme });
  const u = new URL(normalized);

  /** @type {Record<string, any>} */
  const out = {};

  for (const [key, value] of u.searchParams.entries()) {
    const v = coerce ? coerceValue(value) : value;

    if (Object.prototype.hasOwnProperty.call(out, key)) {
      // Promote to array on second occurrence
      out[key] = Array.isArray(out[key]) ? out[key].concat(v) : [out[key], v];
    } else {
      out[key] = v;
    }
  }

  logger.log("parseQueryParams output:", out)
  return out;
}

// Export for require()

/* ---------------- CLI ---------------- */

// ESM equivalent of `require.main === module`
const isCLI =
  process.argv[1] === fileURLToPath(import.meta.url);

if (isCLI) {
  const args = process.argv.slice(2);
  const flags = new Set(args.filter(a => a.startsWith("--")));

  const coerce = flags.has("--coerce");
  const test = flags.has("--test");
  const input = args.find(a => !a.startsWith("--"));

  function usage(exit = 0) {
    console.log(`
Usage:
  node parseQueryParams.js "<url-or-query>" [--coerce]
  node parseQueryParams.js --test

Examples:
  node parseQueryParams.js "example.com?a=1&a=2&b=true"
  node parseQueryParams.js "?tag=a&tag=b"
  node parseQueryParams.js "utm_source=ig&utm_medium=bio"
  node parseQueryParams.js "https://x.com/?n=42" --coerce
`);
    process.exit(exit);
  }

  if (flags.has("--help") || flags.has("-h")) usage(0);

  if (test) {
    const cases = [
      "example.com?a=1&a=2&b=true",
      "https://example.com?tag=a&tag=b&empty=&n=42",
      "?utm_source=twitter&utm_medium=bio",
      "utm_source=ig&utm_source=tiktok&utm_campaign=iran",
      "//example.com?x=1",
      "localhost:3000?x=1&x=2",
    ];

    for (const c of cases) {
      console.log("INPUT:", c);
      console.log(JSON.stringify(parseQueryParams(c, { coerce }), null, 2));
      console.log("---");
    }
    process.exit(0);
  }

  if (!input) usage(1);

  try {
    console.log(
      JSON.stringify(parseQueryParams(input, { coerce }), null, 2)
    );
  } catch (err) {
    console.error("Error:", err.message);
    process.exit(1);
  }
}
