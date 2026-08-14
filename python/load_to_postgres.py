import pandas as pd
from sqlalchemy import create_engine
import os
import csv

# ==== НАСТРОЙКИ ПОДКЛЮЧЕНИЯ — впиши свои данные ====
DB_USER = "postgres"       # твой пользователь
DB_PASSWORD = "123456"  # впиши сюда свой пароль
DB_HOST = "localhost"
DB_PORT = "5432"
DB_NAME = "postgres"

# Строка подключения — собирает все данные выше в один "адрес" базы
connection_string = f"postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}?client_encoding=utf8"
engine = create_engine(connection_string)

# Папка с CSV-файлами
DATA_FOLDER = "проекты/archive"

# Список файлов и названий таблиц, которые получатся в базе
files_to_load = {
    "olist_orders_dataset.csv": "orders",
    "olist_order_items_dataset.csv": "order_items",
    "olist_order_payments_dataset.csv": "order_payments",
    "olist_order_reviews_dataset.csv": "order_reviews",
    "olist_customers_dataset.csv": "customers",
    "olist_products_dataset.csv": "products",
    "olist_sellers_dataset.csv": "sellers",
    "olist_geolocation_dataset.csv": "geolocation",
    "product_category_name_translation.cpsv": "category_translation",
}

# Проходим по каждому файлу и загружаем его в PostgreSQL
for filename, table_name in files_to_load.items():
    filepath = os.path.join(DATA_FOLDER, filename)

    if not os.path.exists(filepath):
        print(f"⚠️  Файл не найден, пропускаю: {filepath}")
        continue

    print(f"Читаю {filename}...")

    df = pd.read_csv(filepath, encoding="utf-8")

    print(f"Загружаю в таблицу '{table_name}' ({len(df)} строк)...")

    try:
        df.to_sql(table_name, engine, if_exists="replace", index=False, schema='olist')
        print(f"✅ Готово: {table_name}\n")
    except UnicodeDecodeError:
        print("Ошибка кодирования")

print("Все файлы обработаны!")


