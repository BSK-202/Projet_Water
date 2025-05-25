# db_connection.py
import psycopg2

DB_CONFIG = {
    "dbname": "mybdd",
    "user": "postgres",
    "password": "1234",
    "host": "localhost",
    "port": "5432"
}

def get_connection():
    """Établit une connexion à la base de données PostgreSQL"""
    try:
        return psycopg2.connect(**DB_CONFIG)
    except Exception as e:
        print("❌ Erreur de connexion à la base :", str(e))
        return None
