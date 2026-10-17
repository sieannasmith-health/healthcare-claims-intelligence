# Power BI Dashboard Build Guide

**Project:** Medicare Claims & Hospital Utilization Analysis  
**Status:** Implementation instructions; dashboard not yet built or verified.

## Inputs

Export `data/processed/beneficiary_model_data.csv` locally by running:

```bash
python3 scripts/04_prepare_model_data.py
```

This export includes one row per beneficiary and columns `DESYNPUF_ID`, `BENE_BIRTH_DT`, `BENE_SEX_IDENT_CD`, `SP_DIABETES`, `SP_CHF`, `SP_COPD`, `SP_CHRNKIDN`, and `claim_count`. The script verifies exactly 116,352 rows. Do not upload beneficiary-level extracts, even synthetic extracts, to GitHub.

Use Power BI Desktop → Get data → Text/CSV and select the local extract. Name the imported table `Beneficiaries`. Set `DESYNPUF_ID` to Text, `claim_count` to Whole Number, and chronic-condition codes and sex code to Text. Treat `BENE_BIRTH_DT` as an eight-character YYYYMMDD text identifier, not as an integer date. Check that there is one unique beneficiary ID per row.

## Calculated columns (DAX)

Add to table `Beneficiaries`:

```dax
Inpatient Any = IF('Beneficiaries'[claim_count] > 0, 1, 0)

Diabetes Status =
SWITCH('Beneficiaries'[SP_DIABETES], "1", "Yes", "2", "No", "Unknown")

CHF Status =
SWITCH('Beneficiaries'[SP_CHF], "1", "Yes", "2", "No", "Unknown")

COPD Status =
SWITCH('Beneficiaries'[SP_COPD], "1", "Yes", "2", "No", "Unknown")

CKD Status =
SWITCH('Beneficiaries'[SP_CHRNKIDN], "1", "Yes", "2", "No", "Unknown")
```

The R modeling script verifies the code conventions `1=Yes` and `2=No` for chronic conditions. Verify each column's data type before adding measures.

## Measures (DAX)

Create these measures separately:

```dax
Beneficiaries = DISTINCTCOUNT('Beneficiaries'[DESYNPUF_ID])

Beneficiaries With Inpatient Claim =
CALCULATE(
    [Beneficiaries],
    'Beneficiaries'[Inpatient Any] = 1
)

Inpatient Utilization % =
DIVIDE([Beneficiaries With Inpatient Claim], [Beneficiaries])

Unique Inpatient Claims = SUM('Beneficiaries'[claim_count])

Average Claims per Beneficiary =
DIVIDE([Unique Inpatient Claims], [Beneficiaries])
```

Format `Inpatient Utilization %` as a Percentage with two decimal places and `Average Claims per Beneficiary` as a decimal with two places.

These are *descriptive synthetic-data measures*, not clinical risk estimates. Filtering by chronic-condition flags changes both numerator and denominator.

## Report pages

1. **Executive Overview:** Cards for Beneficiaries, Beneficiaries With Inpatient Claim, Inpatient Utilization %, Unique Inpatient Claims, Average Claims per Beneficiary; bar chart of utilization by diabetes status; explanation of study population and synthetic-data limitations.
2. **Patient Risk Profiles:** Compare descriptive utilization across diabetes, CHF, COPD and CKD; allow code-based sex filter. Clearly label visualized outcomes as same-window associations.
3. **Statistical Modeling:** Import `reports/inpatient_logistic_odds_ratios.csv` as a *separate* table and display the model's adjusted odds ratios and confidence intervals. Do not label the model as prospective clinical prediction. Display test ROC AUC 0.7833 and Brier score 0.1657 with source/method notes.
4. **Data Quality:** Display validated count checks (116,352 beneficiaries; 66,773 inpatient segment records; 66,705 distinct claims; 0 unmatched inpatient beneficiary IDs). Explain that claims are counted by distinct `CLM_ID` across segments. These fixed source-level QA figures do not respond to dashboard slicers.

## Acceptance checklist

- [ ] CSV exported on user's local computer
- [ ] CSV imported into Power BI Desktop
- [ ] Data types and one-row-per-beneficiary grain confirmed
- [ ] Calculated columns and measures created
- [ ] Unfiltered measures reconcile: 116,352 beneficiaries; 37,780 with inpatient claim; 66,705 claims; 32.47% utilization
- [ ] Four report pages completed
- [ ] Visuals manually inspected and reconciled
- [ ] PBIX saved locally; publish only aggregate screenshots and documentation after review

**Privacy and integrity:** Do not push individual beneficiary IDs, beneficiary-level extracts, or the database into this repository. Dataset is CMS DE-SynPUF synthetic; interpretations are exploratory.
