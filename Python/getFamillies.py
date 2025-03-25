from flask import Flask, jsonify
from flask_cors import CORS
from db import get_connection

app = Flask(__name__)
CORS(app)  # Permet les requêtes depuis Flutter


# Route pour récupérer toutes les familles
@app.route('/families', methods=['GET'])
def get_families():
    try:
        # Connexion à la base PostgreSQL
        conn = get_connection()
        cursor = conn.cursor()

        # Requête pour récupérer les familles
        query = "SELECT \"ReferenceFacture\",\"scoreFamille\", avatar, ST_Y(localisation), ST_X(localisation) FROM famille"
        cursor.execute(query)
        families = cursor.fetchall()

        # Transformer les données en format JSON
        family_list = [
            {"id": str(f[0]), "name": f[1], "avatar": f[2], "latitude": f[3], "longitude": f[4]}
            for f in families
        ]

        # Fermeture de la connexion
        cursor.close()
        conn.close()

        return jsonify(family_list)  # Retourne les données en JSON

    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(host="0.0.0.0", port=5000, debug=True)