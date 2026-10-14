# Baseline Model Comparison: 2008 Claim-Start Outcome

**Dataset:** CMS DE-SynPUF synthetic cohort  
**Analysis:** Same 116,352 complete-case beneficiaries, same seeded 80/20 split.

## Holdout metrics

| Model | AUC | Brier | Log loss |
|---|---:|---:|---:|
| Intercept only | 0.5000 | 0.11845 | 0.40004 |
| Age and coded sex | 0.5654 | 0.11789 | 0.39803 |
| Age, sex, diabetes, CHF, COPD, CKD flags | 0.8880 | 0.07925 | 0.26312 |

Train n = 93,082, test n = 23,270; test event proportion = 13.73%.

## Assessment

The chronic-condition flags increase held-out ROC AUC by approximately 0.323 compared with demographics alone. This shows these flags strongly separate beneficiaries with and without eligible 2008-start inpatient claims *in the synthetic data*, but DOES NOT establish prospective prediction. Their source and timing may depend on the same 2008 claims. The improved fit is consistent with a possible information-overlap problem; it does not prove the magnitude of leakage.

Differences in calibration and proper scoring metrics do not establish causality or real-world clinical usefulness. The outcome counts distinct claims with consistently recorded 2008 start dates, not verified separate hospital admissions. The denominator is 2008 beneficiary-summary records and does not adjust for coverage or exposure time.

## Reproduce

```bash
Rscript scripts/10_demographics_baseline.R
```

Output: `reports/2008_baseline_comparison.csv`. Input extracts remain local and untracked.

## Research next steps

Review official indicator construction and source documentation, add time-defined eligibility, and investigate a design with predictors measured strictly before the outcome interval. Do not market the 0.888 AUC as real-world clinical risk prediction.
