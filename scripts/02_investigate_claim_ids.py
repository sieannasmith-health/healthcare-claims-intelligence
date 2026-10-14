#!/usr/bin/env python3
import csv,json
from pathlib import Path
from collections import defaultdict,Counter
root=Path.home()/"Documents/Healthcare-Claims-Intelligence"
src=root/"data/raw/DE1_0_2008_to_2010_Inpatient_Claims_Sample_1.csv"
groups=defaultdict(list)
with src.open(newline="",encoding="utf-8-sig") as f:
 for row in csv.DictReader(f):
  if row["CLM_ID"]:groups[row["CLM_ID"]].append(row)
repeats={k:v for k,v in groups.items() if len(v)>1}
counts=Counter()
examples=[]
for cid,rows in repeats.items():
 counts["repeated_claim_ids"]+=1
 counts["rows_in_repeated_groups"]+=len(rows)
 if len({tuple(r.items()) for r in rows})==1:counts["fully_identical_groups"]+=1
 for field,label in [("SEGMENT","different_segments"),("DESYNPUF_ID","different_beneficiaries"),("CLM_FROM_DT","different_start_dates"),("CLM_PMT_AMT","different_payments")]:
  if len({r[field] for r in rows})>1:counts[label]+=1
 if len(examples)<5:
  examples.append({"claim_id":cid,"rows":[{k:r.get(k) for k in ("DESYNPUF_ID","SEGMENT","CLM_FROM_DT","CLM_THRU_DT","CLM_PMT_AMT")} for r in rows],"different_fields":[k for k in rows[0] if len({r[k] for r in rows})>1]})
result={"counts":dict(counts),"group_sizes":dict(Counter(str(len(v)) for v in repeats.values())),"segment_patterns":dict(Counter("/".join(sorted(r["SEGMENT"] for r in v)) for v in repeats.values())),"examples":examples}
dest=root/"reports/repeated_claim_investigation.json"
dest.write_text(json.dumps(result,indent=2)+"\n")
print(json.dumps(result,indent=2))
print("SAVED",dest)
