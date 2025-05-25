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

def get_socio_column(column_name):
    """Retourne l'ID socio en fonction du nom de colonne"""
    column_mapping = {
        "Revenu": '13',
        "niveau education": '15',
        "Sensibilisation Environnement": '17',
        "Accès à un Plombier": '32'
    }
    return column_mapping.get(column_name)

def should_include_socio(colname, value):
    """Détermine si une donnée socio doit être incluse dans les résultats"""
    # Ne pas inclure idSocio
    if colname == "idSocio":
        return False
    
    # Ne pas inclure les valeurs NULL
    if value is None:
        return False
    
    # Ne pas inclure les valeurs à 0 (considérées comme non remplies)
    if isinstance(value, (int, float)) and value == 0:
        return False
    
    # Ne pas inclure les chaînes vides ou '0'
    if isinstance(value, str) and value.strip() in ('', '0'):
        return False
    
    # Inclure toutes les autres valeurs non nulles/non vides
    return True

def get_socio_utilisateur(data):
    conn = None
    cur = None
  
    try:
      

        user_email = data['user_id']

        # Vérifie si c'est un chef, un membre ou aucun
        user_type = ischef(user_email)
        if user_type is None:
            return jsonify({"error": "Utilisateur non trouvé"}), 404

        conn = get_connection()
        if not conn:
            return jsonify({"error": "Connexion à la base de données échouée"}), 500
        cur = conn.cursor()

        # Récupérer l'id_socio
        if user_type:
            cur.execute("""SELECT socio FROM "chef" WHERE email = %s""", (user_email,))
        else:
            cur.execute("""SELECT socio FROM "Membre" WHERE email = %s""", (user_email,))
        
        result = cur.fetchone()
        if not result:
            return jsonify({"error": "Données sociodémographiques non trouvées pour l'utilisateur"}), 404

        id_socio = result[0]

        # Récupérer la ligne de la table Sociodémographique
        cur.execute("""SELECT * FROM " Sociodemographique" WHERE "idSocio" = %s""", (id_socio,))
        row = cur.fetchone()
        if not row:
            return jsonify({"error": "Aucune donnée sociodémographique trouvée"}), 404

        # Récupérer les noms des colonnes
        colnames = [desc[0] for desc in cur.description]

        socio_data = []
        for idx, value in enumerate(row):
            colname = colnames[idx]
            if should_include_socio(colname, value):
                socio_id = get_socio_column(colname)
                if socio_id is not None:
                    socio_data.append({
                        "id": socio_id,
                        "attribut": colname,
                        "valeur": value
                    })

    
        return jsonify(socio_data), 200


    except Exception as e:
        print(f"Erreur dans /get : {str(e)}")
        return jsonify({"error": "Erreur interne"}), 500

    finally:
        if cur:
            cur.close()
        if conn:
            conn.close()
