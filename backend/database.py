import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
from dotenv import load_dotenv

# Загружаем переменные окружения из файла .env
load_dotenv()

# Получаем нашу секретную строку подключения
SQLALCHEMY_DATABASE_URL = os.getenv("DATABASE_URL")

# Создаем движок SQLAlchemy для общения с PostgreSQL
engine = create_engine(SQLALCHEMY_DATABASE_URL)

# Настраиваем сессии (через них API будет отправлять SQL-запросы)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Базовый класс, от которого мы будем наследовать все наши таблицы
Base = declarative_base()