from flask import Flask, request, jsonify
from db import get_connection
from flask_cors import CORS  # Ajoutez cette importation

def calculate_challenge(email):
    """
    Pour un email donné, renvoie :
      - count_habitude  : nombre de champs Habitude valides
      - count_socio     : nombre de champs Socio valides
      - challenge_score : somme des deux
    """
    conn = get_connection()
    if not conn:
        return None

    try:
        cur = conn.cursor()

        # 1) Récupérer les ID d'habitude et de socio pour cet utilisateur
        cur.execute("""
            SELECT
              COALESCE(c.id_habitude, m.id_habitude) AS id_habitude,
              COALESCE(c.socio,     m.socio)     AS id_socio
            FROM "chef" c
            FULL   JOIN "Membre" m ON c.email = m.email
            WHERE COALESCE(c.email, m.email) = %s
        """, (email,))
        row = cur.fetchone()
        if not row:
            return None
        id_habitude, id_socio = row

        # 2) Récupérer la ligne Habitude
        count_hab = 0
        if id_habitude is not None:
            cur.execute("SELECT * FROM \"Habitude\" WHERE id_habitude = %s", (id_habitude,))
            hab = cur.fetchone()
            hab_cols = [d[0] for d in cur.description]
            # compter tout sauf id_habitude
            for col, val in zip(hab_cols, hab):
                if col == 'id_habitude':
                    continue
                if val is not None and val != 0 and val != '0':
                    count_hab += 1

        # 3) Récupérer la ligne Sociodemographique
        count_socio = 0
        if id_socio is not None:
            cur.execute("SELECT * FROM \" Sociodemographique\" WHERE \"idSocio\" = %s", (id_socio,))
            socio = cur.fetchone()
            socio_cols = [d[0] for d in cur.description]
            # compter tout sauf idSocio
            for col, val in zip(socio_cols, socio):
                if col.lower() in ('idsocio',):
                    continue
                if val is not None and val != 0 and val != '0':
                    count_socio += 1

        # 4) Retour
        challenge_score = count_hab + count_socio
        return challenge_score
    except Exception as e:
        print(f"Erreur : {e}")
        return None
    finally:
        cur.close()
        conn.close()
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
def get_consumption_evolution(email):
    """Calcule l'évolution de consommation entre les deux derniers mois"""
    try:
        conn = get_connection()
        if not conn:
            return 0.0, None  # Retourner un tuple cohérent
        
        cur = conn.cursor()
        
        # Récupérer l'ID famille de l'utilisateur
        cur.execute("""
            SELECT "IDfamille" FROM "chef" WHERE email = %s
            UNION
            SELECT "idFamille" FROM "Membre" WHERE email = %s
        """, (email, email))
        
        famille_result = cur.fetchone()
        if not famille_result or not famille_result[0]:
            return 0.0, None  # Retourner un tuple cohérent
            
        id_famille = famille_result[0]
        # Récupérer les deux dernières factures
        cur.execute("""
            SELECT "coutConsommation", "dateFacture" 
            FROM "Facture" 
            WHERE "IDfamilleRefFact" = %s 
            ORDER BY "dateFacture" DESC 
            LIMIT 2
        """, (id_famille,))
        
        factures = cur.fetchall()
        
        if len(factures) < 2:
            return 0.0, id_famille  # Retourner l'id_famille même si pas d'évolution
            
        dernier_mois = factures[0][0]
        avant_dernier_mois = factures[1][0]
        
        if avant_dernier_mois == 0:
            return 0.0, id_famille
            
        evolution = ((avant_dernier_mois - dernier_mois) / avant_dernier_mois) * 100
        return round(evolution, 1), id_famille
        
    except Exception as e:
        print(f"Erreur calcul évolution consommation: {str(e)}")
        return 0.0, None  # Retourner un tuple cohérent
    finally:
        if 'cur' in locals():
            cur.close()
        if 'conn' in locals() and conn:
            conn.close()

def get_user_badge_count(user_id):
    """
    Retourne le nombre de badges associés à un user_id donné.
    """
    try:
        conn = get_connection()
        if not conn:
            return 0
        print(f"Connexion réussie pour l'utilisateur {user_id}")
        cur = conn.cursor()

        cur.execute("""
            SELECT COUNT(*) 
            FROM "UserBadge"  -- Remplace par le vrai nom de ta table si différent
            WHERE user_id = %s
        """, (user_id,))
        
        result = cur.fetchone()
        return result[0] if result else 0

    except Exception as e:
        print(f"Erreur lors du comptage des badges pour l'utilisateur {user_id} : {str(e)}")
        return 0

    finally:
        if 'cur' in locals():
            cur.close()
        if 'conn' in locals() and conn:
            conn.close()
                       
def get_user_details(email):
    """Récupère toutes les informations utilisateur depuis la base de données"""
    try:
        conn = get_connection()
        if not conn:
            return None       
        cur = conn.cursor()
        
        # Calculer l'évolution de consommation
        evolution_result = get_consumption_evolution(email)
        if isinstance(evolution_result, tuple):
             evolution, id_famille = evolution_result
        else:
            evolution = evolution_result
            id_famille = None  # ou une valeur par défaut
        
        # Vérifier si c'est un chef ou un membre
        cur.execute("""SELECT email FROM "chef" WHERE email = %s""", (email,))
        is_chef = cur.fetchone() is not None

        # Récupérer les données de base
        if is_chef:
            cur.execute("""
                SELECT c.nom, c.prenom, c.email, c.avatar, c.score, 
                       f."nomFamille", f."scoreFamille", 
                       h.duree_moyenne_douches, h.nbr_bains_par_mois,
                       h.nbr_douches_semaine, h."cosommation cuisine",
                       h.frequence_vidange_toilettes, h.frequence_lave_linge,
                       s."Revenu", s."niveau education",
                       s."Sensibilisation Environnement", s."Accès à un Plombier"
                FROM "chef" c
                LEFT JOIN "Famille" f ON c."IDfamille" = f."codeFamille"
                LEFT JOIN "Habitude" h ON c.id_habitude = h.id_habitude
                LEFT JOIN " Sociodemographique" s ON c.socio = s."idSocio"
                WHERE c.email = %s
            """, (email,))
        else:
            cur.execute("""
                SELECT m.nom, m.prenom, m.email, m.avatar, m.score, 
                       f."nomFamille", f."scoreFamille",
                       h.duree_moyenne_douches, h.nbr_bains_par_mois,
                       h.nbr_douches_semaine, h."cosommation cuisine",
                       h.frequence_vidange_toilettes, h.frequence_lave_linge,
                       s."Revenu", s."niveau education",
                       s."Sensibilisation Environnement", s."Accès à un Plombier"
                FROM "Membre" m
                LEFT JOIN "Famille" f ON m."idFamille" = f."codeFamille"
                LEFT JOIN "Habitude" h ON m.id_habitude = h.id_habitude
                LEFT JOIN " Sociodemographique" s ON m.socio = s."idSocio"
                WHERE m.email = %s
            """, (email,))

        user_data = cur.fetchone()
        if not user_data:
            return None
            
        # Convertir en dictionnaire
        keys = [
            'nom', 'prenom', 'email', 'avatar', 'score',
            'nomFamille', 'scoreFamille', 'avatarFamille',
            'dureeDouches', 'bainsMois', 'douchesSemaine', 'consommationCuisine',
            'freqToilettes', 'freqLaveLinge',
            'revenu', 'niveauEducation', 'sensibilisation', 'accesPlombier'
        ]
        user_dict = dict(zip(keys, user_data))
        user_dict['isChef'] = is_chef
        user_dict['waterSaved'] = evolution  # Ajout de l'évolution
        user_dict['challenge'] = calculate_challenge(email)  # Ajout du challenge
        user_dict['id_famille'] = id_famille
        user_dict['badgeCount'] = get_user_badge_count(email)  # Ajout du nombre de badges
        print(user_dict)
        return user_dict
    except Exception as e:
        print(f"Erreur lors de la récupération des données utilisateur: {str(e)}")
        return None
    finally:
        if 'cur' in locals():
            cur.close()
        if 'conn' in locals() and conn:
          conn.close()