# 2008 Claim-Start Logistic Regression: Comparative Review

**Dataset:** CMS DE-SynPUF synthetic Medicare claims  
**Analytical status:** Completed exploratory model comparison, **not** a prospective risk prediction model.

## Definitions and sample

The first outcome is at least one distinct inpatient claim with consistent, nonempty segment start dates in 2008. The comparison outcome is at least one distinct inpatient claim from the original multi-year inpatient extract. Both use 2008 beneficiary-summary covariates: age, sex code, and diabetes, CHF, COPD, and chronic kidney disease indicators.

Both models use the same seeded random train/test partition and complete-case cohort of 116,352 synthetic beneficiaries. Each model is refitted independently on 93,082 training observations and evaluated on 23,270 test observations.

| Measure | 2008 claim-start | Multi-year |
|---|---:|---:|
| Beneficiaries with an inpatient claim | 15,856 | 37,780 |
| Event proportion (%) | 13.63 | 32.47 |
| Held-out ROC AUC | 0.8880 | 0.7873 |
| Brier score | 0.0793 | 0.1648 |

The original multi-year model's previously reported AUC of 0.7833 came from a different partition; the 0.7873 above is its refit using the same partition as the 2008 model.

## 2008 model adjusted association estimates

| Predictor | Odds ratio | 95% Wald CI |
|---|---:|---:|
| Age, per additional year | 1.006 | 1.004–1.008 |
| Sex code 2 vs 1 | 0.943 | 0.900–0.989 |
| Diabetes flag | 2.092 | 1.981–2.209 |
| CHF flag | 3.646 | 3.463–3.839 |
| COPD flag | 4.347 | 4.132–4.573 |
| Chronic kidney disease flag | 4.309 | 4.098–4.531 |

## Interpretation restrictions

- Claims are not equivalent to confirmed unique hospitalizations; the analysis considers distinct claim identifiers.
- Cohort denominator includes beneficiary summary records and has not been adjusted for person-time or 2008 enrollment eligibility.
- The 2008 summary fields are not confirmed to predate 2008 claim occurrences. Chronic-condition flags may be derived from overlapping claims and create substantial target leakage. Therefore, **do not describe this as a predictive risk model**.
- Different outcome horizons and base rates mean AUC/Brier comparisons are descriptive, not a direct statement of superiority.
- Synthetic records are not representative of real Medicare prevalence, utilization, causality, or intervention outcomes.
- No externally validated or temporally separated test cohort has been assessed.

## Reproduction

From the project root, after the local database and model extract are prepared:

```bash
python3 scripts/09_export_2008_claim_counts.py
Rscript scripts/09_2008_model_comparison.R
```

Outputs: `reports/2008_vs_multiyear_coefficients.csv` and `reports/2008_vs_multiyear_model_metrics.csv`.

## Next validation gates

1. Review CMS DE-SynPUF beneficiary chronic-condition data dictionary and measurement periods.
2. Fit a **demographics-only baseline** and compare it with the chronic-condition model to characterize possible label leakage without claiming to eliminate it.
3. Evaluate coding consistency, age distribution, coverage months, and claims dates.
4. Produce a concise employer-facing case study with limitations prominent.
