# Publication-quality forest plot from verified original R model outputs.
# Run from any directory: Rscript scripts/19_publication_forest_plot.R
args <- commandArgs(trailingOnly=FALSE)
filearg <- grep("^--file=", args, value=TRUE)
if (!length(filearg)) stop("Run via Rscript")
script_path <- normalizePath(sub("^--file=", "", filearg[1]))
root <- dirname(dirname(script_path))
source_csv <- file.path(root,"reports","inpatient_logistic_odds_ratios.csv")
output_dir <- file.path(root,"reports")
d <- read.csv(source_csv, stringsAsFactors=FALSE)
expected <- c("SP_COPD_yes","SP_CHRNKIDN_yes","SP_CHF_yes","SP_DIABETES_yes","age_2008","sexcode_2")
labels <- c("Chronic Obstructive Pulmonary Disease (COPD)","Chronic Kidney Disease (CKD)","Congestive Heart Failure (CHF)","Diabetes","Age (per year)","Female vs. Male (reference)")
stopifnot(all(expected %in% d$variable), !anyDuplicated(d$variable))
d <- d[match(expected,d$variable),]
stopifnot(all(is.finite(d$odds_ratio)),all(d$ci_lower <= d$odds_ratio & d$odds_ratio <= d$ci_upper))
d$label <- labels
d$ci_text <- sprintf("%.3f (%.3f-%.3f)",d$odds_ratio,d$ci_lower,d$ci_upper)
d$y <- rev(seq_len(nrow(d)))
# Logarithmic x-axis reflects the multiplicative odds ratio scale; reference OR=1.
# Avoid overlapping labels for close-to-one age and sex by placing CI strings in a separate column.
draw_forest <- function() {
  par(mar=c(6.7,16.5,5.6,12.3),family="sans",xaxs="i",yaxs="i")
  plot(NA,xlim=c(log(0.85),log(3.35)),ylim=c(0.45,6.65),axes=FALSE,xlab="",ylab="")
  ticks <- c(0.9,1,1.5,2,2.5,3)
  abline(v=log(ticks),col="#EAEAEA",lwd=1)
  abline(v=0,col="#777777",lty=2,lwd=1.4)
  segments(log(d$ci_lower),d$y,log(d$ci_upper),d$y,col="#245B86",lwd=2.4)
  segments(log(d$ci_lower),d$y-.085,log(d$ci_lower),d$y+.085,col="#245B86",lwd=1.5)
  segments(log(d$ci_upper),d$y-.085,log(d$ci_upper),d$y+.085,col="#245B86",lwd=1.5)
  points(log(d$odds_ratio),d$y,pch=21,bg="#1879B9",col="#13405F",cex=1.5,lwd=1.1)
  axis(1,at=log(ticks),labels=ticks,cex.axis=1.03,col.axis="#232323",lwd=0)
  axis(2,at=d$y,labels=d$label,las=1,tick=FALSE,cex.axis=.97,line=-.3,col.axis="#202020")
  mtext("Adjusted odds ratio (logarithmic scale)",side=1,line=2.7,cex=1.05)
  title(main="Adjusted Odds Ratios for Inpatient Utilization",cex.main=1.55,line=2.9)
  title(sub="Multivariable logistic regression | CMS DE-SynPUF synthetic Medicare data",cex.sub=.97,line=1)
  # A separate aligned numerical column with estimate and bounds.
  par(xpd=NA)
  right_edge <- par("usr")[2]
  text(right_edge+0.09,d$y,d$ci_text,adj=0,cex=.88,col="#323232")
  text(right_edge+0.09,6.53,"aOR (95% CI)",adj=0,font=2,cex=.93)
  mtext("Source: CMS Medicare Claims Synthetic Public Use Files (DE-SynPUF).",side=1,line=4.3,adj=0,cex=.77)
  mtext("Exploratory same-window associations; not causal or prospective predictions.",side=1,line=5.2,adj=0,cex=.77)
  par(xpd=FALSE)
}
png(file.path(output_dir,"inpatient_forest_plot_portfolio.png"),width=3600,height=2150,res=300)
draw_forest()
dev.off()
pdf(file.path(output_dir,"inpatient_forest_plot_portfolio.pdf"),width=12,height=7.17,onefile=TRUE)
draw_forest()
dev.off()
write.csv(data.frame(predictor=d$label,odds_ratio=d$odds_ratio,ci_lower=d$ci_lower,ci_upper=d$ci_upper,display=d$ci_text),file.path(output_dir,"inpatient_forest_plot_verified_values.csv"),row.names=FALSE)
cat("PLOT_EXPORT_PASS: 6 covariates; PNG, PDF and verification CSV created\n")
