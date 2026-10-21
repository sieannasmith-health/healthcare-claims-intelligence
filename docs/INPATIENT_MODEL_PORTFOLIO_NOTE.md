# Inpatient utilization adjusted odds ratios — model documentation

Source: `scripts/05_inpatient_logistic_model.R` and `reports/inpatient_logistic_summary.txt`.

## Report-ready note

**Model details:** Outcome: at least one inpatient claim (37,780 events among 116,352 synthetic beneficiaries). Multivariable logistic regression adjusted for age, sex, diabetes, congestive heart failure, chronic obstructive pulmonary disease, and chronic kidney disease. Age assessed at December 31, 2008. This unweighted same-window exploratory model estimates associations, not causal effects or prospective hospitalization risk.

## Validation

Compared displayed effect sizes to `reports/inpatient_logistic_odds_ratios.csv`:

| Variable | Adjusted OR | Lower 95% CI | Upper 95% CI |
|---|---:|---:|---:|
| COPD | 2.923 | 2.800 | 3.051 |
| CKD | 2.773 | 2.663 | 2.888 |
| CHF | 2.441 | 2.362 | 2.522 |
| Diabetes | 2.410 | 2.336 | 2.486 |
| Age per year | 1.003 | 1.002 | 1.004 |
| Female vs. male reference | 0.996 | 0.968 | 1.025 |

Model script uses a binomial `glm`, complete cases, and `confint.default` (Wald confidence intervals). The confidence intervals for female vs. male include 1.00. These outputs are rounded to three decimals.
