# Time-ordered analysis using 2008 baseline and 2009 claims

The 2008 beneficiary-summary birth date and coded sex are used to examine the presence of a consistently dated inpatient claim that started during 2009. No claims-derived chronic-condition predictors are included.

## Data and evaluation

| Metric | Result |
|---|---:|
| 2008 beneficiary-summary records | 116,352 |
| 2009-start, uniquely dated claims | 25,197 |
| 2008-baseline beneficiaries matched to a 2009-start claim | 18,809 |
| Train records | 93,082 |
| Holdout records | 23,270 |
| Intercept-only AUC | 0.5000 |
| Demographics-only AUC | 0.5251 |
| Intercept-only Brier score | 0.13550 |
| Demographics-only Brier score | 0.13541 |

Demographics model adjusted odds ratios:

- Age as of December 31, 2008 (per year): 1.0063 (95% Wald CI 1.0049–1.0078)
- Sex code 2 versus code 1: 1.0642 (95% Wald CI 1.0271–1.1026)

## What is and is not demonstrated

These predictors are temporally anchored to 2008 and the claims outcome begins in 2009, avoiding use of the 2008 synthetic claims-derived chronic-condition flags as features. However, the analysis has **not verified 2009 eligibility, continuous Part A coverage, death/censoring, or missing observation time**. A person with no observed 2009 claims may not have been eligible or under observation for the entire period. This is a **time-ordered descriptive baseline**, not a validated prospective hospitalization risk model.

The AUC of 0.5251 is lower than the earlier 0.8880 from the 2008 same-period chronic-flag model. These are different outcomes and feature sets, and this comparison **does not quantify the effect of leakage**. CMS confirms chronic-condition flags were derived from synthetic claims. Establishing information leakage requires verifying the exact source periods and feature-construction process.

CMS primary sources:
- https://www.cms.gov/data-research/statistics-trends-and-reports/medicare-claims-synthetic-public-use-files/cms-2008-2010-data-entrepreneurs-synthetic-public-use-file-de-synpuf
- https://www.cms.gov/files/document/cms08-10desynpufcodebookpdf
- https://www.cms.gov/data-research/statistics-trends-and-reports/medicare-claims-synthetic-public-use-files/cms-2008-2010-data-entrepreneurs-synthetic-public-use-file-de-synpuf/de10-sample-1

## Reproduction

Run from the project root after constructing the existing database and beneficiary model extract:

```bash
python3 scripts/11_2009_temporal_baseline.py
Rscript scripts/12_2009_temporal_baseline.R
```

Output files: `reports/2009_temporal_baseline_metrics.csv` and `reports/2009_temporal_baseline_coefficients.csv`.

## Next gate

Incorporate 2009 beneficiary-summary records and enrollment months to define a comparable at-risk cohort. Audit death dates and confirm observation windows before any prospective prediction claim. Retain full methodology and synthetic-data caveats in the portfolio case study.
