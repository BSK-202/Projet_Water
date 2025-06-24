import smtplib
from email.message import EmailMessage

def envoyer_email(expediteur, mot_de_passe, destinataire, sujet, message):
    # Créer le message
    email = EmailMessage()
    email['From'] = expediteur
    email['To'] = destinataire
    email['Subject'] = sujet
    email.set_content(message)

    # Connexion au serveur SMTP de Gmail
    try:
        with smtplib.SMTP_SSL('smtp.gmail.com', 465) as smtp:
            smtp.login(expediteur, mot_de_passe)
            smtp.send_message(email)
            print("Email envoyé avec succès !")
    except Exception as e:
        print("Erreur lors de l'envoi de l'email :", e)

# Bloc d'exécution principale
if __name__ == "__main__":
    envoyer_email(
        expediteur="fadmajadda2003@gmail.com",
        mot_de_passe="mkcf lswp zxyn qglw",
        destinataire="baskaneikrame1@gmail.com",
        sujet="Test Python",
        message="Bonjour, ceci est un message envoyé depuis Python !"
    )
