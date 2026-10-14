# 2009 Medicare Beneficiary Linkage and Eligibility Audit

**Source:** CMS DE-SynPUF Sample 1, beneficiary summary files for 2008 and 2009, and 2008–2010 inpatient claims. The claims outcome uses distinct IDs with consistently recorded 2009 start dates.

## Cohort construction and results

| Cohort definition | Beneficiaries | With 2009-start claim | Percentage |
|---|---:|---:|---:|
| All 2008 summary records | 116,352 | 18,809 | 16.17 |
| Linked 2009 beneficiary summary | 114,538 | 18,809 | 16.42 |
| 12 Part A months in 2009 | 106,914 | 18,652 | 17.45 |
| 12 Part A and Part B months | 104,046 | 18,503 | 17.78 |
| 12 Part A months, zero HMO months | 74,961 | 13,021 | 17.37 |
| 12 Part A and Part B months, zero HMO months | 72,685 | 12,911 | 17.76 |

**Additional audit:** 1,814 2008 beneficiary IDs were absent from the 2009 summary. Among linked records, 1,784 had a nonempty 2009 death date. The latter are not necessarily full-year observable, even if months-of-coverage variables show 12.

## Interpretive constraints

The percentages describe inpatient **claim starts** in the synthetic CMS DE-SynPUF extract, not admissions or actual Medicare hospitalization rates. Part A and B enrollment fields and HMO coverage months are annual summaries. They provide useful screening rules but are not a substitute for person-time data or clinical censoring definitions. Careful evaluation of death date and coverage is required to construct a defensible follow-up interval. Some groups listed here exclude HMO months for a fee-for-service sensitivity analysis; that is not necessarily the best denominator for every scientific question.

The analysis is reproducible from the existing local DB and the obtained 2009 CMS beneficiary summary CSV.

## Reproduce

```bash
python3 scripts/13_import_2009_beneficiaries.py
python3 scripts/14_export_eligibility_audit.py
Rscript scripts/15_2009_eligibility_audit.R
```

Derived record-level exports, source ZIP/CSV files and the SQLite database remain local and are excluded from Git.
