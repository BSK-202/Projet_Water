# app.py

from flask import Flask, jsonify,session,request
from classement import get_classement
from db import get_connection
from userFamily import get_family_by_member
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
#****************************************************
app = Flask(__name__)
#****************************************************
app.config["SESSION_TYPE"] = "filesystem"  # Stockage sur le système de fichiers
app.config["PERMANENT_SESSION_LIFETIME"] = timedelta(minutes=30)
app.config["SESSION_COOKIE_SAMESITE"] = "Lax"  # Sécurité contre les attaques CSRF
app.config["SESSION_COOKIE_SECURE"] = True    # Cookies uniquement en HTTPS

# Configuration CORS sécurisée
CORS(app, resources={
    r"/*": {
        "origins": "http://localhost:52928",  # Remplacez par votre domaine client
        "supports_credentials": True
    }
})

# Initialisation de la session serveur
Session(app)
app.secret_key = 'f095a328dd6798c545699eb4d5a79b05924717771b8558e1'  # Clé secrète pour sécuriser les sessions

#****************************************************

@app.route('/', methods=['GET'])
def classement():
    """Renvoie le classement des familles sous format JSON."""
    print("data sent")
    return jsonify(get_classement())



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
    return login(data)

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
         # Avant de sauvegarder le fichier, nettoyer le répertoire d'upload
        #clear_upload_folder()

        filename = secure_filename(file.filename)
        file_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
        file.save(file_path)
        pdf_path = get_pdf_path_from_uploads()  # Récupérer le chemin du fichier PDF depuis le dossier "uploads"

        # Vous pouvez maintenant appeler la fonction d'extraction du PDF ici
        result = extract_data_from_pdf(pdf_path,user_id)
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

        cur.execute("""
            SELECT "dateFacture", "coutConsommation" 
            FROM "Facture" 
            WHERE "IDfamilleRefFact" = %s;
        """, (user_id,))

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

#****************************************************
if __name__ == '__main__':
    app.run(host="0.0.0.0", port=5000, debug=True)
