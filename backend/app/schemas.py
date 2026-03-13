from pydantic import BaseModel, EmailStr
from typing import List, Optional

class UserBase(BaseModel):
    email: EmailStr

class UserCreate(UserBase):
    password: str
    allergies: List[str]
    dislikes: List[str]
    dietary_goals: List[str]

class UserResponse(UserBase):
    id: str
    class Config:
        from_attributes = True