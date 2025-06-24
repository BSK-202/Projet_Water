from flask import request, jsonify, session
from db import get_connection
from habitudes import ischef
import random
import time
import smtplib
from email.message import EmailMessage
import uuid

def send_otp_email(email, otp):
    expediteur = "fadmajadda2003@gmail.com"  # Doit être le même que celui utilisé pour générer le mot de passe d'application
    mot_de_passe = "rzgt kctt auzp ebcf"  # Mot de passe d'application généré sur Google
    sujet = "Code de vérification WaterApp"
    message = f"Votre code de vérification pour changer le mot de passe est : {otp}\nCe code est valable 1 minute."
    try:
        msg = EmailMessage()
        msg['From'] = expediteur
        msg['To'] = email
        msg['Subject'] = sujet
        msg.set_content(message)
        with smtplib.SMTP_SSL('smtp.gmail.com', 465) as smtp:
            smtp.login(expediteur, mot_de_passe)
            smtp.send_message(msg)
        return True
    except Exception as e:
        print("Erreur lors de l'envoi de l'email :", e)
        return False

# Stockage temporaire global (clé: uuid, valeur: dict avec otp, email, etc.)
otp_temp_store = {}

def request_password_change():
    data = request.get_json()
    email = data.get('email')
    new_password = data.get('new_password')
    confirm_password = data.get('confirm_password')
    if not email or not new_password or not confirm_password:
        return jsonify({'error': 'Tous les champs sont obligatoires.'}), 400

    if new_password != confirm_password:
        return jsonify({'error': 'Les mots de passe ne correspondent pas.'}), 400

    user_type = ischef(email)
    if user_type is None:
        return jsonify({'error': "Cet email n'existe pas."}), 404

    otp = str(random.randint(1000, 9999))
    otp_id = str(uuid.uuid4())
    otp_temp_store[otp_id] = {
        'otp': otp,
        'email': email,
        'otp_time': int(time.time()),
        'new_password': new_password,
        'confirm_password': confirm_password
    }
    if send_otp_email(email, otp):
        return jsonify({'message': 'Code envoyé par email.', 'otp_id': otp_id}), 200
    else:
        otp_temp_store.pop(otp_id, None)
        return jsonify({'error': "Erreur lors de l'envoi de l'email."}), 500

def verify_and_change_password():
    data = request.get_json()
    email = data.get('email')
    otp = data.get('otp')
    otp_id = data.get('otp_id')
    if not email or not otp or not otp_id:
        return jsonify({'error': 'Tous les champs sont obligatoires.'}), 400

    otp_data = otp_temp_store.get(otp_id)
    if not otp_data:
        return jsonify({'error': 'Aucune demande de code trouvée ou session expirée.'}), 400

    if email != otp_data['email']:
        return jsonify({'error': "Email ne correspond pas à la demande."}), 400
    if int(time.time()) - otp_data['otp_time'] > 60:
        otp_temp_store.pop(otp_id, None)
        return jsonify({'error': "Le code a expiré. Veuillez recommencer."}), 400
    if otp != otp_data['otp']:
        return jsonify({'error': "Code incorrect."}), 400

    new_password = otp_data['new_password']
    confirm_password = otp_data['confirm_password']
    if not new_password or not confirm_password:
        return jsonify({'error': "Informations manquantes. Veuillez recommencer la procédure."}), 400

    user_type = ischef(email)
    if user_type is None:
        return jsonify({'error': "Cet email n'existe pas."}), 404

    try:
        conn = get_connection()
        cur = conn.cursor()
        if user_type:  # chef
            cur.execute('UPDATE "chef" SET password = %s WHERE email = %s', (new_password, email))
        else:  # membre
            cur.execute('UPDATE "Membre" SET password = %s WHERE email = %s', (new_password, email))
        conn.commit()
        otp_temp_store.pop(otp_id, None)
        return jsonify({'message': 'Mot de passe modifié avec succès.'}), 200
    except Exception as e:
        if conn:
            conn.rollback()
        return jsonify({'error': f'Erreur serveur : {str(e)}'}), 500
    finally:
        if 'cur' in locals():
            cur.close()
        if 'conn' in locals() and conn:
            conn.close()
