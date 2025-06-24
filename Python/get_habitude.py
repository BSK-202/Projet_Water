from flask import Flask, request, jsonify
from db import get_connection

app = Flask(__name__)

def ischef(email):
    """Vérifie si l'utilisateur est un chef"""
    try:
        conn = get_connection()
        if not conn:
            return None
        
        cur = conn.cursor()
        print(f"Vérification de l'utilisateur : {email}")
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

def get_habitude_column(column_name):
    """Retourne l'ID d'habitude en fonction du nom de colonne"""
    column_mapping = {
        "nbr_litre_boire": 1,
        "duree_moyenne_douches": 2,
        "nbr_bains_par_mois": 3,
        "prière": 4,
        "nbr_douches_semaine": 5,
        "duree_moyenne_bains": 6,
        "cosommation cuisine": 7,
        "frequence_vidange_toilettes": 8,
        "frequence_lave_linge": 9,
        "frequence_lave_vaisselle": 10,
        "frequence_lavage_voiture": 11,
        "nbr_voiture": 12
    }
    return column_mapping.get(column_name)

def should_include_habitude(colname, value):
    """Détermine si une habitude doit être incluse dans les résultats"""
    # Ne pas inclure id_habitude
    if colname == "id_habitude":
        return False
    
    # Ne pas inclure les valeurs NULL
    if value is None:
        return False
    
    # Ne pas inclure les entiers à 0 (tous sans exception)
    if isinstance(value, int) and value == 0:
        return False
    
    # Inclure toutes les autres valeurs non nulles
    return True


def get_habitudes_utilisateur(data):
    conn = None
    cur = None
    try:
       
        if not data or 'user_id' not in data:
            return jsonify({"error": "User ID requis"}), 400

        user_email = data['user_id']

        # Vérifie si c'est un chef, un membre ou aucun
        user_type = ischef(user_email)
        if user_type is None:
            return jsonify({"error": "Utilisateur non trouvé"}), 404

        conn = get_connection()
        if not conn:
            return jsonify({"error": "Connexion à la base de données échouée"}), 500
        cur = conn.cursor()

        # Récupérer l'id_habitude
        if user_type:
            cur.execute("""SELECT id_habitude FROM "chef" WHERE email = %s""", (user_email,))
        else:
            cur.execute("""SELECT id_habitude FROM "Membre" WHERE email = %s""", (user_email,))
        
        result = cur.fetchone()
        if not result:
            return jsonify({"error": "Habitude non trouvée pour l'utilisateur"}), 404

        id_habitude = result[0]

        # Récupérer la ligne de la table Habitude
        cur.execute("""SELECT * FROM "Habitude" WHERE id_habitude = %s""", (id_habitude,))
        row = cur.fetchone()
        if not row:
            return jsonify({"error": "Aucune donnée d'habitude trouvée"}), 404

        # Récupérer les noms des colonnes
        colnames = [desc[0] for desc in cur.description]

        habitudes = []
        for idx, value in enumerate(row):
            colname = colnames[idx]
            if should_include_habitude(colname, value):
                hab_id = get_habitude_column(colname)
                if hab_id is not None:
                    habitudes.append({
                        "id": hab_id,
                        "attribut": colname,
                        "valeur": value
                    })

        return jsonify(habitudes), 200

    except Exception as e:
        print(f"Erreur dans /habitudes : {str(e)}")
        return jsonify({"error": "Erreur interne"}), 500

    finally:
        if cur:
            cur.close()
        if conn:
            conn.close()
