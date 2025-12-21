#!/usr/bin/env python3
"""Convert a CSV file into SQL INSERT statements.

The script reads a CSV with headers, lowercases the column names, and
produces an INSERT statement for every row. By default, the table name
is derived from the CSV file name, but you can override it via the
``--table`` option.
"""

import argparse
import csv
import os
import sys
from typing import Iterable, List


def sql_literal(value: str) -> str:
    """Return a SQL-safe literal, handling NULL and escaping quotes."""
    if value is None or value == "":
        return "NULL"
    return "'" + value.replace("'", "''") + "'"


def rows_to_inserts(
    rows: Iterable[dict], columns: List[str], table: str
) -> Iterable[str]:
    column_list = ", ".join(columns)
    for row in rows:
        values = [sql_literal(row.get(col, "")) for col in columns]
        yield f"INSERT INTO {table} ({column_list}) VALUES ({', '.join(values)});"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("csv_path", help="Path to the input CSV file")
    parser.add_argument(
        "-t",
        "--table",
        dest="table_name",
        help="Destination table name (defaults to CSV filename)",
    )
    parser.add_argument(
        "-o",
        "--output",
        dest="output_path",
        help="Optional output file path (defaults to stdout)",
    )
    args = parser.parse_args()

    csv_path = args.csv_path
    if not os.path.isfile(csv_path):
        sys.stderr.write(f"CSV file not found: {csv_path}\n")
        return 1

    table_name = args.table_name or os.path.splitext(os.path.basename(csv_path))[0]

    try:
        with open(csv_path, newline="", encoding="utf-8") as csv_file:
            reader = csv.DictReader(csv_file)
            if reader.fieldnames is None:
                sys.stderr.write("CSV file is missing headers.\n")
                return 1
            columns = [name.strip().lower() for name in reader.fieldnames]
            inserts = rows_to_inserts(reader, columns, table_name)

            if args.output_path:
                with open(args.output_path, "w", encoding="utf-8", newline="") as out:
                    for line in inserts:
                        out.write(line + "\n")
            else:
                for line in inserts:
                    sys.stdout.write(line + "\n")
    except Exception as exc:  # pragma: no cover - safety net
        sys.stderr.write(f"Error processing CSV: {exc}\n")
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
