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

def get_normal_value_for_habit(habit_id):
    # Valeurs normales pour chaque habitude (id 1 à 12)
    normal_values = {
        '1': 2,    # nbr_litre_boire: 2L/jour recommandé
        '2': 10,   # durée moyenne douche (en minutes)
        '3': 8,    # bains par mois
        '4': 1,    # prière: 1 (Oui/Non, donc pas de normalité stricte)
        '5': 7,    # douches par semaine
        '6': 20,   # durée moyenne bains (en minutes)
        '7': 10,   # consommation cuisine (litres/jour)
        '8': 5,    # chasse d'eau par jour
        '9': 5,    # cycles machine à laver par semaine
        '10': 3,   # cycles lave-vaisselle par semaine
        '11': 2,   # lavage voiture par mois
        '12': 2,   # nombre de véhicules
    }
    return normal_values.get(habit_id)

def get_habit_congrats_message(habit_id):
    messages = {
        '2': "Bravo ! Votre durée de douche est dans la norme.",
        '3': "Bravo ! Votre nombre de bains est raisonnable.",
        '5': "Bravo ! Votre fréquence de douche est correcte.",
        '6': "Bravo ! La durée de vos bains est dans la norme.",
        '8': "Bravo ! Votre utilisation des toilettes est raisonnable.",
        '9': "Bravo ! Votre utilisation de la machine à laver est dans la norme.",
        '10': "Bravo ! Votre utilisation du lave-vaisselle est correcte.",
        '11': "Bravo ! Vous lavez votre voiture de façon raisonnable.",
        '12': "Bravo ! Nombre de véhicules dans la norme.",
        # ...autres messages...
    }
    return messages.get(habit_id, "Félicitations pour votre engagement !")

def get_habit_alert_message(habit_id):
    messages = {
        '2': "Attention : Votre durée de douche dépasse la norme. Essayez de la réduire pour économiser l'eau.",
        '3': "Attention : Vous prenez beaucoup de bains. Réduisez pour préserver l'eau.",
        '5': "Attention : Fréquence de douche élevée. Pensez à économiser l'eau.",
        '6': "Attention : Vos bains sont longs. Essayez de réduire la durée.",
        '8': "Attention : Vous tirez souvent la chasse d'eau. Soyez vigilant.",
        '9': "Attention : Beaucoup de cycles de machine à laver. Essayez de regrouper les lessives.",
        '10': "Attention : Utilisation fréquente du lave-vaisselle.",
        '11': "Attention : Lavage de voiture fréquent.",
        '12': "Attention : Beaucoup de véhicules, pensez à l'impact environnemental.",
        # ...autres messages...
    }
    return messages.get(habit_id, "Pensez à adopter de meilleures habitudes pour économiser l'eau.")

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
        print(habit_id, user_email, value, points)
        # Conversion de la valeur
        if value == 'Oui':
            value = True
        else:
            if value == 'Non':
                value = False
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

        # Vérification de la normalité de la valeur AVANT attribution des points
        is_normal = True
        message = ""
        points_added = points
        try:
            normal_value = get_normal_value_for_habit(habit_id)
            if normal_value is not None and value is not None:
                try:
                    float_value = float(value)
                    if float_value > normal_value:
                        is_normal = False
                        message = get_habit_alert_message(habit_id)
                        points_added = 0
                    else:
                        message = get_habit_congrats_message(habit_id)
                except Exception:
                    message = get_habit_congrats_message(habit_id)
            else:
                message = get_habit_congrats_message(habit_id)
        except Exception:
            message = "Merci pour votre réponse."

        # 3. Mettre à jour le score de l'utilisateur SEULEMENT si normal
        if is_normal:
            if user_type:  # Chef
                update_score_query = """UPDATE "chef" SET score = score + %s 
                                       WHERE email = %s"""
            else:  # Membre
                update_score_query = """UPDATE "Membre" SET score = score + %s 
                                       WHERE email = %s"""
            cur.execute(update_score_query, (points, user_email))
            conn.commit()
        # Si hors norme, pas de points, donc pas de mise à jour du score

        return jsonify({
            "message": message,
            "is_normal": is_normal,
            "user_type": "chef" if user_type else "membre",
            "updated_column": column_name,
            "new_value": value,
            "points_added": points_added
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


