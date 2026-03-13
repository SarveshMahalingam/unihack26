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
