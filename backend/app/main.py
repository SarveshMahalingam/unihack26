from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.orm import Session
from . import models, schemas, database
from .services import off_service, gemini_service,ethics_services
from pydantic import BaseModel
import uuid
import json
from typing import List,Optional
import sys
import os
import traceback
from .database import engine, Base
from . import models
import requests
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

# Add this block!
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all devices
    allow_credentials=True,
    allow_methods=["*"],  # Allows GET, POST, PUT, DELETE
    allow_headers=["*"],
)
# Create tables on startup
database.Base.metadata.create_all(bind=database.engine)

class SignUpRequest(BaseModel):
    name: str  # Note: I added name here because your Flutter app sends it!
    email: str
    password: str

class LogInRequest(BaseModel):
    email: str
    password: str

class UserPreferences(BaseModel):
    # Use Optional to prevent the server from choking on empty inputs
    allergies: Optional[List[str]] = []
    dislikes: Optional[List[str]] = []
    dietary_goals: Optional[List[str]] = []

class UserAuth(BaseModel):
    email: str
    password: str


@app.get("/scan/{barcode}")
async def scan_barcode(barcode: str, user_id: str, db: Session = Depends(database.get_db)):
    print(f"🚀 MERGED SCAN INITIATED: Barcode {barcode}")
    
    # 1. Fetch User Profile
    user = db.query(models.User).filter(models.User.id == user_id).first()
    profile = {
        "allergies": [a.name for a in user.allergies] if user else [],
        "dislikes": [d.name for d in user.dislikes] if user else [],
        "goals": [g.name for g in user.goals] if user else []
    }

    # 2. Fetch Open Food Facts Data
    off_data = await off_service.get_product_data(barcode)
    if not off_data or off_data.get("status") == 0:
        raise HTTPException(status_code=404, detail="Product not found in database")
    
    product = off_data.get("product", {})
    brand_name = product.get("brands", "Unknown")
    ingredients_text = product.get("ingredients_text", "No ingredients listed")
    
    # Grab the real Nutri-Score! (Usually a, b, c, d, e)
    nutri_score = product.get("nutriscore_grade", "Unknown").upper()

    # 3. Fetch Ethics Data (Takes ~2-4 seconds)
    print(f"📰 Auditing Ethics for Brand: {brand_name}")
    ethics_data = ethics_services.auditor.run_audit(brand_name)

    # 4. Fetch Health/Allergy Match from Gemini
    print("🧠 Cross-referencing ingredients with User Profile...")
    health_analysis_json = gemini_service.analyze_product(ingredients_text, str(profile))
    
    try:
        health_data = json.loads(health_analysis_json)
    except json.JSONDecodeError:
        health_data = {"health_match": False, "health_status": "Error parsing AI data", "flagged_ingredients": []}

    # 5. THE MEGA-PAYLOAD
    # We combine OFF, Ethics, and Health into one perfect JSON for Flutter
    final_payload = {
        "product_name": product.get("product_name", "Unknown Product"),
        "parent_company": ethics_data.get("parent_company"),
        "nutri_score": nutri_score,
        "ethics_score": ethics_data.get("overall_score", 0),
        "ethics_summary": ethics_data.get("overall_summary", "No ethics data."),
        "health_match": health_data.get("health_match", False),
        "health_status": health_data.get("health_status", "Unknown"),
        "flagged_ingredients": health_data.get("flagged_ingredients", [])
    }
    try:
        new_scan = models.ScanHistory(
            user_id=user_id,
            barcode=barcode,
            product_name=final_payload["product_name"],
            health_status=final_payload["health_status"],
            full_response=final_payload
        )
        db.add(new_scan)
        db.commit()
        print(f"✅ Saved scan history for user {user_id}")
    except Exception as e:
        print(f"⚠️ Could not save history (User might not exist yet): {e}")
        db.rollback()

    return final_payload
    



# @app.post("/signup")
# async def create_user(user: SignUpRequest):
#     # TODO: In a real app, you would hash the password and save to your database here.
#     # For the hackathon, we will generate a fake user ID to keep the app moving.
    
#     print(f" NEW USER SIGNUP: {user.name} ({user.email})")
    
#     new_user_id = str(uuid.uuid4())
    
#     # Return exactly what Flutter is expecting
#     return {"id": new_user_id, "message": "User created successfully"}

@app.post("/signup")
def signup(user: SignUpRequest, db: Session = Depends(database.get_db)):
    # Check if user already exists
    existing = db.query(models.User).filter(models.User.email == user.email).first()
    if existing:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    # Create new user, now including the name!
    new_user = models.User(
        id=str(uuid.uuid4()), 
        name=user.name, # 🚨 SAVING THE NAME
        email=user.email, 
        password=user.password 
    )
    db.add(new_user)
    db.commit()
    
    return {"user_id": new_user.id, "message": "Signup successful!"}

@app.post("/login")
def login(user: UserAuth, db: Session = Depends(database.get_db)):
    db_user = db.query(models.User).filter(models.User.email == user.email, models.User.password == user.password).first()
    
    if not db_user:
        raise HTTPException(status_code=401, detail="Invalid email or password")
        
    return {"user_id": db_user.id, "message": "Login successful!"}


# @app.post("/login")
# async def login_user(user: LogInRequest):
#     # TODO: Check the database to see if the email/password match
    
#     print(f"USER LOG IN ATTEMPT: {user.email}")
    
#     # Fake successful login for now
#     fake_existing_user_id = "123e4567-e89b-12d3-a456-426614174000"
    
#     return {"user_id": fake_existing_user_id}

@app.get("/profile/{user_id}")
def get_profile(user_id: str, db: Session = Depends(database.get_db)):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Dynamically count how many items they've scanned
    scan_count = db.query(models.ScanHistory).filter(models.ScanHistory.user_id == user_id).count()
    
    # 🚨 NO MORE EMAIL CHOPPING! Just use the real name
    display_name = user.name if user.name else "Hacker"
    
    return {
        "user_name": display_name,
        "scan_count": scan_count,
        "allergies": [a.name for a in user.allergies],
        "dislikes": [d.name for d in user.dislikes],
        "dietary_goals": [g.name for g in user.goals]
    }



# Make sure to import your database and models!
# import database, models 
@app.post("/profile/{user_id}")
def update_user_profile(user_id: str, prefs: UserPreferences, db: Session = Depends(database.get_db)):
    print(f"📦 RECEIVED DATA: {prefs}", flush=True)
    # 1. THE BOUNCER: Check if the user exists
    # user = db.query(models.User).filter(models.User.id == user_id).first()
    
    # --- COMMENT OUT THIS ENTIRE ERROR BLOCK ---
    # if not user:
    #     raise HTTPException(status_code=404, detail="User not found in database")

    # 2. WIPE THE SLATE CLEAN (Keep this!)
    db.query(models.Allergy).filter(models.Allergy.user_id == user_id).delete()
    db.query(models.Dislike).filter(models.Dislike.user_id == user_id).delete()
    db.query(models.DietaryGoal).filter(models.DietaryGoal.user_id == user_id).delete()
    
    for a in prefs.allergies: 
        if a.strip(): db.add(models.Allergy(name=a.strip(), user_id=user_id))
    for d in prefs.dislikes: 
        if d.strip(): db.add(models.Dislike(name=d.strip(), user_id=user_id))
    for g in prefs.dietary_goals: 
        if g.strip(): db.add(models.DietaryGoal(name=g.strip(), user_id=user_id))
    
    db.commit()
    return {"message": "Preferences saved successfully"}


@app.get("/history/{user_id}")
def get_history(user_id: str, db: Session = Depends(database.get_db)):
    # Fetch all scans for this user, ordered by newest first
    scans = db.query(models.ScanHistory).filter(
        models.ScanHistory.user_id == user_id
    ).order_by(models.ScanHistory.scanned_at.desc()).all()
    
    # Format them nicely for Flutter
    history_list = []
    for scan in scans:
        # Handle the JSON safely depending on how SQLite stored it
        full_res = scan.full_response
        if isinstance(full_res, str):
            try:
                full_res = json.loads(full_res)
            except:
                full_res = None # Fallback if parsing fails
                
        history_list.append({
            "id": scan.id,
            "barcode": scan.barcode,
            "product_name": scan.product_name,
            "health_status": scan.health_status,
            "scanned_at": scan.scanned_at.strftime("%Y-%m-%d %H:%M"),
            "full_response": full_res 
        })
        
    return {"history": history_list}