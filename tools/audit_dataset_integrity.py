#!/usr/bin/env python3
"""
Dataset Integrity Audit — Phase A (structural only).

Read-only audit of the frozen Week 3 dataset. This script:
  - counts cards / individual GT JSON / CSV rows / JSONL records
  - verifies card ID continuity (001..034) and no duplicates
  - verifies each GT id maps to exactly one PNG and vice versa
  - compares individual JSON ↔ CSV ↔ JSONL metadata fields (005..034)
  - computes SHA-256 for each PNG and reports exact duplicates
  - verifies this script itself does not modify dataset/* (hash before/after)

It does NOT:
  - perform OCR
  - modify any dataset file
  - decide image↔GT identity (that requires human visual review)

Usage:
    python3 tools/audit_dataset_integrity.py [--json]

Output: a structured report printed to stdout.
Exit code: 0 always (audit, not gate); anomalies are reported, not errored.
"""

from __future__ import annotations

import csv
import hashlib
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CARDS_DIR = ROOT / "dataset" / "cards"
GT_DIR = ROOT / "dataset" / "ground-truth"
CSV_PATH = ROOT / "dataset" / "card-index-005-034.csv"
JSONL_PATH = ROOT / "dataset" / "ground-truth-005-034.jsonl"

EXPECTED_IDS = [f"{i:03d}" for i in range(1, 35)]  # 001..034
CONSOLIDATED_IDS = [f"{i:03d}" for i in range(5, 35)]  # 005..034

# Fields compared across individual JSON / CSV / JSONL for 005..034.
COMPARE_FIELDS = [
    "id", "name", "nameLatin", "company", "companyLatin", "department",
    "jobTitle", "mobile", "phone", "fax", "email", "website", "address",
    "purpose",
]


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            h.update(chunk)
    return h.hexdigest()


def card_id_from_filename(name: str) -> str | None:
    m = re.match(r"card-(\d{3})-", name)
    return m.group(1) if m else None


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def normalize(v) -> str:
    """Normalize a metadata value for cross-source comparison."""
    if v is None:
        return ""
    if isinstance(v, list):
        # CSV stores lists as "; "-joined strings; normalize to the same.
        return "; ".join(str(x).strip() for x in v)
    return str(v).strip()


def get_field(record: dict, field: str) -> str:
    """Extract a field, tolerating schema differences between sources."""
    # individual JSON may nest fields differently; try flat first.
    if field in record:
        return normalize(record[field])
    return ""


def main() -> int:
    report: dict = {"phases": {}}

    # --- Phase 0: self-integrity — hash dataset before -------------------
    before_hashes = {
        str(p.relative_to(ROOT)): sha256_file(p)
        for p in sorted((ROOT / "dataset").rglob("*"))
        if p.is_file()
    }

    # --- Phase 1: counts --------------------------------------------------
    card_pngs = sorted(CARDS_DIR.glob("card-*.png"))
    gt_jsons = sorted(GT_DIR.glob("card-*.json"))

    png_ids = [card_id_from_filename(p.name) for p in card_pngs]
    png_ids = [i for i in png_ids if i]  # drop non-matching names
    gt_ids = [p.stem.replace("card-", "") for p in gt_jsons]

    report["phases"]["counts"] = {
        "card_pngs": len(card_pngs),
        "individual_gt_jsons": len(gt_jsons),
        "expected_pngs": 34,
        "expected_gt": 34,
        "png_count_ok": len(card_pngs) == 34,
        "gt_count_ok": len(gt_jsons) == 34,
    }

    # --- Phase 2: ID continuity + duplicates ------------------------------
    def id_continuity(ids: list[str]) -> dict:
        seen: dict[str, int] = {}
        for i in ids:
            seen[i] = seen.get(i, 0) + 1
        duplicates = {k: v for k, v in seen.items() if v > 1}
        missing = [i for i in EXPECTED_IDS if i not in seen]
        unexpected = [i for i in seen if i not in EXPECTED_IDS]
        return {
            "duplicates": duplicates,
            "missing": missing,
            "unexpected": unexpected,
            "continuous": not missing and not unexpected and not duplicates,
        }

    report["phases"]["id_continuity"] = {
        "png": id_continuity(png_ids),
        "individual_gt": id_continuity(gt_ids),
    }

    # --- Phase 3: PNG ↔ GT bijection --------------------------------------
    png_by_id = {card_id_from_filename(p.name): p.name for p in card_pngs}
    gt_by_id = {p.stem.replace("card-", ""): p.name for p in gt_jsons}

    bijection_issues = []
    for cid in EXPECTED_IDS:
        pngs = [p.name for p in card_pngs if card_id_from_filename(p.name) == cid]
        gts = [p.name for p in gt_jsons if p.stem == f"card-{cid}"]
        if len(pngs) != 1 or len(gts) != 1:
            bijection_issues.append({
                "id": cid, "png_count": len(pngs), "gt_count": len(gts),
            })

    report["phases"]["png_gt_bijection"] = {
        "ok": not bijection_issues,
        "issues": bijection_issues,
    }

    # --- Phase 4: consolidated sources (CSV + JSONL) ----------------------
    csv_rows: list[dict] = []
    if CSV_PATH.exists():
        with open(CSV_PATH, encoding="utf-8") as f:
            reader = csv.DictReader(f)
            csv_rows = list(reader)

    jsonl_records: list[dict] = []
    if JSONL_PATH.exists():
        with open(JSONL_PATH, encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if line:
                    jsonl_records.append(json.loads(line))

    csv_ids = [normalize(r.get("id", "")).replace("card-", "") for r in csv_rows]
    jsonl_ids = [normalize(r.get("id", "")).replace("card-", "") for r in jsonl_records]

    report["phases"]["consolidated_counts"] = {
        "csv_rows": len(csv_rows),
        "jsonl_records": len(jsonl_records),
        "expected": 30,
        "csv_count_ok": len(csv_rows) == 30,
        "jsonl_count_ok": len(jsonl_records) == 30,
        "csv_ids_ok": sorted(csv_ids) == CONSOLIDATED_IDS,
        "jsonl_ids_ok": sorted(jsonl_ids) == CONSOLIDATED_IDS,
    }

    # --- Phase 5: metadata cross-consistency (005..034) --------------------
    individual_gt = {}
    for p in gt_jsons:
        cid = p.stem.replace("card-", "")
        individual_gt[cid] = load_json(p)

    csv_by_id = {normalize(r.get("id", "")).replace("card-", ""): r for r in csv_rows}
    jsonl_by_id = {normalize(r.get("id", "")).replace("card-", ""): r for r in jsonl_records}

    inconsistencies = []
    not_comparable = []
    for cid in CONSOLIDATED_IDS:
        ij = individual_gt.get(cid)
        cr = csv_by_id.get(cid)
        jl = jsonl_by_id.get(cid)
        if ij is None or cr is None or jl is None:
            not_comparable.append({"id": cid, "reason": "missing source"})
            continue
        for field in COMPARE_FIELDS:
            v_ij = get_field(ij, field)
            v_cr = get_field(cr, field)
            v_jl = get_field(jl, field)
            # If a field is absent from all three sources, skip.
            if not v_ij and not v_cr and not v_jl:
                continue
            # If a field exists in only one source, mark NOT COMPARABLE.
            present = [bool(v_ij), bool(v_cr), bool(v_jl)]
            if sum(present) == 1:
                not_comparable.append({
                    "id": cid, "field": field,
                    "present_in": [
                        s for s, p_ in zip(["json", "csv", "jsonl"], present) if p_
                    ],
                })
                continue
            values = {v_ij, v_cr, v_jl}
            if len(values) > 1:
                inconsistencies.append({
                    "id": cid, "field": field,
                    "json": v_ij, "csv": v_cr, "jsonl": v_jl,
                })

    report["phases"]["metadata_consistency"] = {
        "inconsistencies": inconsistencies,
        "inconsistency_count": len(inconsistencies),
        "not_comparable": not_comparable,
        "not_comparable_count": len(not_comparable),
    }

    # --- Phase 6: image hashes + duplicates --------------------------------
    image_hashes = {}
    for p in card_pngs:
        image_hashes[p.name] = sha256_file(p)

    hash_to_files: dict[str, list[str]] = {}
    for name, h in image_hashes.items():
        hash_to_files.setdefault(h, []).append(name)

    exact_duplicates = {
        h: files for h, files in hash_to_files.items() if len(files) > 1
    }

    report["phases"]["image_hashes"] = {
        "sha256": image_hashes,
        "exact_duplicate_groups": exact_duplicates,
        "exact_duplicate_count": sum(len(v) - 1 for v in exact_duplicates.values()),
    }

    # --- Phase 7: self-integrity — dataset unchanged ----------------------
    after_hashes = {
        str(p.relative_to(ROOT)): sha256_file(p)
        for p in sorted((ROOT / "dataset").rglob("*"))
        if p.is_file()
    }
    dataset_unchanged = before_hashes == after_hashes
    report["phases"]["self_integrity"] = {
        "dataset_unchanged": dataset_unchanged,
        "files_checked": len(after_hashes),
    }

    # --- Output -------------------------------------------------------------
    if "--json" in sys.argv:
        print(json.dumps(report, indent=2, ensure_ascii=False))
    else:
        p = report["phases"]
        print("=" * 60)
        print("DATASET INTEGRITY AUDIT — STRUCTURAL REPORT")
        print("=" * 60)
        c = p["counts"]
        print(f"\n[Counts]")
        print(f"  Card PNGs:            {c['card_pngs']} (expected 34) "
              f"{'OK' if c['png_count_ok'] else 'FAIL'}")
        print(f"  Individual GT JSONs:  {c['individual_gt_jsons']} (expected 34) "
              f"{'OK' if c['gt_count_ok'] else 'FAIL'}")

        ic = p["id_continuity"]
        print(f"\n[ID Continuity 001..034]")
        print(f"  PNG:  {'OK' if ic['png']['continuous'] else 'FAIL'}")
        if ic["png"]["missing"]:
            print(f"    missing: {ic['png']['missing']}")
        if ic["png"]["duplicates"]:
            print(f"    duplicates: {ic['png']['duplicates']}")
        if ic["png"]["unexpected"]:
            print(f"    unexpected: {ic['png']['unexpected']}")
        print(f"  GT:   {'OK' if ic['individual_gt']['continuous'] else 'FAIL'}")
        if ic["individual_gt"]["missing"]:
            print(f"    missing: {ic['individual_gt']['missing']}")
        if ic["individual_gt"]["duplicates"]:
            print(f"    duplicates: {ic['individual_gt']['duplicates']}")

        b = p["png_gt_bijection"]
        print(f"\n[PNG ↔ GT Bijection]")
        print(f"  {'OK' if b['ok'] else 'FAIL'}")
        for issue in b["issues"]:
            print(f"    {issue}")

        cc = p["consolidated_counts"]
        print(f"\n[Consolidated Metadata 005..034]")
        print(f"  CSV rows:   {cc['csv_rows']} (expected 30) "
              f"{'OK' if cc['csv_count_ok'] else 'FAIL'}")
        print(f"  JSONL recs: {cc['jsonl_records']} (expected 30) "
              f"{'OK' if cc['jsonl_count_ok'] else 'FAIL'}")
        print(f"  CSV IDs 005..034:    {'OK' if cc['csv_ids_ok'] else 'FAIL'}")
        print(f"  JSONL IDs 005..034:  {'OK' if cc['jsonl_ids_ok'] else 'FAIL'}")

        mc = p["metadata_consistency"]
        print(f"\n[Metadata Consistency (JSON ↔ CSV ↔ JSONL)]")
        print(f"  Field inconsistencies: {mc['inconsistency_count']}")
        for inc in mc["inconsistencies"][:20]:
            print(f"    {inc['id']}.{inc['field']}: "
                  f"json={inc['json']!r} csv={inc['csv']!r} jsonl={inc['jsonl']!r}")
        if mc["inconsistency_count"] > 20:
            print(f"    ... and {mc['inconsistency_count'] - 20} more")
        print(f"  NOT COMPARABLE (single-source fields): {mc['not_comparable_count']}")
        for nc in mc["not_comparable"][:10]:
            print(f"    {nc}")

        ih = p["image_hashes"]
        print(f"\n[Image SHA-256 Hashes]")
        print(f"  Images hashed: {len(ih['sha256'])}")
        print(f"  Exact duplicate groups: {len(ih['exact_duplicate_groups'])}")
        for h, files in ih["exact_duplicate_groups"].items():
            print(f"    {h[:16]}... → {files}")

        si = p["self_integrity"]
        print(f"\n[Self-Integrity]")
        print(f"  Dataset unchanged by this script: "
              f"{'YES' if si['dataset_unchanged'] else 'NO — BUG IN SCRIPT'}")
        print(f"  Files hashed: {si['files_checked']}")
        print("\n" + "=" * 60)

    return 0


if __name__ == "__main__":
    sys.exit(main())
