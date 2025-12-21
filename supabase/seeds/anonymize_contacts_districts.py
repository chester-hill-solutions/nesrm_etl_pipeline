#!/usr/bin/env python3
"""Create an anonymised variant of contact_districts.csv.

The script pseudonymises personally identifiable fields (firstname, surname,
email, phone, street_address) with deterministic but fake values so the result
remains useful for development and analytics without exposing real identities.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import re
import sys
from typing import Dict, Iterable, List

DEFAULT_INPUT = "./supabase/seed/contact_districts.csv"
DEFAULT_OUTPUT = "./supabase/seed/contact_districts_redacted.csv"

FIRST_NAMES: List[str] = [
    "Avery",
    "Jordan",
    "Taylor",
    "Morgan",
    "Peyton",
    "Riley",
    "Harper",
    "Quinn",
    "Rowan",
    "Sawyer",
    "Skyler",
    "Emerson",
    "Finley",
    "Dakota",
    "Hayden",
    "Lennon",
    "Parker",
    "Reese",
    "Sloane",
    "Tatum",
]

LAST_NAMES: List[str] = [
    "Archer",
    "Bennett",
    "Callaghan",
    "Dalton",
    "Everett",
    "Fitzgerald",
    "Gallagher",
    "Harrison",
    "Jamison",
    "Kensington",
    "Langley",
    "Monroe",
    "Noble",
    "Oakley",
    "Prescott",
    "Ramsey",
    "Sterling",
    "Thatcher",
    "Whitaker",
    "Winslow",
]

STREET_NAMES: List[str] = [
    "Maple",
    "Cedar",
    "Spruce",
    "Elm",
    "Willow",
    "Birch",
    "Laurel",
    "Hawthorn",
    "Sycamore",
    "Ash",
    "Chestnut",
    "Poplar",
    "Juniper",
    "Magnolia",
    "Hemlock",
    "Pinecrest",
    "Riverstone",
    "Silverleaf",
    "Stonebridge",
    "Foxglove",
]

STREET_SUFFIXES: List[str] = [
    "Ave",
    "St",
    "Rd",
    "Blvd",
    "Way",
    "Cres",
    "Pl",
    "Ln",
    "Terr",
    "Dr",
]

EMAIL_DOMAINS: List[str] = [
    "example.com",
    "samplemail.com",
    "demoapp.dev",
    "sandbox.net",
    "testmail.org",
]


def stable_hash(value: str) -> bytes:
    return hashlib.sha256(value.encode("utf-8", "ignore")).digest()


def choose_option(key: str, options: List[str]) -> str:
    digest = stable_hash(key)
    index = digest[0] % len(options)
    return options[index]


def generate_phone(key: str) -> str:
    digest = stable_hash(key)
    digits = "".join(str(byte % 10) for byte in digest)
    if len(digits) < 7:
        digits = (digits * 3)[:7]
    area = "555"
    exchange = digits[:3]
    subscriber = digits[3:7]
    return f"{area}{exchange}{subscriber}"


def generate_street(key: str) -> str:
    digest = stable_hash(key)
    number = 100 + int.from_bytes(digest[:2], "big") % 900
    name = STREET_NAMES[digest[2] % len(STREET_NAMES)]
    suffix = STREET_SUFFIXES[digest[3] % len(STREET_SUFFIXES)]
    if digest[4] % 5 == 0:
        unit = 100 + digest[5] % 900
        return f"{unit}-{number} {name} {suffix}"
    return f"{number} {name} {suffix}"


def slugify(value: str, fallback: str) -> str:
    slug = re.sub(r"[^a-z0-9]+", "", value.lower())
    return slug or fallback


def generate_email(first: str, last: str, key: str) -> str:
    digest = stable_hash(key)
    base = f"{slugify(first, 'user')}.{slugify(last, 'person')}"
    suffix = digest[0] % 1000
    domain = EMAIL_DOMAINS[digest[1] % len(EMAIL_DOMAINS)]
    return f"{base}{suffix:03d}@{domain}"


def anonymise_rows(rows: Iterable[dict]) -> Iterable[dict]:
    first_cache: Dict[str, str] = {}
    last_cache: Dict[str, str] = {}

    for index, row in enumerate(rows):
        first_original = row.get("firstname", "")
        last_original = row.get("surname", "")
        phone_original = row.get("phone", "")
        street_original = row.get("street_address", "")
        email_original = row.get("email", "")

        first_key = first_original or f"row-{index}-first"
        last_key = last_original or f"row-{index}-last"

        if first_key not in first_cache:
            first_cache[first_key] = choose_option(f"first|{first_key}", FIRST_NAMES)
        if last_key not in last_cache:
            last_cache[last_key] = choose_option(f"last|{last_key}", LAST_NAMES)

        new_first = first_cache[first_key]
        new_last = last_cache[last_key]

        anonymise_key = f"row-{index}|{first_original}|{last_original}|{email_original}"

        new_phone = generate_phone(f"phone|{phone_original or anonymise_key}")
        new_street = generate_street(f"street|{street_original or anonymise_key}")
        new_email = generate_email(new_first, new_last, f"email|{anonymise_key}")

        row["firstname"] = new_first
        row["surname"] = new_last
        row["phone"] = new_phone
        row["street_address"] = new_street
        row["email"] = new_email

        yield row


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--input",
        default=DEFAULT_INPUT,
        help="Path to the source contacts_districts CSV",
    )
    parser.add_argument(
        "--output",
        default=DEFAULT_OUTPUT,
        help="Destination path for the anonymised CSV",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()

    with open(args.input, newline="", encoding="utf-8") as infile:
        reader = csv.DictReader(infile)
        fieldnames = reader.fieldnames or []

        rows = list(reader)
        total = len(rows)

        with open(args.output, "w", newline="", encoding="utf-8") as outfile:
            writer = csv.DictWriter(outfile, fieldnames=fieldnames)
            writer.writeheader()

            for index, row in enumerate(anonymise_rows(rows), start=1):
                writer.writerow(row)
                if total:
                    print(f"{index}/{total}", file=sys.stderr, flush=True)

    print(f"Anonymised {total} rows into {args.output}", file=sys.stderr)


if __name__ == "__main__":
    main()
