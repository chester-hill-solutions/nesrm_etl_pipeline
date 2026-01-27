export function collapseSpaces(str) {
  let result = "";
  let lastWasSpace = false;

  for (const char of str) {
    if (char === " ") {
      if (!lastWasSpace) {
        result += char;
        lastWasSpace = true;
      }
    } else {
      result += char;
      lastWasSpace = false;
    }
  }

  return result;
}


export default function cleanString(str) {
  //If string is empty return undefined
  if (str === null || str === undefined) return undefined;
  //trim either side of string
  const s = collapseSpaces(String(str).trim());
  let cleaned = s.replace(/^,+|,+$/g, "").replace(/\\(?=['"])/g, "");
  return cleaned === "" ? undefined : cleaned;
}
