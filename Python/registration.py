import psycopg2
import uuid
from flask import jsonify
from db import get_connection

is_chef_global = None

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

        # Créer une entrée dans la table Habitude
        cur.execute("""
            INSERT INTO "Habitude" (
                id_habitude,
                nbr_litre_boire, 
                duree_moyenne_douches, 
                nbr_bains_par_mois, 
                "prière", 
                nbr_douches_semaine, 
                duree_moyenne_bains, 
                "cosommation cuisine", 
                frequence_vidange_toilettes, 
                frequence_lave_linge, 
                frequence_lave_vaisselle, 
                frequence_lavage_voiture, 
                nbr_voiture
            ) 
            VALUES (
                nextval('"Habitude_id_habitude_seq"'),
                0, NULL, 0, NULL, 0, NULL, 0, 0, 0, 0, 0, 0
            )
            RETURNING id_habitude;
        """)
        id_habitude = cur.fetchone()[0]
        print(f"✅ Entrée Habitude créée avec id: {id_habitude}")

        # Créer une entrée dans la table Sociodémographique
        cur.execute("""
            INSERT INTO " Sociodémographique" (
                "Revenu", 
                "niveau education", 
                "Sensibilisation Environnement", 
                "Accès à un Plombier"
            ) 
            VALUES (
                NULL, NULL, 0, 0
            )
            RETURNING "idSocio";
        """)
        id_socio = cur.fetchone()[0]
        print(f"✅ Entrée Sociodémographique créée avec id: {id_socio}")

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
                cur.execute("""INSERT INTO "Famille" ("codeFamille", "scoreFamille", "nomFamille")
                    VALUES (%s, 0, %s)
                    RETURNING "codeFamille";""", (code_famille, data["nom"]))
                id_famille = cur.fetchone()[0]

                # Insérer le chef dans la base avec l'id_habitude, id_socio et l'avatar
                cur.execute("""INSERT INTO "chef" (
                    "nom", "prenom", "dateNaiss", "email", "password", "avatar", "IDfamille", "id_habitude", "score", "socio"
                ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, 0, %s);""", (
                    data["nom"], data["prenom"], data["dateNaiss"],
                    data["email"], data["password"], data.get("avatar", None), 
                    id_famille, id_habitude, id_socio
                ))

                conn.commit()
                return jsonify({
                    "message": "✅ Compte Chef créé", 
                    "code_famille": code_famille,
                    "id_habitude": id_habitude,
                    "id_socio": id_socio
                }), 201

            except Exception as e:
                conn.rollback()
                print("❌ Erreur insertion Chef:", str(e))
                return jsonify({"message": f"Erreur Chef : {str(e)}"}), 500

        else:  # Si l'utilisateur est un membre
            try:
                # Insérer le membre avec l'id_habitude, id_socio et l'avatar
                cur.execute("""INSERT INTO "Membre" (
                    "nom", "prenom", "dateNaiss", "email", "password", "idFamille", "avatar", "id_habitude", "score", "socio"
                ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, 0, %s);""", (
                    data["nom"], data["prenom"], data["dateNaiss"],
                    data["email"], data["password"], None, 
                    data.get("avatar", None), id_habitude, id_socio
                ))

                conn.commit()
                return jsonify({
                    "message": "✅ Compte Membre créé",
                    "id_habitude": id_habitude,
                    "id_socio": id_socio
                }), 201

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