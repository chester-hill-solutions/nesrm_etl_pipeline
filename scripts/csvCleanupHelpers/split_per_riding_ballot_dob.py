#!/usr/bin/env python3

"""Split a CSV into per-riding and per-ballot folders with DOB-normalized files.

Reads an input CSV (default: ``data/_100k-noEmptyCols-formatted-olp23.csv``) and
creates a directory tree under ``data/per-riding/``:

- ``data/per-riding/<division_electoral_district_or_blank>/per-olp23_ballot1-is-<ballot_value>/``
  - ``dob_fixed.csv`` (DOB parsed to YYYY-MM-DD, with birthdate (DD)/birthmonth/birthyear filled)
  - ``dob_unparsed.csv`` (DOB present but unparsed; birth fields blank)
  - ``dob_blank.csv`` (DOB missing/blank; birth fields blank)

Assumes DOB column name is ``date_of_birth``. Riding is taken from
``olp23_division_electoral_district`` if present, otherwise
``division_electoral_district``. Folder names are slugified for safety. Ballot
column is expected to be ``olp23_ballot1``.
"""

from __future__ import annotations

import argparse
import csv
import re
from pathlib import Path
from typing import Dict, List, Tuple


DEFAULT_INPUT = Path("data/_100k-noEmptyCols-formatted-olp23.csv")
from cleanDOB import parse_dob


def slugify(value: str) -> str:
    cleaned = value.strip()
    if not cleaned:
        return "blank"
    cleaned = cleaned.lower()
    cleaned = re.sub(r"[^a-z0-9_-]+", "_", cleaned)
    cleaned = re.sub(r"_+", "_", cleaned).strip("_")
    return cleaned or "blank"


def normalize_row(row: Dict[str, str], dob_col: str) -> Tuple[str, str, str, str, str]:
    dob_raw = row.get(dob_col, "") or ""
    parsed, was_blank = parse_dob(dob_raw)
    if parsed:
        birthyear, birthmonth, birthdate = parsed.split("-")
        return parsed, birthdate, birthmonth, birthyear, "fixed"
    if was_blank:
        return "", "", "", "", "blank"
    return "", "", "", "", "fail"


def process(input_path: Path, output_base: Path, dob_col: str, ballot_col: str) -> None:
    if not input_path.is_file():
        raise FileNotFoundError(f"Input CSV not found: {input_path}")

    with input_path.open(newline="", encoding="utf-8") as infile:
        reader = csv.DictReader(infile)
        if reader.fieldnames is None:
            raise ValueError(f"Input CSV is empty: {input_path}")

        fieldnames_out = list(reader.fieldnames)
        for derived in ("birthdate", "birthmonth", "birthyear"):
            if derived not in fieldnames_out:
                fieldnames_out.append(derived)

        buckets: Dict[str, Dict[str, Dict[str, List[Dict[str, str]]]]] = {}
        # buckets[riding][ballot][status] -> list of rows

        for row in reader:
            riding_raw = row.get("olp23_division_electoral_district") or row.get(
                "division_electoral_district", ""
            )
            riding_key = slugify(riding_raw or "")
            ballot_key = slugify(row.get(ballot_col, ""))

            dob_norm, birthdate, birthmonth, birthyear, status = normalize_row(row, dob_col)
            row[dob_col] = dob_norm
            row["birthdate"] = birthdate
            row["birthmonth"] = birthmonth
            row["birthyear"] = birthyear

            ride_bucket = buckets.setdefault(riding_key, {})
            ballot_bucket = ride_bucket.setdefault(ballot_key, {"fixed": [], "fail": [], "blank": []})
            ballot_bucket[status].append(row)

    for riding, ballots in buckets.items():
        for ballot, status_map in ballots.items():
            base_dir = output_base / riding / f"per-olp23_ballot1-is-{ballot}"
            base_dir.mkdir(parents=True, exist_ok=True)

            outputs = {
                "fixed": base_dir / "dob_fixed.csv",
                "fail": base_dir / "dob_unparsed.csv",
                "blank": base_dir / "dob_blank.csv",
            }

            for status, path in outputs.items():
                rows = status_map.get(status, [])
                with path.open("w", newline="", encoding="utf-8") as outfile:
                    writer = csv.DictWriter(outfile, fieldnames=fieldnames_out)
                    writer.writeheader()
                    writer.writerows(rows)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Split CSV per riding and ballot, normalizing DOBs.")
    parser.add_argument("csv_path", nargs="?", type=Path, default=DEFAULT_INPUT, help="Path to input CSV (default: data/_100k-noEmptyCols-formatted-olp23.csv)")
    parser.add_argument("--dob-column", default="date_of_birth", help="Name of DOB column (default: date_of_birth)")
    parser.add_argument("--ballot-column", default="olp23_ballot1", help="Name of ballot column (default: olp23_ballot1)")
    parser.add_argument("--output-base", type=Path, default=Path("data/per-riding"), help="Base output directory (default: data/per-riding)")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    process(args.csv_path, args.output_base, args.dob_column, args.ballot_column)
    print(f"Finished writing per-riding/ballot DOB splits under {args.output_base}")


if __name__ == "__main__":
    main()
