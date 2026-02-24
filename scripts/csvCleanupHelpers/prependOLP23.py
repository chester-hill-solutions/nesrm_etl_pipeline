#!/usr/bin/env python3

"""Prefix non-core columns with ``olp23_`` for standardized ingest.

Keeps core contact fields untouched (firstname, surname, phone, email, address,
municipality, dob, date_of_birth, birthdate, birthyear, birthmonth, postcode).
All other columns are renamed to ``olp23_<original>`` unless they already start
with ``olp23`` or ``tag``. Writes a new CSV (default: ``data/<input-stem>-olp23.csv``).
Use ``-o/--output`` to override (file or directory).
"""

from __future__ import annotations

import argparse
import csv
from pathlib import Path
from typing import Dict, List


CORE_FIELDS = {
    "firstname",
    "surname",
    "phone",
    "email",
    "address",
    "municipality",
    "dob",
    "date_of_birth",
    "birthdate",
    "birthyear",
    "birthmonth",
    "postcode",
}


def normalize_header(header: str) -> str:
    return header.strip().lower().replace(" ", "_")


def resolve_output_path(input_path: Path, provided: Path | None) -> Path:
    base_name = f"{input_path.stem}-olp23.csv"
    if provided is None:
        return Path.cwd() / "data" / base_name
    if provided.is_dir():
        return provided / base_name
    return provided


def build_header_map(fieldnames: List[str]) -> Dict[str, str]:
    mapping: Dict[str, str] = {}
    for header in fieldnames:
        norm = normalize_header(header)
        if norm in CORE_FIELDS or norm.startswith("olp23") or norm.startswith("tag"):
            mapping[header] = header
        else:
            mapping[header] = f"olp23_{header}"
    return mapping


def transform_rows(input_path: Path, header_map: Dict[str, str]) -> List[Dict[str, str]]:
    rows: List[Dict[str, str]] = []
    with input_path.open(newline="", encoding="utf-8") as infile:
        reader = csv.DictReader(infile)
        if reader.fieldnames is None:
            raise ValueError(f"Input CSV is empty: {input_path}")
        for row in reader:
            new_row: Dict[str, str] = {}
            for original, new_name in header_map.items():
                new_row[new_name] = row.get(original, "")
            rows.append(new_row)
    return rows


def prepend_olp23(input_path: Path, output_path: Path) -> Path:
    if not input_path.is_file():
        raise FileNotFoundError(f"Input CSV not found: {input_path}")

    with input_path.open(newline="", encoding="utf-8") as infile:
        reader = csv.DictReader(infile)
        if reader.fieldnames is None:
            raise ValueError(f"Input CSV is empty: {input_path}")
        fieldnames = list(reader.fieldnames)

    header_map = build_header_map(fieldnames)
    new_fieldnames = [header_map[h] for h in fieldnames]

    output_path.parent.mkdir(parents=True, exist_ok=True)
    rows = transform_rows(input_path, header_map)

    with output_path.open("w", newline="", encoding="utf-8") as outfile:
        writer = csv.DictWriter(outfile, fieldnames=new_fieldnames)
        writer.writeheader()
        writer.writerows(rows)

    return output_path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Prefix non-core columns with olp23_.")
    parser.add_argument("csv_path", type=Path, help="Path to the input CSV file")
    parser.add_argument(
        "-o",
        "--output",
        type=Path,
        help="Optional output file or directory (default: data/<input>-olp23.csv)",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    output_path = prepend_olp23(args.csv_path, resolve_output_path(args.csv_path, args.output))
    print(f"Wrote OLP23-prefixed CSV to {output_path}")


if __name__ == "__main__":
    main()
