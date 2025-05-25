from flask import Flask, jsonify, session, request
from classement import get_classement
from db import get_connection
from userFamily import get_family_by_member
from recompense import calculate_rewards
from notification import get_notifications, send_invitation, check_and_notify_chef, get_unread_notifications  # Import notification functions
#****************************************************
from datetime import timedelta
from flask_cors import CORS

from registration import selection, register
from login import login
from pdf_extraction import extract_data_from_pdf
import os
from werkzeug.utils import secure_filename
from pdf_extraction import get_pdf_path_from_uploads
from flask_session import Session

# Connexion à PostgreSQL
conn = get_connection()
cursor = conn.cursor()

#****************************************************
app = Flask(__name__)
#****************************************************
app.config["SESSION_TYPE"] = "filesystem"  # Stockage sur le système de fichiers
app.config["PERMANENT_SESSION_LIFETIME"] = timedelta(minutes=30)
app.config["SESSION_COOKIE_SAMESITE"] = "Lax"  # Sécurité contre les attaques CSRF
app.config["SESSION_COOKIE_SECURE"] = True    # Cookies uniquement en HTTPS

CORS(app)

# Initialisation de la session serveur
Session(app)
app.secret_key = 'f095a328dd6798c545699eb4d5a79b05924717771b8558e1'  # Clé secrète pour sécuriser les sessions

#****************************************************

@app.route('/', methods=['GET'])
def classement():
    """Renvoie le classement des familles sous format JSON."""
    print("data sent")
    return jsonify(get_classement())

@app.route('/get_family/<string:member_id>', methods=['GET'])
def get_family(member_id):
    family = get_family_by_member(member_id)
    if family:
        print("family sent")
        return jsonify({"status": "success", "family": family}), 200
    else:
        return jsonify({"status": "error", "message": "Famille non trouvée"}), 404

@app.route('/selection', methods=['POST'])
def handle_selection():
    data = request.get_json()
    return selection(data)

@app.route('/register', methods=['POST'])
def handle_register():
    data = request.get_json()
    return register(data)

@app.route('/login', methods=['POST'])
def login_route():
    """Route pour gérer la demande de connexion"""
    data = request.get_json()
    return login(data)

#****************************************************
# Notification Routes

@app.route('/send_invitation', methods=['POST'])
def handle_send_invitation():
    return send_invitation()

@app.route('/check_notifications', methods=['GET'])
def handle_check_notifications():
    return check_and_notify_chef()

@app.route('/get_unread_notifications', methods=['GET'])
def handle_get_unread_notifications():
    return get_unread_notifications()

#****************************************************

# Assurez-vous que le dossier upload existe
UPLOAD_FOLDER = 'uploads'
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
app.config['ALLOWED_EXTENSIONS'] = {'pdf'}

# Fonction pour vérifier l'extension du fichier
def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in app.config['ALLOWED_EXTENSIONS']

# Fonction pour supprimer tous les fichiers dans le dossier 'uploads'
def clear_upload_folder():
    for filename in os.listdir(UPLOAD_FOLDER):
        file_path = os.path.join(UPLOAD_FOLDER, filename)
        try:
            if os.path.isfile(file_path):
                os.remove(file_path)  # Supprime le fichier
            elif os.path.isdir(file_path):
                os.rmdir(file_path)  # Supprime le répertoire s'il est vide
        except Exception as e:
            print(f"Erreur lors de la suppression du fichier {file_path}: {e}")

@app.route('/extract_pdf', methods=['POST'])
def extract_pdf():
    if 'file' not in request.files:
        return jsonify({"message": "Aucun fichier sélectionné"}), 400
    user_id = request.form.get('user_id')  # Récupération du user_id

    print(user_id)
    file = request.files['file']
    
    if file and allowed_file(file.filename):
        filename = secure_filename(file.filename)
        file_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
        file.save(file_path)
        pdf_path = get_pdf_path_from_uploads()  # Récupérer le chemin du fichier PDF depuis le dossier "uploads"

        # Appeler la fonction d'extraction ici
        result = extract_data_from_pdf(pdf_path, user_id)
        print(result)
        return result

@app.route('/factures', methods=['GET'])
def get_factures():
    conn = None
    cur = None
    try:
        conn = get_connection()
        if not conn:
            return jsonify({"message": "❌ Connexion à la base échouée"}), 500

        cur = conn.cursor()
        user_id = request.args.get('user_id')

        if not user_id:
            return jsonify({"message": "❌ Paramètre user_id manquant"}), 400

        cur.execute("""
            SELECT "dateFacture", "coutConsommation" 
            FROM "Facture" 
            WHERE "IDfamilleRefFact" = %s;
        """, (user_id,))

        factures = cur.fetchall()
        factures_list = [
            {"dateFacture": row[0].strftime("%Y-%m-%d"),
             "consommation_eau_m3": float(row[1])}
            for row in factures
        ]

        return jsonify(factures_list)
    
    except Exception as e:
        print(f"🔥 Erreur: {str(e)}")
        return jsonify({"message": f"❌ Erreur serveur: {str(e)}"}), 500

    finally:
        if cur:
            cur.close()
        if conn:
            conn.close()

@app.route('/adresse', methods=['POST'])
def ajouter_adresse():
    try:
        data = request.json
        ville = data.get("ville")
        quartier = data.get("quartier")
        region = data.get("region")
        latitude = data.get("latitude")
        longitude = data.get("longitude")

        cursor.execute(
            'INSERT INTO "Adresse" (ville, quartier, region, localisation) '
            'VALUES (%s, %s, %s, point(%s, %s)) '
            'RETURNING adresse',
            (ville, quartier, region, longitude, latitude)
        )
        
        adresse_id = cursor.fetchone()[0]
        conn.commit()

        return jsonify({
            "status": "success",
            "message": "Adresse ajoutée avec succès",
            "adresse_id": adresse_id
        }), 200

    except Exception as e:
        conn.rollback()
        return jsonify({
            "status": "error",
            "message": str(e)
        }), 500

@app.route('/local', methods=['POST'])
def ajouter_local():
    try:
        data = request.json

        # Insertion du nouveau local
        cursor.execute(
            'INSERT INTO "Local" '
            '(type, surface, "nbChambre", "nbDouche", "nbVoiture", '
            '"nbCuisine", piscine, garage, jardin, "codeFamille", adress, nb_personne) '
            'VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s) '
            'RETURNING "IDlocal"',
            (data["type"], data["surface"], data["nbChambre"], 
             data["nbDouche"], data["nbVoiture"], data["nbCuisine"],
             data["piscine"], data["garage"], data["jardin"],
             data["codeFamille"], data["adress"], data["nb_personne"])
        )
        
        local_id = cursor.fetchone()[0]
        conn.commit()

        return jsonify({
            "status": "success",
            "message": "Local enregistré avec succès",
            "local_id": local_id
        }), 200

    except Exception as e:
        conn.rollback()
        return jsonify({
            "status": "error",
            "message": str(e)
        }), 500

@app.route('/calculate_rewards', methods=['GET'])
def calculate_rewards_endpoint():
    family_code = request.args.get('user')
    if not family_code:
        return jsonify({"error": "Le code famille est requis."}), 400

    result = calculate_rewards(family_code)
    if not result:
        return jsonify({"error": "Famille non trouvée ou données insuffisantes."}), 404

    return jsonify(result)

@app.route('/get_notifications', methods=['GET'])
def handle_get_notifications():
    return get_notifications()

@app.route('/invitation_action', methods=['POST'])
def invitation_action():
    data = request.get_json()
    member_email = data["memberEmail"]
    action = data["action"]  # "accept" or "ignore"
    notif_id = data["notificationId"]

    conn = get_connection()
    cursor = conn.cursor()
    try:
        # Fetch chef_email (senderId) from Notification table using notif_id
        cursor.execute('SELECT "senderId" FROM "Notification" WHERE "idNotification" = %s', (notif_id,))
        chef_row = cursor.fetchone()
        chef_email = chef_row[0] if chef_row else None

        print('member_email:', member_email)
        print('chef_email:', chef_email)
        print('action:', action)
        print('notif_id:', notif_id)

        if not chef_email:
            return jsonify({"status": "error", "message": "Chef email not found in notification"}), 404

        if action == "accept":
            # Get family of chef
            cursor.execute('SELECT "IDfamille" FROM chef WHERE email = %s', (chef_email,))
            family = cursor.fetchone()
            if not family:
                return jsonify({"status": "error", "message": "Famille introuvable"}), 404
            family_id = family[0]
            # Update member's family
            cursor.execute('UPDATE "Membre" SET "idFamille" = %s WHERE email = %s', (family_id, member_email))
            # Update invitation status to accepted
            cursor.execute(
                'UPDATE "Invitation" SET status = %s, "updatedAt" = CURRENT_TIMESTAMP WHERE "senderId" = %s AND "receiverId" = %s AND status = %s',
                ("accepted", chef_email, member_email, "pending")
            )
            cursor.execute(
                '''
                INSERT INTO "Notification"
                ("senderId", "receiverId", type, title, message, status, "createdAt", "updatedAt", "senderType")
                VALUES (%s, %s, %s, %s, %s, %s, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, %s)
                ''',
                (
                    member_email,               # senderId: the member who accepted
                    chef_email,                 # receiverId: the chef who sent the invite
                    "invitation_accepted",      # type
                    "Invitation acceptée",      # title
                    f"{member_email} a accepté votre invitation à rejoindre la famille.", # message
                    "pending",                  # status
                    "member"                    # senderType
                )
            )
        else:  # action == "ignore"
            # Update invitation status to ignored
            cursor.execute(
                'UPDATE "Invitation" SET status = %s, "updatedAt" = CURRENT_TIMESTAMP WHERE "senderId" = %s AND "receiverId" = %s AND status = %s',
                ("ignored", chef_email, member_email, "pending")
            )
        # Mark notification as "read"
        cursor.execute('UPDATE "Notification" SET status = %s WHERE "idNotification" = %s', ("accepted" if action=="accept" else "ignored", notif_id))
        conn.commit()
        return jsonify({"status": "success"}), 200
    except Exception as e:
        conn.rollback()
        return jsonify({"status": "error", "message": str(e)}), 500
    finally:
        cursor.close()
        conn.close()

@app.route('/mark_notification_vued', methods=['POST'])
def mark_notification_vued_route():
    from notification import mark_notification_vued
    return mark_notification_vued()

#****************************************************
if __name__ == '__main__':
    app.run(host="0.0.0.0", port=5000, debug=True)