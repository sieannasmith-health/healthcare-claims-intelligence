# Healthcare Claims Intelligence

**Independent health data analytics portfolio project**  
**Dataset:** CMS DE-SynPUF synthetic Medicare claims (2008 beneficiary records and inpatient claim segments)  
**Skills:** Python, SQLite/SQL, R, relational data modeling, data integrity, logistic regression, visualization, model evaluation.

## Problem

How can raw segmented Medicare-style claims data be transformed into an auditable relational dataset to characterize inpatient utilization and test associations with demographic and chronic-condition indicators?

## Verified analytical outputs

| Metric | Result |
|---|---:|
| Beneficiary records | 116,352 |
| Inpatient claim-segment records | 66,773 |
| Distinct claim IDs | 66,705 |
| Beneficiaries with inpatient claims | 37,780 |
| Unmatched inpatient beneficiary IDs | 0 |
| Proportion with any inpatient claim | 32.47% |
| Mean distinct claims per beneficiary | 0.57 |

## Methods and deliverables

1. **Data profiling and quality checks:** inspect raw extracts, investigate repeated claim IDs and verify relational integrity.
2. **Relational database:** construct a SQLite dataset with beneficiary and inpatient segment tables.
3. **SQL reporting:** calculate beneficiary-level utilization, stratifications and chronic-condition comparisons.
4. **Exploratory statistical analysis:** multivariable logistic regression of any inpatient claim using age, sex and selected chronic-condition flags.
5. **Diagnostics:** reproducible seeded 80/20 train/test split, ROC AUC, Brier score and calibration-decile summaries.

### Exploratory model diagnostics

| Diagnostic | Value |
|---|---:|
| Training cohort | 93,081 |
| Held-out test cohort | 23,271 |
| ROC AUC | 0.7833 |
| Brier score | 0.1657 |
| Mean predicted outcome proportion | 0.3264 |
| Actual test outcome proportion | 0.3273 |

See [model methods](reports/04_model_methods.md), `reports/inpatient_model_diagnostics.txt`, and saved visualization outputs.

## Reproduce locally

Requires appropriately obtained CMS DE-SynPUF source files for the original database builder, plus Python 3 and R.

Once your SQLite file is built at `data/processed/healthcare_claims.db`:

```bash
python3 scripts/04_prepare_model_data.py
Rscript scripts/05_inpatient_logistic_model.R
Rscript scripts/06_model_visualization.R
Rscript scripts/07_model_diagnostics.R
```

Original import and audit steps are under `scripts/01_...`, `02_...`, and `03_...`. Source-file assumptions and download instructions still need a complete reproducibility review; do not treat this as a one-command clean-room reproduction yet.

## Scope and limitations

**CMS DE-SynPUF is synthetic, not a representative clinical study sample.** Its estimates do not describe actual Medicare utilization or health outcomes. The chronic-condition indicators are potentially claims-derived, so their timing and information content may overlap the outcome. The logistic regression and random holdout are **exploratory associations**, not prospective prediction or causal effects. ROC AUC and Brier score reflect the synthetic held-out data only. A deeper methodological review is needed before extending these findings.

The repository intentionally excludes downloaded raw files, derived beneficiary-level records, database files, and local IDE configuration.

**Author:** Sieanna Smith  
**Career focus:** Health Data Analytics | Public Health Informatics | Epidemiology
