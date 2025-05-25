from flask import Flask, request, jsonify
import psycopg2
from flask_cors import CORS

app_local = Flask(__name__)
CORS(app_local)

# Connexion à PostgreSQL
conn = psycopg2.connect(
    dbname="watercontrol_bdd",
    user="postgres",
    password="1234",
    host="localhost",
    port="5432"
)
cursor = conn.cursor()

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
        
        # Vérifiez d'abord si le local existe déjà
        cursor.execute(
            'SELECT "IDlocal" FROM "Local" WHERE "codeFamille" = %s AND adress = %s',
            (data["codeFamille"], data["adress"])
        )
        existing = cursor.fetchone()
        
        if existing:
            return jsonify({
                "status": "error",
                "message": "Un local existe déjà pour cette famille à cette adresse"
            }), 400

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

if __name__ == '__main__':
    app_local.run(debug=True, host="0.0.0.0", port=5000)