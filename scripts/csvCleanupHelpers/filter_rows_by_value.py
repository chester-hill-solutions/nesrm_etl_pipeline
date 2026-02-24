#!/usr/bin/env python3

"""Filter CSV rows by column value.

Single-value mode: provide an input CSV, a column name, and a value. The script
writes two CSVs: rows where the column matches the value and the complement
(non-matching rows). By default it writes ``<input-name>-<column>_is_<value>.csv``
and ``<input-name>-no_<column>_is_<value>.csv`` to ``data``. An optional
``--output`` argument can override the output path or directory; if a file is
provided, it is used for the matching set and the complement is written
alongside it.

Multi-value mode: provide only an input CSV and a column name. The script
creates one file per unique value in that column using the naming pattern
``<input-name>-<column>_is_<value>.csv`` (slugified). If there are more than 10
unique values, it aborts without writing files and reports the reason.
"""

from __future__ import annotations

import argparse
import csv
import re
from pathlib import Path
from typing import Dict, List, Tuple


def slugify(text: str) -> str:
    return re.sub(r"[^A-Za-z0-9_-]+", "_", text.strip()) or "value"


def resolve_output_paths(input_path: Path, column: str, value: str, provided: Path | None) -> Tuple[Path, Path]:
    base_name = f"{input_path.stem}-{slugify(column)}_is_{slugify(value)}.csv"
    complement_name = f"{input_path.stem}-no_{slugify(column)}_is_{slugify(value)}.csv"

    if provided is None:
        base_dir = Path.cwd() / "data"
        return base_dir / base_name, base_dir / complement_name

    if provided.is_dir():
        return provided / base_name, provided / complement_name

    return provided, provided.parent / complement_name


def resolve_output_dir_multi(input_path: Path, provided: Path | None) -> Path:
    if provided is None:
        return Path.cwd() / "data"

    if provided.is_dir():
        return provided

    return provided.parent


def filter_rows(input_path: Path, column: str, value: str, output_path: Path, complement_path: Path) -> Tuple[Path, Path]:
    if not input_path.is_file():
        raise FileNotFoundError(f"Input CSV not found: {input_path}")

    with input_path.open(newline="", encoding="utf-8") as infile:
        reader = csv.DictReader(infile)
        if reader.fieldnames is None:
            raise ValueError(f"Input CSV is empty: {input_path}")

        if column not in reader.fieldnames:
            raise ValueError(f"Column '{column}' not found in CSV header")

        matching_rows: List[Dict[str, str]] = []
        nonmatching_rows: List[Dict[str, str]] = []

        for row in reader:
            if (row.get(column) or "").strip() == value:
                matching_rows.append(row)
            else:
                nonmatching_rows.append(row)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    complement_path.parent.mkdir(parents=True, exist_ok=True)

    with output_path.open("w", newline="", encoding="utf-8") as outfile:
        writer = csv.DictWriter(outfile, fieldnames=reader.fieldnames)
        writer.writeheader()
        writer.writerows(matching_rows)

    with complement_path.open("w", newline="", encoding="utf-8") as outfile:
        writer = csv.DictWriter(outfile, fieldnames=reader.fieldnames)
        writer.writeheader()
        writer.writerows(nonmatching_rows)

    return output_path, complement_path


def split_by_unique_values(input_path: Path, column: str, output_dir: Path) -> List[Path]:
    if not input_path.is_file():
        raise FileNotFoundError(f"Input CSV not found: {input_path}")

    with input_path.open(newline="", encoding="utf-8") as infile:
        reader = csv.DictReader(infile)
        if reader.fieldnames is None:
            raise ValueError(f"Input CSV is empty: {input_path}")

        if column not in reader.fieldnames:
            raise ValueError(f"Column '{column}' not found in CSV header")

        buckets: Dict[str, List[Dict[str, str]]] = {}
        for row in reader:
            key = (row.get(column) or "").strip()
            buckets.setdefault(key, []).append(row)

    unique_count = len(buckets)
    if unique_count > 10:
        raise ValueError(
            f"Aborting: found {unique_count} unique values in '{column}' (limit 10 for multi-output)."
        )

    output_dir.mkdir(parents=True, exist_ok=True)
    outputs: List[Path] = []
    for value, rows in buckets.items():
        file_path = output_dir / f"{input_path.stem}-{slugify(column)}_is_{slugify(value)}.csv"
        with file_path.open("w", newline="", encoding="utf-8") as outfile:
            writer = csv.DictWriter(outfile, fieldnames=reader.fieldnames)
            writer.writeheader()
            writer.writerows(rows)
        outputs.append(file_path)

    return outputs


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Filter rows in a CSV by column value.")
    parser.add_argument("csv_path", type=Path, help="Path to the input CSV file")
    parser.add_argument("column", help="Column name to match")
    parser.add_argument("value", nargs="?", help="Value to match (case-sensitive). If omitted, one file per unique value is produced (max 10 unique values).")
    parser.add_argument(
        "-o",
        "--output",
        type=Path,
        help=(
            "Optional output file or directory (default: data/<input>-<column>_is_<value>.csv "
            "and data/<input>-no_<column>_is_<value>.csv). If a file is provided, it "
            "is used for matches and the complement is written alongside it."
        ),
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    try:
        if args.value is None:
            outputs = split_by_unique_values(
                args.csv_path,
                args.column,
                resolve_output_dir_multi(args.csv_path, args.output),
            )
            print(f"Wrote {len(outputs)} files:")
            for path in outputs:
                print(f"- {path}")
        else:
            output_path, complement_path = filter_rows(
                args.csv_path,
                args.column,
                args.value,
                *resolve_output_paths(args.csv_path, args.column, args.value, args.output),
            )
            print(f"Wrote filtered rows to {output_path}")
            print(f"Wrote non-matching rows to {complement_path}")
    except ValueError as exc:
        print(exc)
        raise SystemExit(1)


if __name__ == "__main__":
    main()
