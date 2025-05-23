from flask import jsonify, request, session
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

def get_habitude_column(id_habitude):
    """Retourne le nom de la colonne en fonction de l'ID"""
    columns = {
        '1': "nbr_litre_boire",
        '2': "duree_moyenne_douches",
        '3': "nbr_bains_par_mois",
        '4': "prière",
        '5': "nbr_douches_semaine",
        '6': "duree_moyenne_bains",
        '7': "cosommation cuisine",
        '8': "frequence_vidange_toilettes",
        '9': "frequence_lave_linge",
        '10': "frequence_lave_vaisselle",
        '11': "frequence_lavage_voiture",
        '12': "nbr_voiture"
    }
    return columns.get(id_habitude)


def receive_habits(data):
    conn = None
    cur = None
    print("DATA:", data)
    try:
             
        if not data:
            return jsonify({"error": "Aucune donnée reçue"}), 400

        # Valider les données requises
        required_fields = ['id', 'user_id', 'value', 'points']
        for field in required_fields:
            if field not in data:
                return jsonify({"error": f"Champ manquant: {field}"}), 400

        habit_id = data.get('id')
        user_email = data.get('user_id')
        value = data.get('value')
        points = data.get('points')
        print(habit_id,user_email,value,points)
         # Conversion de la valeur
        if value == 'Oui':
            value=True
        else:
            if value == 'Non': 
                value=False
        # Vérifier si l'utilisateur existe et est chef ou membre
        user_type = ischef(user_email)
        if user_type is None:
            return jsonify({"error": "Utilisateur non trouvé"}), 404

        # Obtenir le nom de la colonne correspondant à l'ID
        column_name = get_habitude_column(habit_id)
        print("COLUMN NAME:", column_name)
        if not column_name:
            return jsonify({"error": "ID d'habitude non valide"}), 400

        conn = get_connection()
        if not conn:
            return jsonify({"error": "Connexion à la base de données échouée"}), 500

        cur = conn.cursor()

        # 1. Trouver l'id_habitude de l'utilisateur
        if user_type:  # Chef
            cur.execute("""SELECT id_habitude FROM "chef" WHERE email = %s""", (user_email,))
        else:  # Membre
            cur.execute("""SELECT id_habitude FROM "Membre" WHERE email = %s""", (user_email,))
        
        result = cur.fetchone()
        if not result:
            return jsonify({"error": "Habitude de l'utilisateur non trouvée"}), 404
        
        id_habitude = result[0]


      
        print("VALUES:", value, id_habitude)

        # 2. Mettre à jour l'habitude
        # Gestion spéciale pour les colonnes boolean (prière)
        if column_name == "prière ":
            update_query = f"""UPDATE "Habitude" SET "{column_name}" = %s 
                              WHERE id_habitude = %s"""
            cur.execute(update_query, (bool(value), id_habitude))
        else:
            update_query = f"""UPDATE "Habitude" SET "{column_name}" = %s 
                              WHERE id_habitude = %s"""
            cur.execute(update_query, (value, id_habitude))

        conn.commit()    

        # 3. Mettre à jour le score de l'utilisateur
        if user_type:  # Chef
            update_score_query = """UPDATE "chef" SET score = score + %s 
                                   WHERE email = %s"""
        else:  # Membre
            update_score_query = """UPDATE "Membre" SET score = score + %s 
                                   WHERE email = %s"""
        
        cur.execute(update_score_query, (points, user_email))

        conn.commit()

        return jsonify({
            "message": "Habitude et score mis à jour avec succès",
            "user_type": "chef" if user_type else "membre",
            "updated_column": column_name,
            "new_value": value,
            "points_added": points
        }), 200

    except Exception as e:
        if conn:
            conn.rollback()
        print(f"Erreur lors de la mise à jour des habitudes: {str(e)}")
        return jsonify({"error": f"Erreur serveur: {str(e)}"}), 500

    finally:
        if cur:
            cur.close()
        if conn:
            conn.close()

            
