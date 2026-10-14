# Exploratory Inpatient Utilization Model

**Project:** Healthcare Claims Intelligence  
**Dataset:** CMS DE-SynPUF synthetic beneficiary 2008 + inpatient claims segments  
**Analysis date:** October 14, 2026

## Question

Which coded demographic and chronic-condition characteristics are statistically associated with having at least one distinct inpatient claim in this synthetic cohort?

## Cohort and outcome

- 116,352 unique beneficiary records, joined to distinct inpatient claims using `DESYNPUF_ID`.
- Outcome: indicator of at least one distinct `CLM_ID` across loaded inpatient claim segments.
- 37,780 positive outcomes, 78,572 zero-claim beneficiaries.
- Logistic regression fit on 116,352 complete cases.
- Predictors: beneficiary age at 2008-12-31, sex code, diabetes, congestive heart failure, COPD, and chronic kidney disease indicators.
- Chronic-condition flags coded 1 = Yes, 2 = No. Age calculated approximately from the source birth date.
- Model: multivariable binomial logistic regression (base R `glm`); Wald 95% confidence intervals.

## Adjusted estimates

| Predictor | Odds ratio | 95% CI |
|---|---:|---:|
| Age, per year | 1.003 | 1.002–1.004 |
| Sex code 2 vs code 1 | 0.996 | 0.968–1.025 |
| Diabetes indicator: Yes vs No | 2.410 | 2.336–2.486 |
| Heart failure indicator: Yes vs No | 2.441 | 2.362–2.522 |
| COPD indicator: Yes vs No | 2.923 | 2.800–3.051 |
| Chronic kidney disease indicator: Yes vs No | 2.773 | 2.663–2.888 |

## Interpretation and limitations

These are *conditional descriptive associations* among synthetic records, not estimates of real clinical risk or effects. Because CMS chronic-condition flags may be constructed from underlying claims, the modeled predictors can overlap temporally or informationally with the inpatient claim outcome. **Do not interpret this cross-sectional model as prospective risk prediction or evidence that conditions cause utilization.** Check the source indicator definitions and study windows before adding claims about temporality.

Additional limitations: no real-world representativeness from synthetic DE-SynPUF, possible unmeasured confounding, simplified age calculation, incomplete care utilization outside the loaded tables, no patient-level longitudinal validation, and no assessment yet of collinearity, calibration, discrimination, or model stability. Small p-values in a large synthetic dataset do not establish clinical importance.

## Reproduction

From project root:

```bash
.venv/bin/python scripts/04_prepare_model_data.py
Rscript scripts/05_inpatient_logistic_model.R
Rscript scripts/06_model_visualization.R
```

Outputs are `reports/inpatient_logistic_summary.txt`, `reports/inpatient_logistic_odds_ratios.csv`, and `reports/inpatient_adjusted_odds_ratios.png`.

**Next methodological gate:** audit coding/provenance and assessment for leakage; then evaluate model adequacy and consider defensible alternatives.
