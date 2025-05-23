import openai

def main():
    # Hardcode de la clé (uniquement pour test rapide)
    openai.api_key = "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"

    try:
        # Nouvelle syntaxe v1.0+
        response = openai.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": "Vous êtes un assistant utile."},
                {"role": "user",   "content": "Bonjour, comment ça va aujourd'hui ?"}
            ],
            temperature=0.7,
            max_tokens=150
        )
        reply = response.choices[0].message.content
        print("GPT répond :", reply)

    except Exception as e:
        print("Erreur lors de l'appel API :", e)

if __name__ == "__main__":
    main()
