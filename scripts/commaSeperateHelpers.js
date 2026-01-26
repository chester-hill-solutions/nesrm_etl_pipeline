import cleanString from "./cleanString.js";
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
