from app.database import engine, Base
# Importing models ensures SQLAlchemy sees ALL the classes before building
from app import models 

print("🔨 Forcing database creation...")
Base.metadata.create_all(bind=engine)
print("✅ Tables built successfully!")

