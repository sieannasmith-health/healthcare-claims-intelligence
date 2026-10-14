"""Export one row per beneficiary with qualifying 2008-start claims."""
import sqlite3,csv
from pathlib import Path
root=Path(__file__).resolve().parents[1]
sql="""
WITH claims AS (
 SELECT CLM_ID,MIN(DESYNPUF_ID) id, COUNT(DISTINCT DESYNPUF_ID) ids,
 COUNT(DISTINCT NULLIF(TRIM(CLM_FROM_DT),'')) date_count,
 MIN(NULLIF(TRIM(CLM_FROM_DT),'')) first_date,
 SUM(CASE WHEN TRIM(COALESCE(CLM_FROM_DT,''))='' THEN 1 ELSE 0 END) missing
 FROM inpatient_segments GROUP BY CLM_ID
)
SELECT id AS DESYNPUF_ID,COUNT(*) AS claims_2008 FROM claims
WHERE ids=1 AND date_count=1 AND missing=0
AND SUBSTR(first_date,1,4)='2008'
GROUP BY id
"""
out=root/"data/processed/beneficiary_2008_claim_counts.csv"
with sqlite3.connect(f"file:{root/'data/processed/healthcare_claims.db'}?mode=ro",uri=True) as db:
 rows=db.execute(sql).fetchall()
assert sum(n for _,n in rows)==27657
assert len(rows)==15856
with out.open("w",newline="") as f:
 w=csv.writer(f);w.writerow(["DESYNPUF_ID","claims_2008"]);w.writerows(rows)
print("Saved 2008 claim counts:",len(rows),"beneficiaries",sum(n for _,n in rows),"claims")
