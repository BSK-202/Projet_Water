<div align="center">

# 🌊 Projet Water

### Plateforme mobile de sensibilisation, de suivi et de réduction de la consommation d'eau

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge\&logo=flutter\&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.7-0175C2?style=for-the-badge\&logo=dart\&logoColor=white)](https://dart.dev/)
[![Python](https://img.shields.io/badge/Python-3.10+-3776AB?style=for-the-badge\&logo=python\&logoColor=white)](https://www.python.org/)
[![Flask](https://img.shields.io/badge/Flask-2.x-000000?style=for-the-badge\&logo=flask\&logoColor=white)](https://flask.palletsprojects.com/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-4169E1?style=for-the-badge\&logo=postgresql\&logoColor=white)](https://www.postgresql.org/)
[![Firebase](https://img.shields.io/badge/Firebase-Auth-FFCA28?style=for-the-badge\&logo=firebase\&logoColor=black)](https://firebase.google.com/)

**Sensibiliser • Mesurer • Agir • Économiser**

</div>

---

## 📖 À propos

**Projet Water** est une application mobile développée avec **Flutter**, accompagnée d'un backend **Python / Flask** et d'une base de données **PostgreSQL**.

L'application a pour objectif de sensibiliser les familles à la consommation d'eau et de les encourager à adopter des habitudes plus responsables grâce à un système combinant :

* 📊 suivi de la consommation ;
* 🧾 analyse des factures d'eau ;
* 🏆 défis et gamification ;
* 🎖️ badges et récompenses ;
* 🗺️ cartographie ;
* 🥇 classement des familles ;
* 🔔 notifications et invitations.

Le projet introduit une approche ludique de la sensibilisation : les utilisateurs peuvent suivre leur évolution, relever des défis et progresser dans un système de récompenses.

---

# 🎯 Objectifs

Le projet répond à plusieurs objectifs :

* Encourager une utilisation responsable de l'eau.
* Permettre aux familles de suivre leur consommation.
* Transformer les habitudes quotidiennes en défis mesurables.
* Récompenser les comportements permettant de réduire la consommation.
* Donner une vision comparative grâce au classement.
* Exploiter les données des factures d'eau.
* Sensibiliser les utilisateurs grâce à des contenus éducatifs.

---

# ✨ Fonctionnalités

## 🔐 Authentification et profils

L'application propose un parcours d'inscription adapté aux différents types d'utilisateurs.

* Inscription multi-étapes.
* Connexion utilisateur.
* Vérification de l'adresse email.
* Réinitialisation du mot de passe avec OTP.
* Modification du profil.
* Gestion de l'avatar.
* Gestion de session.

L'application distingue notamment deux rôles :

| Rôle                   | Responsabilités                                                 |
| ---------------------- | --------------------------------------------------------------- |
| 👑 **Chef de famille** | Création et gestion du foyer, invitations, gestion des factures |
| 👤 **Membre**          | Participation aux défis et suivi de la consommation             |

---

## 🏠 Gestion du foyer

Chaque famille peut configurer son logement afin d'obtenir une estimation plus adaptée de sa consommation.

Les informations prises en compte comprennent notamment :

* Type de logement.
* Surface.
* Nombre de pièces.
* Équipements.
* Installations sanitaires.
* Informations liées à la plomberie.
* Localisation géographique.

La localisation est obtenue grâce aux services de cartographie et de géolocalisation.

---

## 💧 Suivi de la consommation

L'application permet de suivre l'évolution de la consommation d'eau à partir des factures.

### Fonctionnalités

* Importation de factures PDF.
* Extraction automatique des données.
* Historique des consommations.
* Visualisation graphique.
* Comparaison avec une moyenne de référence.
* Détection de séries d'économies.
* Calcul d'un seuil de consommation personnalisé.

Le traitement des factures repose sur un service backend Python utilisant notamment **PyPDF2**.

---

## 🧾 Analyse des factures

Le parcours de traitement est le suivant :

```text
       Facture PDF
            │
            ▼
      Upload Flutter
            │
            ▼
       API Flask
            │
            ▼
      Extraction PDF
         PyPDF2
            │
            ▼
     Données extraites
            │
            ▼
        PostgreSQL
            │
            ▼
   Historique consommation
            │
            ▼
     Graphiques Flutter
```

Cette fonctionnalité permet de transformer les informations présentes dans les factures en données exploitables par l'application.

---

# 🏆 Gamification

La gamification constitue un élément central du projet.

L'utilisateur peut progresser grâce à différentes catégories de défis.

### 💦 Défis liés aux habitudes

Des défis portent notamment sur :

* les douches ;
* les bains ;
* les robinets ;
* la machine à laver ;
* les habitudes quotidiennes liées à l'utilisation de l'eau.

### 👥 Défis sociodémographiques

L'application propose également des défis ou questionnaires portant sur certaines informations sociodémographiques et la sensibilisation à la consommation d'eau.

### 🎖️ Système de récompenses

Les utilisateurs peuvent obtenir :

* ⭐ des points ;
* 🏅 des badges ;
* 🎁 des récompenses ;
* 🔥 des séries d'économie.

Le système permet ainsi de transformer les efforts individuels en progression visible dans l'application.

---

# 🗺️ Carte et classement

## Carte

L'application propose une carte interactive permettant de visualiser les familles participantes.

Technologies utilisées :

* `flutter_map`
* Mapbox
* Google Maps
* Geolocator
* Geocoding
* Nominatim / OpenStreetMap

## Classement

Les familles peuvent également apparaître dans un classement permettant de comparer leur progression.

Le classement propose notamment plusieurs niveaux :

```text
🏆 Expert
🥇 Avancé
🥈 Intermédiaire
🥉 Débutant
```

Un podium permet également de mettre en évidence les trois premières familles.

---

# 🔔 Notifications et invitations

Le système de notification permet notamment de gérer :

* Les invitations à rejoindre une famille.
* Les notifications non lues.
* Les notifications affichées dans l'application.
* Les actions sur les invitations.
* Les rappels liés à l'activité de l'utilisateur.

---

# 🏗️ Architecture

Le projet adopte une architecture séparant l'application mobile, l'API backend et la base de données.

```text
                         ┌─────────────────────┐
                         │     Flutter App     │
                         │                     │
                         │  UI / Screens       │
                         │  Providers          │
                         │  Services           │
                         └──────────┬──────────┘
                                    │
                              HTTP / JSON
                                    │
                                    ▼
                         ┌─────────────────────┐
                         │    Flask Backend    │
                         │                     │
                         │ Authentication      │
                         │ Consumption         │
                         │ Invoices            │
                         │ Gamification        │
                         │ Notifications       │
                         │ Family Management   │
                         └──────────┬──────────┘
                                    │
                                    ▼
                         ┌─────────────────────┐
                         │     PostgreSQL      │
                         │                     │
                         │ Users               │
                         │ Families            │
                         │ Local               │
                         │ Invoices            │
                         │ Challenges         │
                         │ Badges              │
                         │ Notifications       │
                         └─────────────────────┘

          ┌──────────────────┐
          │ External Services │
          ├──────────────────┤
          │ Firebase Auth    │
          │ Google Maps      │
          │ Mapbox           │
          │ OpenStreetMap    │
          │ Gmail SMTP       │
          └──────────────────┘
```

---

# 📁 Structure du projet

```text
Projet_Water/
│
├── Water_V0/
│   ├── lib/
│   │   ├── models/
│   │   ├── providers/
│   │   ├── screens/
│   │   ├── services/
│   │   ├── widgets/
│   │   └── main.dart
│   │
│   ├── android/
│   ├── ios/
│   ├── web/
│   └── pubspec.yaml
│
├── Python/
│   ├── app.py
│   ├── db.py
│   │
│   ├── auth/
│   │   ├── login.py
│   │   └── registration.py
│   │
│   ├── gamification/
│   │   ├── habitudes.py
│   │   ├── socio.py
│   │   └── recompense.py
│   │
│   ├── factures/
│   │   └── pdf_extraction.py
│   │
│   ├── notifications/
│   │   └── notification.py
│   │
│   └── local/
│       ├── adresse.py
│       └── getFamillies.py
│
├── docs/
│   └── screenshots/
│
└── README.md
```

---

# 🛠️ Stack technique

## 📱 Frontend

| Technologie               | Utilisation                        |
| ------------------------- | ---------------------------------- |
| **Flutter**               | Application mobile multiplateforme |
| **Dart**                  | Langage                            |
| **Provider**              | Gestion d'état                     |
| **HTTP**                  | Communication avec l'API           |
| **fl_chart**              | Graphiques                         |
| **flutter_map**           | Cartographie                       |
| **Mapbox**                | Cartographie                       |
| **Google Maps**           | Cartographie                       |
| **Geolocator**            | Géolocalisation                    |
| **Geocoding**             | Conversion adresse / coordonnées   |
| **shared_preferences**    | Stockage local                     |
| **file_picker**           | Sélection de fichiers              |
| **image_picker**          | Sélection d'images                 |
| **video_player / Chewie** | Contenus vidéo éducatifs           |
| **Google ML Kit**         | Reconnaissance de texte            |
| **intl**                  | Internationalisation               |

## 🐍 Backend

| Technologie       | Utilisation                |
| ----------------- | -------------------------- |
| **Python**        | Langage                    |
| **Flask**         | API REST                   |
| **PostgreSQL**    | Persistance des données    |
| **psycopg2**      | Connexion PostgreSQL       |
| **PyPDF2**        | Extraction des factures    |
| **Flask-CORS**    | Communication cross-origin |
| **Flask-Session** | Gestion des sessions       |
| **smtplib**       | Envoi des emails           |

## ☁️ Services externes

| Service                       | Utilisation        |
| ----------------------------- | ------------------ |
| **Firebase Authentication**   | Vérification email |
| **Google Maps**               | Cartographie       |
| **Mapbox**                    | Cartographie       |
| **OpenStreetMap / Nominatim** | Géocodage          |
| **Gmail SMTP**                | Envoi des OTP      |

---

# 📸 Captures d'écran

Les captures d'écran du projet peuvent être placées dans :

```text
docs/screenshots/
```

Exemple :

| Authentification                     | Tableau de bord                              | Défis                                          |
| ------------------------------------ | -------------------------------------------- | ---------------------------------------------- |
| ![Login](docs/screenshots/login.png) | ![Dashboard](docs/screenshots/dashboard.png) | ![Challenges](docs/screenshots/challenges.png) |

| Carte                            | Classement                               | Factures                                   |
| -------------------------------- | ---------------------------------------- | ------------------------------------------ |
| ![Map](docs/screenshots/map.png) | ![Ranking](docs/screenshots/ranking.png) | ![Invoices](docs/screenshots/invoices.png) |

---

# 🚀 Installation

## Prérequis

* Flutter SDK
* Dart SDK
* Python 3.10+
* PostgreSQL
* Android Studio ou environnement mobile équivalent
* Compte Firebase
* Clé Google Maps / Mapbox selon la plateforme utilisée

---

## 1. Cloner le projet

```bash
git clone https://github.com/BSK-202/Projet_Water.git

cd Projet_Water
```

---

## 2. Configurer PostgreSQL

Créer la base de données :

```bash
createdb last_bdd
```

Puis configurer les paramètres de connexion du backend.

---

## 3. Installer le backend

```bash
cd Python

python -m venv venv
```

### Windows

```bash
venv\Scripts\activate
```

### Linux / macOS

```bash
source venv/bin/activate
```

Installer les dépendances :

```bash
pip install flask psycopg2-binary PyPDF2 flask-cors flask-session
```

Lancer le serveur :

```bash
python app.py
```

API disponible sur :

```text
http://127.0.0.1:5000
```

---

## 4. Installer l'application Flutter

Depuis le dossier du projet Flutter :

```bash
cd Water_V0

flutter pub get
```

Puis :

```bash
flutter run
```

---

# 🔐 Configuration et variables d'environnement

Les clés API et informations sensibles doivent être configurées localement.

Exemple :

```env
DATABASE_NAME=last_bdd
DATABASE_USER=postgres
DATABASE_PASSWORD=your_password
DATABASE_HOST=localhost
DATABASE_PORT=5432

FLASK_SECRET_KEY=your_secret_key

GOOGLE_MAPS_API_KEY=your_google_maps_key
MAPBOX_ACCESS_TOKEN=your_mapbox_token

SMTP_EMAIL=your_email
SMTP_PASSWORD=your_app_password
```

> ⚠️ **Ne jamais publier de véritables clés API, mots de passe, tokens ou secrets dans GitHub.**

Ajoute notamment les fichiers sensibles au `.gitignore` :

```gitignore
.env
.env.*
!.env.example

venv/
__pycache__/

*.log
```

---

# 📡 API REST

Le backend Flask expose plusieurs groupes d'endpoints.

## 🔐 Authentification

| Méthode | Endpoint                      | Fonction                    |
| ------- | ----------------------------- | --------------------------- |
| `POST`  | `/login`                      | Connexion                   |
| `POST`  | `/register`                   | Inscription                 |
| `POST`  | `/selection`                  | Sélection du type de compte |
| `POST`  | `/request_password_change`    | Demande de changement       |
| `POST`  | `/verify_and_change_password` | Vérification OTP            |

## 👤 Utilisateurs

| Méthode | Endpoint           | Fonction             |
| ------- | ------------------ | -------------------- |
| `GET`   | `/profile`         | Récupérer le profil  |
| `POST`  | `/update_profile`  | Modifier le profil   |
| `GET`   | `/badges/<email>`  | Récupérer les badges |
| `GET`   | `/get_family/<id>` | Récupérer la famille |

## 💧 Consommation

| Méthode | Endpoint             | Fonction                 |
| ------- | -------------------- | ------------------------ |
| `POST`  | `/extract_pdf`       | Extraire une facture     |
| `GET`   | `/factures`          | Récupérer les factures   |
| `GET`   | `/calculate_rewards` | Calculer les récompenses |

## 🏆 Gamification

| Méthode | Endpoint                | Fonction                      |
| ------- | ----------------------- | ----------------------------- |
| `POST`  | `/habits`               | Enregistrer une habitude      |
| `POST`  | `/get_completed_habits` | Récupérer les défis complétés |
| `POST`  | `/socio`                | Enregistrer une donnée socio  |
| `POST`  | `/get_socio`            | Récupérer les données socio   |
| `GET`   | `/families`             | Classement des familles       |

## 🏠 Foyer et localisation

| Méthode | Endpoint                       | Fonction               |
| ------- | ------------------------------ | ---------------------- |
| `POST`  | `/adresse`                     | Ajouter une adresse    |
| `POST`  | `/local`                       | Créer un local         |
| `PUT`   | `/update-local`                | Modifier un local      |
| `GET`   | `/check-local`                 | Vérifier un local      |
| `GET`   | `/get_location/<code_famille>` | Récupérer une position |

## 🔔 Notifications

| Méthode | Endpoint                    | Fonction                           |
| ------- | --------------------------- | ---------------------------------- |
| `POST`  | `/send_invitation`          | Envoyer une invitation             |
| `POST`  | `/invitation_action`        | Traiter une invitation             |
| `GET`   | `/get_notifications`        | Récupérer les notifications        |
| `GET`   | `/get_unread_notifications` | Compter les notifications non lues |
| `POST`  | `/mark_notification_vued`   | Marquer une notification comme lue |

---

# 🗄️ Modèle de données

Les principales données manipulées par l'application sont organisées autour des utilisateurs, familles, logements, consommations et mécanismes de gamification.

```text
                         ┌──────────────┐
                         │   Famille    │
                         └──────┬───────┘
                                │
                ┌───────────────┼───────────────┐
                ▼               ▼               ▼
          ┌──────────┐    ┌──────────┐    ┌──────────┐
          │  Chef    │    │ Membre   │    │  Local   │
          └──────────┘    └──────────┘    └────┬─────┘
                                                │
                                                ▼
                                          ┌──────────┐
                                          │ Adresse  │
                                          └──────────┘

     ┌──────────┐       ┌──────────┐       ┌──────────────┐
     │ Facture  │       │ Habitude │       │ Sociodémo.   │
     └────┬─────┘       └──────────┘       └──────────────┘
          │
          ▼
   Consommation

     ┌──────────┐       ┌──────────┐       ┌──────────────┐
     │  Badge   │       │ Reward   │       │ Notification │
     └──────────┘       └──────────┘       └──────────────┘
```

---

# 🧪 Tests

## Flutter

```bash
cd Water_V0

flutter test
```

## Python

```bash
cd Python

python -m pytest
```

---

# 🗺️ Évolutions envisagées

Les évolutions possibles du projet comprennent :

* [ ] Migration vers **PostGIS** pour les fonctionnalités géospatiales avancées.
* [ ] Tableau de bord analytique pour l'administration.
* [ ] Notifications push avec Firebase Cloud Messaging.
* [ ] Mode hors ligne avec synchronisation.
* [ ] Support multilingue FR / AR / EN.
* [ ] Déploiement du backend sur une plateforme cloud.
* [ ] Authentification à deux facteurs.
* [ ] Génération de rapports PDF.
* [ ] Amélioration de l'analyse automatique des factures.

---

# 🤝 Contribution

Les contributions sont les bienvenues.

```bash
# Créer une branche
git checkout -b feature/my-feature

# Développer et tester

# Commit
git commit -m "feat: add my feature"

# Push
git push origin feature/my-feature
```

Puis ouvrir une Pull Request.

### Convention de commits

Le projet suit une convention inspirée de **Conventional Commits** :

```text
feat:       nouvelle fonctionnalité
fix:        correction d'un bug
docs:       documentation
refactor:   refactorisation
test:       ajout ou modification de tests
style:      formatage
chore:      maintenance
```

---

# 📄 Licence

Projet réalisé dans un cadre **académique et personnel**.

Tous droits réservés © 2026 **BSK-202**.

---

# 👥 Équipe

<div align="center">

### BSK-202

[![GitHub](https://img.shields.io/badge/GitHub-BSK--202-181717?style=for-the-badge\&logo=github)](https://github.com/BSK-202)

</div>

---

<div align="center">

## 🌊 Projet Water

### *Chaque goutte compte.*

</div>
