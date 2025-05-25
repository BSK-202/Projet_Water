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

        # Chercher d'abord dans la table 'chef'
        cur.execute("""SELECT nom, prenom, email, password, "IDfamille"
                       FROM "chef" WHERE email = %s AND password = %s;""",
                    (data["email"], data["password"]))
        chef = cur.fetchone()

        if chef:  # Si l'utilisateur est un chef
            session["user_id"] = chef[2]  # chef[2] est l'email (index 2)
            session["is_chef"] = True
            session["id_famille"] = chef[4]  # chef[4] est "IDfamille"
            session.modified = True  # Force la sauvegarde de la session avant retour

             # Call the notification function for chefs
            check_and_notify_chef(chef[2]) 

            return jsonify({"message": "✅ Connexion réussie en tant que Chef", 
                            "user_id": chef[2], "is_chef": True, "idFamille": chef[4]}), 200
        
        # Si l'utilisateur n'est pas un chef, chercher dans la table 'membre'
        cur.execute("""SELECT nom, prenom, email, password, "idFamille" 
                       FROM "Membre" WHERE email = %s AND password = %s;""",
                    (data["email"], data["password"]))
        membre = cur.fetchone()

        if membre:  # Si l'utilisateur est un membre
            session["user_id"] = membre[2]  # membre[2] est l'email (index 2)
            session["is_chef"] = False
            session["id_famille"] = membre[4]  # membre[4] est "idFamille"
            session.modified = True  # Force la sauvegarde de la session avant retour

            return jsonify({"message": "✅ Connexion réussie en tant que Membre", 
                            "user_id": membre[2], "is_chef": False, "idFamille": membre[4]}), 200
        
        return jsonify({"message": "❌ Identifiants incorrects"}), 401

    except Exception as e:
        print("❌ Erreur lors de la connexion :", str(e))
        return jsonify({"message": f"Erreur serveur : {str(e)}"}), 500

    finally:
        if 'cur' in locals():
            cur.close()
        if 'conn' in locals() and conn:
            conn.close()