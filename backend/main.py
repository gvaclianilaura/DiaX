from fastapi import FastAPI, Depends
from sqlalchemy import text
from sqlalchemy.orm import Session
from passlib.context import CryptContext

from database import SessionLocal, engine
import models
import schemas

# Создаем таблицы в БД
models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="DiaX API")

# Настройка шифрования (используем надежный алгоритм bcrypt)
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def get_password_hash(password: str):
    return pwd_context.hash(password)

def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@app.get("/")
def read_root():
    return {"status": "ok", "message": "Сервер DiaX успешно запущен и готов к работе!"}

@app.get("/test-db")
def test_db_connection(db: Session = Depends(get_db)):
    try:
        db.execute(text("SELECT 1"))
        return {"status": "ok", "message": "Ура! Подключение к базе данных Onreza установлено успешно!"}
    except Exception as e:
        return {"status": "error", "message": f"Ошибка подключения к БД: {str(e)}"}

# НОВЫЙ МАРШРУТ: Регистрация пользователя
@app.post("/register")
def register_user(user: schemas.UserCreate, db: Session = Depends(get_db)):
    # 1. Проверяем, нет ли уже такого email в базе
    existing_user = db.query(models.User).filter(models.User.email == user.email).first()
    if existing_user:
        return {"status": "error", "message": "Пользователь с таким email уже существует"}
    
    # 2. Шифруем пароль
    hashed_pw = get_password_hash(user.password)
    
    # 3. Создаем запись в базе
    new_user = models.User(email=user.email, hashed_password=hashed_pw)
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    
    return {"status": "ok", "message": "Регистрация успешна!", "user_id": new_user.id}

@app.post("/login")
def login_user(user: schemas.UserCreate, db: Session = Depends(get_db)):
    # 1. Ищем пользователя в базе по email
    db_user = db.query(models.User).filter(models.User.email == user.email).first()
    
    # Если пользователя нет или пароль не совпадает — выдаем ошибку
    if not db_user or not verify_password(user.password, db_user.hashed_password):
        return {"status": "error", "message": "Неверный email или пароль"}
    
    # Если всё верно, пускаем пользователя (в будущем тут можно выдавать токен)
    return {"status": "ok", "message": "Успешный вход!", "user_id": db_user.id}