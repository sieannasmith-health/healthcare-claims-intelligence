"""Prepare local Power BI inputs and reconcile source metrics. No row-level data is committed."""
import csv, json, collections
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
SRC=ROOT/"data/processed/beneficiary_model_data.csv"
OUT=ROOT/"powerbi/local_data"
OUT.mkdir(parents=True,exist_ok=True)
DIMS=["SP_DIABETES","SP_CHF","SP_COPD","SP_CHRNKIDN"]
labels={"1":"Yes","2":"No"}
summary=collections.defaultdict(lambda:[0,0,0])
num=0; eligible=0; total_claims=0; seen=set()
with SRC.open(newline="") as f:
    for row in csv.DictReader(f):
        ident=row["DESYNPUF_ID"]
        if ident in seen: raise ValueError("Duplicate beneficiary ID")
        seen.add(ident)
        claims=int(row["claim_count"])
        if claims<0:raise ValueError("Negative claims")
        any_claim=int(claims>0)
        num+=1; eligible+=any_claim; total_claims+=claims
        for field in DIMS:
            status=labels.get(row[field],"Unknown")
            bucket=summary[(field,status)]
            bucket[0]+=1; bucket[1]+=any_claim; bucket[2]+=claims
assert (num,eligible,total_claims)==(116352,37780,66705),(num,eligible,total_claims)
with (OUT/"chronic_condition_summary.csv").open("w",newline="") as f:
    w=csv.writer(f);w.writerow(["condition","status","beneficiaries","beneficiaries_with_inpatient_claim","distinct_inpatient_claims","inpatient_utilization_rate"])
    for (condition,status),(n,events,claims) in sorted(summary.items()):
        w.writerow([condition.replace("SP_",""),status,n,events,claims,round(events/n,6)])
with (OUT/"kpi_summary.csv").open("w",newline="") as f:
    w=csv.writer(f);w.writerow(["metric","value"])
    for metric,val in [("beneficiaries",num),("beneficiaries_with_inpatient_claim",eligible),("unique_inpatient_claims",total_claims),("inpatient_utilization_rate",eligible/num),("average_claims_per_beneficiary",total_claims/num)]:
        w.writerow([metric,round(val,8)])
src=ROOT/"reports/inpatient_logistic_odds_ratios.csv"
if src.exists():
    (OUT/"inpatient_logistic_odds_ratios.csv").write_bytes(src.read_bytes())
audit={"source":str(SRC),"records":num,"unique_beneficiary_ids":len(seen),"inpatient_beneficiaries":eligible,"distinct_claims":total_claims,"utilization_pct":round(eligible/num*100,4),"passed":True,"notes":"CMS DE-SynPUF synthetic data; descriptive same-window associations only"}
(OUT/"validation.json").write_text(json.dumps(audit,indent=2)+"\n")
print(json.dumps(audit,indent=2))
print("Wrote",*[p.name for p in sorted(OUT.iterdir())],sep="\n")