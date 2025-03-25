# db.py
import psycopg2
options="-c client_encoding=UTF8"
from config import DB_NAME, DB_USER, DB_PASSWORD, DB_HOST, DB_PORT
def get_connection():
    """Établit la connexion à la base de données PostgreSQL."""
    try:
        conn = psycopg2.connect(
            dbname=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD,
            host=DB_HOST,
            port=DB_PORT,
            
            
        )
        return conn
    except Exception as e:
        print("Erreur de connexion à la base de données :", e)
        return None
