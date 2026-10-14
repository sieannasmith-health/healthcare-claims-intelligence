"""Idempotently import CMS 2009 beneficiary summary into the existing SQLite DB."""
import csv
import sqlite3
from pathlib import Path

root=Path(__file__).resolve().parents[1]
source=root/"data/raw/DE1_0_2009_Beneficiary_Summary_File_Sample_1.csv"
db_path=root/"data/processed/healthcare_claims.db"
table="beneficiaries_2009"
with source.open(newline="",encoding="utf-8-sig") as f:
    reader=csv.DictReader(f)
    fields=reader.fieldnames
    assert fields and "DESYNPUF_ID" in fields
    assert all(s.replace("_","").isalnum() for s in fields)
    with sqlite3.connect(db_path) as conn:
        existing=conn.execute("SELECT name FROM sqlite_master WHERE type='table' AND name=?",(table,)).fetchone()
        if existing:
            n=conn.execute("SELECT COUNT(*) FROM beneficiaries_2009").fetchone()[0]
            print("Already imported:",n)
        else:
            schema=", ".join(f'"{s}" TEXT' for s in fields)
            conn.execute(f'CREATE TABLE "{table}" ({schema}, PRIMARY KEY ("DESYNPUF_ID"))')
            insert=f'INSERT INTO "{table}" VALUES ('+",".join("?" for _ in fields)+")"
            batch=[]
            for row in reader:
                batch.append(tuple(row[name] for name in fields))
                if len(batch)==1000:
                    conn.executemany(insert,batch);batch.clear()
            if batch:conn.executemany(insert,batch)
            n=conn.execute("SELECT COUNT(*) FROM beneficiaries_2009").fetchone()[0]
            print("Imported records:",n)
        print("Schema columns:",len(fields))
