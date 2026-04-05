"""
Destinator Admin Dashboard
Flask + Firestore admin panel for viewing GPS trip data
from my C++ Destinator simulator.

Cloud Databases Module - CSE 310
Three collections: 'users', 'drivers', and 'trips'
CRUD operations: Insert, Modify, Delete, Retrieve/Query

I added a DEMO_MODE that kicks in when the serviceAccountKey.json file
isn't present — learned from the Firebase docs that the key is needed
for authentication, so this lets me preview the dashboard without it.
"""

import os
import re
import csv
import uuid
from datetime import datetime
from functools import wraps
from flask import Flask, render_template, request, redirect, url_for, flash, jsonify, session
import bcrypt
from flask_login import LoginManager, UserMixin, login_user, logout_user, login_required, current_user

# ---------------------------------------------------------------------------
# Flask setup — learned from the Flask quickstart guide
# ---------------------------------------------------------------------------
app = Flask(__name__)
app.secret_key = os.environ.get("FLASK_SECRET_KEY", "destinator-dev-key-change-in-prod")

# ---------------------------------------------------------------------------
# Firestore initialization — firebase-admin docs say to use a service
# account key for server-side access. If the key is missing, fall back
# to demo mode with in-memory data so I can still test the UI.
# ---------------------------------------------------------------------------
SERVICE_ACCOUNT_PATH = os.environ.get(
    "GOOGLE_APPLICATION_CREDENTIALS",
    os.path.join(os.path.dirname(__file__), "serviceAccountKey.json"),
)

DEMO_MODE = not os.path.exists(SERVICE_ACCOUNT_PATH)

if DEMO_MODE:
    print("\n⚠  serviceAccountKey.json not found — running in DEMO MODE")
    print("   Dashboard will show sample data. Add your Firebase key to go live.\n")
    db = None
    drivers_ref = None
    trips_ref = None
    users_ref = None
else:
    import firebase_admin
    from firebase_admin import credentials, firestore
    if not firebase_admin._apps:
        cred = credentials.Certificate(SERVICE_ACCOUNT_PATH)
        firebase_admin.initialize_app(cred)
    db = firestore.client()
    drivers_ref = db.collection("drivers")
    trips_ref = db.collection("trips")
    users_ref = db.collection("users")

# ---------------------------------------------------------------------------
# Flask-Login setup — the docs say to create a LoginManager, set
# login_view for redirects, and define a user_loader callback.
# ---------------------------------------------------------------------------
login_manager = LoginManager()
login_manager.init_app(app)
login_manager.login_view = "login"
login_manager.login_message = "Please log in to access the dashboard."
login_manager.login_message_category = "warning"


class User(UserMixin):
    """User object for Flask-Login — UserMixin gives us is_authenticated, etc."""
    def __init__(self, uid, firstname, lastname, email):
        self.id = uid
        self.firstname = firstname
        self.lastname = lastname
        self.email = email


@login_manager.user_loader
def load_user(user_id):
    """Flask-Login calls this on every request to reload the user from their session id."""
    if DEMO_MODE:
        u = next((u for u in DEMO_USERS if u["id"] == user_id), None)
        if u:
            return User(u["id"], u["firstname"], u["lastname"], u["email"])
        return None
    doc = users_ref.document(user_id).get()
    if doc.exists:
        d = doc.to_dict()
        return User(doc.id, d["firstname"], d["lastname"], d["email"])
    return None

# ---------------------------------------------------------------------------
# Demo data — used when Firestore key isn't available.
# I pre-hash the demo password with bcrypt so the login flow is realistic.
# ---------------------------------------------------------------------------
_demo_hash = bcrypt.hashpw(b"DemoPass123!", bcrypt.gensalt(10))

DEMO_USERS = [
    {
        "id": "user_admin",
        "firstname": "James",
        "lastname": "Burdick",
        "email": "james@destinator.dev",
        "password": _demo_hash,
    },
]

DEMO_DRIVERS = [
    {"id": "driver_default", "name": "James Burdick", "vehicle": "2019 Honda Civic"},
    {"id": "driver_02", "name": "Sarah Chen", "vehicle": "2021 Toyota Camry"},
]

DEMO_TRIPS = [
    {"id": "trip_001", "driver_id": "driver_default", "from_location": "Home",
     "to_location": "Daycare 1", "odo_start": 1200.0, "odo_end": 1202.0,
     "odo_miles": 2.0, "gps_miles": 2.01, "criteria": "JUST RIGHT",
     "date": "03-28-2026", "start_time": "09:01:22", "end_time": "09:04:13",
     "explanation": "On track"},
    {"id": "trip_002", "driver_id": "driver_default", "from_location": "Daycare 1",
     "to_location": "Work", "odo_start": 1202.0, "odo_end": 1205.0,
     "odo_miles": 3.0, "gps_miles": 2.68, "criteria": "UNDER",
     "date": "03-28-2026", "start_time": "09:06:00", "end_time": "09:12:45",
     "explanation": "Route was faster than expected"},
    {"id": "trip_003", "driver_id": "driver_default", "from_location": "Work",
     "to_location": "Store", "odo_start": 1205.0, "odo_end": 1210.0,
     "odo_miles": 5.0, "gps_miles": 5.34, "criteria": "OVER",
     "date": "03-28-2026", "start_time": "17:30:00", "end_time": "17:42:18",
     "explanation": "Detour for construction"},
    {"id": "trip_004", "driver_id": "driver_02", "from_location": "Home",
     "to_location": "Gas", "odo_start": 8400.0, "odo_end": 8403.0,
     "odo_miles": 3.0, "gps_miles": 2.95, "criteria": "JUST RIGHT",
     "date": "03-29-2026", "start_time": "08:15:00", "end_time": "08:22:30",
     "explanation": "On track"},
    {"id": "trip_005", "driver_id": "driver_02", "from_location": "Gas",
     "to_location": "Daycare 2", "odo_start": 8403.0, "odo_end": 8407.0,
     "odo_miles": 4.0, "gps_miles": 3.91, "criteria": "JUST RIGHT",
     "date": "03-29-2026", "start_time": "08:25:00", "end_time": "08:35:12",
     "explanation": "On track"},
]

# ---------------------------------------------------------------------------
# Helper: seed a default driver so there's at least one for new trips
# ---------------------------------------------------------------------------
def ensure_default_driver():
    """Create a default driver document if the drivers collection is empty."""
    if DEMO_MODE:
        return
    from firebase_admin import firestore as fs
    docs = list(drivers_ref.limit(1).stream())
    if not docs:
        drivers_ref.document("driver_default").set({
            "name": "James Burdick",
            "vehicle": "Default Vehicle",
            "created_at": fs.SERVER_TIMESTAMP,
        })

# ---------------------------------------------------------------------------
# Password validation — regex requires 12+ chars with uppercase,
# lowercase, digit, and a special character. I found examples of this
# pattern in the bcrypt docs and various Flask auth tutorials.
# ---------------------------------------------------------------------------
PASSWORD_PATTERN = re.compile(
    r'^(?=.*\d)(?=.*[a-z])(?=.*[A-Z])(?=.*[^a-zA-Z0-9])(?!.*\s).{12,}$'
)


def _validate_password(password):
    """Return error string or None if valid."""
    if not PASSWORD_PATTERN.match(password):
        return ("Password does not meet requirements. "
                "Must be 12+ characters with uppercase, lowercase, number, and symbol.")
    return None

# ---------------------------------------------------------------------------
# Routes – Authentication
# ---------------------------------------------------------------------------
@app.route("/login", methods=["GET", "POST"])
def login():
    """Handle GET (show form) and POST (check credentials) for login."""
    if current_user.is_authenticated:
        return redirect(url_for("dashboard"))

    errors = []
    account_email = ""

    if request.method == "POST":
        account_email = request.form.get("account_email", "").strip()
        account_password = request.form.get("account_password", "")

        if not account_email:
            errors.append("A valid email is required.")
        pwd_err = _validate_password(account_password)
        if pwd_err:
            errors.append(pwd_err)

        if not errors:
            if DEMO_MODE:
                user_data = next(
                    (u for u in DEMO_USERS if u["email"] == account_email), None
                )
                if user_data and bcrypt.checkpw(
                    account_password.encode("utf-8"), user_data["password"]
                ):
                    login_user(User(
                        user_data["id"], user_data["firstname"],
                        user_data["lastname"], user_data["email"],
                    ))
                    flash(f"Welcome back, {user_data['firstname']}!", "success")
                    return redirect(url_for("dashboard"))
                else:
                    errors.append("Invalid email or password.")
            else:
                # Query Firestore for a user doc matching this email
                docs = list(users_ref.where("email", "==", account_email).limit(1).stream())
                if docs:
                    doc = docs[0]
                    d = doc.to_dict()
                    stored_hash = d["password"]
                    if isinstance(stored_hash, str):
                        stored_hash = stored_hash.encode("utf-8")
                    if bcrypt.checkpw(account_password.encode("utf-8"), stored_hash):
                        login_user(User(doc.id, d["firstname"], d["lastname"], d["email"]))
                        flash(f"Welcome back, {d['firstname']}!", "success")
                        return redirect(url_for("dashboard"))
                    else:
                        errors.append("Invalid email or password.")
                else:
                    errors.append("Invalid email or password.")

    return render_template("login.html", errors=errors, account_email=account_email)


@app.route("/register", methods=["GET", "POST"])
def register():
    """Handle GET (show form) and POST (create new user) for registration."""
    if current_user.is_authenticated:
        return redirect(url_for("dashboard"))

    errors = []
    account_firstname = ""
    account_lastname = ""
    account_email = ""

    if request.method == "POST":
        account_firstname = request.form.get("account_firstname", "").strip()
        account_lastname = request.form.get("account_lastname", "").strip()
        account_email = request.form.get("account_email", "").strip()
        account_password = request.form.get("account_password", "")

        # Validate each field before storing anything
        if not account_firstname:
            errors.append("Please provide a first name.")
        if not account_lastname or len(account_lastname) < 2:
            errors.append("Please provide a last name.")
        if not account_email or "@" not in account_email:
            errors.append("A valid email is required.")
        pwd_err = _validate_password(account_password)
        if pwd_err:
            errors.append(pwd_err)

        # Check for existing email
        if not errors:
            if DEMO_MODE:
                email_exists = any(u["email"] == account_email for u in DEMO_USERS)
            else:
                email_exists = bool(
                    list(users_ref.where("email", "==", account_email).limit(1).stream())
                )
            if email_exists:
                errors.append("Email exists. Please log in or use a different email.")

        if not errors:
            # Hash password with bcrypt — docs recommend 10+ salt rounds
            hashed = bcrypt.hashpw(account_password.encode("utf-8"), bcrypt.gensalt(10))

            if DEMO_MODE:
                DEMO_USERS.append({
                    "id": "user_" + uuid.uuid4().hex[:6],
                    "firstname": account_firstname,
                    "lastname": account_lastname,
                    "email": account_email,
                    "password": hashed,
                })
            else:
                users_ref.add({
                    "firstname": account_firstname,
                    "lastname": account_lastname,
                    "email": account_email,
                    "password": hashed.decode("utf-8"),
                })

            flash(
                f"Congratulations, you're registered {account_firstname}. Please log in.",
                "success",
            )
            return redirect(url_for("login"))

    return render_template(
        "register.html", errors=errors,
        account_firstname=account_firstname,
        account_lastname=account_lastname,
        account_email=account_email,
    )


@app.route("/logout")
@login_required
def logout():
    """Clear the session and send user back to the login page."""
    logout_user()
    flash("You have been logged out.", "success")
    return redirect(url_for("login"))

# ---------------------------------------------------------------------------
# Routes – Dashboard
# ---------------------------------------------------------------------------
@app.route("/")
@login_required
def dashboard():
    """Main page — pulls trips and drivers to show summary stats."""
    if DEMO_MODE:
        trips = list(DEMO_TRIPS)
        drivers = list(DEMO_DRIVERS)
    else:
        trips = [doc.to_dict() | {"id": doc.id} for doc in trips_ref.stream()]
        drivers = [doc.to_dict() | {"id": doc.id} for doc in drivers_ref.stream()]
    total_miles = sum(float(t.get("gps_miles", 0)) for t in trips)
    return render_template(
        "dashboard.html",
        trips=trips,
        drivers=drivers,
        total_miles=round(total_miles, 2),
        total_trips=len(trips),
        total_drivers=len(drivers),
        demo_mode=DEMO_MODE,
    )

# ---------------------------------------------------------------------------
# Routes – Trips (CRUD)
# ---------------------------------------------------------------------------
@app.route("/trips")
@login_required
def list_trips():
    """RETRIEVE — list all trips, with optional filter by driver_id."""
    driver_filter = request.args.get("driver_id", "")
    if DEMO_MODE:
        trips = [t for t in DEMO_TRIPS if not driver_filter or t["driver_id"] == driver_filter]
        drivers = list(DEMO_DRIVERS)
    else:
        query = trips_ref
        if driver_filter:
            query = query.where("driver_id", "==", driver_filter)
        trips = [doc.to_dict() | {"id": doc.id} for doc in query.stream()]
        drivers = [doc.to_dict() | {"id": doc.id} for doc in drivers_ref.stream()]
    return render_template("trips.html", trips=trips, drivers=drivers,
                           active_filter=driver_filter)


@app.route("/trips/add", methods=["GET", "POST"])
@login_required
def add_trip():
    """INSERT — add a new trip document to Firestore (or demo list)."""
    if DEMO_MODE:
        drivers = list(DEMO_DRIVERS)
    else:
        drivers = [doc.to_dict() | {"id": doc.id} for doc in drivers_ref.stream()]
    if request.method == "POST":
        data = {
            "driver_id": request.form["driver_id"],
            "from_location": request.form["from_location"],
            "to_location": request.form["to_location"],
            "odo_start": float(request.form["odo_start"]),
            "odo_end": float(request.form["odo_end"]),
            "odo_miles": float(request.form["odo_end"]) - float(request.form["odo_start"]),
            "gps_miles": float(request.form["gps_miles"]),
            "criteria": request.form["criteria"],
            "date": request.form["date"],
            "start_time": request.form["start_time"],
            "end_time": request.form["end_time"],
            "explanation": request.form.get("explanation", ""),
        }
        if DEMO_MODE:
            data["id"] = "trip_" + uuid.uuid4().hex[:6]
            DEMO_TRIPS.append(data)
        else:
            from firebase_admin import firestore as fs
            data["created_at"] = fs.SERVER_TIMESTAMP
            trips_ref.add(data)
        flash("Trip added successfully.", "success")
        return redirect(url_for("list_trips"))
    return render_template("trip_form.html", trip=None, drivers=drivers, action="Add")


@app.route("/trips/edit/<trip_id>", methods=["GET", "POST"])
@login_required
def edit_trip(trip_id):
    """MODIFY — update fields on an existing trip document."""
    if DEMO_MODE:
        drivers = list(DEMO_DRIVERS)
        trip = next((t for t in DEMO_TRIPS if t["id"] == trip_id), None)
        if request.method == "POST" and trip:
            trip.update({
                "driver_id": request.form["driver_id"],
                "from_location": request.form["from_location"],
                "to_location": request.form["to_location"],
                "odo_start": float(request.form["odo_start"]),
                "odo_end": float(request.form["odo_end"]),
                "odo_miles": float(request.form["odo_end"]) - float(request.form["odo_start"]),
                "gps_miles": float(request.form["gps_miles"]),
                "criteria": request.form["criteria"],
                "date": request.form["date"],
                "start_time": request.form["start_time"],
                "end_time": request.form["end_time"],
                "explanation": request.form.get("explanation", ""),
            })
            flash("Trip updated successfully.", "success")
            return redirect(url_for("list_trips"))
        return render_template("trip_form.html", trip=trip, drivers=drivers, action="Edit")

    doc_ref = trips_ref.document(trip_id)
    drivers = [doc.to_dict() | {"id": doc.id} for doc in drivers_ref.stream()]
    if request.method == "POST":
        updates = {
            "driver_id": request.form["driver_id"],
            "from_location": request.form["from_location"],
            "to_location": request.form["to_location"],
            "odo_start": float(request.form["odo_start"]),
            "odo_end": float(request.form["odo_end"]),
            "odo_miles": float(request.form["odo_end"]) - float(request.form["odo_start"]),
            "gps_miles": float(request.form["gps_miles"]),
            "criteria": request.form["criteria"],
            "date": request.form["date"],
            "start_time": request.form["start_time"],
            "end_time": request.form["end_time"],
            "explanation": request.form.get("explanation", ""),
        }
        doc_ref.update(updates)
        flash("Trip updated successfully.", "success")
        return redirect(url_for("list_trips"))
    trip = doc_ref.get().to_dict() | {"id": trip_id}
    return render_template("trip_form.html", trip=trip, drivers=drivers, action="Edit")


@app.route("/trips/delete/<trip_id>", methods=["POST"])
@login_required
def delete_trip(trip_id):
    """DELETE — remove a trip document."""
    if DEMO_MODE:
        DEMO_TRIPS[:] = [t for t in DEMO_TRIPS if t["id"] != trip_id]
    else:
        trips_ref.document(trip_id).delete()
    flash("Trip deleted.", "warning")
    return redirect(url_for("list_trips"))

# ---------------------------------------------------------------------------
# Routes – Drivers (CRUD)
# ---------------------------------------------------------------------------
@app.route("/drivers")
@login_required
def list_drivers():
    """RETRIEVE — list all driver documents."""
    if DEMO_MODE:
        drivers = list(DEMO_DRIVERS)
    else:
        drivers = [doc.to_dict() | {"id": doc.id} for doc in drivers_ref.stream()]
    return render_template("drivers.html", drivers=drivers)


@app.route("/drivers/add", methods=["GET", "POST"])
@login_required
def add_driver():
    """INSERT — add a new driver document."""
    if request.method == "POST":
        data = {
            "name": request.form["name"],
            "vehicle": request.form["vehicle"],
        }
        if DEMO_MODE:
            data["id"] = "driver_" + uuid.uuid4().hex[:6]
            DEMO_DRIVERS.append(data)
        else:
            from firebase_admin import firestore as fs
            data["created_at"] = fs.SERVER_TIMESTAMP
            drivers_ref.add(data)
        flash("Driver added successfully.", "success")
        return redirect(url_for("list_drivers"))
    return render_template("driver_form.html", driver=None, action="Add")


@app.route("/drivers/edit/<driver_id>", methods=["GET", "POST"])
@login_required
def edit_driver(driver_id):
    """MODIFY — update an existing driver's info."""
    if DEMO_MODE:
        driver = next((d for d in DEMO_DRIVERS if d["id"] == driver_id), None)
        if request.method == "POST" and driver:
            driver.update({"name": request.form["name"], "vehicle": request.form["vehicle"]})
            flash("Driver updated.", "success")
            return redirect(url_for("list_drivers"))
        return render_template("driver_form.html", driver=driver, action="Edit")

    doc_ref = drivers_ref.document(driver_id)
    if request.method == "POST":
        doc_ref.update({
            "name": request.form["name"],
            "vehicle": request.form["vehicle"],
        })
        flash("Driver updated.", "success")
        return redirect(url_for("list_drivers"))
    driver = doc_ref.get().to_dict() | {"id": driver_id}
    return render_template("driver_form.html", driver=driver, action="Edit")


@app.route("/drivers/delete/<driver_id>", methods=["POST"])
@login_required
def delete_driver(driver_id):
    """DELETE — remove a driver and cascade-delete their trips."""
    if DEMO_MODE:
        DEMO_TRIPS[:] = [t for t in DEMO_TRIPS if t["driver_id"] != driver_id]
        DEMO_DRIVERS[:] = [d for d in DEMO_DRIVERS if d["id"] != driver_id]
    else:
        related = trips_ref.where("driver_id", "==", driver_id).stream()
        for doc in related:
            doc.reference.delete()
        drivers_ref.document(driver_id).delete()
    flash("Driver and related trips deleted.", "warning")
    return redirect(url_for("list_drivers"))

# ---------------------------------------------------------------------------
# Routes – CSV Import
# ---------------------------------------------------------------------------
@app.route("/import", methods=["GET", "POST"])
@login_required
def import_csv():
    """Import trip data from a CSV file (exported by my C++ simulator)."""
    if request.method == "POST":
        csv_file = request.files.get("csv_file")
        driver_id = request.form.get("driver_id", "driver_default")
        if not csv_file or not csv_file.filename.endswith(".csv"):
            flash("Please upload a valid .csv file.", "error")
            return redirect(url_for("import_csv"))

        reader = csv.DictReader(csv_file.stream.read().decode("utf-8").splitlines())
        count = 0
        for row in reader:
            trip = {
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
            }
            if DEMO_MODE:
                trip["id"] = "trip_" + uuid.uuid4().hex[:6]
                DEMO_TRIPS.append(trip)
            else:
                from firebase_admin import firestore as fs
                trip["created_at"] = fs.SERVER_TIMESTAMP
                trips_ref.add(trip)
            count += 1
        flash(f"Imported {count} trip(s) from CSV.", "success")
        return redirect(url_for("list_trips"))
    if DEMO_MODE:
        drivers = list(DEMO_DRIVERS)
    else:
        drivers = [doc.to_dict() | {"id": doc.id} for doc in drivers_ref.stream()]
    return render_template("import.html", drivers=drivers)

# ---------------------------------------------------------------------------
# API endpoint – returns JSON for potential AJAX use
# ---------------------------------------------------------------------------
@app.route("/api/trips")
@login_required
def api_trips():
    """Return all trips as JSON — useful for fetching data from JS."""
    if DEMO_MODE:
        return jsonify(DEMO_TRIPS)
    trips = []
    for doc in trips_ref.order_by("date", direction=firestore.Query.DESCENDING).stream():
        t = doc.to_dict()
        t["id"] = doc.id
        if t.get("created_at"):
            t["created_at"] = str(t["created_at"])
        trips.append(t)
    return jsonify(trips)

# ---------------------------------------------------------------------------
# Start the app
# ---------------------------------------------------------------------------
if __name__ == "__main__":
    ensure_default_driver()
    app.run(debug=True, port=5000)
