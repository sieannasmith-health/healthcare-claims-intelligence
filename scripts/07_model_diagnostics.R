# Exploratory logistic model diagnostics; CMS DE-SynPUF synthetic cohort.
root <- getwd()
d <- read.csv(file.path(root,"data/processed/beneficiary_model_data.csv"),
              colClasses="character")
d$claim_count <- as.integer(d$claim_count)
d$inpatient_any <- as.integer(d$claim_count > 0)
d$age_2008 <- floor(as.numeric(as.Date("2008-12-31") -
                     as.Date(d$BENE_BIRTH_DT, format="%Y%m%d"))/365.2425)
d$sex <- factor(d$BENE_SEX_IDENT_CD,levels=c("1","2"))
for (v in c("SP_DIABETES","SP_CHF","SP_COPD","SP_CHRNKIDN")) {
 d[[paste0(v,"_yes")]] <- ifelse(d[[v]]=="1",1L,
                                ifelse(d[[v]]=="2",0L,NA_integer_))
}
cols <- c("inpatient_any","age_2008","sex","SP_DIABETES_yes",
          "SP_CHF_yes","SP_COPD_yes","SP_CHRNKIDN_yes")
d <- d[complete.cases(d[,cols]) & d$age_2008>=0 & d$age_2008<=115,]
set.seed(20261014)
idx <- sample.int(nrow(d),floor(.8*nrow(d)))
train <- d[idx,]; test <- d[-idx,]
formula <- inpatient_any ~ age_2008 + sex + SP_DIABETES_yes +
           SP_CHF_yes + SP_COPD_yes + SP_CHRNKIDN_yes
m <- glm(formula, data=train,family=binomial())
p <- predict(m,newdata=test,type="response")
auc <- function(y,p) {
 r <- rank(p,ties.method="average")
 n1 <- sum(y==1); n0 <- sum(y==0)
 (sum(r[y==1])-n1*(n1+1)/2)/(n1*n0)
}
cal <- data.frame(predicted=p,actual=test$inpatient_any)
cal$bin <- cut(rank(cal$predicted,ties.method="first"),
               breaks=seq(0,nrow(cal),length.out=11),include.lowest=TRUE,
               labels=FALSE)
calibration <- aggregate(cbind(predicted,actual)~bin,data=cal,FUN=mean)
calibration$n <- as.integer(table(cal$bin))
write.csv(calibration,file.path(root,"reports/inpatient_calibration_deciles.csv"),
          row.names=FALSE)
png(file.path(root,"reports/inpatient_calibration.png"),
    width=900,height=650,res=140)
plot(calibration$predicted,calibration$actual,pch=19,col="#173D2B",
     xlim=c(0,1),ylim=c(0,1),xlab="Predicted event proportion",
     ylab="Observed event proportion",
     main="Held-out calibration: synthetic claims cohort")
abline(0,1,lty=2,col="grey50")
dev.off()
s <- c(
 "Exploratory diagnostics: claims-derived chronic flags, synthetic cohort",
 sprintf("Train n: %d; test n: %d",nrow(train),nrow(test)),
 sprintf("Held-out AUC: %.4f",auc(test$inpatient_any,p)),
 sprintf("Held-out Brier score: %.4f",mean((p-test$inpatient_any)^2)),
 sprintf("Test observed event rate: %.4f",mean(test$inpatient_any)),
 sprintf("Test mean predicted probability: %.4f",mean(p)),
 sprintf("Null-model AIC (train): %.2f",AIC(glm(inpatient_any~1,data=train,family=binomial()))),
 sprintf("Full-model AIC (train): %.2f",AIC(m)),
 "Interpretation restriction: Random holdout does not remove temporal leakage.",
 "Do not market this as prospective patient risk prediction."
)
writeLines(s,file.path(root,"reports/inpatient_model_diagnostics.txt"))
cat(paste(s,collapse="\n"),"\n")
