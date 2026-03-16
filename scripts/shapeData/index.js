import fs from "fs";
import { parse } from "csv-parse/sync";

function attachHeader(obj, headers, force=false) {
  let result;
  if (obj.body) {
    result = { headers: (obj.headers && force != true) ? obj.headers : headers, body: obj.body };
  } else {
    return {
      headers: headers,
      body: obj,
    };
  }
  return result;
}

async function csvToJson(filePath) {
  const data = await fs.promises.readFile(filePath, "utf8");

  // Detect delimiter: prefer tab if present in header, else fallback to comma.
  const firstLine = data.split(/\r?\n/, 1)[0] ?? "";
  const delimiter = firstLine.includes("\t") ? "\t" : ",";

  const records = parse(data, {
    columns: true, // first row as headers
    skip_empty_lines: true,
    trim: true,
    delimiter,
    group_columns_by_name: true,
    relax_quotes: true,
    relax_column_count: true,
  });

  const splitCell = (value) => {
    if (value === null || value === undefined) return [];
    if (Array.isArray(value)) return value.flatMap(splitCell);
    return String(value)
      .split(",")
      .map((v) => v.trim())
      .map((v) => v.replace(/^['"]|['"]$/g, ""))
      .filter(Boolean);
  };

  const isEmptyValue = (value) => {
    if (value === null || value === undefined) return true;
    if (typeof value === "string") return value.trim() === "";
    if (Array.isArray(value)) return value.length === 0;
    return false;
  };

  const normalized = records.map((record) => {
    const baseTags = [];
    const derivedTags = [];
    const organizers = [];
    const next = {};

    for (const [rawKey, rawValue] of Object.entries(record)) {
      const key = rawKey?.trim?.() ?? rawKey;
      const lowerKey = String(key).toLowerCase();

      if (lowerKey === "tags") {
        baseTags.push(...splitCell(rawValue));
        continue;
      }

      if (lowerKey.startsWith("tags:")) {
        const tagKey = key.slice(key.indexOf(":") + 1).trim();
        if (tagKey) {
          const values = splitCell(rawValue);
          for (const val of values) {
            derivedTags.push(`${tagKey}:${val}`);
          }
        }
        continue;
      }

      if (lowerKey.startsWith("organizer") && !lowerKey.startsWith("olp23_organizer")) {
        organizers.push(...splitCell(rawValue));
        continue;
      }

      next[rawKey] = typeof rawValue === "string" ? rawValue.trim() : rawValue;
    }

    const combined = [...baseTags, ...derivedTags];
    if (combined.length) {
      const seen = new Set();
      const deduped = [];
      for (const tag of combined) {
        const key = tag.toLowerCase();
        if (seen.has(key)) continue;
        seen.add(key);
        deduped.push(tag);
      }
      next.tags = deduped.join(",");
    } else {
      delete next.tags;
    }

    if (organizers.length) {
      const seenOrg = new Set();
      const dedupedOrg = [];
      for (const org of organizers) {
        const k = org.toLowerCase();
        if (seenOrg.has(k)) continue;
        seenOrg.add(k);
        dedupedOrg.push(org);
      }
      next.organizer = dedupedOrg;
    }

    for (const [key, value] of Object.entries(next)) {
      if (isEmptyValue(value)) {
        delete next[key];
      } else if (typeof value === "string") {
        next[key] = value.trim();
      }
    }

    return next;
  });

  return normalized;
}
export { attachHeader, csvToJson };
