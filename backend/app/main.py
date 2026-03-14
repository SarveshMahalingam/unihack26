from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.orm import Session
from . import models, schemas, database
from .services import off_service, gemini_service
from pydantic import BaseModel
import uuid
import json
from typing import List
import sys
import os
import traceback
 # Now this will definitely work
app = FastAPI()

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
    allergies: List[str]
    dislikes: List[str]
    dietary_goals: List[str]

import requests
from fastapi import Depends, HTTPException
from sqlalchemy.orm import Session
import json
# import app.gemini_service as gemini_service # Ensure this import matches your structure

@app.get("/scan/{barcode}")
async def scan_barcode(barcode: str, user_id: str, db: Session = Depends(database.get_db)):
    print(f"🚀 REAL SCAN INITIATED: Barcode {barcode} for User {user_id}")
    
    # 1. Pull the User's health profile
    user_allergies = [a.name for a in db.query(models.Allergy).filter(models.Allergy.user_id == user_id).all()]
    user_dislikes = [d.name for d in db.query(models.Dislike).filter(models.Dislike.user_id == user_id).all()]
    dietary_goals = [g.name for g in db.query(models.DietaryGoal).filter(models.DietaryGoal.user_id == user_id).all()]
    
    user_profile = {
        "allergies": user_allergies,
        "dislikes": user_dislikes,
        "goals": dietary_goals
    }

    # 2. Call your off_service.py correctly using 'await'
    try:
        off_response = await off_service.get_product_data(barcode)
        
        # OFF Trap Fix: Check the internal 'status' key (0 = not found, 1 = found)
        if not off_response or off_response.get("status") == 0:
            print(f"❌ OFF API: Barcode {barcode} not found in database.")
            raise HTTPException(status_code=404, detail="Product not found in Open Food Facts database")
            
        product = off_response.get("product", {})
        
        # Safely extract what Gemini needs (fallback to strings if missing)
        product_data = {
            "product_name": product.get("product_name", "Unknown Product"),
            "ingredients_text": product.get("ingredients_text", "Ingredients not listed."),
            "brands": product.get("brands", "Unknown Brand")
        }
        print(f"🍫 Product Found: {product_data['product_name']}")
        
    except HTTPException:
        raise # Re-raise the 404 so Flutter sees it
    except Exception as e:
        print(f"❌ OFF Service Error: {e}")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail="Error connecting to product database")

    # 3. Call your Gemini Service
    try:
        analysis_result = gemini_service.analyze_product(product_data, user_profile)
    except Exception as e:
        print(f"❌ Gemini Error: {e}")
        raise HTTPException(status_code=500, detail="Error communicating with Gemini AI")
    
    # 4. Parse the JSON string from Gemini safely
    if isinstance(analysis_result, dict):
        return analysis_result

    try:
        return json.loads(analysis_result)
    except json.JSONDecodeError:
        # Markdown block stripper (Lifesaver for LLM JSON outputs)
        cleaned_result = analysis_result.replace('```json', '').replace('```', '').strip()
        try:
            return json.loads(cleaned_result)
        except Exception as parse_error:
            print(f"❌ Failed to parse Gemini response: {parse_error}")
            return {"error": "AI response was not valid JSON", "raw": analysis_result}



@app.post("/signup")
async def create_user(user: SignUpRequest):
    # TODO: In a real app, you would hash the password and save to your database here.
    # For the hackathon, we will generate a fake user ID to keep the app moving.
    
    print(f"🚨 NEW USER SIGNUP: {user.name} ({user.email})")
    
    new_user_id = str(uuid.uuid4())
    
    # Return exactly what Flutter is expecting
    return {"id": new_user_id, "message": "User created successfully"}

@app.post("/login")
async def login_user(user: LogInRequest):
    # TODO: Check the database to see if the email/password match
    
    print(f"🚨 USER LOG IN ATTEMPT: {user.email}")
    
    # Fake successful login for now
    fake_existing_user_id = "123e4567-e89b-12d3-a456-426614174000"
    
    return {"user_id": fake_existing_user_id}

@app.get("/profile/{user_id}", response_model=schemas.ProfileResponse)
def get_profile(user_id: str, db: Session = Depends(database.get_db)):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    return {
        "email": user.email,
        "allergies": [a.name for a in user.allergies],
        "dislikes": [d.name for d in user.dislikes],
        "dietary_goals": [g.name for g in user.goals]
    }





from fastapi import Depends, HTTPException
from sqlalchemy.orm import Session
# Make sure to import your database and models!
# import database, models 
@app.put("/profile/{user_id}")
def update_user_profile(user_id: str, prefs: UserPreferences, db: Session = Depends(database.get_db)):
    
    # 1. THE BOUNCER: Check if the user exists
    # user = db.query(models.User).filter(models.User.id == user_id).first()
    
    # --- COMMENT OUT THIS ENTIRE ERROR BLOCK ---
    # if not user:
    #     raise HTTPException(status_code=404, detail="User not found in database")

    # 2. WIPE THE SLATE CLEAN (Keep this!)
    db.query(models.Allergy).filter(models.Allergy.user_id == user_id).delete()
    db.query(models.Dislike).filter(models.Dislike.user_id == user_id).delete()
    db.query(models.DietaryGoal).filter(models.DietaryGoal.user_id == user_id).delete()
    
    # 3. INSERT NEW DATA
    for a in prefs.allergies: 
        if a.strip(): db.add(models.Allergy(name=a.strip(), user_id=user_id))
        
    for d in prefs.dislikes: 
        if d.strip(): db.add(models.Dislike(name=d.strip(), user_id=user_id))
        
    for g in prefs.dietary_goals: 
        if g.strip(): db.add(models.DietaryGoal(name=g.strip(), user_id=user_id))
    
    # 4. LOCK IT IN
    db.commit()
    
    print(f"✅ HACKATHON BYPASS: SAVED ALL PREFS TO DB FOR: {user_id}")
    return {"message": "Preferences saved successfully", "user_id": user_id}