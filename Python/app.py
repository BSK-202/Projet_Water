# app.py

from flask import Flask, jsonify,request, session
from getUserBadge import get_all_badges_for_user
from get_profil import get_user_details
from update_profile import update_profile
from get_socio import get_socio_utilisateur
from socio import receive_sociodemographique
from get_habitude import get_habitudes_utilisateur
from habitudes import receive_habits
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
from edit_pass import request_password_change, verify_and_change_password
import os
from werkzeug.utils import secure_filename
from pdf_extraction import get_pdf_path_from_uploads
from flask_session import Session
from datetime import datetime, timedelta
import json

# Connexion à PostgreSQL
conn = get_connection()
cursor = conn.cursor()
#****************************************************
app = Flask(__name__)
#****************************************************
app.config["SESSION_TYPE"] = "filesystem"
app.config["PERMANENT_SESSION_LIFETIME"] = timedelta(minutes=30)
app.secret_key = 'f095a328dd6798c545699eb4d5a79b05924717771b8558e1'
Session(app)
app.secret_key = 'f095a328dd6798c545699eb4d5a79b05924717771b8558e1'  # Clé secrète pour sécuriser les sessions

CORS(app, resources={
    r"/*": {
        "origins": "*",
        "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        "allow_headers": ["Content-Type", "Authorization"]
    }
})
@app.before_request
def make_session_permanent():
    session.permanent = True
    session.modified = True  # Set a flag indicating that the session has been modified

# Initialisation de la session serveur

#****************************************************

@app.route('/families', methods=['GET'])
def classement():
    """Renvoie le classement des familles sous format JSON."""
    print("data sent")
    return jsonify(get_classement())


# Route pour recuperer les badges d'un utilisateur par son email 
@app.route('/badges/<string:email>', methods=['GET'])
def get_badges(email):
    """
    Récupère tous les badges, indiquant ceux que l'utilisateur a débloqués ou pas,
    avec les champs de progression si disponibles.
    """
    try:
        badges = get_all_badges_for_user(email)
        return jsonify(badges), 200
    except Exception as e:
        print("Erreur :", e)
        return jsonify({"error": str(e)}), 500

#****************************************************
#****************************************************
# Notification Routes

@app.route('/send_invitation', methods=['POST'])
def handle_send_invitation():
    print("send_invitation called")
    return send_invitation()

@app.route('/check_notifications', methods=['GET'])
def handle_check_notifications():
    print("check_notifications called")
    return check_and_notify_chef()

@app.route('/get_unread_notifications', methods=['GET'])
def handle_get_unread_notifications():
    print("get_unread_notifications called")
    return get_unread_notifications()


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

# Route API pour obtenir la famille d'un utilisateur par son ID
@app.route('/get_family/<string:member_id>', methods=['GET'])
def get_family(member_id):
    family = get_family_by_member(member_id)
    if family:
        print("family sent")
        return jsonify({"status": "success", "family": family}), 200
    else:
        return jsonify({"status": "error", "message": "Famille non trouvée"}), 404


#****************************************************
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
    data_user=login(data)
    session["user_id"] = data_user["user_id"] # chef[2] est l'email (index 2)
    session["is_chef"] = data_user["is_chef"]  # # chef[3] est le mot de passe (index 3)
    session["id_famille"] =data_user["idFamille"] 
    session.modified = True 
    return data_user







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
    cur = conn.cursor()
    print(user_id)
    file = request.files['file']
    
    if file and allowed_file(file.filename):
         # Avant de sauvegarder le fichier, nettoyer le répertoire d'upload
        clear_upload_folder()

        filename = secure_filename(file.filename)
        file_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
        file.save(file_path)
        pdf_path = get_pdf_path_from_uploads()  # Récupérer le chemin du fichier PDF depuis le dossier "uploads"
        cur.execute("""
            SELECT "IDfamille" FROM "chef" WHERE email = %s
            UNION
            SELECT "idFamille" FROM "Membre" WHERE email = %s
        """, (user_id, user_id))
        
        famille_result = cur.fetchone()
        if not famille_result or not famille_result[0]:
            return 0.0, None  # Retourner un tuple cohérent
            
        id_famille = famille_result[0]
        # Vous pouvez maintenant appeler la fonction d'extraction du PDF ici
        result = extract_data_from_pdf(pdf_path,id_famille)
        print(result)
        return result
    

@app.route('/factures', methods=['GET'])
def get_factures():
    conn = None
    cur = None
    try:
        # Connexion à la base de données
        conn = get_connection()
        if not conn:
            return jsonify({"message": "❌ Connexion à la base échouée"}), 500

        cur = conn.cursor()
        user_id = request.args.get('user_id')
     
        # Vérifier si user_id est présent
        if not user_id:
            return jsonify({"message": "❌ Paramètre user_id manquant"}), 400
   # Récupérer l'ID famille de l'utilisateur
        cur.execute("""
            SELECT "IDfamille" FROM "chef" WHERE email = %s
            UNION
            SELECT "idFamille" FROM "Membre" WHERE email = %s
        """, (user_id, user_id))
        
        famille_result = cur.fetchone()
        if not famille_result or not famille_result[0]:
            return 0.0, None  # Retourner un tuple cohérent
            
        id_famille = famille_result[0]

        cur.execute("""
            SELECT "dateFacture", "coutConsommation" 
            FROM "Facture" 
            WHERE "IDfamilleRefFact" = %s;
        """, (id_famille,))

        factures = cur.fetchall()
        factures_list = [
            {"dateFacture": row[0].strftime("%Y-%m-%d"),  # Formatage de la date
             "consommation_eau_m3": float(row[1])}  # Conversion en float
            for row in factures
        ]

        return jsonify(factures_list)
    
    except Exception as e:
        print(f"🔥 Erreur: {str(e)}")  # Log pour débogage
        return jsonify({"message": f"❌ Erreur serveur: {str(e)}"}), 500

    finally:
        # Fermeture sécurisée des ressources
        if cur:
            cur.close()
        if conn:
            conn.close()



###########################local
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
        app.logger.debug(f"Données reçues: {data}")

        # Validation des champs obligatoires
        required_fields = [
            "type", "surface", "nbChambre", "nbDouche", "nbCuisine",
            "codeFamille", "nb_personne", "nbr_toilettes", "nbr_robinets",
            "nbr_salles_de_bain", "nbr_etages", "nbr_chasse_eau", "age_plomberie",
            "dernier_renovation_plomberie", "nbr_lave_linge", "nbr_lave_vaisselle"
        ]

        for field in required_fields:
            if field not in data:
                return jsonify({"error": f"Le champ {field} est obligatoire"}), 400

        # Construction des paramètres avec conversion explicite
        params = (
            str(data['type']),
            float(data['surface']),
            int(data['nbChambre']),
            int(data['nbDouche']),
            int(data['nbCuisine']),
            bool(data.get('piscine', False)),
            bool(data.get('garage', False)),
            bool(data.get('jardin', False)),
            str(data['codeFamille']),
            int(data['adress']),
            int(data['nb_personne']),
            int(data['nbr_toilettes']),
            int(data['nbr_robinets']),
            float(data.get('surface_jardin', 0)),
            float(data.get('surface_piscine', 0)),
            int(data['nbr_salles_de_bain']),
            int(data['nbr_etages']),
            int(data['nbr_chasse_eau']),
            int(data['age_plomberie']),
            str(data.get('type_tuyauterie')) if data.get('type_tuyauterie') else None,
            int(data['dernier_renovation_plomberie']),
            str(data.get('type_chauffe_eau')) if data.get('type_chauffe_eau') else None,
            bool(data.get('arrosage_automatique', False)),
            int(data['nbr_lave_linge']),
            int(data['nbr_lave_vaisselle']),
            float(data.get('utilisation_nettoyage_sols', 0)),
            bool(data.get('statut_occupation', False))
        )

        # Requête SQL avec paramètres positionnels
        query = '''
            INSERT INTO "Local" (
                type, surface, "nbChambre", "nbDouche", "nbCuisine", 
                piscine, garage, jardin, "codeFamille", adress, nb_personne,
                nbr_toilettes, nbr_robinets, surface_jardin, surface_piscine,
                nbr_salles_de_bain, nbr_etages, nbr_chasse_eau, age_plomberie,
                type_tuyauterie, dernier_renovation_plomberie, type_chauffe_eau,
                arrosage_automatique, nbr_lave_linge, nbr_lave_vaisselle,
                utilisation_nettoyage_sols, statut_occupation
            ) VALUES (
                %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s,
                %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s,
                %s, %s, %s, %s, %s
            ) RETURNING "IDlocal"
        '''

        cursor.execute(query, params)
        # Modification ici: accès par index au lieu de clé
        local_id = cursor.fetchone()[0]  # Premier élément du tuple
        conn.commit()

        return jsonify({
            "status": "success",
            "message": "Local enregistré avec succès",
            "local_id": local_id
        }), 200

    except Exception as e:
        conn.rollback()
        app.logger.error(f"Erreur lors de l'insertion: {str(e)}", exc_info=True)
        return jsonify({
            "status": "error",
            "message": f"Erreur serveur: {str(e)}"
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

@app.route('/habits', methods=['POST'])
def receive_habits_main():
    try:
        # Récupérer les données JSON envoyées par l'application Flutter
        data = request.get_json()
       
        # Afficher les données dans la console
        print("Données reçues :")
        print(f"ID: {data.get('id')}")
        print(f"Category: {data.get('category')}")
        print(f"Value: {data.get('value')}")
        print(f"Points: {data.get('points')}")
        print(f"User ID: {data.get('user_id')}")

        # Retourner une réponse de succès
        return receive_habits(data)

    except Exception as e:
        # Gérer les erreurs et retourner une réponse d'erreur
        print(f"Erreur lors de la réception des données : {str(e)}")
        return jsonify({"error": "Erreur lors de la réception des données"}), 500
    
@app.route('/get_completed_habits', methods=['POST'])
def get_completed_habits():
    try:
        data = request.get_json()
        if not data or 'user_id' not in data:
            print("Erreur : User ID manquant")
            return jsonify({"error": "User ID requis"}), 400

        user_id = data.get('user_id')
        print(f"User ID reçu : {user_id}")

        # Appeler la fonction pour récupérer les habitudes
        return get_habitudes_utilisateur({"user_id": user_id})
    except Exception as e:
        print(f"Erreur : {str(e)}")
        return jsonify({"error": "Erreur lors de la récupération des habitudes"}), 500
    #*********************************
@app.route('/socio', methods=['POST'])
def get_socio():
    try:
        print("hhhhh")
        data = request.get_json()
        print(data)
        if not data or 'user_id' not in data:
            print("Erreur : User ID manquant")
            return jsonify({"error": "User ID requis"}), 400

        user_id = data.get('user_id')
        print(f"User ID reçu : {user_id}")

        # Appeler la fonction pour récupérer les habitudes
        return receive_sociodemographique(data)
    except Exception as e:
        print(f"Erreur : {str(e)}")
        return jsonify({"error": "Erreur lors de la récupération des habitudes"}), 500
    #**********
    
@app.route('/get_socio', methods=['POST'])
def get_socio_rec():
    try:
        print("hoho")
        data = request.get_json()
        
        if not data or 'user_id' not in data:
            print("Erreur : User ID manquant")
            return jsonify({"error": "User ID requis"}), 400

        user_id = data.get('user_id')
        print(f"*//User ID reçu socio : {user_id}")

        # Appeler la fonction pour récupérer les habitudes
        return get_socio_utilisateur(data)
    except Exception as e:
        print(f"Erreur : {str(e)}")
        return jsonify({"error": "Erreur lors de la récupération des socio hhh"}), 500
    #**********
    
@app.route('/profile', methods=['GET'])
def get_user_profile():
        email = request.args.get('email')
        if not email:
            return jsonify({'error': 'Email parameter is required'}), 400

        user_data = get_user_details(email)
        if not user_data:
            return jsonify({'error': 'User not found'}), 404

        return jsonify(user_data)

@app.route('/update_profile', methods=['POST'])
def handle_profile_update():
    try:
        # Vérifier le content-type
        if request.content_type.startswith('multipart/form-data'):
            # Vérifier si la requête contient des données
            if 'data' not in request.form:
                return jsonify({'success': False, 'message': 'Données manquantes'}), 400

            data = json.loads(request.form['data'])
            print("Données reçues pour update_profile:", data)  # <-- Ajouté pour debug
            email = data.get('email')
            
            if not email:
                return jsonify({'success': False, 'message': 'Email manquant'}), 400

            # Le reste du traitement...
            return update_profile()  # Renommez cette fonction en process_profile_update()
            
        return jsonify({'success': False, 'message': 'Content-Type non supporté'}), 415
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 500
@app.route('/check-local', methods=['GET'])
def check_local():
    code_famille = request.args.get('code_famille')
    if not code_famille:
        return jsonify({"error": "Code famille manquant"}), 400
    
    try:
        cursor.execute("""
            SELECT l.*, a.ville, a.quartier, a.region, 
                   a.localisation[0] as latitude, 
                   a.localisation[1] as longitude
            FROM "Local" l
            JOIN "Adresse" a ON l.adress = a.adresse
            WHERE l."codeFamille" = %s
            LIMIT 1
        """, (code_famille,))
        
        columns = [desc[0] for desc in cursor.description]  # Récupère les noms de colonnes
        local = cursor.fetchone()
        
        if local:
            # Convertir le tuple en dictionnaire
            local_dict = dict(zip(columns, local))
            return jsonify({
                "has_local": True,
                "local": local_dict
            })
        else:
            return jsonify({"has_local": False})
            
    except Exception as e:
        print(f"Erreur dans check_local: {str(e)}")
        return jsonify({"error": str(e)}), 500
    
@app.route('/update-local', methods=['PUT'])
def update_local():
    data = request.get_json()
    local_id = data.get('local_id')
    
    if not local_id:
        return jsonify({"error": "ID local manquant"}), 400
    
    try:
        print(f"Données reçues pour mise à jour: {data}")

        # Récupérer les données actuelles avant mise à jour
        cursor.execute('SELECT * FROM "Local" WHERE "IDlocal" = %s', (local_id,))
        current_data = cursor.fetchone()
        if not current_data:
            return jsonify({"error": "Aucun local trouvé avec cet ID"}), 404

        # Mise à jour du local
        cursor.execute("""
            UPDATE "Local" SET
                type = COALESCE(%s, type),
                surface = COALESCE(%s, surface),
                "nbChambre" = COALESCE(%s, "nbChambre"),
                "nbDouche" = COALESCE(%s, "nbDouche"),
                "nbCuisine" = COALESCE(%s, "nbCuisine"),
                piscine = COALESCE(%s, piscine),
                garage = COALESCE(%s, garage),
                jardin = COALESCE(%s, jardin),
                nb_personne = COALESCE(%s, nb_personne),
                nbr_toilettes = COALESCE(%s, nbr_toilettes),
                nbr_robinets = COALESCE(%s, nbr_robinets),
                surface_jardin = COALESCE(%s, surface_jardin),
                surface_piscine = COALESCE(%s, surface_piscine),
                nbr_salles_de_bain = COALESCE(%s, nbr_salles_de_bain),
                nbr_etages = COALESCE(%s, nbr_etages),
                nbr_chasse_eau = COALESCE(%s, nbr_chasse_eau),
                age_plomberie = COALESCE(%s, age_plomberie),
                type_tuyauterie = COALESCE(%s, type_tuyauterie),
                dernier_renovation_plomberie = COALESCE(%s, dernier_renovation_plomberie),
                type_chauffe_eau = COALESCE(%s, type_chauffe_eau),
                arrosage_automatique = COALESCE(%s, arrosage_automatique),
                nbr_lave_linge = COALESCE(%s, nbr_lave_linge),
                nbr_lave_vaisselle = COALESCE(%s, nbr_lave_vaisselle),
                utilisation_nettoyage_sols = COALESCE(%s, utilisation_nettoyage_sols),
                statut_occupation = COALESCE(%s, statut_occupation)
            WHERE "IDlocal" = %s
            RETURNING *
        """, (
            data.get('type'),
            data.get('surface'),
            data.get('nbChambre'),
            data.get('nbDouche'),
            data.get('nbCuisine'),
            data.get('piscine'),
            data.get('garage'),
            data.get('jardin'),
            data.get('nb_personne'),
            data.get('nbr_toilettes'),
            data.get('nbr_robinets'),
            data.get('surface_jardin'),
            data.get('surface_piscine'),
            data.get('nbr_salles_de_bain'),
            data.get('nbr_etages'),
            data.get('nbr_chasse_eau'),
            data.get('age_plomberie'),
            data.get('type_tuyauterie'),
            data.get('dernier_renovation_plomberie'),
            data.get('type_chauffe_eau'),
            data.get('arrosage_automatique'),
            data.get('nbr_lave_linge'),
            data.get('nbr_lave_vaisselle'),
            data.get('utilisation_nettoyage_sols'),
            data.get('statut_occupation'),
            local_id
        ))
        
        updated_local = cursor.fetchone()
        if not updated_local:
            conn.rollback()
            return jsonify({"error": "La mise à jour a échoué", "details": "Aucune ligne affectée"}), 400
            
        conn.commit()
        
        # Vérifier si des données ont réellement changé
        changes_detected = False
        for i, field in enumerate(cursor.description):
            field_name = field.name
            if field_name in data and str(current_data[i]) != str(data[field_name]):
                changes_detected = True
                break

        if not changes_detected:
            return jsonify({
                "success": False,
                "message": "Aucune modification détectée - les données sont identiques",
                "local_id": local_id
            }), 200

        # Mise à jour de l'adresse si nécessaire
        address_updated = False
        if any(key in data for key in ['ville', 'quartier', 'region', 'latitude', 'longitude']):
            cursor.execute("""
                UPDATE "Adresse" SET
                    ville = COALESCE(%s, ville),
                    quartier = COALESCE(%s, quartier),
                    region = COALESCE(%s, region),
                    localisation = CASE 
                        WHEN %s IS NOT NULL AND %s IS NOT NULL THEN point(%s, %s)
                        ELSE localisation
                    END
                WHERE adresse = (
                    SELECT adress FROM "Local" WHERE "IDlocal" = %s
                )
                RETURNING adresse
            """, (
                data.get('ville'),
                data.get('quartier'),
                data.get('region'),
                data.get('latitude'),
                data.get('longitude'),
                data.get('latitude'),
                data.get('longitude'),
                local_id
            ))
            
            if cursor.fetchone():
                address_updated = True
                conn.commit()

        return jsonify({
            "success": True, 
            "local_id": local_id,
            "address_updated": address_updated,
            "message": "Mise à jour effectuée avec succès",
            "changes_detected": changes_detected
        })
        
    except Exception as e:
        conn.rollback()
        print(f"Erreur lors de la mise à jour: {str(e)}")
        return jsonify({
            "error": str(e),
            "success": False,
            "message": "Échec de la mise à jour"
   }),500
    
   ## route pour recuperer la localisation d'une famille
   # @app.route('/get_location', methods=['GET'])
@app.route('/get_location/<string:code_famille>', methods=['GET'])
def get_location(code_famille):   
    if not code_famille:
        return jsonify({"error": "Code famille manquant"}), 400
    try:
        cursor.execute("""
            SELECT a.ville, a.quartier, a.region, 
                   a.localisation[0] as latitude, 
                   a.localisation[1] as longitude
            FROM "Adresse" a
            JOIN "Local" l ON a.adresse = l.adress
            WHERE l."codeFamille" = %s
            LIMIT 1
        """, (code_famille,))
        
        location = cursor.fetchone()
        
        if location:
            return jsonify({                                  
                    "latitude": float(location[3]),
                    "longitude": float(location[4])                
            })
        else:
            return jsonify({"has_location": False})
    except Exception as e:
        print(f"Erreur dans get_location: {str(e)}")
        return jsonify({"error": str(e)}), 500


@app.route('/request_password_change', methods=['POST'])
def request_password_change_route():
    return request_password_change()

@app.route('/verify_and_change_password', methods=['POST'])
def verify_and_change_password_route():
    return verify_and_change_password()

if __name__ == '__main__':
    app.run(host="0.0.0.0", port=5000, debug=True)