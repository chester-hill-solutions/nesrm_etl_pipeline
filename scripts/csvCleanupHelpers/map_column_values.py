#!/usr/bin/env python3
"""
Map values from one column to another in CSV files.
"""

import argparse
import glob
import os
import sys

import csv


def parse_args():
    parser = argparse.ArgumentParser(
        description="Map values from one column to another in CSV files.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument(
        "--input-glob",
        required=True,
        help="Glob pattern for input CSV files."
    )
    parser.add_argument(
        "--input-col",
        required=True,
        help="Name of the source column."
    )
    parser.add_argument(
        "--input-values",
        required=True,
        nargs="+",
        help="List of source values to map."
    )
    parser.add_argument(
        "--output-col",
        required=True,
        help="Name of the target column (created if missing)."
    )
    parser.add_argument(
        "--output-values",
        required=True,
        nargs="+",
        help="List of target values corresponding to input values."
    )
    parser.add_argument(
        "--overwrite",
        action="store_true",
        help="Overwrite non-empty target cells (default: skip)."
    )
    return parser.parse_args()


def main():
    args = parse_args()

    if len(args.input_values) != len(args.output_values):
        sys.exit("Error: --input-values and --output-values must have the same number of elements.")

    files = glob.glob(args.input_glob)
    if not files:
        sys.exit(f"Error: no files match pattern {args.input_glob!r}")

    mapping = dict(zip(args.input_values, args.output_values))

    for infile in files:
        with open(infile, newline="") as rf:
            reader = csv.DictReader(rf)
            fieldnames = list(reader.fieldnames) if reader.fieldnames else []
            if args.input_col not in fieldnames:
                print(f"Skipping {infile!r}: missing column {args.input_col!r}")
                continue
            if args.output_col not in fieldnames:
                fieldnames.append(args.output_col)

            rows = []
            total = 0
            updated = 0

            for row in reader:
                total += 1
                src = row.get(args.input_col, "")
                if src in mapping:
                    existing = row.get(args.output_col, "")
                    if args.overwrite or existing == "":
                        row[args.output_col] = mapping[src]
                        updated += 1
                rows.append(row)

        skipped = total - updated
        base, ext = os.path.splitext(infile)
        outname = f"{base}-transform_{args.input_col}_to_{args.output_col}{ext}"

        with open(outname, "w", newline="") as wf:
            writer = csv.DictWriter(wf, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(rows)

        print(f"{infile!r}: rows={total}, updated={updated}, skipped={skipped}, output={outname!r}")


if __name__ == "__main__":
    main()
