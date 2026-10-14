"""Audit claim-level dates and summarize calendar-2008 claim starts. Read-only."""
from pathlib import Path
import sqlite3
import csv

root = Path(__file__).resolve().parents[1]
db = root / "data/processed/healthcare_claims.db"
report = root / "reports/claims_period_audit.csv"
sql = """
WITH claim_dates AS (
 SELECT CLM_ID,
        COUNT(*) AS segments,
        COUNT(DISTINCT NULLIF(TRIM(CLM_FROM_DT), '')) AS distinct_start_dates,
        MIN(NULLIF(TRIM(CLM_FROM_DT), '')) AS min_start,
        MAX(NULLIF(TRIM(CLM_FROM_DT), '')) AS max_start,
        SUM(CASE WHEN CLM_FROM_DT IS NULL OR TRIM(CLM_FROM_DT)=''
                 THEN 1 ELSE 0 END) AS missing_segments
 FROM inpatient_segments GROUP BY CLM_ID
)
SELECT CASE WHEN min_start IS NULL THEN 'missing'
            WHEN substr(min_start,1,4)='2008'
                 AND distinct_start_dates=1 AND missing_segments=0 THEN '2008_unambiguous'
            WHEN distinct_start_dates>1 THEN 'conflicting_segment_dates'
            WHEN missing_segments>0 THEN 'partially_missing'
            ELSE 'other_year' END AS date_class,
       COUNT(*) AS claims
FROM claim_dates GROUP BY date_class ORDER BY date_class
"""
with sqlite3.connect(f"file:{db}?mode=ro", uri=True) as con:
    rows = con.execute(sql).fetchall()
    unique = con.execute("SELECT COUNT(DISTINCT CLM_ID) FROM inpatient_segments").fetchone()[0]
assert sum(n for _,n in rows)==unique
with report.open("w",newline="") as f:
    w=csv.writer(f); w.writerow(["date_class","distinct_claims"]); w.writerows(rows)
print("Distinct claims:",unique)
for label,n in rows: print(label,n)
print("Saved:",report)
