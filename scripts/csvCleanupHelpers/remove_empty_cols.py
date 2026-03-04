#!/usr/bin/env python3

"""Remove entirely empty columns from a CSV file.

The script accepts a positional argument pointing to the input CSV. By default
it writes ``<input_name>-noEmptyCols.csv`` to a ``data`` folder relative to the
current working directory. An optional ``--output`` argument can override the
output path or directory. Use ``--drop-constant`` to also remove columns whose
values are identical in every row.
"""

from __future__ import annotations

import argparse
import csv
from pathlib import Path
from typing import List


def resolve_output_path(input_path: Path, provided: Path | None) -> Path:
    default_name = f"{input_path.stem}-noEmptyCols.csv"

    if provided is None:
        base_dir = Path.cwd() / "data"
        return base_dir / default_name

    if provided.is_dir():
        return provided / default_name

    return provided


def remove_empty_columns(input_path: Path, output_path: Path, drop_constant: bool) -> Path:
    if not input_path.is_file():
        raise FileNotFoundError(f"Input CSV not found: {input_path}")

    output_path.parent.mkdir(parents=True, exist_ok=True)

    with input_path.open(newline="", encoding="utf-8") as infile:
        reader = csv.reader(infile)
        try:
            header = next(reader)
        except StopIteration as exc:
            raise ValueError(f"Input CSV is empty: {input_path}") from exc

        non_empty_flags: List[bool] = [False] * len(header)
        constant_values: List[str | None] = [None] * len(header)
        rows: List[List[str]] = []

        for row in reader:
            rows.append(row)
            for idx, value in enumerate(row):
                if value.strip():
                    non_empty_flags[idx] = True

                if drop_constant:
                    current = constant_values[idx]
                    if current is None:
                        constant_values[idx] = value
                    elif current != value:
                        constant_values[idx] = "__VARIES__"

    keep_indices = [idx for idx, has_data in enumerate(non_empty_flags) if has_data]

    if drop_constant:
        keep_indices = [
            idx
            for idx in keep_indices
            if constant_values[idx] is None or constant_values[idx] == "__VARIES__"
        ]

    if not keep_indices:
        raise ValueError("All columns are empty; nothing to write.")

    with output_path.open("w", newline="", encoding="utf-8") as outfile:
        writer = csv.writer(outfile)
        writer.writerow([header[idx] for idx in keep_indices])
        for row in rows:
            trimmed = [row[idx] if idx < len(row) else "" for idx in keep_indices]
            writer.writerow(trimmed)

    return output_path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Remove columns that are empty across all rows.")
    parser.add_argument("csv_path", type=Path, help="Path to the input CSV file")
    parser.add_argument(
        "-o",
        "--output",
        type=Path,
        help="Optional output file or directory (default: data/<input_name>-noEmptyCols.csv)",
    )
    parser.add_argument(
        "--drop-constant",
        action="store_true",
        help="Also drop columns where every row has the same value.",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    output_path = remove_empty_columns(
        args.csv_path,
        resolve_output_path(args.csv_path, args.output),
        args.drop_constant,
    )
    print(f"Wrote CSV without empty columns to {output_path}")


if __name__ == "__main__":
    main()
