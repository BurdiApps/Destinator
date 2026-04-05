"""
csv_importer.py
Standalone script to import trip_data.csv from the C++ Destinator
simulator directly into Firestore (without Flask running).

Usage:
    python csv_importer.py path/to/trip_data.csv [driver_id]
"""

import sys
import csv
import os
import firebase_admin
from firebase_admin import credentials, firestore

SERVICE_ACCOUNT_PATH = os.environ.get(
    "GOOGLE_APPLICATION_CREDENTIALS",
    os.path.join(os.path.dirname(__file__), "serviceAccountKey.json"),
)

def import_csv(csv_path, driver_id="driver_default"):
    """Read the C++ simulator CSV and push each row to Firestore."""
    if not firebase_admin._apps:
        cred = credentials.Certificate(SERVICE_ACCOUNT_PATH)
        firebase_admin.initialize_app(cred)

    db = firestore.client()
    trips_ref = db.collection("trips")

    with open(csv_path, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        count = 0
        for row in reader:
            trips_ref.add({
                "driver_id": driver_id,
                "from_location": row.get("From", ""),
                "to_location": row.get("To", ""),
                "odo_start": float(row.get("Odo Start", 0)),
                "odo_end": float(row.get("Odo End", 0)),
                "odo_miles": float(row.get("Odo Miles", 0)),
                "gps_miles": float(row.get("GPS Miles", 0)),
                "criteria": row.get("Criteria", ""),
                "date": row.get("Date", ""),
                "start_time": row.get("Start Time", ""),
                "end_time": row.get("End Time", ""),
                "explanation": row.get("Explanation", "").strip('"'),
                "created_at": firestore.SERVER_TIMESTAMP,
            })
            count += 1
    print(f"Imported {count} trip(s) into Firestore.")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python csv_importer.py <csv_file> [driver_id]")
        sys.exit(1)
    csv_file = sys.argv[1]
    did = sys.argv[2] if len(sys.argv) > 2 else "driver_default"
    import_csv(csv_file, did)
