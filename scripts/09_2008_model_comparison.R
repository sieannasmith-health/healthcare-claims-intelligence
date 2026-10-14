# CMS DE-SynPUF: retrospective 2008 claim-start association model.
# Explicitly not a prospective risk model. Original multi-year model preserved.
root <- getwd()
d <- read.csv(file.path(root,"data/processed/beneficiary_model_data.csv"),colClasses="character")
d$age_2008 <- floor(as.numeric(as.Date("2008-12-31") - as.Date(d$BENE_BIRTH_DT,format="%Y%m%d"))/365.2425)
d$sex <- factor(d$BENE_SEX_IDENT_CD,levels=c("1","2"))
for(v in c("SP_DIABETES","SP_CHF","SP_COPD","SP_CHRNKIDN"))
 d[[paste0(v,"_yes")]] <- ifelse(d[[v]]=="1",1L,ifelse(d[[v]]=="2",0L,NA_integer_))
# Obtain 2008 eligible claim counts using Python sqlite3 standard library export.
y <- read.csv(file.path(root,"data/processed/beneficiary_2008_claim_counts.csv"),colClasses=c("character","integer"))
stopifnot(anyDuplicated(y$DESYNPUF_ID)==0L)
d <- merge(d,y,by="DESYNPUF_ID",all.x=TRUE,sort=FALSE)
d$claims_2008[is.na(d$claims_2008)] <- 0L
d$any_2008 <- as.integer(d$claims_2008>0)
d$any_multiyear <- as.integer(as.integer(d$claim_count)>0)
vars <- c("age_2008","sex","SP_DIABETES_yes","SP_CHF_yes","SP_COPD_yes","SP_CHRNKIDN_yes")
d <- d[complete.cases(d[,vars]) & d$age_2008>=0 & d$age_2008<=115,]
set.seed(20261014)
test_idx <- sample.int(nrow(d),floor(.2*nrow(d)))
f <- ~ age_2008+sex+SP_DIABETES_yes+SP_CHF_yes+SP_COPD_yes+SP_CHRNKIDN_yes
auc <- function(y,p) { n1<-sum(y==1); n0<-sum(y==0); (sum(rank(p,ties.method="average")[y==1])-n1*(n1+1)/2)/(n1*n0) }
fit_model <- function(outcome,label) {
 train <- d[-test_idx,]; test <- d[test_idx,]
 m <- glm(reformulate(attr(terms(f),"term.labels"),response=outcome),data=train,family=binomial())
 prob <- predict(m,newdata=test,type="response")
 z <- summary(m)$coefficients
 ci <- confint.default(m)
 t <- data.frame(model=label,variable=rownames(z),odds_ratio=exp(z[,1]),ci_lower=exp(ci[,1]),ci_upper=exp(ci[,2]),row.names=NULL)
 metrics <- data.frame(model=label,train_n=nrow(train),test_n=nrow(test),events=sum(d[[outcome]]),
                       event_percent=100*mean(d[[outcome]]),auc=auc(test[[outcome]],prob),
                       brier=mean((test[[outcome]]-prob)^2))
 list(coef=t,metrics=metrics)
}
a <- fit_model("any_2008","2008_consistent_claim_starts")
b <- fit_model("any_multiyear","multiyear_original_outcome_refit")
dir.create(file.path(root,"reports"),showWarnings=FALSE)
write.csv(rbind(a$coef,b$coef),file.path(root,"reports/2008_vs_multiyear_coefficients.csv"),row.names=FALSE)
write.csv(rbind(a$metrics,b$metrics),file.path(root,"reports/2008_vs_multiyear_model_metrics.csv"),row.names=FALSE)
print(rbind(a$metrics,b$metrics))
print(a$coef)
