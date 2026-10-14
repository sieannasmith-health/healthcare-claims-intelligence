
import csv
import re
import sqlite3
from pathlib import Path

# Locate our project and original Medicare files.
ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / "data" / "raw"
DB_DIR = ROOT / "data" / "processed"
DB_DIR.mkdir(parents=True, exist_ok=True)

DB_PATH = DB_DIR / "healthcare_claims.db"

FILES = {
    "beneficiaries_2008": (
        "DE1_0_2008_Beneficiary_Summary_File_Sample_1.csv",
        ["DESYNPUF_ID"],
    ),
    "inpatient_segments": (
        "DE1_0_2008_to_2010_Inpatient_Claims_Sample_1.csv",
        ["CLM_ID", "SEGMENT"],
    ),
}


def quote_identifier(name):
    """Allow only conventional SQL column identifiers."""
    if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", name):
        raise ValueError(f"Unexpected column name: {name}")
    return f'"{name}"'


def load_table(connection, table, filename, key_columns):
    """Create a table and load every original CSV column."""
    source = RAW / filename

    with source.open(newline="", encoding="utf-8-sig") as file:
        reader = csv.DictReader(file)
        columns = reader.fieldnames

        if not columns or not set(key_columns).issubset(columns):
            raise ValueError(f"Invalid columns in {filename}")

        column_definitions = [
            f"{quote_identifier(col)} TEXT"
            for col in columns
        ]

        primary_key = ", ".join(
            quote_identifier(col) for col in key_columns
        )

        column_definitions.append(
            f"PRIMARY KEY ({primary_key})"
        )

        if table == "inpatient_segments":
            column_definitions.append(
                'FOREIGN KEY ("DESYNPUF_ID") '
                'REFERENCES beneficiaries_2008("DESYNPUF_ID")'
            )

        create_sql = (
            f"CREATE TABLE {table} "
            f"({', '.join(column_definitions)})"
        )
        connection.execute(create_sql)

        fields = ", ".join(
            quote_identifier(col) for col in columns
        )
        placeholders = ", ".join("?" for _ in columns)

        insert_sql = (
            f"INSERT INTO {table} ({fields}) "
            f"VALUES ({placeholders})"
        )

        batch = []
        total = 0

        for row in reader:
            if any(not row.get(key) for key in key_columns):
                raise ValueError(f"Missing key in {table}")

            batch.append(tuple(row[col] for col in columns))

            if len(batch) == 1000:
                connection.executemany(insert_sql, batch)
                total += len(batch)
                batch.clear()

        if batch:
            connection.executemany(insert_sql, batch)
            total += len(batch)

    print(f"Loaded {table}: {total:,} rows")


def main():
    if DB_PATH.exists():
        raise FileExistsError(
            f"Database already exists: {DB_PATH}"
        )

    print("Building Healthcare Claims database...")

    connection = sqlite3.connect(DB_PATH)

    try:
        connection.execute("PRAGMA foreign_keys = ON")

        with connection:
            for table, (filename, keys) in FILES.items():
                load_table(
                    connection, table, filename, keys
                )

            for table in FILES:
                count = connection.execute(
                    f"SELECT COUNT(*) FROM {table}"
                ).fetchone()[0]
                print(f"Verified {table}: {count:,} rows")

            claims = connection.execute(
                "SELECT COUNT(DISTINCT CLM_ID) "
                "FROM inpatient_segments"
            ).fetchone()[0]

            print(f"Unique claims: {claims:,}")

            violations = connection.execute(
                "PRAGMA foreign_key_check"
            ).fetchall()

            if violations:
                raise ValueError(
                    f"Foreign key violations: {violations[:5]}"
                )

            assert connection.execute(
                "SELECT COUNT(*) FROM beneficiaries_2008"
            ).fetchone()[0] == 116352

            assert connection.execute(
                "SELECT COUNT(*) FROM inpatient_segments"
            ).fetchone()[0] == 66773

            assert claims == 66705

        print("All validation checks passed.")
        print(f"Database saved: {DB_PATH}")

    except Exception:
        connection.close()
        DB_PATH.unlink(missing_ok=True)
        raise

    finally:
        connection.close()

if __name__ == "__main__":

    main()
