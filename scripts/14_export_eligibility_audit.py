"""Export 2008-to-2009 cohort linkage and annual coverage fields for R."""
import csv,sqlite3
from pathlib import Path
root=Path(__file__).resolve().parents[1]
out=root/"data/processed/2009_eligibility_audit.csv"
sql="""
WITH starts AS (
 SELECT CLM_ID,MIN(DESYNPUF_ID) id,COUNT(DISTINCT DESYNPUF_ID) ids,
        COUNT(DISTINCT NULLIF(TRIM(CLM_FROM_DT),'')) ndates,
        MIN(NULLIF(TRIM(CLM_FROM_DT),'')) dt,
        SUM(CASE WHEN TRIM(COALESCE(CLM_FROM_DT,''))='' THEN 1 ELSE 0 END) miss
 FROM inpatient_segments GROUP BY CLM_ID
), claims AS (
 SELECT id,COUNT(*) n FROM starts
 WHERE ids=1 AND ndates=1 AND miss=0
 AND dt BETWEEN '20090101' AND '20091231'
 GROUP BY id
)
SELECT b.DESYNPUF_ID,
       CASE WHEN y.DESYNPUF_ID IS NOT NULL THEN 1 ELSE 0 END AS linked_2009,
       y.BENE_HI_CVRAGE_TOT_MONS AS hi_months_2009,
       y.BENE_SMI_CVRAGE_TOT_MONS AS smi_months_2009,
       y.BENE_HMO_CVRAGE_TOT_MONS AS hmo_months_2009,
       y.BENE_DEATH_DT AS death_date_2009,
       b.BENE_DEATH_DT AS death_date_2008,
       COALESCE(c.n,0) AS claims_started_2009
FROM beneficiaries_2008 b
LEFT JOIN beneficiaries_2009 y ON b.DESYNPUF_ID=y.DESYNPUF_ID
LEFT JOIN claims c ON b.DESYNPUF_ID=c.id
"""
with sqlite3.connect(f"file:{root/'data/processed/healthcare_claims.db'}?mode=ro",uri=True) as db:
 cur=db.execute(sql)
 with out.open("w",newline="") as f:
  w=csv.writer(f);w.writerow([d[0] for d in cur.description]);w.writerows(cur)
 n=db.execute("SELECT COUNT(*) FROM beneficiaries_2008 b JOIN beneficiaries_2009 y ON b.DESYNPUF_ID=y.DESYNPUF_ID").fetchone()[0]
print("Linked 2008 to 2009:",n)
print("Saved cohort export")
