#!/usr/bin/env python3

"""Normalize date-of-birth values to ISO (YYYY-MM-DD) and split components.

Reads a CSV and attempts to rewrite a DOB column (default: ``date_of_birth``)
into ISO format, also populating ``birthdate`` (YYYY-MM-DD), ``birthmonth``
(MM), and ``birthyear`` (YYYY). Outputs three files in the target directory:
rows with a normalized DOB, rows with an unparsable DOB, and rows with a blank
DOB. By default outputs go to ``data/<input-stem>-dob_fixed.csv``,
``data/<input-stem>-dob_unparsed.csv``, and ``data/<input-stem>-dob_blank.csv``.
Override the output location with ``-o/--output`` (file -> used for fixed rows;
other files are written alongside; directory -> all files are placed there).
Use ``-c/--column`` to target a different DOB column.
"""

from __future__ import annotations

import argparse
import csv
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Tuple


DATE_FORMATS: Tuple[str, ...] = (
    "%Y-%m-%d",
    "%Y/%m/%d",
    "%Y-%B-%d",
    "%Y-%b-%d",
    "%d-%m-%Y",
    "%m-%d-%Y",
    "%m/%d/%Y",
    "%d/%m/%Y",
    "%y-%m-%d",
    "%y/%m/%d",
    "%y-%d-%m",
    "%y/%d/%m",
    "%m-%d-%y",
    "%m/%d/%y",
    "%d-%m-%y",
    "%d/%m/%y",
    "%B %d %Y",
    "%b %d %Y",
    "%d %B %Y",
    "%d %b %Y",
    "%B %d, %Y",
    "%b %d, %Y",
    "%d %B, %Y",
    "%d %b, %Y",
    "%B-%d-%Y",
    "%b-%d-%Y",
)


def clean_value(raw: str) -> str:
    normalized = raw.strip()
    if not normalized:
        return ""
    normalized = normalized.replace(".", "-").replace(",", " ")
    normalized = normalized.replace("/", "-")
    while "  " in normalized:
        normalized = normalized.replace("  ", " ")
    return normalized.strip()


def parse_dob(value: str) -> Tuple[str | None, bool]:
    cleaned = clean_value(value)
    if not cleaned:
        return None, True

    for fmt in DATE_FORMATS:
        try:
            return datetime.strptime(cleaned, fmt).date().isoformat(), False
        except ValueError:
            continue

    return None, False


def resolve_output_paths(input_path: Path, provided: Path | None) -> Tuple[Path, Path, Path]:
    fixed_name = f"{input_path.stem}-dob_fixed.csv"
    fail_name = f"{input_path.stem}-dob_unparsed.csv"
    blank_name = f"{input_path.stem}-dob_blank.csv"

    if provided is None:
        base = Path.cwd() / "data"
        return base / fixed_name, base / fail_name, base / blank_name

    if provided.is_dir():
        return provided / fixed_name, provided / fail_name, provided / blank_name

    base_dir = provided.parent
    return provided, base_dir / fail_name, base_dir / blank_name


def process(input_path: Path, column: str, fixed_path: Path, fail_path: Path, blank_path: Path) -> Tuple[int, int, int]:
    if not input_path.is_file():
        raise FileNotFoundError(f"Input CSV not found: {input_path}")

    with input_path.open(newline="", encoding="utf-8") as infile:
        reader = csv.DictReader(infile)
        if reader.fieldnames is None:
            raise ValueError(f"Input CSV is empty: {input_path}")

        if column not in reader.fieldnames:
            raise ValueError(f"Column '{column}' not found in CSV header")

        fieldnames_out = list(reader.fieldnames)
        for derived in ("birthdate", "birthmonth", "birthyear"):
            if derived not in fieldnames_out:
                fieldnames_out.append(derived)

        fixed_rows: List[Dict[str, str]] = []
        fail_rows: List[Dict[str, str]] = []
        blank_rows: List[Dict[str, str]] = []

        for row in reader:
            parsed, was_blank = parse_dob(row.get(column, ""))
            if parsed:
                row[column] = parsed
                row["birthdate"] = parsed
                row["birthyear"], row["birthmonth"] = parsed.split("-")[0], parsed.split("-")[1]
                fixed_rows.append(row)
            elif was_blank:
                row["birthdate"] = ""
                row["birthmonth"] = ""
                row["birthyear"] = ""
                blank_rows.append(row)
            else:
                row["birthdate"] = ""
                row["birthmonth"] = ""
                row["birthyear"] = ""
                fail_rows.append(row)

    fixed_path.parent.mkdir(parents=True, exist_ok=True)
    fail_path.parent.mkdir(parents=True, exist_ok=True)
    blank_path.parent.mkdir(parents=True, exist_ok=True)

    with fixed_path.open("w", newline="", encoding="utf-8") as outfile:
        writer = csv.DictWriter(outfile, fieldnames=fieldnames_out)
        writer.writeheader()
        writer.writerows(fixed_rows)

    with fail_path.open("w", newline="", encoding="utf-8") as outfile:
        writer = csv.DictWriter(outfile, fieldnames=fieldnames_out)
        writer.writeheader()
        writer.writerows(fail_rows)

    with blank_path.open("w", newline="", encoding="utf-8") as outfile:
        writer = csv.DictWriter(outfile, fieldnames=fieldnames_out)
        writer.writeheader()
        writer.writerows(blank_rows)

    return len(fixed_rows), len(fail_rows), len(blank_rows)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Normalize DOB column to YYYY-MM-DD, splitting successes and failures.")
    parser.add_argument("csv_path", type=Path, help="Path to the input CSV file")
    parser.add_argument(
        "-c",
        "--column",
        default="date_of_birth",
        help="Column name containing DOBs (default: date_of_birth)",
    )
    parser.add_argument(
        "-o",
        "--output",
        type=Path,
        help=(
            "Optional output file or directory (default: data/<input>-dob_fixed.csv, "
            "...-dob_unparsed.csv, and ...-dob_blank.csv). If a file is given, it is used "
            "for the fixed rows; other files are written alongside."
        ),
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    fixed_path, fail_path, blank_path = resolve_output_paths(args.csv_path, args.output)
    fixed_count, fail_count, blank_count = process(
        args.csv_path, args.column, fixed_path, fail_path, blank_path
    )
    print(f"Wrote {fixed_count} normalized DOB rows to {fixed_path}")
    print(f"Wrote {fail_count} unparsed DOB rows to {fail_path}")
    print(f"Wrote {blank_count} blank DOB rows to {blank_path}")


if __name__ == "__main__":
    main()
