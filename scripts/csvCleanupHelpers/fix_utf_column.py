#!/usr/bin/env python3

"""Fix mojibake/UTF issues in a specified CSV column.

Takes an input CSV and repairs the target column (e.g., turning "Orl√©ans" into
"Orléans" or "Beaches‚ÄîEast York" into "Beaches—East York") without dropping
characters. Writes a corrected CSV to ``data/<input-stem>-utf_fixed.csv`` by
default. Use ``-o/--output`` to override the destination (file or directory).
"""

from __future__ import annotations

import argparse
import csv
from pathlib import Path
from typing import Dict, List, Tuple


def _try_repair_mojibake(text: str) -> str | None:
    # Typical mojibake: UTF-8 bytes decoded as single-byte encodings, then re-encoded.
    for encoding in ("latin-1", "cp1252", "mac_roman"):
        try:
            raw_bytes = text.encode(encoding, errors="strict")
        except Exception:
            continue
        try:
            repaired = raw_bytes.decode("utf-8", errors="strict")
        except Exception:
            continue
        if repaired != text:
            return repaired
    return None


COMMON_REPLACEMENTS = {
    # Accents commonly seen as mojibake
    "√©": "é",
    "√®": "ê",
    "√´": "ô",
    "√ª": "î",
    "√§": "ç",
    "√º": "ú",
    "√±": "ñ",
    # Dashes/quotes and punctuation
    "‚Äî": "—",
    "‚Äì": "–",
    "‚Äô": "’",
    "‚Äù": "”",
    "‚Äú": "“",
    "â€“": "–",
    "â€”": "—",
    "â€™": "’",
    "â€œ": "“",
    "â€�": "”",
    "â€¦": "…",
    "Ã¢â‚¬â€œ": "–",
    "Ã¢â‚¬â€�": "—",
    "Ã¢â‚¬Ëœ": "‘",
    "Ã¢â‚¬â„¢": "’",
    "Ã¢â‚¬Å“": "“",
    "Ã¢â‚¬ï¿½": "”",
}


def apply_common_replacements(text: str) -> str:
    repaired = text
    changed = True
    while changed:
        changed = False
        for bad, good in COMMON_REPLACEMENTS.items():
            if bad in repaired:
                repaired = repaired.replace(bad, good)
                changed = True
    return repaired


def _byte_roundtrip_fix(text: str) -> str | None:
    markers = ("Ã", "â", "Â", "‚", "ƒ")
    if not any(m in text for m in markers):
        return None
    try:
        candidate = text.encode("cp1252", errors="replace").decode("utf-8", errors="replace")
    except Exception:
        return None
    if candidate != text and "�" not in candidate:
        return candidate
    return None


def fix_text(value: str) -> str:
    if value is None:
        return ""
    original = value

    # First pass: common replacements
    replaced = apply_common_replacements(original)

    # Second pass: structured mojibake repair
    repaired = _try_repair_mojibake(replaced)
    if repaired is not None:
        replaced = repaired

    # Third pass: byte round-trip heuristic for common mojibake markers
    rt = _byte_roundtrip_fix(replaced)
    if rt is not None:
        replaced = rt

    # Final pass: ensure replacements are fully applied
    replaced = apply_common_replacements(replaced)

    return replaced


def resolve_output_path(input_path: Path, provided: Path | None) -> Path:
    base_name = f"{input_path.stem}-utf_fixed.csv"

    if provided is None:
        return Path.cwd() / "data" / base_name

    if provided.is_dir():
        return provided / base_name

    return provided


def process(input_path: Path, column: str, output_path: Path) -> Tuple[int, int]:
    if not input_path.is_file():
        raise FileNotFoundError(f"Input CSV not found: {input_path}")

    with input_path.open(newline="", encoding="utf-8") as infile:
        reader = csv.DictReader(infile)
        if reader.fieldnames is None:
            raise ValueError(f"Input CSV is empty: {input_path}")
        if column not in reader.fieldnames:
            raise ValueError(f"Column '{column}' not found in CSV header")

        rows: List[Dict[str, str]] = []
        fixed_count = 0
        total_count = 0

        for row in reader:
            total_count += 1
            value = row.get(column, "")
            fixed = fix_text(value)
            if fixed != value:
                fixed_count += 1
            row[column] = fixed
            rows.append(row)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    with output_path.open("w", newline="", encoding="utf-8") as outfile:
        writer = csv.DictWriter(outfile, fieldnames=reader.fieldnames)
        writer.writeheader()
        writer.writerows(rows)

    return fixed_count, total_count


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Fix mojibake/UTF issues in a CSV column.")
    parser.add_argument("csv_path", type=Path, help="Path to the input CSV file")
    parser.add_argument("column", help="Column name to repair")
    parser.add_argument(
        "-o",
        "--output",
        type=Path,
        help="Optional output file or directory (default: data/<input>-utf_fixed.csv)",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    output_path = resolve_output_path(args.csv_path, args.output)
    fixed_count, total_count = process(args.csv_path, args.column, output_path)
    print(f"Wrote repaired CSV to {output_path} ({fixed_count} of {total_count} rows changed)")


if __name__ == "__main__":
    main()
