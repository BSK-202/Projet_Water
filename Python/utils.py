from flask import session

def get_session():
    """Retourne l'objet session global."""
    return session