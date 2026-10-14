# Healthcare Claims Intelligence
## Building and validating an epidemiologic analytics pipeline using synthetic Medicare claims

**Analyst:** Sieanna Smith  
**Methods:** SQL · Python · R · Logistic regression · Data quality · Cohort design  
**Data:** CMS DE-SynPUF Sample 1, 2008 and 2009 beneficiary summaries, 2008–2010 inpatient claims  
**Status:** Completed descriptive and exploratory analysis; not a clinically validated prediction model

### Research question

How can segmented Medicare-style inpatient claims be cleaned, linked to beneficiary records, and analyzed to understand how cohort eligibility and time alignment change estimates of inpatient claim utilization?

### Analytical workflow

1. Profiled the source CSV extracts and audited missingness and repeated claim identifiers.
2. Built a relational SQLite database, preserving segment keys and beneficiary foreign-key relationships.
3. Calculated unique claims with `COUNT(DISTINCT CLM_ID)`, rather than counting each segment as an admission.
4. Audited claim start dates before narrowing the analysis to 2008 and 2009 claim-start windows.
5. Linked annual beneficiary summary records; assessed Part A and B coverage, HMO months, and recorded deaths.
6. Conducted logistic regression and diagnostic comparisons in R, with explicit limitations on claims-derived condition flags.
7. Audited death-date consistency and potential post-death claim starts.

### Dataset validation

| Metric | Verified result |
|---|---:|
| 2008 beneficiary records | 116,352 |
| 2009 beneficiary records | 114,538 |
| Linked beneficiary records | 114,538 |
| Inpatient claim segments | 66,773 |
| Unique claim IDs, full extract | 66,705 |
| Unmatched inpatient beneficiary IDs | 0 |
| Qualifying 2008-start claims | 27,657 |
| Qualifying 2009-start claims | 25,197 |

### Denominator sensitivity: 2009 inpatient claim starts

| Cohort rule | Beneficiaries | With claims | Percentage |
|---|---:|---:|---:|
| All 2008 summary records | 116,352 | 18,809 | 16.17 |
| Matched to 2009 summary | 114,538 | 18,809 | 16.42 |
| 12 months Part A | 106,914 | 18,652 | 17.45 |
| 12 months Parts A and B | 104,046 | 18,503 | 17.78 |
| 12 months Parts A and B, no HMO months | 72,685 | 12,911 | 17.76 |

The numerator counts beneficiaries with one or more **distinct claims starting in 2009**, not clinically adjudicated hospital admissions. Percentages describe this synthetic extract, not real Medicare utilization.

### Mortality and timing quality checks

| Test | Observed |
|---|---:|
| Death dates in 2008 summary | 1,814 |
| Death dates in 2009 summary | 1,784 |
| Conflicting nonempty death dates in both summaries | 0 |
| Unique qualifying claims with start dates after recorded death | 0 |
| Qualifying claims on death date | 0 |

The date audit uses the available claims and recorded death dates; absence of observed inconsistencies is not proof of complete follow-up.

### Statistical modeling

The first cross-sectional model used 2008 beneficiary attributes against the multi-year inpatient extract. We subsequently corrected the outcome definition to distinguish 2008-only and 2009-only claim starts. The larger AUC for a same-period model using claims-derived chronic-condition flags suggests strong information overlap; it does not establish prediction of future hospitalization.

For the **2009 time-ordered demographics-only model**, which used age and sex measured in the 2008 summary:

- Held-out AUC: **0.525**
- Held-out Brier score: **0.1354**

After restricting to 12 months Parts A and B coverage with no HMO months:

- Analysis group: **72,685**
- With a qualifying 2009-start claim: **12,911 (17.76%)**
- Age-and-sex model held-out AUC: **0.520**
- Brier score: **0.1461**

A sensitivity analysis excluding the 1,123 recorded 2009 deaths yielded 71,562 beneficiaries and 17.89% with qualifying claims. This survivor restriction is **not** preferred for causal or risk analysis, since it can introduce selection bias.

### Scientific interpretation

**Key finding:** The population denominator and observation window materially change descriptive inpatient utilization estimates. SQL validation, cohort linkage, feature provenance, and eligibility definitions are as important as fitting a statistical model.

**Limitations:** CMS DE-SynPUF is synthetic and not representative of real Medicare populations. Annual coverage-month counts are not complete longitudinal person-time. Distinct claim identifiers do not necessarily equal unique admissions. Some chronic-condition flags derive from synthetic claims, and their source windows may overlap the outcome. No causal inference or deployable clinical risk prediction is claimed.

### Reproducibility

The private repository contains SQL, Python, and R scripts, analytical summaries and diagnostics. Source and beneficiary-level derived datasets, SQLite files, and IDE configuration are excluded from version control.

Relevant code:
- `sql/01_inpatient_utilization.sql`
- `sql/02_2008_claim_start_cohort.sql`
- `scripts/09_2008_model_comparison.R`
- `scripts/12_2009_temporal_baseline.R`
- `scripts/15_2009_eligibility_audit.R`
- `scripts/16_mortality_followup_model.R`
- `scripts/17_death_claim_timing_audit.py`

**Conclusion:** This case study demonstrates reproducible healthcare data engineering, data-quality assessment, epidemiologic cohort construction, multivariable analysis, and evidence-based reporting.
