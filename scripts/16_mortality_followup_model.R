# CMS synthetic cohort: 2008 demographics -> 2009 qualifying claim starts.
# Sensitivity analysis: exclude observed 2009 deaths from full-year coverage group.
root <- getwd()
a <- read.csv(file.path(root,"data/processed/2009_eligibility_audit.csv"),colClasses="character")
b <- read.csv(file.path(root,"data/processed/beneficiary_model_data.csv"),colClasses="character")
d <- merge(a,b[,c("DESYNPUF_ID","BENE_BIRTH_DT","BENE_SEX_IDENT_CD")],
           by="DESYNPUF_ID",all.x=TRUE,sort=FALSE)
d$hi <- suppressWarnings(as.integer(d$hi_months_2009))
d$smi <- suppressWarnings(as.integer(d$smi_months_2009))
d$hmo <- suppressWarnings(as.integer(d$hmo_months_2009))
d$claim <- as.integer(d$claims_started_2009)>0
d$death <- !is.na(d$death_date_2009) & nzchar(trimws(d$death_date_2009))
d$eligible <- d$linked_2009=="1" & !is.na(d$hi) & d$hi==12 &
              !is.na(d$smi) & d$smi==12 & !is.na(d$hmo) & d$hmo==0
d$age <- floor(as.numeric(as.Date("2008-12-31") -
               as.Date(d$BENE_BIRTH_DT,format="%Y%m%d"))/365.2425)
d$sex <- factor(d$BENE_SEX_IDENT_CD,levels=c("1","2"))
d <- d[complete.cases(d[,c("claim","age","sex")]) & d$age>=0 & d$age<=115,]
summ <- function(label, subset) {
 x<-d[subset,]
 data.frame(cohort=label,n=nrow(x),events=sum(x$claim),
            percent=round(100*mean(x$claim),3),deaths=sum(x$death))
}
cohorts <- rbind(summ("full_coverage_no_hmo",d$eligible),
                 summ("same_excluding_2009_deaths",d$eligible & !d$death))
write.csv(cohorts,file.path(root,"reports/2009_mortality_sensitivity.csv"),row.names=FALSE)
set.seed(20261014)
analyze <- function(label,sub) {
 z<-d[sub,]
 te<-sample.int(nrow(z),floor(.2*nrow(z)))
 tr<-z[-te,];test<-z[te,]
 fit<-glm(claim~age+sex,family=binomial(),data=tr)
 prob<-predict(fit,newdata=test,type="response")
 yy<-as.integer(test$claim)
 n1<-sum(yy);n0<-length(yy)-n1
 auc<-(sum(rank(prob,ties.method="average")[yy==1])-n1*(n1+1)/2)/(n1*n0)
 co<-summary(fit)$coefficients;ci<-confint.default(fit)
 estimates<-data.frame(cohort=label,predictor=rownames(co),
                       odds_ratio=exp(co[,1]),lower=exp(ci[,1]),upper=exp(ci[,2]))
 list(metrics=data.frame(cohort=label,train_n=nrow(tr),test_n=nrow(test),
                         auc=auc,brier=mean((yy-prob)^2),
                         event_percent=100*mean(z$claim)),
      estimates=estimates)
}
one<-analyze("full_coverage_no_hmo",d$eligible)
two<-analyze("same_excluding_2009_deaths",d$eligible & !d$death)
metrics<-rbind(one$metrics,two$metrics)
write.csv(metrics,file.path(root,"reports/2009_mortality_model_metrics.csv"),row.names=FALSE)
write.csv(rbind(one$estimates,two$estimates),
          file.path(root,"reports/2009_mortality_model_odds_ratios.csv"),row.names=FALSE)
print(cohorts,row.names=FALSE)
print(metrics,row.names=FALSE)
