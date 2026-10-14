-- Healthcare Claims Intelligence | CMS DE-SynPUF (synthetic data)
-- Read-only SQLite analyses. Saved 2026-10-14.
-- Distinct CLM_ID counts claims; individual segments are not necessarily admissions.

-- 01: Row counts
SELECT 'Beneficiaries' AS dataset, COUNT(*) AS total_records FROM beneficiaries_2008
UNION ALL
SELECT 'Inpatient segments', COUNT(*) FROM inpatient_segments;

-- 02: Schema
PRAGMA table_info(beneficiaries_2008);
PRAGMA table_info(inpatient_segments);

-- 03: Claim granularity and beneficiary coverage
SELECT COUNT(*) AS total_segments,
       COUNT(DISTINCT CLM_ID) AS unique_claims,
       COUNT(DISTINCT DESYNPUF_ID) AS beneficiaries_with_claims,
       COUNT(DISTINCT CLM_ID || '|' || SEGMENT) AS unique_claim_segments
FROM inpatient_segments;

-- 04: Unmatched beneficiary IDs
SELECT COUNT(*) AS inpatient_segments,
       COUNT(DISTINCT i.DESYNPUF_ID) AS inpatient_beneficiaries,
       COUNT(DISTINCT CASE WHEN b.DESYNPUF_ID IS NULL THEN i.DESYNPUF_ID END)
         AS unmatched_beneficiaries
FROM inpatient_segments i
LEFT JOIN beneficiaries_2008 b ON i.DESYNPUF_ID = b.DESYNPUF_ID;

-- 05: Claims per beneficiary among beneficiaries with inpatient claims
WITH claims_per_beneficiary AS (
  SELECT DESYNPUF_ID, COUNT(DISTINCT CLM_ID) AS claim_count
  FROM inpatient_segments GROUP BY DESYNPUF_ID
)
SELECT claim_count, COUNT(*) AS beneficiaries
FROM claims_per_beneficiary
GROUP BY claim_count ORDER BY claim_count;

-- 06: Full-cohort utilization (includes people with zero claims)
WITH claims_per_beneficiary AS (
  SELECT DESYNPUF_ID, COUNT(DISTINCT CLM_ID) AS claim_count
  FROM inpatient_segments GROUP BY DESYNPUF_ID
)
SELECT COUNT(*) AS total_beneficiaries,
       SUM(CASE WHEN c.claim_count > 0 THEN 1 ELSE 0 END) AS beneficiaries_with_claims,
       ROUND(100.0 * SUM(CASE WHEN c.claim_count > 0 THEN 1 ELSE 0 END)/COUNT(*),2)
          AS pct_with_inpatient_claims,
       ROUND(AVG(COALESCE(c.claim_count,0)),2) AS avg_claims_per_beneficiary
FROM beneficiaries_2008 b
LEFT JOIN claims_per_beneficiary c ON b.DESYNPUF_ID = c.DESYNPUF_ID;

-- 07: Sex-code-stratified utilization; refer to CMS codebook for labels
WITH claims_per_beneficiary AS (
  SELECT DESYNPUF_ID, COUNT(DISTINCT CLM_ID) AS claim_count
  FROM inpatient_segments GROUP BY DESYNPUF_ID
)
SELECT b.BENE_SEX_IDENT_CD AS sex_code, COUNT(*) AS total_beneficiaries,
       SUM(CASE WHEN c.claim_count > 0 THEN 1 ELSE 0 END) AS beneficiaries_with_claims,
       ROUND(100.0*SUM(CASE WHEN c.claim_count > 0 THEN 1 ELSE 0 END)/COUNT(*),2)
          AS pct_with_inpatient_claims,
       ROUND(AVG(COALESCE(c.claim_count,0)),2) AS avg_claims_per_beneficiary
FROM beneficiaries_2008 b
LEFT JOIN claims_per_beneficiary c ON b.DESYNPUF_ID = c.DESYNPUF_ID
GROUP BY b.BENE_SEX_IDENT_CD ORDER BY b.BENE_SEX_IDENT_CD;

-- 08: Profile diabetes indicator codes (CMS DE-SynPUF: 1=yes, 2=no)
SELECT SP_DIABETES AS diabetes_code, COUNT(*) AS beneficiaries
FROM beneficiaries_2008
GROUP BY SP_DIABETES ORDER BY SP_DIABETES;

-- 09: Inpatient utilization by diabetes indicator
WITH claims_per_beneficiary AS (
  SELECT DESYNPUF_ID, COUNT(DISTINCT CLM_ID) AS claim_count
  FROM inpatient_segments GROUP BY DESYNPUF_ID
)
SELECT CASE WHEN b.SP_DIABETES='1' THEN 'Diabetes indicator: Yes'
            WHEN b.SP_DIABETES='2' THEN 'Diabetes indicator: No'
            ELSE 'Unknown' END AS diabetes_status,
       COUNT(*) AS total_beneficiaries,
       SUM(CASE WHEN c.claim_count > 0 THEN 1 ELSE 0 END) AS beneficiaries_with_claims,
       ROUND(100.0*SUM(CASE WHEN c.claim_count > 0 THEN 1 ELSE 0 END)/COUNT(*),2)
         AS pct_with_inpatient_claims,
       ROUND(AVG(COALESCE(c.claim_count,0)),2) AS avg_claims_per_beneficiary
FROM beneficiaries_2008 b
LEFT JOIN claims_per_beneficiary c ON b.DESYNPUF_ID = c.DESYNPUF_ID
GROUP BY b.SP_DIABETES ORDER BY b.SP_DIABETES;

-- Validated outputs in this synthetic cohort:
-- 116352 beneficiaries, 66773 inpatient segments, 66705 distinct claims,
-- 37780 beneficiaries with inpatient claims, 0 unmatched beneficiary IDs.
-- 32.47% of all beneficiaries had inpatient claims; average 0.57 distinct claims.
-- Diabetes yes: 24250/44060=55.04%; no: 13530/72292=18.72%.
-- Do not generalize these synthetic estimates to actual Medicare populations.
