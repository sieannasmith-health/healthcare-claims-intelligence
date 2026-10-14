# Mortality and Follow-Up Sensitivity Analysis

## Design

CMS DE-SynPUF synthetic Medicare Sample 1. Outcome: at least one inpatient claim with unambiguous 2009 start date. Predictors: age on December 31, 2008 and sex code, from 2008 beneficiary summary.

The primary descriptive cohort requires linkage to 2009 summary, 12 months of Part A and Part B coverage, and zero HMO months.

## Observed results

| Cohort | N | With claim | With claim (%) | Recorded 2009 deaths |
|---|---:|---:|---:|---:|
| Coverage-defined cohort | 72,685 | 12,911 | 17.763 | 1,123 |
| Same, excluding 2009 deaths | 71,562 | 12,801 | 17.888 | 0 |

### R model diagnostics

| Cohort | Train | Test | AUC | Brier |
|---|---:|---:|---:|---:|
| Coverage-defined | 58,148 | 14,537 | 0.5199 | 0.1461 |
| Exclude recorded deaths | 57,250 | 14,312 | 0.5351 | 0.1448 |

The two models use separately seeded partitions and different populations; treat their diagnostic differences descriptively, not as a fair paired model-performance comparison.

## Methodological interpretation

- Excluding people who died during 2009 conditions on an event occurring after baseline and can introduce survival-selection bias. The coverage-defined cohort is preferred to a survivor-only cohort for this descriptive comparison, pending audit of observation time.
- Annual coverage-month summaries do not establish exact start and stop dates for person-time. A censoring-aware rate analysis needs defensible observation dates, such as monthly enrollment, and properly defined event time.
- Inpatient claims with a start date are not necessarily unique clinical admissions.
- Claims data are synthetic; the findings do not estimate genuine Medicare population risk or hospitalization incidence.
- The observed low AUC for age and sex alone is expected to have little discriminative value and is not an indicator of analysis failure.

## Reproduction

```bash
Rscript scripts/16_mortality_followup_model.R
```

Outputs: `reports/2009_mortality_sensitivity.csv`, `reports/2009_mortality_model_metrics.csv`, and `reports/2009_mortality_model_odds_ratios.csv`.

**Next:** Verify death-date consistency between 2008 and 2009 summaries, identify potential post-death claim starts, check follow-up definitions, and include a transparent limitations section in the portfolio case study.
