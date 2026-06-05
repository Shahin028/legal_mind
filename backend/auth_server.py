from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pymongo import MongoClient
from passlib.context import CryptContext
import uuid
from datetime import datetime

app = FastAPI()

#################################################
# CORS SETTINGS
#################################################

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

#################################################
# PASSWORD HASHING
#################################################

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(password: str, hashed: str) -> bool:
    try:
        return pwd_context.verify(password, hashed)
    except Exception as e:
        print(f"[AUTH] verify_password ERROR: {e}")
        return False

#################################################
# MONGODB CONNECTION
#################################################

try:
    client = MongoClient("mongodb://127.0.0.1:27017", serverSelectionTimeoutMS=3000)
    client.server_info()
    db           = client["legalmind"]
    users        = db["users"]
    lawyers      = db["lawyers"]
    appointments = db["appointments"]
    messages     = db["messages"]
    chat_history = db["chat_history"]
    reviews      = db["reviews"]
    saved_laws   = db["saved_laws"]
    print("MongoDB Connected")
except Exception as e:
    print(f"MongoDB Connection FAILED: {e}")
    raise

#################################################
# HEALTH CHECK
#################################################

@app.get("/")
def home():
    return {"status": "success", "message": "LegalMind Auth Server Running"}

#################################################
# SIGNUP API
#################################################

@app.post("/signup")
def signup(data: dict):
    email    = data.get("email",    "").strip()
    password = data.get("password", "").strip()
    role     = data.get("role",     "user").strip().lower()

    print(f"[AUTH-SIGNUP] email='{email}' role='{role}'")

    if role not in ["user", "lawyer"]:
        return {"status": "failed", "message": "Invalid role specified"}

    if not email or not password:
        return {"status": "failed", "message": "Email and Password required"}

    try:
        if users.find_one({"email": email}) or lawyers.find_one({"email": email}):
            return {"status": "failed", "message": "User already exists with this email"}

        hashed_password = hash_password(password)

        new_account = {
            "name":     data.get("name",   "").strip(),
            "state":    data.get("state",  "").strip(),
            "mobile":   data.get("mobile", "").strip(),
            "email":    email,
            "password": hashed_password,
            "role":     role,
        }

        if role == "lawyer":
            new_account.update({
                "specialization":      "",
                "experience":          "",
                "contact":             new_account["mobile"],
                "location":            new_account["state"],
                "bio":                 "",
                "win_rate":            0,
                "courts":              [],
                "languages":           [],
                "cases":               [],
                "enrollment_number":   "",
                "is_profile_complete": False,
            })
            lawyers.insert_one(new_account)
        else:
            users.insert_one(new_account)

        print(f"[AUTH-SIGNUP] success: {email} as {role}")
        return {"status": "success", "message": "Signup Successful", "role": role}

    except Exception as e:
        print(f"[AUTH-SIGNUP] ERROR: {e}")
        return {"status": "error", "message": f"Server error {e} during signup"}

#################################################
# LOGIN API
#################################################

@app.post("/login")
def login(data: dict):
    email    = data.get("email",    "").strip()
    password = data.get("password", "").strip()
    role     = data.get("role",     "user").strip().lower()

    print(f"[AUTH-LOGIN] email='{email}' role='{role}'")

    if not email or not password:
        return {"status": "failed", "message": "Email and Password required"}

    if role not in ["user", "lawyer"]:
        return {"status": "failed", "message": "Invalid role"}

    try:
        collection = lawyers if role == "lawyer" else users
        existing   = collection.find_one({"email": email})

        if not existing:
            return {"status": "failed", "message": f"Account not found for role: {role}"}

        if not verify_password(password, existing["password"]):
            return {"status": "failed", "message": "Wrong password"}

        print(f"[AUTH-LOGIN] success: {email} as {role}")
        return {
            "status": "success",
            "name":   existing.get("name", ""),
            "email":  existing["email"],
            "role":   role,
        }

    except Exception as e:
        print(f"[AUTH-LOGIN] ERROR: {e}")
        return {"status": "error", "message": "Server error during login"}

#################################################
# LAWYER PROFILE UPDATE
#################################################

@app.post("/register-lawyer")
def register_lawyer(data: dict):
    email = data.get("email", "").strip()
    print(f"[AUTH-UPDATE-LAWYER] email='{email}'")

    if not email:
        return {"status": "failed", "message": "Email required"}

    try:
        existing = lawyers.find_one({"email": email})
        if not existing:
            return {"status": "failed", "message": "Lawyer account not found. Please signup as a lawyer first."}

        # Accept courts/languages as comma-separated strings or lists
        raw_courts    = data.get("courts",    existing.get("courts",    []))
        raw_languages = data.get("languages", existing.get("languages", []))
        if isinstance(raw_courts, str):
            raw_courts = [c.strip() for c in raw_courts.split(",") if c.strip()]
        if isinstance(raw_languages, str):
            raw_languages = [l.strip() for l in raw_languages.split(",") if l.strip()]

        update_data = {
            "name":                data.get("name",              existing.get("name", "")).strip(),
            "specialization":      data.get("specialization",    "").strip(),
            "experience":          data.get("experience",        "").strip(),
            "contact":             data.get("contact",           existing.get("contact", "")).strip(),
            "location":            data.get("location",          existing.get("location", "")).strip(),
            "bio":                 data.get("bio",               existing.get("bio", "")).strip(),
            "win_rate":            data.get("win_rate",          existing.get("win_rate", 0)),
            "courts":              raw_courts,
            "languages":           raw_languages,
            "enrollment_number":   data.get("enrollment_number", existing.get("enrollment_number", "")).strip(),
            "is_profile_complete": True,
        }

        lawyers.update_one({"email": email}, {"$set": update_data})
        print(f"[AUTH-UPDATE-LAWYER] updated: {email}")
        return {"status": "success", "message": "Lawyer Profile Updated Successfully"}

    except Exception as e:
        print(f"[AUTH-UPDATE-LAWYER] ERROR: {e}")
        return {"status": "error", "message": "Server error updating profile"}

#################################################
# ADD CASE TO LAWYER PORTFOLIO
#################################################

@app.patch("/add-case")
def add_case(data: dict):
    email = data.get("email", "").strip()
    print(f"[AUTH-ADD-CASE] email='{email}'")

    if not email:
        return {"status": "failed", "message": "Email required"}

    case = {
        "title":       data.get("title",       "").strip(),
        "type":        data.get("type",        "General").strip(),
        "year":        data.get("year",        "").strip(),
        "outcome":     data.get("outcome",     "Settled").strip(),
        "description": data.get("description", "").strip(),
    }

    if not case["title"]:
        return {"status": "failed", "message": "Case title required"}

    try:
        result = lawyers.update_one({"email": email}, {"$push": {"cases": case}})
        if result.matched_count == 0:
            return {"status": "failed", "message": "Lawyer not found"}
        print(f"[AUTH-ADD-CASE] case '{case['title']}' added for {email}")
        return {"status": "success", "message": "Case added to portfolio"}
    except Exception as e:
        print(f"[AUTH-ADD-CASE] ERROR: {e}")
        return {"status": "error", "message": str(e)}

#################################################
# GET LAWYERS LIST
#################################################

@app.get("/lawyers")
def get_lawyers():
    print("[AUTH-LAWYERS] fetching lawyers list")
    try:
        lawyer_list = []
        for lawyer in lawyers.find():
            ratings    = lawyer.get("ratings", [])
            avg_rating = round(sum(ratings) / len(ratings), 1) if ratings else 0.0

            lawyer_list.append({
                "name":           lawyer.get("name"),
                "specialization": lawyer.get("specialization"),
                "experience":     lawyer.get("experience"),
                "contact":        lawyer.get("contact"),
                "location":       lawyer.get("location"),
                "email":          lawyer.get("email"),
                "bio":            lawyer.get("bio", ""),
                "win_rate":       lawyer.get("win_rate", 0),
                "courts":         lawyer.get("courts", []),
                "languages":      lawyer.get("languages", []),
                "cases":          lawyer.get("cases", []),
                "rating_avg":     avg_rating,
                "rating_count":   len(ratings),
            })
        print(f"[AUTH-LAWYERS] returning {len(lawyer_list)} lawyers")
        return {"status": "success", "lawyers": lawyer_list}

    except Exception as e:
        print(f"[AUTH-LAWYERS] ERROR: {e}")
        return {"status": "error", "lawyers": [], "message": str(e)}

#################################################
# RATE LAWYER
#################################################

@app.post("/rate-lawyer")
def rate_lawyer(data: dict):
    lawyer_email = data.get("lawyer_email", "").strip()
    rating       = data.get("rating")

    print(f"[AUTH-RATE-LAWYER] email='{lawyer_email}' rating='{rating}'")

    if not lawyer_email or rating is None:
        return {"status": "failed", "message": "Lawyer email and rating are required"}

    try:
        rating = float(rating)
        if rating < 1.0 or rating > 5.0:
            return {"status": "failed", "message": "Rating must be between 1 and 5"}

        existing = lawyers.find_one({"email": lawyer_email})
        if not existing:
            return {"status": "failed", "message": "Lawyer not found"}

        lawyers.update_one({"email": lawyer_email}, {"$push": {"ratings": rating}})
        print(f"[AUTH-RATE-LAWYER] added {rating} for {lawyer_email}")
        return {"status": "success", "message": "Rating submitted successfully"}

    except ValueError:
        return {"status": "failed", "message": "Invalid rating format"}
    except Exception as e:
        print(f"[AUTH-RATE-LAWYER] ERROR: {e}")
        return {"status": "error", "message": "Server error while submitting rating"}

#################################################
# REVIEWS
#################################################

@app.post("/add-review")
def add_review(data: dict):
    lawyer_email = data.get("lawyer_email", "").strip()
    user_email   = data.get("user_email",   "").strip()
    user_name    = data.get("user_name",    "Anonymous").strip()
    review_text  = data.get("review_text",  "").strip()
    rating       = data.get("rating", 0)

    print(f"[AUTH-ADD-REVIEW] from={user_email} to={lawyer_email}")

    if not lawyer_email or not review_text:
        return {"status": "failed", "message": "Lawyer email and review text required"}

    try:
        reviews.insert_one({
            "lawyer_email": lawyer_email,
            "user_email":   user_email,
            "user_name":    user_name,
            "review_text":  review_text,
            "rating":       rating,
            "created_at":   datetime.now().isoformat(),
        })
        print(f"[AUTH-ADD-REVIEW] saved for {lawyer_email}")
        return {"status": "success", "message": "Review submitted"}
    except Exception as e:
        print(f"[AUTH-ADD-REVIEW] ERROR: {e}")
        return {"status": "error", "message": str(e)}


@app.get("/reviews")
def get_reviews(lawyer_email: str):
    print(f"[AUTH-GET-REVIEWS] lawyer_email='{lawyer_email}'")
    try:
        result = []
        for r in reviews.find({"lawyer_email": lawyer_email}).sort("created_at", -1):
            result.append({
                "user_name":   r.get("user_name", "Anonymous"),
                "review_text": r.get("review_text", ""),
                "rating":      r.get("rating", 0),
                "created_at":  r.get("created_at", ""),
            })
        return {"status": "success", "reviews": result}
    except Exception as e:
        print(f"[AUTH-GET-REVIEWS] ERROR: {e}")
        return {"status": "error", "reviews": [], "message": str(e)}

#################################################
# CHAT HISTORY
#################################################

@app.post("/save-history")
def save_history(data: dict):
    user_email = data.get("user_email", "").strip()
    query      = data.get("query",      "").strip()
    response   = data.get("response",   "").strip()
    type_      = data.get("type",       "explain").strip()

    print(f"[AUTH-SAVE-HISTORY] user='{user_email}' type='{type_}'")

    if not user_email or not query:
        return {"status": "failed", "message": "user_email and query required"}

    try:
        chat_history.insert_one({
            "user_email": user_email,
            "query":      query,
            "response":   response,
            "type":       type_,
            "created_at": datetime.now().isoformat(),
        })
        return {"status": "success"}
    except Exception as e:
        print(f"[AUTH-SAVE-HISTORY] ERROR: {e}")
        return {"status": "error", "message": str(e)}


@app.get("/history")
def get_history(email: str):
    print(f"[AUTH-GET-HISTORY] email='{email}'")
    try:
        result = []
        for h in chat_history.find({"user_email": email}).sort("created_at", -1).limit(50):
            result.append({
                "query":      h.get("query", ""),
                "response":   h.get("response", ""),
                "type":       h.get("type", "explain"),
                "created_at": h.get("created_at", ""),
            })
        return {"status": "success", "history": result}
    except Exception as e:
        print(f"[AUTH-GET-HISTORY] ERROR: {e}")
        return {"status": "error", "history": [], "message": str(e)}

#################################################
# APPOINTMENTS & CHAT API
#################################################

@app.post("/request-appointment")
def request_appointment(data: dict):
    user_email   = data.get("user_email",   "").strip()
    user_name    = data.get("user_name",    "").strip()
    lawyer_email = data.get("lawyer_email", "").strip()
    lawyer_name  = data.get("lawyer_name",  "").strip()

    print(f"[AUTH-APPOINTMENT] {user_email} → {lawyer_email}")

    if not user_email or not lawyer_email:
        return {"status": "failed", "message": "User and Lawyer emails are required"}

    try:
        existing = appointments.find_one({
            "user_email":   user_email,
            "lawyer_email": lawyer_email,
        })

        if existing:
            return {
                "status": "success",
                "message": "Appointment already exists",
                "appointment_id": existing["appointment_id"],
            }

        appt_id  = str(uuid.uuid4())
        appointments.insert_one({
            "appointment_id": appt_id,
            "user_email":    user_email,
            "user_name":     user_name,
            "lawyer_email":  lawyer_email,
            "lawyer_name":   lawyer_name,
            "created_at":    datetime.now().isoformat(),
            "status":        "active",
        })
        print(f"[AUTH-APPOINTMENT] created: {appt_id}")
        return {"status": "success", "message": "Appointment created", "appointment_id": appt_id}

    except Exception as e:
        print(f"[AUTH-APPOINTMENT] ERROR: {e}")
        return {"status": "error", "message": str(e)}


@app.get("/appointments")
def get_appointments(email: str, role: str):
    print(f"[AUTH-APPOINTMENTS] {email} as {role}")
    try:
        query     = {"lawyer_email": email} if role == "lawyer" else {"user_email": email}
        appt_list = []
        for appt in appointments.find(query).sort("created_at", -1):
            appt_list.append({
                "appointment_id": appt.get("appointment_id"),
                "user_email":    appt.get("user_email"),
                "user_name":     appt.get("user_name"),
                "lawyer_email":  appt.get("lawyer_email"),
                "lawyer_name":   appt.get("lawyer_name"),
                "created_at":    appt.get("created_at"),
                "status":        appt.get("status"),
            })
        return {"status": "success", "appointments": appt_list}
    except Exception as e:
        print(f"[AUTH-APPOINTMENTS] ERROR: {e}")
        return {"status": "error", "message": str(e)}


@app.post("/send-message")
def send_message(data: dict):
    appt_id      = data.get("appointment_id", "").strip()
    sender_email = data.get("sender_email",   "").strip()
    text         = data.get("text",           "").strip()

    if not appt_id or not sender_email or not text:
        return {"status": "failed", "message": "Missing required fields"}

    try:
        messages.insert_one({
            "appointment_id": appt_id,
            "sender_email":   sender_email,
            "text":           text,
            "timestamp":      datetime.now().isoformat(),
        })
        return {"status": "success", "message": "Message sent"}
    except Exception as e:
        print(f"[AUTH-SEND-MSG] ERROR: {e}")
        return {"status": "error", "message": str(e)}


@app.get("/messages")
def get_messages(appointment_id: str):
    try:
        msg_list = []
        for msg in messages.find({"appointment_id": appointment_id}).sort("timestamp", 1):
            msg_list.append({
                "sender_email": msg.get("sender_email"),
                "text":         msg.get("text"),
                "timestamp":    msg.get("timestamp"),
            })
        return {"status": "success", "messages": msg_list}
    except Exception as e:
        print(f"[AUTH-GET-MSGS] ERROR: {e}")
        return {"status": "error", "message": str(e)}

#################################################
# SAVED LAWS ENDPOINTS
#################################################

@app.post("/save-law")
def save_law(data: dict):
    try:
        user_email = data.get("user_email")
        law_title = data.get("law_title")
        law_description = data.get("law_description")
        
        if not user_email or not law_title:
            return {"status": "error", "message": "Email and law_title are required"}
            
        saved_laws.insert_one({
            "law_id": str(uuid.uuid4()),
            "user_email": user_email,
            "law_title": law_title,
            "law_description": law_description,
            "timestamp": datetime.now().isoformat()
        })
        return {"status": "success", "message": "Law saved successfully"}
    except Exception as e:
        print(f"[AUTH-SAVE-LAW] ERROR: {e}")
        return {"status": "error", "message": str(e)}

@app.get("/saved-laws")
def get_saved_laws(user_email: str):
    try:
        laws_list = []
        for law in saved_laws.find({"user_email": user_email}).sort("timestamp", -1):
            laws_list.append({
                "law_id": law.get("law_id"),
                "law_title": law.get("law_title"),
                "law_description": law.get("law_description"),
                "timestamp": law.get("timestamp")
            })
        return {"status": "success", "laws": laws_list}
    except Exception as e:
        print(f"[AUTH-GET-LAWS] ERROR: {e}")
        return {"status": "error", "message": str(e)}

@app.delete("/remove-law")
def remove_law(law_id: str):
    try:
        result = saved_laws.delete_one({"law_id": law_id})
        if result.deleted_count > 0:
            return {"status": "success", "message": "Law removed successfully"}
        else:
            return {"status": "error", "message": "Law not found"}
    except Exception as e:
        print(f"[AUTH-REMOVE-LAW] ERROR: {e}")
        return {"status": "error", "message": str(e)}