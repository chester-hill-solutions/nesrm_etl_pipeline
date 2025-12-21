#!/usr/bin/env python3
"""Convert a CSV with a `dob` column into one with birth components.

Reads an input CSV, removes the `dob` column, and adds three new columns:
`birthyear`, `birthmonth`, and `birthdate`. The script expects dates in ISO
format (YYYY-MM-DD) but falls back to blanks when the value is missing or
unparseable.
"""

from __future__ import annotations

import argparse
import csv
import sys
from datetime import datetime
from typing import List, Sequence

DEFAULT_INPUT = "./supabase/seed/contact_districts.csv"
DEFAULT_OUTPUT = "./supabase/seed/contact_districts_birthparts.csv"


def parse_dob(value: str) -> tuple[str, str, str]:
    if not value:
        return "", "", ""

    cleaned = value.strip()
    if not cleaned:
        return "", "", ""

    formats = ["%Y-%m-%d", "%Y/%m/%d", "%d-%m-%Y", "%d/%m/%Y"]
    for fmt in formats:
        try:
            dt = datetime.strptime(cleaned, fmt)
            return str(dt.year), f"{dt.month:02d}", f"{dt.day:02d}"
        except ValueError:
            continue

    print(f"warning: could not parse dob value {cleaned!r}", file=sys.stderr)
    return "", "", ""


def updated_fieldnames(fieldnames: Sequence[str]) -> List[str]:
    if "dob" not in fieldnames:
        raise ValueError("Input CSV is missing required 'dob' column")

    base = list(fieldnames)
    idx = base.index("dob")
    return base[:idx] + ["birthyear", "birthmonth", "birthdate"] + base[idx + 1 :]


def process_file(input_path: str, output_path: str) -> None:
    with open(input_path, newline="", encoding="utf-8") as infile:
        reader = csv.DictReader(infile)
        if reader.fieldnames is None:
            raise ValueError("Input CSV missing header row")

        out_fieldnames = updated_fieldnames(reader.fieldnames)

        rows = list(reader)
        total = len(rows)

    with open(output_path, "w", newline="", encoding="utf-8") as outfile:
        writer = csv.DictWriter(outfile, fieldnames=out_fieldnames)
        writer.writeheader()

        for index, row in enumerate(rows, start=1):
            birthyear, birthmonth, birthdate = parse_dob(row.get("dob", ""))

            row["birthyear"] = birthyear
            row["birthmonth"] = birthmonth
            row["birthdate"] = birthdate
            row.pop("dob", None)

            writer.writerow(row)
            if total:
                print(f"{index}/{total}", file=sys.stderr, flush=True)

    print(
        f"Converted {total} rows from {input_path} to {output_path}",
        file=sys.stderr,
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--input",
        default=DEFAULT_INPUT,
        help="Path to the source CSV containing a 'dob' column",
    )
    parser.add_argument(
        "--output",
        default=DEFAULT_OUTPUT,
        help="Destination path for the transformed CSV",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()

    try:
        process_file(args.input, args.output)
    except Exception as exc:  # pragma: no cover - convenience for CLI usage
        print(f"error: {exc}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
