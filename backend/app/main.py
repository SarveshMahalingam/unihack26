from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.orm import Session
from . import models, schemas, database
from .services import off_service, gemini_service

app = FastAPI()

# Create tables on startup
database.Base.metadata.create_all(bind=database.engine)

@app.post("/signup", response_model=schemas.UserResponse)
def signup(user: schemas.UserCreate, db: Session = Depends(database.get_db)):
    db_user = models.User(email=user.email, password_hash=user.password) # In prod, hash this!
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    
    # Add preferences
    for a in user.allergies: db.add(models.Allergy(name=a, user_id=db_user.id))
    for d in user.dislikes: db.add(models.Dislike(name=d, user_id=db_user.id))
    for g in user.dietary_goals: db.add(models.DietaryGoal(name=g, user_id=db_user.id))
    
    db.commit()
    return db_user

@app.get("/scan/{barcode}")
async def scan_barcode(barcode: str, user_id: str, db: Session = Depends(database.get_db)):
    # 1. Get user preferences
    user = db.query(models.User).filter(models.User.id == user_id).first()
    profile = {
        "allergies": [a.name for a in user.allergies],
        "dislikes": [d.name for d in user.dislikes],
        "goals": [g.name for g in user.goals]
    }
    
    # 2. Get OpenFoodFacts data
    product = await off_service.get_product_data(barcode)
    if not product or "product" not in product:
        raise HTTPException(status_code=404, detail="Product not found")

    # 3. Get Gemini Analysis
    analysis = gemini_service.analyze_food(product['product'], profile)
    return {"analysis": analysis}

@app.post("/login")
def login(user: schemas.UserLogin, db: Session = Depends(database.get_db)):
    # Find the user by email
    db_user = db.query(models.User).filter(models.User.email == user.email).first()
    
    # Check if user exists and password matches
    if not db_user or db_user.password_hash != user.password:
        raise HTTPException(status_code=400, detail="Incorrect email or password")
    
    # Return a success message and the user's ID
    return {
        "message": "Login successful", 
        "user_id": db_user.id
    }

# 

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

@app.put("/profile/{user_id}")
def update_profile(user_id: str, profile_data: schemas.ProfileUpdate, db: Session = Depends(database.get_db)):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # 1. Wipe the old preferences
    db.query(models.Allergy).filter(models.Allergy.user_id == user_id).delete()
    db.query(models.Dislike).filter(models.Dislike.user_id == user_id).delete()
    db.query(models.DietaryGoal).filter(models.DietaryGoal.user_id == user_id).delete()
    
    # 2. Insert the newly updated preferences
    for a in profile_data.allergies: db.add(models.Allergy(name=a, user_id=user_id))
    for d in profile_data.dislikes: db.add(models.Dislike(name=d, user_id=user_id))
    for g in profile_data.dietary_goals: db.add(models.DietaryGoal(name=g, user_id=user_id))
    
    # 3. Save to database
    db.commit()
    return {"message": "Profile updated successfully"}