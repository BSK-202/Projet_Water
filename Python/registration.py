# registration.py
import psycopg2
import uuid
from flask import jsonify
from db import get_connection  # Changer la relative importation en absolue

is_chef_global = None  # Variable globale pour stocker le choix de l'utilisateur

def selection(data):
    """Enregistre si l'utilisateur est un chef ou un membre"""
    global is_chef_global
    try:
        if "isChef" not in data:
            return jsonify({"message": "❌ Champ manquant : isChef"}), 400

        is_chef_global = data["isChef"]  
        print(f"✅ Choix reçu : isChef = {is_chef_global}")
        
        return jsonify({"message": "✅ Choix enregistré", "isChef": is_chef_global}), 200

    except Exception as e:
        print("❌ Erreur lors de la mise à jour :", str(e))
        return jsonify({"message": f"Erreur serveur : {str(e)}"}), 500


def register(data):
    """Gère l'inscription d'un chef ou d'un membre"""
    global is_chef_global

    try:
        print("📩 Données reçues :", data)

        required_keys = ["nom", "prenom", "dateNaiss", "email", "password"]
        for key in required_keys:
            if key not in data:
                return jsonify({"message": f"❌ Champ manquant : {key}"}), 400

        conn = get_connection()
        if not conn:
            return jsonify({"message": "❌ Connexion à la base échouée"}), 500
        
        cur = conn.cursor()

        if is_chef_global:  # Si l'utilisateur est un chef
            # Vérifier l'existence de la table 'Famille'
            cur.execute("""SELECT EXISTS (
                    SELECT 1 FROM information_schema.tables 
                    WHERE table_name = 'Famille'
                );""")
            if not cur.fetchone()[0]:
                return jsonify({"message": "❌ Table 'Famille' non trouvée"}), 500

            # Générer un code de famille unique
            code_famille = str(uuid.uuid4())[:8]

            try:
                # Insérer une nouvelle famille
                cur.execute("""INSERT INTO "Famille" ("codeFamille", "scoreFamille", "nb_personne", "nomFamille")
                    VALUES (%s, 0, 1, %s)
                    RETURNING "codeFamille";""", (code_famille, data["nom"]))
                id_famille = cur.fetchone()[0]

                # Insérer le chef dans la base
                cur.execute("""INSERT INTO "chef" ("nom", "prenom", "dateNaiss", "email", "password", "avatar", "IDfamille")
                    VALUES (%s, %s, %s, %s, %s, %s, %s);""", (
                        data["nom"], data["prenom"], data["dateNaiss"],
                        data["email"], data["password"], data.get("avatar"), id_famille
                    ))

                

                conn.commit()
                return jsonify({"message": "✅ Compte Chef créé", "code_famille": code_famille}), 201

            except Exception as e:
                conn.rollback()
                print("❌ Erreur insertion Chef:", str(e))
                return jsonify({"message": f"Erreur Chef : {str(e)}"}), 500

        else:  # Si l'utilisateur est un membre
            try:
                cur.execute("""INSERT INTO "Membre" ("nom", "prenom", "dateNaiss", "email", "password", "idFamille", "avatar")
                    VALUES (%s, %s, %s, %s, %s, %s, %s);""", (
                        data["nom"], data["prenom"], data["dateNaiss"],
                        data["email"], data["password"], None, data.get("avatar")
                    ))

                conn.commit()
                return jsonify({"message": "✅ Compte Membre créé"}), 201

            except Exception as e:
                conn.rollback()
                print("❌ Erreur insertion Membre:", str(e))
                return jsonify({"message": f"Erreur Membre : {str(e)}"}), 500

    except Exception as e:
        print("❌ Erreur générale:", str(e))
        return jsonify({"message": f"Erreur serveur : {str(e)}"}), 500

    finally:
        if 'cur' in locals():
            cur.close()
        if 'conn' in locals() and conn:
            conn.close()
