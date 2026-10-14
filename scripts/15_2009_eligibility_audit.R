# CMS synthetic cohort: yearly linkage and conservative enrollment sensitivity.
root <- getwd()
d <- read.csv(file.path(root,"data/processed/2009_eligibility_audit.csv"),colClasses="character")
stopifnot(nrow(d)==116352,anyDuplicated(d$DESYNPUF_ID)==0)
d$linked <- d$linked_2009=="1"
d$hi <- suppressWarnings(as.integer(d$hi_months_2009))
d$smi <- suppressWarnings(as.integer(d$smi_months_2009))
d$hmo <- suppressWarnings(as.integer(d$hmo_months_2009))
d$claims <- as.integer(d$claims_started_2009)
d$event <- d$claims>0
d$full_part_a <- d$linked & !is.na(d$hi) & d$hi==12
d$full_part_ab <- d$full_part_a & !is.na(d$smi) & d$smi==12
d$full_ffsa <- d$full_part_a & !is.na(d$hmo) & d$hmo==0
d$full_ffsa_b <- d$full_part_ab & !is.na(d$hmo) & d$hmo==0
d$death_2009 <- !is.na(d$death_date_2009) & nzchar(trimws(d$death_date_2009))
metrics <- function(label,keep) {
 z<-d[keep,]
 data.frame(cohort=label,n=nrow(z),events=sum(z$event),
            event_percent=round(100*mean(z$event),2),
            distinct_claims=sum(z$claims))
}
result <- do.call(rbind,list(
 metrics("2008_summary_all",rep(TRUE,nrow(d))),
 metrics("2009_summary_linked",d$linked),
 metrics("2009_part_a_12_months",d$full_part_a),
 metrics("2009_part_ab_12_months",d$full_part_ab),
 metrics("2009_part_a_12_no_hmo",d$full_ffsa),
 metrics("2009_part_ab_12_no_hmo",d$full_ffsa_b)
))
write.csv(result,file.path(root,"reports/2009_eligibility_cohort_comparison.csv"),row.names=FALSE)
cat("2008 cohort",nrow(d),"\n")
cat("2009-linked",sum(d$linked),"unlinked",sum(!d$linked),"\n")
cat("2009 death dates",sum(d$death_2009),"\n")
cat("Part A coverage monthly distribution:\n")
print(table(d$hi,useNA="ifany"))
cat("Cohort sensitivity:\n")
print(result,row.names=FALSE)
