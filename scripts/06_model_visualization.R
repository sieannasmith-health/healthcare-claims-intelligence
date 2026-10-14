# Plot coefficient odds ratios from validated exploratory model.
root <- getwd()
x <- read.csv(file.path(root,"reports/inpatient_logistic_odds_ratios.csv"))
x <- x[x$variable %in% c("SP_DIABETES_yes","SP_CHF_yes",
                         "SP_COPD_yes","SP_CHRNKIDN_yes"),]
x$label <- c("Diabetes","Heart failure","COPD","Chronic kidney disease")[
  match(x$variable,c("SP_DIABETES_yes","SP_CHF_yes",
                     "SP_COPD_yes","SP_CHRNKIDN_yes"))]
x <- x[order(x$odds_ratio),]
png(file.path(root,"reports/inpatient_adjusted_odds_ratios.png"),
    width=1100,height=660,res=140)
par(mar=c(5,12,4,3))
y <- seq_len(nrow(x))
plot(x$odds_ratio,y,xlim=c(0.8,3.5),ylim=c(.5,nrow(x)+.5),
     yaxt="n",ylab="",xlab="Adjusted odds ratio (95% Wald CI)",
     pch=19,cex=1.4,col="#173D2B",
     main="Inpatient claim association in CMS synthetic data")
axis(2,at=y,labels=x$label,las=1)
segments(x$ci_lower,y,x$ci_upper,y,lwd=3,col="#7D9460")
abline(v=1,lty=2,col="grey40")
dev.off()
cat("Created reports/inpatient_adjusted_odds_ratios.png\n")
