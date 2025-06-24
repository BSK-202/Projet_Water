from flask import jsonify, session
from db import get_connection
from notification import check_and_notify_chef  # Import the notification function

def login(data):
    """Gère la connexion d'un utilisateur (chef ou membre)"""
    try:
        if "email" not in data or "password" not in data:
            return jsonify({"message": "❌ Champs manquants : email ou password"}), 400
        
        conn = get_connection()
        if not conn:
            return jsonify({"message": "❌ Connexion à la base échouée"}), 500
        
        cur = conn.cursor()

        # Vérifier si l'email existe dans chef
        cur.execute("""SELECT nom, prenom, email, password, "IDfamille"
                       FROM "chef" WHERE email = %s;""", (data["email"],))
        chef = cur.fetchone()
        if chef:
            if chef[3] == data["password"]:
                check_and_notify_chef(chef[2]) 
                return {
                    "user_id": chef[2],  # email
                    "is_chef": True,
                    "idFamille": chef[4]  # IDfamille
                }
            else:
                return jsonify({"message": "❌ Mot de passe incorrect"}), 401

        # Vérifier si l'email existe dans membre
        cur.execute("""SELECT nom, prenom, email, password, "idFamille" 
                       FROM "Membre" WHERE email = %s;""", (data["email"],))
        membre = cur.fetchone()
        if membre:
            if membre[3] == data["password"]:
                return {
                    "user_id": membre[2],  # email
                    "is_chef": False,
                    "idFamille": membre[4]  # IDfamille
                }
            else:
                return jsonify({"message": "❌ Mot de passe incorrect"}), 401

        # Si l'email n'existe ni dans chef ni dans membre
        return jsonify({"message": "❌ Email inexistant"}), 404

    except Exception as e:
        print("❌ Erreur lors de la connexion :", str(e))
        return jsonify({"message": f"Erreur serveur : {str(e)}"}), 500

    finally:
        if 'cur' in locals():
            cur.close()
        if 'conn' in locals() and conn:
            conn.close()