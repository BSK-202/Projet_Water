from flask import jsonify, request
from db import get_connection
from datetime import datetime, timedelta

def send_invitation():
    conn = get_connection()
    cursor = conn.cursor()
    data = request.get_json()
    try:
        sender_id = data['senderId']
        receiver_id = data['receiverId']
       # Fetch chef name
        cursor.execute("SELECT nom FROM chef WHERE email = %s", (sender_id,))
        chef_name = cursor.fetchone()
        chef_name = chef_name[0] if chef_name else sender_id  # fallback to email

        # Insert invitation into the database
        cursor.execute(
            """
            INSERT INTO "Invitation" ("senderId", "receiverId", "status", "createdAt", "updatedAt")
            VALUES (%s, %s, 'pending', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
            RETURNING "idInvitation";
            """,
            (sender_id, receiver_id)
        )
        invitation_id = cursor.fetchone()[0]

         # Insert Notification for member
        cursor.execute(
            """
            INSERT INTO "Notification" (
                "senderId", "receiverId", type, title, message, status, "createdAt", "updatedAt", "senderType"
            ) VALUES (%s, %s, %s, %s, %s, %s, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, %s)
            """,
            (
                sender_id,
                receiver_id,
                'invitation',
                "Invitation à rejoindre une famille",
                f"Le chef {chef_name} ({sender_id}) vous invite à rejoindre sa famille. Cliquez pour accepter ou ignorer l'invitation.",
                'pending',
                'chef'
            )
        )

        conn.commit()
        return jsonify({"status": "success", "message": "Invitation sent", "invitationId": invitation_id}), 200
    except Exception as e:
        conn.rollback()
        return jsonify({"status": "error", "message": str(e)}), 500
    finally:
        cursor.close()
        conn.close()

def check_and_notify_chef(chef_email, days_between=5):
    """
    Checks if a chef should be notified (not more than once every X days),
    and sends a notification if appropriate.
    """
    conn = get_connection()
    cursor = conn.cursor()
    try:
        system_email = 'system@notifications.com'

        # Get the latest notification for this chef (type 'system')
        cursor.execute(
            'SELECT "createdAt" FROM "Notification" WHERE "receiverId" = %s AND type = %s ORDER BY "createdAt" DESC LIMIT 1',
            (chef_email, 'system')
        )
        row = cursor.fetchone()
        now = datetime.now()
        should_send = False
        if row:
            last_sent = row[0]
            if now.date() > last_sent.date() and (now - last_sent).days >= days_between:
                should_send = True
        else:
            should_send = True

        if should_send:
            # Get the chef's family info and member count
            cursor.execute("""
                SELECT c.email AS chef_email, COUNT(m.email) AS member_count, l.nb_personne AS family_limit
                FROM chef c
                JOIN "Famille" f ON c."IDfamille" = f."codeFamille"
                LEFT JOIN "Membre" m ON m."idFamille" = f."codeFamille"
                JOIN "Local" l ON l."codeFamille" = f."codeFamille"
                WHERE c.email = %s
                GROUP BY c.email, l.nb_personne;
            """, (chef_email,))
            data = cursor.fetchone()
            if data:
                member_count, family_limit = data[1], data[2]
                message = f"You have {member_count}/{family_limit} members in your family. Please invite more members."
                title = "Invitation de membre"
                cursor.execute(
                    """
                    INSERT INTO "Notification" ("senderId", "receiverId", type, title, message, status, "createdAt", "updatedAt")
                    VALUES (%s, %s, 'system', %s, %s, 'pending', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
                    """,
                    (system_email, chef_email, title, message)
                )
                conn.commit()
        return True
    except Exception as e:
        conn.rollback()
        print("Error in check_and_notify_chef:", str(e))
        return False
    finally:
        cursor.close()
        conn.close()


def add_member_to_family():
    conn = get_connection()
    cursor = conn.cursor()
    data = request.get_json()
    try:
        chef_email = data['chefEmail']
        member_email = data['memberEmail']

        # Check if the member exists
        cursor.execute("SELECT id FROM Membre WHERE email = %s", (member_email,))
        member = cursor.fetchone()
        if not member:
            return jsonify({"status": "error", "message": "Member does not exist"}), 404

        # Get the family ID of the chef
        cursor.execute("SELECT IDfamille FROM chef WHERE email = %s", (chef_email,))
        family = cursor.fetchone()
        if not family:
            return jsonify({"status": "error", "message": "Chef does not exist"}), 404

        family_id = family[0]

        # Update the member's family ID
        cursor.execute(
            "UPDATE Membre SET idFamille = %s WHERE email = %s",
            (family_id, member_email)
        )
        conn.commit()
        return jsonify({"status": "success", "message": "Member added to family"}), 200
    except Exception as e:
        conn.rollback()
        return jsonify({"status": "error", "message": str(e)}), 500
    finally:
        cursor.close()
        conn.close()


def get_unread_notifications():
    user_id = request.args.get('userId')
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("""
            SELECT COUNT(*) 
            FROM "Notification" 
            WHERE "receiverId" = %s AND status = 'pending';
        """, (user_id,))
        unread_count = cursor.fetchone()[0]
        return jsonify({"unreadCount": unread_count}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        cursor.close()
        conn.close()
        
        
        
def get_notifications():
    user_id = request.args.get('userId')  # Chef's email
    conn = get_connection()
    cursor = conn.cursor()
    try:
        # Fetch all notifications for the user
        cursor.execute("""
            SELECT "idNotification", title, message, "createdAt", status
            FROM "Notification"
            WHERE "receiverId" = %s
            ORDER BY "createdAt" DESC;
        """, (user_id,))
        notifications = cursor.fetchall()
        return jsonify({"notifications": [{
            "id": row[0],
            "title": row[1],            # <-- Add this
            "message": row[2],
            "createdAt": row[3].strftime("%Y-%m-%d %H:%M:%S"),
            "status": row[4]
        } for row in notifications]}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        cursor.close()
        conn.close()
        

def mark_notification_vued():
    notification_id = request.json.get('notificationId')
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(
            'UPDATE "Notification" SET status = %s, "updatedAt" = CURRENT_TIMESTAMP WHERE "idNotification" = %s',
            ('vued', notification_id)
        )
        conn.commit()
        return jsonify({"status": "success"}), 200
    except Exception as e:
        conn.rollback()
        return jsonify({"status": "error", "message": str(e)}), 500
    finally:
        cursor.close()
        conn.close()