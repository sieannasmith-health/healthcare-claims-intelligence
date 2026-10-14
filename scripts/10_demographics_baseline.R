# Fair model comparison using one synthetic cohort and one held-out partition.
root <- getwd()
d <- read.csv(file.path(root,"data/processed/beneficiary_model_data.csv"),colClasses="character")
y <- read.csv(file.path(root,"data/processed/beneficiary_2008_claim_counts.csv"),colClasses=c("character","integer"))
d <- merge(d,y,by="DESYNPUF_ID",all.x=TRUE,sort=FALSE)
d$claims_2008[is.na(d$claims_2008)] <- 0L
d$event <- as.integer(d$claims_2008>0)
d$age <- floor(as.numeric(as.Date("2008-12-31")-as.Date(d$BENE_BIRTH_DT,format="%Y%m%d"))/365.2425)
d$sex <- factor(d$BENE_SEX_IDENT_CD,levels=c("1","2"))
for(v in c("SP_DIABETES","SP_CHF","SP_COPD","SP_CHRNKIDN"))
 d[[paste0(v,"_yes")]] <- ifelse(d[[v]]=="1",1L,ifelse(d[[v]]=="2",0L,NA_integer_))
cols <- c("event","age","sex","SP_DIABETES_yes","SP_CHF_yes","SP_COPD_yes","SP_CHRNKIDN_yes")
d <- d[complete.cases(d[,cols]) & d$age>=0 & d$age<=115,]
set.seed(20261014)
test_idx <- sample.int(nrow(d),floor(.2*nrow(d)))
train <- d[-test_idx,]; test <- d[test_idx,]
auc <- function(y,p) {
 n1 <- sum(y==1);n0 <- sum(y==0)
 (sum(rank(p,ties.method="average")[y==1])-n1*(n1+1)/2)/(n1*n0)
}
models <- list(
 intercept_only = event ~ 1,
 demographics_only = event ~ age + sex,
 demographics_plus_chronic_flags = event ~ age + sex + SP_DIABETES_yes +
   SP_CHF_yes + SP_COPD_yes + SP_CHRNKIDN_yes
)
rows <- lapply(names(models),function(name) {
 m <- glm(models[[name]],data=train,family=binomial())
 p <- predict(m,newdata=test,type="response")
 data.frame(model=name,train_n=nrow(train),test_n=nrow(test),
            event_rate=mean(test$event),auc=auc(test$event,p),
            brier=mean((test$event-p)^2),mean_prediction=mean(p),
            log_loss=-mean(test$event*log(pmax(p,1e-15))+
                       (1-test$event)*log(pmax(1-p,1e-15))),
            stringsAsFactors=FALSE)
})
out <- do.call(rbind,rows)
write.csv(out,file.path(root,"reports/2008_baseline_comparison.csv"),row.names=FALSE)
print(out)
