import boto3
import uuid
from fastapi import FastAPI, Depends, HTTPException, UploadFile, File, Request
from fastapi.responses import RedirectResponse
from sqlalchemy import text
from sqlalchemy.orm import Session
from passlib.context import CryptContext

from database import SessionLocal, engine
import models
import schemas

# Создаем таблицы в БД (если их еще нет)
models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="DiaX API")

# --- НАСТРОЙКИ CLOUD.RU (S3) ---
S3_ENDPOINT = "https://s3.cloud.ru" 
S3_ACCESS_KEY = "4b77f046-2b6e-455e-b6ee-586f51365fd4:86a27ce5d92a06bc00aa8dc6b59a2d5e"
S3_SECRET_KEY = "a095783c27001c21dda6537da8d0d2ed"
S3_BUCKET_NAME = "diax-photos-onezone"

# Инициализация клиента S3 для связи с облаком
s3_client = boto3.client(
    "s3",
    endpoint_url=S3_ENDPOINT,
    aws_access_key_id=S3_ACCESS_KEY,
    aws_secret_access_key=S3_SECRET_KEY,
    region_name="ru-central-1"
)

# Настройка шифрования паролей (bcrypt)
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

# --- МАРШРУТЫ ---

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

@app.post("/register")
def register_user(user: schemas.UserCreate, db: Session = Depends(get_db)):
    existing_user = db.query(models.User).filter(models.User.email == user.email).first()
    if existing_user:
        return {"status": "error", "message": "Пользователь с таким email уже существует"}

    hashed_pw = get_password_hash(user.password)
    new_user = models.User(email=user.email, hashed_password=hashed_pw)
    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    return {"status": "ok", "message": "Регистрация успешна!", "user_id": new_user.id}

@app.post("/login")
def login_user(user: schemas.UserCreate, db: Session = Depends(get_db)):
    db_user = db.query(models.User).filter(models.User.email == user.email).first()
    if not db_user or not verify_password(user.password, db_user.hashed_password):
        return {"status": "error", "message": "Неверный email или пароль"}

    return {"status": "ok", "message": "Успешный вход!", "user_id": db_user.id}

@app.post("/upload")
def upload_photo(request: Request, file: UploadFile = File(...)):
    file_extension = file.filename.split(".")[-1] if "." in file.filename else "jpg"
    unique_filename = f"{uuid.uuid4()}.{file_extension}"
    
    try:
        print(f"\nНачинаю загрузку файла {unique_filename} в бакет {S3_BUCKET_NAME}...")
        
        s3_client.upload_fileobj(
            file.file,
            S3_BUCKET_NAME,
            unique_filename,
            ExtraArgs={"ContentType": file.content_type} 
        )
        
        base_url = str(request.base_url).rstrip('/')
        image_url = f"{base_url}/image/{unique_filename}"
        
        print(f"Успех! Ссылка на файл: {image_url}\n")
        return {"status": "ok", "image_url": image_url}
        
    except Exception as e:
        print("\n" + "="*50)
        print("!!! КРИТИЧЕСКАЯ ОШИБКА ЗАГРУЗКИ В CLOUD.RU !!!")
        print(f"САМА ОШИБКА: {str(e)}")
        print("="*50 + "\n")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/image/{filename}")
def get_image_from_cloud(filename: str):
    """Генерирует временную безопасную ссылку на S3 и перенаправляет на нее"""
    try:
        presigned_url = s3_client.generate_presigned_url(
            'get_object',
            Params={'Bucket': S3_BUCKET_NAME, 'Key': filename},
            ExpiresIn=604800  # Ссылка действительна 7 дней
        )
        return RedirectResponse(url=presigned_url)
    except Exception as e:
        raise HTTPException(status_code=404, detail=f"Файл не найден: {str(e)}")

@app.post("/records")
def create_record(record: schemas.RecordCreate, db: Session = Depends(get_db)):
    new_record = models.Record(
        user_id=record.user_id,
        product_name=record.product_name,
        carbs_per_100=record.carbs_per_100,
        weight=record.weight,
        bread_units=record.bread_units,
        carbs_in_portion=record.carbs_in_portion,
        image_url=record.image_url 
    )
    db.add(new_record)
    db.commit()
    db.refresh(new_record)
    return {"status": "ok", "message": "Расчет успешно сохранен!", "record_id": new_record.id}

@app.get("/records/{user_id}")
def get_user_records(user_id: int, db: Session = Depends(get_db)):
    records = db.query(models.Record).filter(models.Record.user_id == user_id).all()
    return {"status": "ok", "records": records}

@app.delete("/records/{record_id}")
def delete_record(record_id: int, db: Session = Depends(get_db)):
    record = db.query(models.Record).filter(models.Record.id == record_id).first()
    if not record:
        raise HTTPException(status_code=404, detail="Запись не найдена")

    db.delete(record)
    db.commit()
    return {"status": "ok", "message": "Успешно удалено"}

@app.get("/users")
def get_all_users(db: Session = Depends(get_db)):
    users = db.query(models.User).all()
    safe_users_list = []
    for u in users:
        safe_users_list.append({
            "id": u.id,
            "email": u.email
        })
    return {"status": "ok", "users": safe_users_list}

# --- ЭНДПОИНТЫ КАЛЕНДАРЯ ---

@app.post("/calendar")
def create_calendar_event(event: schemas.CalendarEventCreate, db: Session = Depends(get_db)):
    new_event = models.CalendarEvent(
        user_id=event.user_id,
        title=event.title,
        description=event.description,
        start_time=event.start_time,
        end_time=event.end_time
    )
    db.add(new_event)
    db.commit()
    db.refresh(new_event)
    return {"status": "ok", "message": "Событие успешно сохранено в календарь!", "event_id": new_event.id}

@app.get("/calendar/{user_id}")
def get_user_calendar_events(user_id: int, db: Session = Depends(get_db)):
    events = db.query(models.CalendarEvent).filter(models.CalendarEvent.user_id == user_id).all()
    return {"status": "ok", "events": events}