from pydantic import BaseModel

# Описываем, что именно мы ждем от Flutter при регистрации
class UserCreate(BaseModel):
    email: str
    password: str