import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
// Assurez-vous que ce fichier est importé pour la redirection

class Step1AccountType extends StatelessWidget {
  final bool? isChef;
  final VoidCallback onNext;
  final Function(bool) onSelected;
  final bool canProceed;
  final VoidCallback onSkipToStep3; // Callback pour sauter à l'étape 3
  final VoidCallback onBackToLogin; // Callback pour retourner à la page de login

  const Step1AccountType({
    super.key,
    required this.isChef,
    required this.onNext,
    required this.onSelected,
    required this.canProceed,
    required this.onSkipToStep3,
    required this.onBackToLogin, // Ajouter ce callback dans le constructeur
  });

  Future<void> _sendSelection(bool isChef) async {
    final url = Uri.parse("http://127.0.0.1:5000/selection"); // URL du serveur Flask

    final Map<String, dynamic> selectionData = {
      "isChef": isChef,
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(selectionData),
      );

      if (response.statusCode == 200) {
        print("Données envoyées avec succès : ${response.body}");
      } else {
        print("Erreur : ${response.body}");
      }
    } catch (e) {
      print("Erreur réseau : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Êtes-vous chef de famille ?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Le chef de famille a accès à toutes les fonctionnalités de l\'application et peut inviter d\'autres membres.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // Option Chef de famille
              _buildSelectionCard(
                title: 'Je suis chef de famille',
                subtitle: 'J\'ai une facture à scanner',
                icon: Icons.check_circle_outline,
                color: const Color(0xFF2E7D32),
                isSelected: isChef == true,
                onTap: () {
                  onSelected(true);
                },
              ),

              const SizedBox(height: 12),

              // Option Membre de famille
              _buildSelectionCard(
                title: 'Je suis membre de famille',
                subtitle: 'Je n\'ai pas de facture à scanner',
                icon: Icons.people_outline,
                color: const Color(0xFF26A69A),
                isSelected: isChef == false,
                onTap: () {
                  onSelected(false);
                },
              ),

              const SizedBox(height: 24),

              // Bouton Continuer
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: canProceed
                      ? () async {
                    if (isChef != null) {
                      await _sendSelection(isChef!); // Envoyer les données
                      onNext(); // Passer à l'étape suivante
                    }
                  }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    minimumSize: const Size(120, 45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Continuer'),
                ),
              ),

              const SizedBox(height: 16),

              // Bouton Retour vers la page de connexion
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: onBackToLogin, // Appeler la fonction de retour
                  child: const Text(
                    'Retour à la connexion',
                    style: TextStyle(
                      color: Color(0xFF2E7D32),
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: color,
              ),
          ],
        ),
      ),
    );
  }
}
