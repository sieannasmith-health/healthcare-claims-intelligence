# Time-ordered synthetic cohort: 2008 sex and birth year, 2009 claim starts.
# NOT a prospective clinical model: 2009 eligibility and censoring are unverified.
root <- getwd()
b <- read.csv(file.path(root,"data/processed/beneficiary_model_data.csv"),
              colClasses="character")
y <- read.csv(file.path(root,"data/processed/beneficiary_2009_claim_counts.csv"),
              colClasses=c("character","integer"))
b <- merge(b,y,by="DESYNPUF_ID",all.x=TRUE,sort=FALSE)
b$claims_2009[is.na(b$claims_2009)] <- 0L
b$event <- as.integer(b$claims_2009 > 0)
b$age_baseline <- floor(as.numeric(as.Date("2008-12-31")-
                          as.Date(b$BENE_BIRTH_DT,format="%Y%m%d"))/365.2425)
b$sex <- factor(b$BENE_SEX_IDENT_CD,levels=c("1","2"))
b <- b[complete.cases(b[,c("event","age_baseline","sex")]) &
       b$age_baseline>=0 & b$age_baseline<=115,]
set.seed(20261014)
test_ids <- sample.int(nrow(b),floor(.2*nrow(b)))
train <- b[-test_ids,]; test <- b[test_ids,]
auc <- function(y,p) {
 n1 <- sum(y==1); n0 <- sum(y==0)
 (sum(rank(p,ties.method="average")[y==1])-n1*(n1+1)/2)/(n1*n0)
}
fits <- list(
 intercept_only=glm(event~1,data=train,family=binomial()),
 demographics_only=glm(event~age_baseline+sex,data=train,family=binomial()))
out <- do.call(rbind,lapply(names(fits),function(n) {
 p <- predict(fits[[n]],newdata=test,type="response")
 data.frame(model=n,train_n=nrow(train),test_n=nrow(test),
            events_total=sum(b$event),
            test_event_rate=mean(test$event),
            auc=auc(test$event,p),
            brier=mean((p-test$event)^2),
            mean_prediction=mean(p))
}))
write.csv(out,file.path(root,"reports/2009_temporal_baseline_metrics.csv"),row.names=FALSE)
print(out)
s <- summary(fits$demographics_only)$coefficients
ci <- confint.default(fits$demographics_only)
coef <- data.frame(variable=rownames(s),odds_ratio=exp(s[,1]),
                   ci_lower=exp(ci[,1]),ci_upper=exp(ci[,2]))
write.csv(coef,file.path(root,"reports/2009_temporal_baseline_coefficients.csv"),
          row.names=FALSE)
print(coef)
