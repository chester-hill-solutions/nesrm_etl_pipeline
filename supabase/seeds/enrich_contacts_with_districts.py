#!/usr/bin/env python3
"""Augment contacts.csv with federal electoral district names.

This script reads a CSV file containing Canadian postcodes and adds a
`division_electoral_district` column by querying the Open North Represent API.
It caches lookups per postcode, reports per-row progress, and retries with
exponential backoff when rate limited.
"""

from __future__ import annotations

import argparse
import csv
import json
import sys
import time
from dataclasses import dataclass
from typing import Dict, Iterable, Optional
from urllib.error import HTTPError, URLError
from urllib.parse import quote
from urllib.request import Request, urlopen

API_URL_TEMPLATE = "https://represent.opennorth.ca/postcodes/{postcode}/"
TARGET_BOUNDARY_URL = "/boundary-sets/federal-electoral-districts-2023-representation-order/"
USER_AGENT = "nes-dashboard-district-updater/1.0"
MAX_ATTEMPTS = 5
INITIAL_BACKOFF_SECONDS = 1.0
MAX_BACKOFF_SECONDS = 16.0


@dataclass
class LookupResult:
    postcode: str
    district: str
    status: str
    message: Optional[str] = None


def normalise_postcode(value: str) -> str:
    """Strip whitespace and normalise casing for a postcode string."""
    return "" if value is None else "".join(value.split()).upper()


def fetch_district(postcode: str) -> LookupResult:
    """Fetch the district name for a postcode from the Represent API."""
    normalised = normalise_postcode(postcode)
    if not normalised:
        return LookupResult(postcode, "", "skipped", "empty postcode")

    url = API_URL_TEMPLATE.format(postcode=quote(normalised))
    request = Request(url, headers={"User-Agent": USER_AGENT})

    payload: Optional[dict] = None
    delay = INITIAL_BACKOFF_SECONDS

    for attempt in range(MAX_ATTEMPTS):
        try:
            with urlopen(request, timeout=10) as response:
                payload = json.load(response)
            break
        except HTTPError as exc:
            if exc.code == 429:
                if attempt == MAX_ATTEMPTS - 1:
                    return LookupResult(
                        postcode,
                        "",
                        "error",
                        f"rate limited after {MAX_ATTEMPTS} attempts",
                    )
                retry_after = exc.headers.get("Retry-After") if exc.headers else None
                sleep_for = delay
                if retry_after:
                    try:
                        sleep_for = max(sleep_for, float(retry_after))
                    except ValueError:
                        pass
                time.sleep(sleep_for)
                delay = min(delay * 2, MAX_BACKOFF_SECONDS)
                continue
            return LookupResult(postcode, "", "error", f"HTTP {exc.code}")
        except URLError as exc:
            return LookupResult(postcode, "", "error", f"network error: {exc.reason}")
        except json.JSONDecodeError:
            return LookupResult(postcode, "", "error", "invalid JSON response")
    else:
        return LookupResult(postcode, "", "error", "unable to fetch postcode data")

    if payload is None:
        return LookupResult(postcode, "", "error", "empty response payload")

    boundaries = payload.get("boundaries_centroid") or []
    for item in boundaries:
        related = item.get("related") or {}
        if related.get("boundary_set_url") == TARGET_BOUNDARY_URL:
            district = (item.get("name") or "").strip()
            if district:
                return LookupResult(postcode, district, "ok")

    return LookupResult(postcode, "", "not_found", "district not located in response")


def enrich_rows(rows: Iterable[dict]) -> Iterable[dict]:
    """Yield rows with an additional division_electoral_district column."""
    cache: Dict[str, LookupResult] = {}

    for row in rows:
        raw_postcode = row.get("postcode", "")
        key = normalise_postcode(raw_postcode)

        if key in cache:
            result = cache[key]
        else:
            result = fetch_district(raw_postcode)
            cache[key] = result

        if result.status != "ok" and result.message:
            print(
                f"warning: {raw_postcode!r} -> {result.status} ({result.message})",
                file=sys.stderr,
            )

        row["division_electoral_district"] = result.district
        yield row


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--input",
        default="./supabase/seed/contacts.csv",
        help="Path to the source contacts CSV",
    )
    parser.add_argument(
        "--output",
        default="./supabase/seed/contacts_with_districts.csv",
        help="Destination path for the enriched CSV",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()

    with open(args.input, newline="", encoding="utf-8") as infile:
        reader = csv.DictReader(infile)
        fieldnames = list(reader.fieldnames or [])
        rows = list(reader)
        total_rows = len(rows)

        if "division_electoral_district" not in fieldnames:
            fieldnames.append("division_electoral_district")

        with open(args.output, "w", newline="", encoding="utf-8") as outfile:
            writer = csv.DictWriter(outfile, fieldnames=fieldnames)
            writer.writeheader()

            if total_rows == 0:
                row_count = 0
            else:
                for index, row in enumerate(enrich_rows(rows), start=1):
                    writer.writerow(row)
                    print(f"{index}/{total_rows}", file=sys.stderr, flush=True)
                row_count = total_rows

    print(
        f"Wrote {row_count} rows to {args.output} with division_electoral_district column.",
        file=sys.stderr,
    )


if __name__ == "__main__":
    main()
