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
sys.path.append(os.path.dirname(os.path.abspath("/Users/sarvesh/Desktop/UNIHACK26/backend/app/services/gemini_service.py")))

import gemini_service  # Now this will definitely work
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
# @app.post("/signup", response_model=schemas.UserResponse)
# def signup(user: schemas.UserCreate, db: Session = Depends(database.get_db)):
#     db_user = models.User(email=user.email, password_hash=user.password) # In prod, hash this!
#     db.add(db_user)
#     db.commit()
#     db.refresh(db_user)
    
#     # Add preferences
#     for a in user.allergies: db.add(models.Allergy(name=a, user_id=db_user.id))
#     for d in user.dislikes: db.add(models.Dislike(name=d, user_id=db_user.id))
#     for g in user.dietary_goals: db.add(models.DietaryGoal(name=g, user_id=db_user.id))
    
#     db.commit()
#     return db_user

@app.get("/scan/{barcode}")
async def scan_barcode(barcode: str, user_id: str, db: Session = Depends(database.get_db)):
    # 1. Get user preferences
    user = db.query(models.User).filter(models.User.id == user_id).first()
    profile = {
        "allergies": [a.name for a in user.allergies] if user else [],
        "dislikes": [d.name for d in user.dislikes] if user else [],
        "goals": [g.name for g in user.goals] if user else []
    }
    
    # 2. Get OpenFoodFacts data
    product = await off_service.get_product_data(barcode)
    if not product or "product" not in product:
        raise HTTPException(status_code=404, detail="Product not found")

    # 3. Get Gemini Analysis
    analysis = gemini_service.analyze_product(product['product'], profile)
    return {"analysis": analysis}

# from fastapi import Depends, HTTPException
# from sqlalchemy.orm import Session
# import json
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
    user_goals = [g.name for g in db.query(models.DietaryGoal).filter(models.DietaryGoal.user_id == user_id).all()]
    
    user_profile = {
        "allergies": user_allergies,
        "dislikes": user_dislikes,
        "goals": user_goals
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



# @app.get("/scan/{barcode}")
# async def scan_barcode(barcode: str, user_id: str, db: Session = Depends(database.get_db)):
#     print(f"🚀 REAL SCAN INITIATED: Barcode {barcode} for User {user_id}")
    
#     # 1. Pull the User's health profile from the DB
#     user_allergies = [a.name for a in db.query(models.Allergy).filter(models.Allergy.user_id == user_id).all()]
#     user_dislikes = [d.name for d in db.query(models.Dislike).filter(models.Dislike.user_id == user_id).all()]
#     user_goals = [g.name for g in db.query(models.DietaryGoal).filter(models.DietaryGoal.user_id == user_id).all()]
    
#     user_profile = {
#         "allergies": user_allergies,
#         "dislikes": user_dislikes,
#         "goals": user_goals
#     }

#     # 2. Fetch REAL product info from Open Food Facts
#     off_url = f"https://world.openfoodfacts.org/api/v2/product/{barcode}.json"
#     try:
#         response = requests.get(off_url, timeout=5)
#         response.raise_for_status()
#         data = response.json()
        
#         if data.get("status") == 0:
#             raise HTTPException(status_code=404, detail="Product not found in Open Food Facts database")
            
#         product = data.get("product", {})
#         product_data = {
#             "product_name": product.get("product_name", "Unknown Product"),
#             "ingredients_text": product.get("ingredients_text", "Ingredients not listed."),
#             "brands": product.get("brands", "Unknown Brand")
#         }
#     except Exception as e:
#         print(f"❌ OFF API Error: {e}")
#         # Fallback if API fails during hackathon
#         product_data = {"product_name": "Unknown", "ingredients_text": "Could not fetch ingredients.", "brands": "N/A"}

#     # 3. Call your updated Gemini Service with the REAL data
#     analysis_result = gemini_service.analyze_product(product_data, user_profile)
    
#     # 4. Parse the JSON string from Gemini into a Python dict to return it correctly
#     try:
#         final_response = json.loads(analysis_result)
#         return final_response
#     except json.JSONDecodeError:
#         # Emergency fallback if Gemini returns bad formatting
#         return {"error": "AI response was not valid JSON", "raw": analysis_result}








# @app.get("/scan/{barcode}")
# async def scan_barcode(barcode: str, user_id: str, db: Session = Depends(database.get_db)):
#     print(f"🚨 SCAN INITIATED: Barcode {barcode} for User {user_id}")
    
#     # 1. Pull the User's exact health profile from the database
#     user_allergies = [a.name for a in db.query(models.Allergy).filter(models.Allergy.user_id == user_id).all()]
#     user_dislikes = [d.name for d in db.query(models.Dislike).filter(models.Dislike.user_id == user_id).all()]
#     user_diets = [g.name for g in db.query(models.DietaryGoal).filter(models.DietaryGoal.user_id == user_id).all()]
    
#     # Combine them into a clean format for the AI
#     user_health_profile = f"Allergies: {', '.join(user_allergies)}. Dislikes: {', '.join(user_dislikes)}. Diets: {', '.join(user_diets)}."
#     print(f"🧠 FEEDING GEMINI THIS PROFILE: {user_health_profile}")

#     # 2. Fetch the product info (Keep your existing Open Food Facts logic here!)
#     # product_info = your_open_food_facts_function(barcode)
    
#     # (If your OpenFoodFacts isn't hooked up yet, use this dummy data for testing)
#     product_info = f"Barcode {barcode}: Milk Chocolate Bar. Ingredients: sugar, milk, cocoa butter, peanuts, soy lecithin."

#     # 3. Call your Gemini Service
#     # Make sure your gemini_service has a function that accepts both variables! 
#     analysis_result = gemini_service.analyze_product(product_info, user_health_profile)
    
#     # 4. Return the JSON straight to Flutter so it can build the UI!
#     return json.loads(analysis_result)

# @app.post("/login")
# def login(user: schemas.UserLogin, db: Session = Depends(database.get_db)):
#     # Find the user by email
#     db_user = db.query(models.User).filter(models.User.email == user.email).first()
    
#     # Check if user exists and password matches
#     if not db_user or db_user.password_hash != user.password:
#         raise HTTPException(status_code=400, detail="Incorrect email or password")
    
#     # Return a success message and the user's ID
#     return {
#         "message": "Login successful", 
#         "user_id": db_user.id
#     }

# # 

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



# @app.put("/profile/{user_id}")
# def update_profile(user_id: str, profile_data: schemas.ProfileUpdate, db: Session = Depends(database.get_db)):
#     user = db.query(models.User).filter(models.User.id == user_id).first()
#     if not user:
#         raise HTTPException(status_code=404, detail="User not found")
    
#     # 1. Wipe the old preferences
#     db.query(models.Allergy).filter(models.Allergy.user_id == user_id).delete()
#     db.query(models.Dislike).filter(models.Dislike.user_id == user_id).delete()
#     db.query(models.DietaryGoal).filter(models.DietaryGoal.user_id == user_id).delete()
    
#     # 2. Insert the newly updated preferences
#     for a in profile_data.allergies: db.add(models.Allergy(name=a, user_id=user_id))
#     for d in profile_data.dislikes: db.add(models.Dislike(name=d, user_id=user_id))
#     for g in profile_data.dietary_goals: db.add(models.DietaryGoal(name=g, user_id=user_id))
    
#     # 3. Save to database
#     db.commit()
#     return {"message": "Profile updated successfully"}



# @app.put("/profile/{user_id}")
# async def update_user_profile(user_id: str, prefs: UserPreferences):
#     # TODO: Connect to your database and UPDATE the user's row where id == user_id
    
#     # For now, let's print it to the terminal so you know it arrived safely!
#     print(f"✅ SAVING PREFS FOR USER {user_id}:")
#     print(f"   Allergies: {prefs.allergies}")
#     print(f"   Dislikes: {prefs.dislikes}")
#     print(f"   Dietary: {prefs.dietary_goals}")
    
#     # Return a success message so Flutter knows it worked and can move to the scanner
#     return {"message": "Preferences saved successfully", "user_id": user_id}


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