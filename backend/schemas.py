from datetime import datetime
from pydantic import BaseModel
from typing import Optional

class UserCreate(BaseModel):
    email: str
    password: str

class RecordCreate(BaseModel):
    user_id: int
    product_name: Optional[str] = None
    carbs_per_100: float
    weight: float
    bread_units: float
    carbs_in_portion: float
    image_url: Optional[str] = None 

class CalendarEventCreate(BaseModel):
    user_id: int
    title: str
    description: Optional[str] = None
    start_time: datetime
    end_time: datetime

class CalendarEventResponse(CalendarEventCreate):
    id: int
    created_at: datetime

    class Config:
        from_attributes = True