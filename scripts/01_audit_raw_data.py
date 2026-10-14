#!/usr/bin/env python3
"""Project 01: streaming audit of CMS DE-SynPUF Sample 1 CSV files."""
import csv, json
from pathlib import Path
from collections import Counter

ROOT = Path.home() / "Documents" / "Healthcare-Claims-Intelligence"
RAW = ROOT / "data" / "raw"
OUT = ROOT / "reports"
OUT.mkdir(parents=True, exist_ok=True)

files = {
    "beneficiaries": RAW / "DE1_0_2008_Beneficiary_Summary_File_Sample_1.csv",
    "inpatient_claims": RAW / "DE1_0_2008_to_2010_Inpatient_Claims_Sample_1.csv"
}
audit = {}
ids = {}
for label, path in files.items():
    missing = Counter()
    observed_ids = Counter()
    claim_ids = Counter()
    rows = 0
    with path.open(newline="", encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        cols = reader.fieldnames
        for row in reader:
            rows += 1
            missing.update(k for k,v in row.items() if v is None or not v.strip())
            if row.get("DESYNPUF_ID", "").strip():
                observed_ids[row["DESYNPUF_ID"].strip()] += 1
            if label == "inpatient_claims" and row.get("CLM_ID", "").strip():
                claim_ids[row["CLM_ID"].strip()] += 1
    ids[label] = set(observed_ids)
    audit[label] = {
        "filename": path.name, "file_bytes": path.stat().st_size,
        "rows": rows, "columns": len(cols), "unique_beneficiaries": len(observed_ids),
        "missing_beneficiary_ids": missing.get("DESYNPUF_ID",0),
        "repeated_beneficiary_ids": sum(n-1 for n in observed_ids.values()),
        "unique_claim_ids": len(claim_ids) if label == "inpatient_claims" else None,
        "repeated_claim_ids": sum(n-1 for n in claim_ids.values()) if label == "inpatient_claims" else None,
        "missing_counts": dict(missing.most_common()),
        "column_names": cols
    }
audit["relationships"] = {
    "inpatient_unique_beneficiaries_without_2008_summary": len(ids["inpatient_claims"]-ids["beneficiaries"]),
    "inpatient_unique_beneficiaries_with_2008_summary": len(ids["inpatient_claims"] & ids["beneficiaries"])
}
(OUT/"initial_data_quality.json").write_text(json.dumps(audit,indent=2)+"\n")
print(json.dumps({label: {k:v for k,v in info.items() if k not in ("missing_counts","column_names")} for label,info in audit.items()},indent=2))
print("Saved", OUT/"initial_data_quality.json")
