# classement.py

from db import get_connection

def get_classement():
    """Récupère les données des familles et calcule le classement."""
    conn = get_connection()
    if conn is None:
        return []

    cursor = conn.cursor()

    # Récupération des données    
    #cursor.execute("SELECT \"CodeFamille\", \"nomFamille\",\"scoreFamille\", \"avatarFamille\",localisation FROM public.\"Famille\"")
    cursor.execute("""
   SELECT 
        f."codeFamille", 
        f."nomFamille", 
        f."scoreFamille", 
        f."avatarFamille ", 
        a."localisation"
    FROM public."Famille" f
    JOIN public."Local" l ON f."codeFamille" = l."codeFamille"
    JOIN public."Adresse"a ON l."adress" = a."adresse"
""")

    familles = cursor.fetchall()

    classement = []

    for famille in familles:
        id_famille, nom,score, avatar,localisation = famille       

        classement.append({"id": id_famille,"nom": nom, "score": score, "avatar": avatar, "localisation":localisation})

    # Trier les familles par score décroissant
    classement.sort(key=lambda x: x["score"], reverse=True)

    cursor.close()
    conn.close()
    
    return classement
