"""Create beneficiary-level synthetic claims modeling extract (stdlib only)."""
import csv
import sqlite3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DB = ROOT / "data/processed/healthcare_claims.db"
OUT = ROOT / "data/processed/beneficiary_model_data.csv"

SQL = """
WITH claims AS (
 SELECT DESYNPUF_ID, COUNT(DISTINCT CLM_ID) AS claim_count
 FROM inpatient_segments GROUP BY DESYNPUF_ID
)
SELECT b.DESYNPUF_ID, b.BENE_BIRTH_DT, b.BENE_SEX_IDENT_CD,
       b.SP_DIABETES, b.SP_CHF, b.SP_COPD, b.SP_CHRNKIDN,
       COALESCE(c.claim_count, 0) AS claim_count
FROM beneficiaries_2008 b
LEFT JOIN claims c ON b.DESYNPUF_ID = c.DESYNPUF_ID
"""

def main():
    conn = sqlite3.connect(f"file:{DB}?mode=ro", uri=True)
    try:
        result = conn.execute(SQL)
        with OUT.open("w", newline="") as handle:
            writer = csv.writer(handle)
            writer.writerow([d[0] for d in result.description])
            count = 0
            for row in result:
                writer.writerow(row)
                count += 1
        assert count == 116352, f"Unexpected rows: {count}"
        print(f"Exported {count:,} beneficiary records to {OUT}")
    finally:
        conn.close()

if __name__ == "__main__":
    main()
