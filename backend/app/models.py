from sqlalchemy import Column, Integer, String, ForeignKey , DateTime, JSON
from sqlalchemy.orm import relationship
import uuid
from .database import Base
import datetime

class User(Base):
    __tablename__ = "users"

    id = Column(String, primary_key=True, index=True)
    name = Column(String) # 🚨 ADD THIS LINE RIGHT HERE!
    email = Column(String, unique=True, index=True, nullable=True)
    password = Column(String)

    allergies = relationship("Allergy", back_populates="owner", cascade="all, delete-orphan")
    dislikes = relationship("Dislike", back_populates="owner", cascade="all, delete-orphan")
    goals = relationship("DietaryGoal", back_populates="owner", cascade="all, delete-orphan")
    scans = relationship("ScanHistory", back_populates="owner", cascade="all, delete-orphan")
    
class Allergy(Base):
    __tablename__ = "allergies"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String)
    user_id = Column(String, ForeignKey("users.id"))
    owner = relationship("User", back_populates="allergies")

class Dislike(Base):
    __tablename__ = "dislikes"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String)
    user_id = Column(String, ForeignKey("users.id"))
    owner = relationship("User", back_populates="dislikes")

class DietaryGoal(Base):
    __tablename__ = "dietary_goals"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String)
    user_id = Column(String, ForeignKey("users.id"))
    owner = relationship("User", back_populates="goals")

class ScanHistory(Base):
    __tablename__ = "scan_history"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(String, ForeignKey("users.id", ondelete="CASCADE"))
    
    barcode = Column(String, index=True)
    product_name = Column(String)
    health_status = Column(String) # e.g., "Allergen Alert", "Safe"
    scanned_at = Column(DateTime, default=datetime.datetime.utcnow)
    full_response = Column(JSON)
    owner = relationship("User", back_populates="scans")