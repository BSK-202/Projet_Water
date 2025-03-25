import os

# Générer une clé aléatoire de 24 octets
secret_key = os.urandom(24)

# Convertir en chaîne hexadécimale pour l'utiliser dans Flask
secret_key_hex = secret_key.hex()
print(secret_key_hex)
