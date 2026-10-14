"""Time-ordered 2008 demographic baseline against 2009-start inpatient claims.
Only population-level synthetic descriptive cohort; not deployable prediction.
"""
import sqlite3
import csv
from pathlib import Path

root = Path(__file__).resolve().parents[1]
db_path = root / "data/processed/healthcare_claims.db"
out_path = root / "data/processed/beneficiary_2009_claim_counts.csv"
sql = """
WITH claim_audit AS (
 SELECT CLM_ID,
        MIN(DESYNPUF_ID) AS beneficiary_id,
        COUNT(DISTINCT DESYNPUF_ID) AS beneficiary_ids,
        COUNT(DISTINCT NULLIF(TRIM(CLM_FROM_DT), '')) AS start_count,
        MIN(NULLIF(TRIM(CLM_FROM_DT), '')) AS claim_start,
        SUM(CASE WHEN TRIM(COALESCE(CLM_FROM_DT,''))=''
                 THEN 1 ELSE 0 END) AS missing_start
 FROM inpatient_segments GROUP BY CLM_ID
)
SELECT beneficiary_id,COUNT(*) AS claim_count_2009
FROM claim_audit
WHERE beneficiary_ids=1 AND start_count=1 AND missing_start=0
  AND claim_start BETWEEN '20090101' AND '20091231'
GROUP BY beneficiary_id
"""
with sqlite3.connect(f"file:{db_path}?mode=ro",uri=True) as db:
    data=db.execute(sql).fetchall()
assert len(set(x for x,_ in data))==len(data)
with out_path.open("w",newline="") as f:
    w=csv.writer(f)
    w.writerow(["DESYNPUF_ID","claims_2009"])
    w.writerows(data)
print("2009-start claims:",sum(n for _,n in data))
print("2008-baseline beneficiaries with 2009-start claims:",len(data))
print("Saved:",out_path)
