from db import get_connection
from flask import jsonify


def get_all_badges_for_user(email):
    """
    Récupère tous les badges, indiquant ceux que l'utilisateur a débloqués ou pas,
    avec les champs de progression si disponibles.
    """
    try:
        conn = get_connection()
        cursor = conn.cursor()

        cursor.execute("""
            SELECT
                b.badge_id,
                b.name,
                ub.progress,
                ub.unlockedat,
                ub.completedat,
                ub.completed,
                CASE
                    WHEN ub.user_id IS NULL THEN FALSE
                    ELSE TRUE
                END AS is_unlocked
            FROM public."Badge" b
            LEFT JOIN "UserBadge" ub ON b.badge_id = ub.badge_id AND ub.user_id = %s
        """, (email,))

        rows = cursor.fetchall()

        # Structurer les résultats pour Flutter (liste de dictionnaires)
        badges = []
        for row in rows:
            badges.append({
                "badge_id": row[0],
                "name": row[1],
                "progress": row[2] if row[2] is not None else 0.0,
                "unlockedAt": row[3],
                "completedAt": row[4],
                "completed": row[5]if row[5] is not None else False,
                "is_locked": not row[6]
            })

        return badges

    except Exception as e:
        print("Erreur :", e)
        return []

    finally:
        if 'cursor' in locals():
            cursor.close()
        if 'conn' in locals():
            conn.close()
