from app.database import engine, Base
from app import models

print("🗑️ Dropping all tables...")
Base.metadata.drop_all(bind=engine)

print("✨ Rebuilding fresh tables...")
Base.metadata.create_all(bind=engine)

print("✅ Database is completely clean!")