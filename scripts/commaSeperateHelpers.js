import logger from "simple-logs-sai-node";
import cleanString from "./cleanString.js";
export function combineCommaSeperate(f, s, output = "string") {
  const toArray = (v) => {
    logger.dev.log(`mapping ${v} toArray`)
    if (v == null || !v) return [];

    if (Array.isArray(v)) {
      logger.dev.log(`${v} already array`)
      return v.map(cleanString).filter(Boolean);
    }

    if (typeof v === "string") {
      let str = v.trim();

      // strip surrounding brackets: [ ... ]
      if (str.startsWith("[") && str.endsWith("]")) {
        str = str.slice(1, -1);
      }
      const o = str
        .split(",")
        .map(s =>
          cleanString(
            s
              .replace(/^['"]|['"]$/g, "") // strip quotes
          )
        )
        .filter(Boolean);
      logger.dev.log(`mapping ${v} to ${o}`)
      return o
    }

    return [];
  };

  const fArr = toArray(f);
  const sArr = toArray(s);
  console.log(fArr, sArr)

  // early returns
  if (sArr.length === 0)
    return fArr.length ? (output === "array" ? fArr : fArr.join(",")) : undefined;

  if (fArr.length === 0)
    return output === "array" ? sArr : sArr.join(",");

  // case-insensitive merge
  const seen = new Set(fArr.map(v => v.toLowerCase()));
  for (const v of sArr) {
    const k = v.toLowerCase();
    if (!seen.has(k)) {
      fArr.push(v);
      seen.add(k);
    }
  }

  return output === "array" ? fArr : fArr.join(",");
}
export function commaSeperate(profileValue, shapedDataValue, return_as="string") {
  const toArray = (v) => {
    if (v == null) return [];
    if (Array.isArray(v)) return v.map(cleanString);
    return String(v)
      .split(",")
      .map((s) => s.trim())
      .filter(Boolean);
  };

  const profileArr = toArray(profileValue);
  const shapedArr = toArray(shapedDataValue);
  // If nothing new, return existing (or undefined if both empty)
  if (shapedArr.length === 0) return profileArr.length ? profileArr.join(",") : undefined;
  if (profileArr.length === 0) return shapedArr.join(",");

  const seen = new Set(profileArr.map((v) => v.toLowerCase()));
  for (const v of shapedArr) {
    const k = v.toLowerCase();
    if (!seen.has(k)) {
      profileArr.push(v);
      seen.add(k);
    }
  }

  return return_as == "string" ? profileArr.join(",") : profileArr;
}

export function commaSeperateUpdateLogic(updateData, profile, shapedData, key, return_as="string") {
  const pv = profile?.[key];
  const sv = shapedData?.[key];

  // only set updateData[key] when shapedData has something (your original intent)
  if (sv != null && (Array.isArray(sv) ? sv.length : String(sv).trim() !== "")) {
    updateData[key] = commaSeperate(pv, sv, return_as);
  }

  return updateData;
}
