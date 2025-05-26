from flask import Flask, request, jsonify
from db import get_connection


def ischef(email):
    """Vérifie si l'utilisateur est un chef"""
    try:
        conn = get_connection()
        if not conn:
            return None
        
        cur = conn.cursor()

        # Chercher d'abord dans la table 'chef'
        cur.execute("""SELECT email FROM "chef" WHERE email = %s""", (email,))
        chef = cur.fetchone()

        if chef:  # Si l'utilisateur est un chef
            return True
        
        # Sinon vérifier dans la table membre
        cur.execute("""SELECT email FROM "Membre" WHERE email = %s""", (email,))
        membre = cur.fetchone()
        
        if membre:
            return False
        
        return None  # Utilisateur non trouvé

    except Exception as e:
        print(f"Erreur lors de l'exécution de ischef: {str(e)}")
        return None

    finally:
        if 'cur' in locals():
            cur.close()
        if 'conn' in locals() and conn:
            conn.close()

def get_sociodemographique_column(id_socio):
    """Retourne le nom de la colonne en fonction de l'ID pour la table Sociodemographique"""
    columns = {
        '13': "Revenu",
        '15': "niveau education",
        '17': "Sensibilisation Environnement",
        '32': "Accès à un Plombier"
    }
    return columns.get(id_socio)

def receive_sociodemographique(data):
    conn = None
    cur = None
    try:
        socio_id = data['id']
        user_email = data['user_id']
        value = data['value']
        points = data['points']

        # Conversion de la valeur
        if value == 'Oui':
            value=1
        else:
            if value == 'Non': 
                value=0

        print(f"🔹 socio_id: {socio_id}, user_email: {user_email}, value: {value}, points: {points}")

        # Vérifier si l'utilisateur existe et est chef ou membre
        user_type = ischef(user_email)
        if user_type is None:
            print("❌ Utilisateur non trouvé")
            return jsonify({"error": "Utilisateur non trouvé"}), 404

        # Obtenir le nom de la colonne correspondant à l'ID
        column_name = get_sociodemographique_column(socio_id)
        if not column_name:
            print(f"❌ ID sociodemographique non valide: {socio_id}")
            return jsonify({"error": "ID sociodemographique non valide"}), 400

        print(f"🔹 column_name: {column_name}")

        conn = get_connection()
        if not conn:
            print("❌ Connexion à la base de données échouée")
            return jsonify({"error": "Connexion à la base de données échouée"}), 500

        cur = conn.cursor()

        # Trouver l'id_socio de l'utilisateur
        if user_type:  # Chef
            cur.execute("""SELECT socio FROM "chef" WHERE email = %s""", (user_email,))
        else:  # Membre
            cur.execute("""SELECT socio FROM "Membre" WHERE email = %s""", (user_email,))
        
        result = cur.fetchone()
        if not result:
            print("❌ Données sociodemographiques non trouvées")
            return jsonify({"error": "Données sociodemographiques de l'utilisateur non trouvées"}), 404
        
        id_socio = result[0]
        print(f"🔹 id_socio: {id_socio}")

        # Mettre à jour la donnée sociodemographique
        update_query = f"""UPDATE " Sociodemographique" SET "{column_name}" = %s 
                           WHERE "idSocio" = %s"""
        print(f"🔹 Requête UPDATE: {update_query}, Valeurs: {value}, {id_socio}")
        cur.execute(update_query, (value, id_socio))

        # Mettre à jour le score de l'utilisateur
        if user_type:  # Chef
            update_score_query = """UPDATE "chef" SET score = score + %s 
                                    WHERE email = %s"""
        else:  # Membre
            update_score_query = """UPDATE "Membre" SET score = score + %s 
                                    WHERE email = %s"""
        print(f"🔹 Requête UPDATE score: {update_score_query}, Valeurs: {points}, {user_email}")
        cur.execute(update_score_query, (points, user_email))

        conn.commit()

        print("✅ Mise à jour réussie")
        return jsonify({
            "message": "Donnée sociodemographique et score mis à jour avec succès",
            "user_type": "chef" if user_type else "membre",
            "updated_column": column_name,
            "new_value": value,
            "points_added": points
        }), 200

    except Exception as e:
        if conn:
            conn.rollback()
        print(f"❌ Erreur lors de la mise à jour des données sociodemographiques: {str(e)}")
        return jsonify({"error": f"Erreur serveur: {str(e)}"}), 500

    finally:
        if cur:
            cur.close()
        if conn:
            conn.close()