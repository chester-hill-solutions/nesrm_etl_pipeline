#!/usr/bin/env node

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

function normalizeKey(value) {
  return value.toLowerCase().replace(/[^a-z0-9]/g, "");
}

function loadPasswordMap(envFile) {
  const content = fs.readFileSync(envFile, "utf8");
  const map = new Map();

  for (const rawLine of content.split(/\r?\n/)) {
    const line = rawLine.trim();
    if (!line || line.startsWith("#")) {
      continue;
    }

    const separatorIndex = line.indexOf("=");
    if (separatorIndex === -1) {
      continue;
    }

    const key = line.slice(0, separatorIndex).trim();
    const value = line.slice(separatorIndex + 1).trim();

    if (!key) {
      continue;
    }

    map.set(normalizeKey(key), value);
  }

  return map;
}

function parseRoleName(roleName) {
  const trimmed = roleName.replace(/^(riding|region)_/i, "");
  const match = trimmed.match(/_(reader|writer)$/i);
  const suffix = match ? match[1].toLowerCase() : null;
  const base = match ? trimmed.slice(0, -match[0].length) : trimmed;
  return { base, suffix };
}

function normalizeStringLiterals(sql) {
  let result = "";
  let inString = false;
  let inLineComment = false;
  let inBlockComment = false;
  let changed = false;

  for (let i = 0; i < sql.length; i += 1) {
    const char = sql[i];
    const next = sql[i + 1];

    if (inLineComment) {
      result += char;
      if (char === "\n") {
        inLineComment = false;
      }
      continue;
    }

    if (inBlockComment) {
      result += char;
      if (char === "*" && next === "/") {
        result += next;
        i += 1;
        inBlockComment = false;
      }
      continue;
    }

    if (!inString) {
      if (char === "-" && next === "-") {
        result += char + next;
        i += 1;
        inLineComment = true;
        continue;
      }

      if (char === "/" && next === "*") {
        result += char + next;
        i += 1;
        inBlockComment = true;
        continue;
      }

      if (char === "'") {
        inString = true;
      }

      result += char;
      continue;
    }

    if (char === "'") {
      if (next === "'") {
        result += "''";
        i += 1;
        continue;
      }

      const prev = sql[i - 1];
      const isWordAdjacent =
        prev &&
        next &&
        /[\p{L}\p{N}]/u.test(prev) &&
        /[\p{L}\p{N}]/u.test(next);

      if (isWordAdjacent) {
        result += "''";
        changed = true;
        continue;
      }

      inString = false;
      result += "'";
      continue;
    }

    result += char;
  }

  if (inString) {
    throw new Error("Unterminated string literal detected in SQL file");
  }

  return { sql: result, changed };
}

function updateSqlPasswords(sqlFile, passwordMap) {
  const originalSql = fs.readFileSync(sqlFile, "utf8");
  const { sql: normalizedSql, changed: normalizedChanged } =
    normalizeStringLiterals(originalSql);

  const missing = new Set();
  let passwordChanges = false;
  const createRolePattern =
    /^(\s*CREATE ROLE\s+)(\w+)(\s+LOGIN PASSWORD\s+)'((?:''|[^'])*)'(.*)$/gm;

  const updatedSql = normalizedSql.replace(
    createRolePattern,
    (match, prefix, roleName, middle, currentPassword, suffix) => {
      const { base, suffix: roleType } = parseRoleName(roleName);
      const candidates = [];

      if (roleType) {
        candidates.push(`${base}_${roleType}`);
      }

      candidates.push(base);

      let password;
      for (const candidate of candidates) {
        password = passwordMap.get(normalizeKey(candidate));
        if (password) {
          break;
        }
      }

      if (!password) {
        missing.add(roleName);
        return match;
      }

      const escaped = password.replace(/'/g, "''");
      if (currentPassword === escaped) {
        return match;
      }

      passwordChanges = true;
      return `${prefix}${roleName}${middle}'${escaped}'${suffix}`;
    }
  );

  if (missing.size > 0) {
    const list = Array.from(missing).join(", ");
    throw new Error(`Missing password mappings for: ${list}`);
  }

  const hasChanges = normalizedChanged || passwordChanges;
  if (!hasChanges) {
    return {
      changed: false,
      passwordChanges: false,
      stringEscapesFixed: false,
    };
  }

  if (updatedSql !== originalSql) {
    fs.writeFileSync(sqlFile, updatedSql, "utf8");
  }

  return {
    changed: true,
    passwordChanges,
    stringEscapesFixed: normalizedChanged,
  };
}

function ensureFile(pathToCheck, label) {
  if (!fs.existsSync(pathToCheck)) {
    throw new Error(`${label} not found at ${pathToCheck}`);
  }
}

function resolveEnvFile(envArg) {
  if (envArg) {
    return path.resolve(envArg);
  }

  const candidates = [
    "supabase/roles/.env.role_passwords",
    "supabase/roles/.env.geo_role_passwords",
  ];

  for (const candidate of candidates) {
    const resolved = path.resolve(candidate);
    if (fs.existsSync(resolved)) {
      return resolved;
    }
  }

  return path.resolve(candidates[0]);
}

function main() {
  const [envArg, sqlArg] = process.argv.slice(2);
  const envFile = resolveEnvFile(envArg);
  const sqlFile = path.resolve(
    sqlArg ||
      "supabase/roles/20251023_create_riding_region_with_passwords_roles.sql"
  );

  ensureFile(envFile, "Password environment file");
  ensureFile(sqlFile, "SQL file");

  const passwordMap = loadPasswordMap(envFile);
  if (passwordMap.size === 0) {
    throw new Error(`No passwords found in ${envFile}`);
  }

  const result = updateSqlPasswords(sqlFile, passwordMap);

  if (!result.changed) {
    console.log(
      `No CREATE ROLE passwords changed; ${sqlFile} is already in sync.`
    );
    return;
  }

  if (result.passwordChanges) {
    console.log(`Updated role passwords in ${sqlFile}`);
  }

  if (result.stringEscapesFixed) {
    console.log(`Normalized unescaped apostrophes in SQL string literals.`);
  }
}

const isMainModule =
  process.argv[1] &&
  path.resolve(process.argv[1]) === fileURLToPath(import.meta.url);

if (isMainModule) {
  try {
    main();
  } catch (error) {
    console.error(error.message);
    process.exitCode = 1;
  }
}
