from datetime import datetime, timedelta
from db import get_connection
# Create a cursor object
conn = get_connection()
cursor = conn.cursor()

###############"recompense"
    # Définir les coefficients pour le calcul du seuil personnalisé
COEFF_TYPE_HABITAT = {"Appartement": 1.0, "Maison": 1.2, "Villa": 1.5}
COEFF_SURFACE = 0.5
COEFF_NB_CHAMBRES = 0.03
COEFF_NB_DOUCHES = 0.4
COEFF_NB_VOITURES = 0.02
COEFF_NB_CUISINES = 0.1
COEFF_PISCINE = 1.5
COEFF_GARAGE = 1.2
COEFF_JARDIN = 1.3

# Fonction pour récupérer la consommation des 3 derniers mois
def get_consumption_last_3_months(family_code):
    consommation_list = []

    # Récupérer la dernière date de facture pour cette famille
    cursor.execute("""
        SELECT "dateFacture" FROM "Facture" 
        WHERE "IDfamilleRefFact" = %s 
        ORDER BY "dateFacture" DESC LIMIT 1
    """, (family_code,))
    last_facture_date = cursor.fetchone()

    if not last_facture_date:
        return [0, 0, 0]  # Aucun historique de consommation trouvé

    last_date = last_facture_date[0]

    for i in range(3):
        target_month = last_date.month - i
        target_year = last_date.year

        if target_month <= 0:
            target_month += 12
            target_year -= 1

            

        print(f"Recherche consommation pour {target_month}/{target_year} pour la famille {family_code}")

        cursor.execute("""
            SELECT "coutConsommation" FROM "Facture" 
            WHERE "IDfamilleRefFact" = %s 
              AND EXTRACT(MONTH FROM "dateFacture") = %s 
              AND EXTRACT(YEAR FROM "dateFacture") = %s
            ORDER BY "dateFacture" DESC LIMIT 1
        """, (family_code, target_month, target_year))
        
        res = cursor.fetchone()
        consommation_list.append(res[0] if res else 0)

    print(f"Consommation des 3 derniers mois pour la famille {family_code}: {consommation_list}")
    return consommation_list,last_date


# Fonction pour récupérer les informations de la famille
def get_family_info(family_code):
    cursor.execute('SELECT  "nomFamille", "scoreFamille" FROM "Famille" WHERE "codeFamille" = %s', (family_code,))
    return cursor.fetchone()

# Fonction pour récupérer les informations du logement (Local)
def get_local_info(family_code):
    cursor.execute("""
        SELECT type, "surface", "nbChambre", "nbDouche", "nbCuisine", "piscine", "garage", "jardin", "nb_personne"
        FROM "Local"
        WHERE "codeFamille" = %s
    """, (family_code,))
    result = cursor.fetchone()
    print("result", result)
    if result:
        local_info = {
            "type": result[0],
            "surface": result[1],
            "nbChambre": result[2],
            "nbDouche": result[3],
            "nbCuisine": result[4],
            "piscine": result[5],
            "garage": result[6],
            "jardin": result[7],
            "nb_personne": result[8]
        }
        return local_info
    return None

# Fonction pour calculer le seuil personnalisé de consommation
def calculer_seuil(local_info):
    seuil = (
        COEFF_TYPE_HABITAT.get(local_info["type"], 1.0) +
        COEFF_SURFACE * local_info["surface"] +
        COEFF_NB_CHAMBRES * local_info["nbChambre"] +
        COEFF_NB_DOUCHES * local_info["nbDouche"] +
        COEFF_NB_CUISINES * local_info["nbCuisine"] +
        (COEFF_PISCINE if local_info["piscine"] else 1.0) +
        (COEFF_GARAGE if local_info["garage"] else 1.0) +
        (COEFF_JARDIN if local_info["jardin"] else 1.0) +
        local_info["nb_personne"] * 0.05  # Coefficient supplémentaire en fonction du nombre de personnes
    )
    return seuil

# Fonction principale pour calculer et retourner les récompenses
def calculate_rewards(family_code):
    points = 0
    reasons = []

    # Récupérer les informations de la famille
    famille_data = get_family_info(family_code)
    print(f"Famille data: {famille_data}")
    if not famille_data:
     return  {
        "scoreFamille":  famille_data[1],
        "nomFamille": famille_data[0],
        "points": 0,
        "consommation": [0, 0, 0],
        "reasons": "reasons"
      } # Famille non trouvée
    nom_famille, score_famille = famille_data

    # Consommation du mois en cours
    now = datetime.now()
    mois_courant = now.month
    annee_courante = now.year

    cursor.execute("""
        SELECT "coutConsommation", "dateFacture" 
        FROM "Facture" 
        WHERE "IDfamilleRefFact" = %s 
          AND EXTRACT(MONTH FROM "dateFacture") = %s 
          AND EXTRACT(YEAR FROM "dateFacture") = %s
        ORDER BY "dateFacture" DESC LIMIT 1
    """, (family_code, mois_courant, annee_courante))
    facture_current = cursor.fetchone()

    if not facture_current:
       reasons.append("Aucun")

       return  {
        "scoreFamille":  famille_data[1],
        "nomFamille": famille_data[0],
        "points": 0,
        "consommation": [0, 0, 0],
        "reasons": reasons
      } # Aucune consommation enregistrée pour ce mois
    consommation_actuelle, date_actuelle = facture_current

    # Vérifier si la dernière facture a été traitée
    cursor.execute("""
        SELECT traite FROM "Facture" 
        WHERE "IDfamilleRefFact" = %s 
        ORDER BY "dateFacture" DESC LIMIT 1
    """, (family_code,))
    last_facture = cursor.fetchone()

    if last_facture and last_facture[0]:
        consommation_list = get_consumption_last_3_months(family_code)
        return {
            "scoreFamille": score_famille,
            "nomFamille": nom_famille,
            "consommation": consommation_list,
            "message": "La dernière facture a déjà été traitée. Affichage des données sans calcul des points."
        }

 # Récupérer la consommation du mois précédent
    if mois_courant == 1:
      prev_date = datetime(annee_courante - 1, 12, 1)  # Définir prev_date comme un objet datetime
    else:
      prev_date = datetime(annee_courante, mois_courant - 1, 1)  # Définir correctement prev_date

    cursor.execute("""
        SELECT "coutConsommation" FROM "Facture" 
        WHERE "IDfamilleRefFact" = %s 
          AND EXTRACT(MONTH FROM "dateFacture") = %s 
          AND EXTRACT(YEAR FROM "dateFacture") = %s
        ORDER BY "dateFacture" DESC LIMIT 1
    """, (family_code, prev_date.month, prev_date.year))
    facture_previous = cursor.fetchone()

    # Récupérer la consommation moyenne de la ville du mois dernier
    cursor.execute("""
        SELECT AVG("coutConsommation") FROM "Facture" 
        WHERE EXTRACT(MONTH FROM "dateFacture") = %s 
        AND EXTRACT(YEAR FROM "dateFacture") = %s
    """, (prev_date.month, prev_date.year))
    moyenne_ville_dernier_mois = cursor.fetchone()[0] or 0

    # Affichage de la moyenne de la ville dans la console
    print(f"Moyenne de la consommation de la ville pour {prev_date.month}/{prev_date.year}: {moyenne_ville_dernier_mois:.2f}")

    if facture_previous:
        consommation_precedente = facture_previous[0]

        # 1️⃣ Objectif de Réduction Progressive (10% de réduction)
        reduction_cible = consommation_precedente * 0.9
        if consommation_actuelle <= reduction_cible:
            points += 10
            reasons.append("Réduction progressive atteinte (10% de réduction)")

        # 2️⃣ Consommation Inférieure à la Moyenne de la Ville (mois dernier)
        if consommation_actuelle < moyenne_ville_dernier_mois:
            points += 15
            reasons.append("Consommation inférieure à la moyenne de la ville du mois dernier")

        # 3️⃣ Streaks d’Économie
        cursor.execute("""
            SELECT COUNT(*) FROM "Facture"
            WHERE "IDfamilleRefFact" = %s AND "coutConsommation" < (
                SELECT "coutConsommation" FROM "Facture" 
                WHERE "IDfamilleRefFact" = %s 
                ORDER BY "dateFacture" DESC LIMIT 1 OFFSET 1
            )
        """, (family_code, family_code))
        streak = cursor.fetchone()[0]
        if streak == 1:
            points += 5
            reasons.append("Streak d'économie: 1 mois")
        elif streak == 2:
            points += 15
            reasons.append("Streak d'économie: 2 mois")
        elif streak >= 3:
            points += 30
            reasons.append("Streak d'économie: 3 mois ou plus")

        # Mettre à jour le score de la famille
        cursor.execute('UPDATE "Famille" SET "scoreFamille" = "scoreFamille" + %s WHERE "codeFamille" = %s', (points, family_code))
        conn.commit()

        # Mettre à jour l'attribut 'traite' de la facture
        cursor.execute("""
            UPDATE "Facture" 
            SET traite = TRUE
            WHERE "IDfamilleRefFact" = %s 
              AND "dateFacture" = %s
        """, (family_code, date_actuelle))
        conn.commit()

    consommation_list,last_date = get_consumption_last_3_months(family_code)

    # Récupérer les informations du logement
    local_info = get_local_info(family_code)
    if local_info:
        seuil_personnalise = calculer_seuil(local_info)
        print(f"Seuil personnalisé calculé pour la famille {family_code}: {seuil_personnalise:.2f}")
        if consommation_actuelle < seuil_personnalise:
            points += 10
            reasons.append("Consommation inférieure au seuil personnalisé")
        elif last_date.month in [6, 7, 8]:  # Été
            if consommation_actuelle < seuil_personnalise:
                points += 5
                reasons.append("Bonus d'été: consommation inférieure au seuil personnalisé")


    result = {
        "scoreFamille": score_famille + points,
        "nomFamille": nom_famille,
        "points": points,
        "consommation": consommation_list,
        "reasons": reasons
    }
    return result