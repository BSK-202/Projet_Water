from flask import Flask, request, jsonify
from werkzeug.utils import secure_filename
import os
from db import get_connection
from flask_cors import CORS
import json

app = Flask(__name__)
CORS(app)  # Active CORS pour toutes les routes

# Configuration pour le stockage des avatars
UPLOAD_FOLDER = 'uploads/avatars'
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif'}
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

def allowed_file(filename):
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS


def update_profile():
    try:
        # Vérifier si la requête contient des données multipart
        if 'data' not in request.form:
            return jsonify({'success': False, 'message': 'Données manquantes'}), 400
        
        # Récupérer les données JSON
        data = request.form.get('data')
        update_data = json.loads(data)
        
        email = update_data.get('email')
        new_email = update_data.get('new_email')
        prenom = update_data.get('prenom')
        nom = update_data.get('nom')
        avatar_from_data = update_data.get('avatar')  # <-- Ajouté

        if not all([email, prenom, nom]):
            return jsonify({'success': False, 'message': 'Données incomplètes'}), 400

        # Vérifier si l'utilisateur est un chef ou un membre
        user_type = ischef(email)
        if user_type is None:
            return jsonify({'success': False, 'message': 'Utilisateur non trouvé'}), 404

        conn = get_connection()
        if not conn:
            return jsonify({'success': False, 'message': 'Erreur de connexion à la base de données'}), 500
        
        cur = conn.cursor()

        # Gérer l'upload de l'avatar s'il est présent
        avatar_path = None
        if 'avatar' in request.files:
            file = request.files['avatar']
            if file and allowed_file(file.filename):
                filename = secure_filename(f"{email}_{file.filename}")
                os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)
                filepath = os.path.join(app.config['UPLOAD_FOLDER'], filename)
                file.save(filepath)
                avatar_path = filepath
        elif avatar_from_data:  # <-- Ajouté : si pas de fichier mais avatar dans data
            avatar_path = avatar_from_data

        # Mettre à jour les informations dans la bonne table
        if user_type:  # Chef
            # Vérifier si le nouvel email existe déjà
            if new_email and new_email != email:
                cur.execute("""SELECT email FROM "chef" WHERE email = %s""", (new_email,))
                if cur.fetchone():
                    return jsonify({'success': False, 'message': 'Email déjà utilisé'}), 400

            update_query = """
                UPDATE "chef" 
                SET prenom = %s, nom = %s
                {email_part}
                {avatar_part}
                WHERE email = %s
            """.format(
                email_part=", email = %s" if new_email else "",
                avatar_part=", avatar = %s" if avatar_path else ""
            )
            
            params = [prenom, nom]
            if new_email:
                params.append(new_email)
            if avatar_path:
                params.append(avatar_path)
            params.append(email)
            
            cur.execute(update_query, params)
        else:  # Membre
            # Vérifier si le nouvel email existe déjà
            if new_email and new_email != email:
                cur.execute("""SELECT email FROM "Membre" WHERE email = %s""", (new_email,))
                if cur.fetchone():
                    return jsonify({'success': False, 'message': 'Email déjà utilisé'}), 400

            update_query = """
                UPDATE "Membre" 
                SET prenom = %s, nom = %s
                {email_part}
                {avatar_part}
                WHERE email = %s
            """.format(
                email_part=", email = %s" if new_email else "",
                avatar_part=", avatar = %s" if avatar_path else ""
            )
            
            params = [prenom, nom]
            if new_email:
                params.append(new_email)
            if avatar_path:
                params.append(avatar_path)
            params.append(email)
            
            cur.execute(update_query, params)

        conn.commit()
        
        return jsonify({
            'success': True,
            'message': 'Profil mis à jour avec succès',
            'new_email': new_email if new_email else email,
            'prenom': prenom,
            'nom': nom,
            'avatar': avatar_path if avatar_path else None
        })

    except Exception as e:
        conn.rollback()
        return jsonify({'success': False, 'message': str(e)}), 500
    finally:
        if 'cur' in locals():
            cur.close()
        if 'conn' in locals() and conn:
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