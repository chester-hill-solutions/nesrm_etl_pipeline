function pick(obj, keys) {
  return Object.fromEntries(
    keys.map((k) => {
      const val = obj?.[k];
      return [k, val];
    })
  );
}

function keyCompare(toFilter, base) {
  return Object.fromEntries(
    Object.entries(base).map(([k, v]) => {
      if (v && typeof v === "object" && !Array.isArray(v)) {
        // recurse for nested objects
        return [k, keyCompare(toFilter?.[k] || {}, v)];
      } else {
        return [k, toFilter?.[k]];
      }
    })
  );
}

export { pick, keyCompare };
