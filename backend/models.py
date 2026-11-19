from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey
from sqlalchemy.sql import func
from database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())


class Record(Base):
    __tablename__ = "calculations"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    
    product_name = Column(String, nullable=True)
    carbs_per_100 = Column(Float, nullable=False)
    weight = Column(Float, nullable=False)
    bread_units = Column(Float, nullable=False)
    carbs_in_portion = Column(Float, nullable=False)
    image_url = Column(String, nullable=True) 
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())


class CalendarEvent(Base):
    __tablename__ = "calendar_events"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    
    title = Column(String, nullable=False)          # Название события
    description = Column(String, nullable=True)     # Описание (если есть)
    start_time = Column(DateTime(timezone=True), nullable=False) # Время начала
    end_time = Column(DateTime(timezone=True), nullable=False)     # Время окончания
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())