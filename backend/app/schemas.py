from pydantic import BaseModel, EmailStr, field_validator
from typing import List, Union, Any, Optional
from pydantic import BaseModel
from typing import List

class UserBase(BaseModel):
    email: EmailStr

class UserCreate(UserBase):
    password: str
    # Union tells FastAPI: "Accept EITHER a list of strings OR a single string"
    allergies: Union[List[str], str]
    dislikes: Union[List[str], str]
    dietary_goals: Union[List[str], str]

    @field_validator('allergies', 'dislikes', 'dietary_goals', mode='before')
    @classmethod
    def split_string_to_list(cls, v: Any) -> List[str]:
        # Scenario 1: It's a raw string like "peanuts, dairy"
        if isinstance(v, str):
            return [item.strip() for item in v.split(',') if item.strip()]
        
        # Scenario 2: It's a list, but might have commas hiding inside like ["peanuts, dairy"]
        elif isinstance(v, list):
            clean_list = []
            for item in v:
                if isinstance(item, str):
                    clean_list.extend([i.strip() for i in item.split(',') if i.strip()])
                else:
                    clean_list.append(item)
            return clean_list
            
        return v
class UserResponse(UserBase):
    id: str
    class Config:
        from_attributes = True

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class ProfileBase(BaseModel):
    allergies: Union[List[str], str]
    dislikes: Union[List[str], str]
    dietary_goals: Union[List[str], str]

    @field_validator('allergies', 'dislikes', 'dietary_goals', mode='before')
    @classmethod
    def split_string_to_list(cls, v: Any) -> List[str]:
        # Scenario 1: It's a raw string like "peanuts, dairy"
        if isinstance(v, str):
            return [item.strip() for item in v.split(',') if item.strip()]
        
        # Scenario 2: It's a list, but might have commas hiding inside like ["peanuts, dairy"]
        elif isinstance(v, list):
            clean_list = []
            for item in v:
                if isinstance(item, str):
                    clean_list.extend([i.strip() for i in item.split(',') if i.strip()])
                else:
                    clean_list.append(item)
            return clean_list
            
        return v


class ProfileUpdate(BaseModel):
    allergies: List[str]
    dislikes: List[str]
    dietary_goals: List[str]

class ProfileResponse(ProfileBase):
    email: str
    class Config:
        from_attributes = True