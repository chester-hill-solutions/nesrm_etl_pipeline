#!/usr/bin/env python3

"""Normalize CSV headers for ingest and reorder common contact fields.

The script standardizes common columns (e.g., first/last name, phone, email,
gender, DOB, VAN ID) and pulls additional priority columns (ballots, donor /
donation info, location, language, organizer/recruiter) to the front. By
default, it writes to ``data/<input-name>-formatted.csv``. Use ``-o/--output``
to override the output file or directory (directories still use the
``<input-name>-formatted.csv`` filename). No complement file is produced.
"""

from __future__ import annotations

import argparse
import csv
import re
from pathlib import Path
from typing import Dict, List, Set, Tuple


TARGET_ORDER = [
    "firstname",
    "surname",
    "phone",
    "email",
    "address",
    "municipality",
    "postcode",
    "tags:culture",
    "gender",
    "date_of_birth",
    "birthyear",
    "birthmonth",
    "birthdate",
    "comms_consent",
    "member",
    "van_id",
    "voted",
    "division_electoral_district",
    "campus_club",
    "olp23_organizer",
]


def normalize(text: str) -> str:
    cleaned = re.sub(r"[^A-Za-z0-9]+", " ", text).strip().lower()
    return re.sub(r"\s+", " ", cleaned)


def to_lower_underscored(text: str) -> str:
    return re.sub(r"\s+", "_", text.strip().lower())


VARIANT_MAP: Dict[str, str] = {
    "firstname": "firstname",
    "first name": "firstname",
    "lastname": "surname",
    "last name": "surname",
    "sur name": "surname",
    "surname": "surname",
    "phone number": "phone",
    "phonenumber": "phone",
    "phone": "phone",
    "email": "email",
    "email address": "email",
    "e mail address": "email",
    "address": "address",
    "street address": "address_street_fallback",
    "city": "municipality",
    "municipality": "municipality",
    "postcode": "postcode",
    "postal code": "postcode",
    "postalcode": "postcode",
    "zip code": "postcode",
    "zipcode": "postcode",
    "riding": "division_electoral_district",
    "country": "country",
    "region": "country",
    "country region": "country",
    "country/region": "country",
    "language": "tags:culture",
    "religion": "tags:culture",
    "religious affiliation": "tags:culture",
    "campus": "campus_club",
    "campus club": "campus_club",
    "campusclub": "campus_club",
    "campus clubs": "campus_club",
    "gender": "gender",
    "date of birth": "date_of_birth",
    "dob": "date_of_birth",
    "birthdate": "birthdate",
    "birth date": "birthdate",
    "birthmonth": "birthmonth",
    "birth month": "birthmonth",
    "birthyear": "birthyear",
    "birth year": "birthyear",
    "member": "member",
    "van id": "van_id",
    "vanid": "van_id",
    "van_id": "van_id",
    "voted": "voted",
    "recruited by": "olp23_organizer",
    "recruiter": "olp23_organizer",
}


def is_priority_header(norm: str) -> bool:
    if norm.startswith("ballot"):
        return True
    if "donation" in norm or "donor" in norm:
        return True
    if "total spend" in norm:
        return True
    if "country" in norm or "region" in norm:
        return True
    if "state" in norm or "province" in norm:
        return True
    if "language" in norm:
        return True
    if "organizer" in norm:
        return True
    if "recruiter" in norm or "recruited" in norm:
        return True
    if "liberal member" in norm:
        return True
    if "nate sign up" in norm:
        return True
    if "support level" in norm:
        return True
    if "voter id method" in norm:
        return True
    if "volunteer status" in norm:
        return True
    if "volunteer preference" in norm:
        return True
    return False


def resolve_output_path(input_path: Path, provided: Path | None) -> Path:
    base_name = f"{input_path.stem}-formatted.csv"

    if provided is None:
        return Path.cwd() / "data" / base_name

    if provided.is_dir():
        return provided / base_name

    return provided


def map_headers(fieldnames: List[str]) -> Tuple[Dict[str, str], List[Tuple[str, str]], List[Tuple[str, str]]]:
    canonical_sources: Dict[str, str] = {}
    priority_mappings: List[Tuple[str, str]] = []  # (target, source)
    other_mappings: List[Tuple[str, str]] = []  # (target, source)
    priority_seen: Set[str] = set()
    street_fallback: str | None = None

    for header in fieldnames:
        norm = normalize(header)
        mapped = VARIANT_MAP.get(norm)

        if mapped is not None:
            if mapped == "address_street_fallback":
                if street_fallback is None:
                    street_fallback = header
                continue

            if mapped not in canonical_sources:
                canonical_sources[mapped] = header
            continue

        if is_priority_header(norm):
            if header not in priority_seen:
                priority_seen.add(header)
                priority_mappings.append((to_lower_underscored(header), header))
            continue

        other_mappings.append((to_lower_underscored(header), header))

    if "address" not in canonical_sources and street_fallback:
        canonical_sources["address"] = street_fallback

    return canonical_sources, priority_mappings, other_mappings


def build_output_headers(
    canonical_sources: Dict[str, str], priority_mappings: List[Tuple[str, str]], other_mappings: List[Tuple[str, str]]
) -> List[str]:
    ordered = [name for name in TARGET_ORDER if name in canonical_sources]
    ordered.extend(target for target, _ in priority_mappings)
    ordered.extend(target for target, _ in other_mappings)
    return ordered


def transform_rows(
    input_path: Path, column_map: Dict[str, str], output_headers: List[str]
) -> List[Dict[str, str]]:
    rows: List[Dict[str, str]] = []

    with input_path.open(newline="", encoding="utf-8") as infile:
        reader = csv.DictReader(infile)
        if reader.fieldnames is None:
            raise ValueError(f"Input CSV is empty: {input_path}")

        for row in reader:
            new_row: Dict[str, str] = {}
            for header in output_headers:
                if header in column_map:
                    source = column_map[header]
                    value = row.get(source, "")
                    if header.startswith("tag"):
                        value = value.lower()
                    if header == "comms_consent":
                        if value == "" and row.get("olp23_ballot1", "").strip() in {"Nate Erskine-Smith", "Possible Nate"}:
                            value = "true"
                    new_row[header] = value
                else:
                    new_row[header] = row.get(header, "")
            rows.append(new_row)

    return rows


def format_for_ingest(input_path: Path, output_path: Path) -> Path:
    if not input_path.is_file():
        raise FileNotFoundError(f"Input CSV not found: {input_path}")

    with input_path.open(newline="", encoding="utf-8") as infile:
        reader = csv.DictReader(infile)
        if reader.fieldnames is None:
            raise ValueError(f"Input CSV is empty: {input_path}")
        fieldnames = list(reader.fieldnames)

    canonical_map, priority_mappings, other_mappings = map_headers(fieldnames)
    combined_map: Dict[str, str] = {**canonical_map, **{t: s for t, s in priority_mappings}, **{t: s for t, s in other_mappings}}
    output_headers = build_output_headers(canonical_map, priority_mappings, other_mappings)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    transformed_rows = transform_rows(input_path, combined_map, output_headers)

    with output_path.open("w", newline="", encoding="utf-8") as outfile:
        writer = csv.DictWriter(outfile, fieldnames=output_headers)
        writer.writeheader()
        writer.writerows(transformed_rows)

    return output_path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Format CSV headers for ingest and reorder common fields.")
    parser.add_argument("csv_path", type=Path, help="Path to the input CSV file")
    parser.add_argument(
        "-o",
        "--output",
        type=Path,
        help="Optional output file or directory (default: data/<input-name>-formatted.csv)",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    output_path = format_for_ingest(args.csv_path, resolve_output_path(args.csv_path, args.output))
    print(f"Wrote formatted CSV to {output_path}")


if __name__ == "__main__":
    main()
