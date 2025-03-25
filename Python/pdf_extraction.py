import os
import re
import json
from PyPDF2 import PdfReader
from flask import  jsonify, session
from db import get_connection

# Fonction d'extraction des données depuis le PDF
def extract_data_from_pdf(pdf_path,user_id):
    text = ""
    with open(pdf_path, 'rb') as file:
        reader = PdfReader(file)
        for page in reader.pages:
            text += page.extract_text()

    # Extraction des dates (gestion des sauts de ligne)
    date_pattern = r'du\s*(\d{2}/\d{2}/\d{4})\s*au\s*(\d{2}/\d{2}/\d{4})'
    dates = re.search(date_pattern, text, re.DOTALL)
    date_debut = dates.group(1) if dates else None
    date_fin = dates.group(2) if dates else None

    # Extraction de la consommation d'eau (format "11 m³")
    eau_pattern = r'Eau et assainissement\s+(\d+)\s*m'
    consommation_eau = re.search(eau_pattern, text, re.DOTALL)
    consommation = consommation_eau.group(1) if consommation_eau else None

    result = {
        "date_debut": date_debut,
        "date_fin": date_fin,
        "consommation_eau_m3": int(consommation) if consommation else None
    }

    conn = get_connection()
    if not conn:
        return jsonify({"message": "❌ Connexion à la base échouée"}), 500
    cur = conn.cursor()
    cur.execute("""INSERT INTO "Facture" ("coutConsommation", "dateFacture", "IDfamilleRefFact")
                    VALUES ( %s, %s,%s)
                    RETURNING "IDfamilleRefFact";""", (result['consommation_eau_m3'], result["date_fin"],user_id))
    conn.commit()
    return json.dumps(result, indent=2, ensure_ascii=False)

# Fonction pour récupérer le chemin du fichier PDF dans le dossier "uploads"
def get_pdf_path_from_uploads(directory="uploads"):
    # Récupérer la liste des fichiers dans le dossier uploads
    for filename in os.listdir(directory):
        # Vérifier si le fichier est un PDF
        if filename.endswith(".pdf"):
            # Retourner le chemin complet du fichier
            return os.path.join(directory, filename)
    return None  # Aucun fichier trouvé
