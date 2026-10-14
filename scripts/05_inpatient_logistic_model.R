# CMS DE-SynPUF synthetic cohort: exploratory inpatient claim occurrence model.
# Base R only. Associations are synthetic, unweighted, and not clinically generalizable.
root <- normalizePath(file.path(getwd()))
input <- file.path(root, "data/processed/beneficiary_model_data.csv")
output <- file.path(root, "reports")
dir.create(output, recursive=TRUE, showWarnings=FALSE)
d <- read.csv(input, colClasses="character", stringsAsFactors=FALSE)
stopifnot(nrow(d)==116352, anyDuplicated(d$DESYNPUF_ID)==0L)
d$claims <- as.integer(d$claim_count)
stopifnot(all(!is.na(d$claims) & d$claims >= 0))
d$inpatient_any <- as.integer(d$claims > 0)
birth <- as.Date(d$BENE_BIRTH_DT, format="%Y%m%d")
reference <- as.Date("2008-12-31")
d$age_2008 <- floor(as.numeric(reference - birth) / 365.2425)
d$sex <- factor(d$BENE_SEX_IDENT_CD, levels=c("1","2"),
                labels=c("code_1","code_2"))
for (v in c("SP_DIABETES","SP_CHF","SP_COPD","SP_CHRNKIDN")) {
  stopifnot(all(na.omit(unique(d[[v]])) %in% c("1","2")))
  d[[paste0(v,"_yes")]] <- ifelse(d[[v]]=="1",1L,
                                 ifelse(d[[v]]=="2",0L,NA_integer_))
}
fields <- c("inpatient_any","age_2008","sex","SP_DIABETES_yes",
            "SP_CHF_yes","SP_COPD_yes","SP_CHRNKIDN_yes")
model_data <- d[complete.cases(d[,fields]) & d$age_2008 >= 0 &
                d$age_2008 <= 115, fields]
stopifnot(nrow(model_data) > 100000)
fit <- glm(inpatient_any ~ age_2008 + sex + SP_DIABETES_yes +
             SP_CHF_yes + SP_COPD_yes + SP_CHRNKIDN_yes,
           family=binomial(), data=model_data)
co <- summary(fit)$coefficients
ci <- suppressMessages(confint.default(fit))
or_table <- data.frame(
  variable=rownames(co),
  odds_ratio=round(exp(co[,1]),3),
  ci_lower=round(exp(ci[,1]),3),
  ci_upper=round(exp(ci[,2]),3),
  p_value=signif(co[,4],3),
  row.names=NULL
)
write.csv(or_table, file.path(output,"inpatient_logistic_odds_ratios.csv"),
          row.names=FALSE)
sink(file.path(output,"inpatient_logistic_summary.txt"))
cat("CMS DE-SynPUF synthetic beneficiary analysis, 2008\n")
cat("Descriptive cross-sectional associations, not causal or clinical risk estimates\n")
cat("Original records:",nrow(d),"Model complete cases:",nrow(model_data),"\n")
cat("Model event count:",sum(model_data$inpatient_any),"\n")
cat("Age computed as of 2008-12-31; years are approximate\n\n")
print(or_table)
cat("\nModel AIC:",AIC(fit),"\n")
cat("\nNotes: 1=Yes/2=No for chronic condition flags; code_1 reference for sex.\n")
cat("Odds ratios are adjusted for displayed covariates, not evidence of causation.\n")
sink()
print(or_table)
cat("Rows modeled:",nrow(model_data),"events:",sum(model_data$inpatient_any),"\n")
