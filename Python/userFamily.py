from flask import Flask, jsonify, request
from db import get_connection
app = Flask(__name__)

# Fonction pour récupérer la famille d'un utilisateur
def get_family_by_member(member_id):
    print("member_id", member_id)
    try:
        conn = get_connection()
        cursor = conn.cursor()
        
        query = """
             SELECT 
             f."codeFamille", 
        f."nomFamille", 
        f."scoreFamille", 
        f."avatarFamille ", 
        a."localisation"
            FROM public."Famille" f
            JOIN public."Local" l ON l."codeFamille" = f."codeFamille"
            JOIN public."Adresse"a ON l."adress" = a."adresse"
            WHERE f."codeFamille" = %s;
        """
        
        cursor.execute(query, (member_id,))
        family = cursor.fetchone()
        
        cursor.close()
        conn.close()

        if family:
            family_data = {
                "id": family[0],
                "nom": family[1],
                "score": family[2],               
                "avatarFamille": family[3],
                "localisation": family[4]
            }
            return family_data
        else:
            return None

    except Exception as e:
        print("Erreur lors de la récupération de la famille :", str(e))
        return None
