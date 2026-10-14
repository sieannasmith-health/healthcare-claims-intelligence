-- Descriptive 2008 claim-start cohort: consistent nonempty segment dates.
WITH claims AS (
 SELECT CLM_ID, MIN(DESYNPUF_ID) AS id,
 COUNT(DISTINCT DESYNPUF_ID) AS ids,
 COUNT(DISTINCT NULLIF(TRIM(CLM_FROM_DT),'')) AS date_count,
 MIN(NULLIF(TRIM(CLM_FROM_DT),'')) AS first_date,
 SUM(CASE WHEN TRIM(COALESCE(CLM_FROM_DT,''))='' THEN 1 ELSE 0 END) AS missing
 FROM inpatient_segments GROUP BY CLM_ID
), counts AS (
 SELECT id, COUNT(*) AS n FROM claims
 WHERE ids=1 AND date_count=1 AND missing=0
 AND SUBSTR(first_date,1,4)='2008' GROUP BY id
)
SELECT COUNT(*) AS cohort,
 SUM(CASE WHEN COALESCE(c.n,0)>0 THEN 1 ELSE 0 END) AS beneficiaries_with_claim,
 ROUND(100.0*SUM(CASE WHEN COALESCE(c.n,0)>0 THEN 1 ELSE 0 END)/COUNT(*),2) AS percent_with_claim,
 SUM(COALESCE(c.n,0)) AS claims
FROM beneficiaries_2008 b LEFT JOIN counts c ON b.DESYNPUF_ID=c.id;
