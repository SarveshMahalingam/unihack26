from sqlalchemy import Column, Integer, String, ForeignKey
from sqlalchemy.orm import relationship
import uuid
from .database import Base

class User(Base):
    __tablename__ = "users"
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    email = Column(String, unique=True, index=True)
    password_hash = Column(String)

    allergies = relationship("Allergy", back_populates="owner")
    dislikes = relationship("Dislike", back_populates="owner")
    goals = relationship("DietaryGoal", back_populates="owner")

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