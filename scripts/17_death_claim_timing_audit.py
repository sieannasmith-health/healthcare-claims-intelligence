"""Read-only death-date consistency and claim timing audit for synthetic CMS data."""
from pathlib import Path
import sqlite3, csv
root=Path(__file__).resolve().parents[1]
db=root/"data/processed/healthcare_claims.db"
sql="""
WITH deaths AS (
 SELECT a.DESYNPUF_ID,
 NULLIF(TRIM(a.BENE_DEATH_DT),'') death08,
 NULLIF(TRIM(b.BENE_DEATH_DT),'') death09,
 COALESCE(NULLIF(TRIM(b.BENE_DEATH_DT),''),NULLIF(TRIM(a.BENE_DEATH_DT),'')) death_date
 FROM beneficiaries_2008 a LEFT JOIN beneficiaries_2009 b ON a.DESYNPUF_ID=b.DESYNPUF_ID
), claims AS (
 SELECT CLM_ID,MIN(DESYNPUF_ID) id,
 COUNT(DISTINCT DESYNPUF_ID) person_ids,
 COUNT(DISTINCT NULLIF(TRIM(CLM_FROM_DT),'')) start_dates,
 MIN(NULLIF(TRIM(CLM_FROM_DT),'')) start_date,
 SUM(CASE WHEN TRIM(COALESCE(CLM_FROM_DT,''))='' THEN 1 ELSE 0 END) missing_dates
 FROM inpatient_segments GROUP BY CLM_ID
), outcomes AS (
 SELECT c.*,d.death08,d.death09,d.death_date
 FROM claims c LEFT JOIN deaths d ON c.id=d.DESYNPUF_ID
)
SELECT
 (SELECT COUNT(*) FROM deaths WHERE death08 IS NOT NULL) death08_count,
 (SELECT COUNT(*) FROM deaths WHERE death09 IS NOT NULL) death09_count,
 (SELECT COUNT(*) FROM deaths WHERE death08 IS NOT NULL AND death09 IS NOT NULL AND death08<>death09) conflicting_death_dates,
 (SELECT COUNT(*) FROM outcomes WHERE person_ids=1 AND start_dates=1 AND missing_dates=0 AND death_date IS NOT NULL AND start_date>death_date) claims_started_after_death,
 (SELECT COUNT(DISTINCT id) FROM outcomes WHERE person_ids=1 AND start_dates=1 AND missing_dates=0 AND death_date IS NOT NULL AND start_date>death_date) beneficiaries_with_post_death_claim,
 (SELECT COUNT(*) FROM outcomes WHERE person_ids=1 AND start_dates=1 AND missing_dates=0 AND death_date IS NOT NULL AND start_date=death_date) claims_started_on_death,
 (SELECT COUNT(*) FROM outcomes WHERE death_date IS NOT NULL AND (start_dates<>1 OR missing_dates>0)) unassessable_claim_dates_with_death
"""
with sqlite3.connect(f"file:{db}?mode=ro",uri=True) as con:
 cur=con.execute(sql);names=[x[0] for x in cur.description];values=cur.fetchone()
out=root/"reports/death_claim_timing_audit.csv"
with out.open("w",newline="") as f:
 w=csv.writer(f);w.writerow(names);w.writerow(values)
for k,v in zip(names,values): print(k,v)
