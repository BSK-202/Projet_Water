import 'package:flutter/material.dart';

class Step2Location extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  final bool canProceed;

  const Step2Location({Key? key, required this.onNext, required this.onBack, required this.canProceed})
      : super(key: key);

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
                'Localisation',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Veuillez entrer votre adresse et autoriser la localisation GPS pour une précision accrue.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // Champ Adresse
              TextField(
                decoration: InputDecoration(
                  hintText: 'Adresse',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Bouton Rechercher GPS
              ElevatedButton.icon(
                onPressed: () {
                  // Logique pour activer la localisation GPS
                },
                icon: const Icon(Icons.location_on),
                label: const Text('Utiliser ma position actuelle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Boutons de navigation
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                    onPressed: onBack,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      side: BorderSide(color: Colors.grey.shade300),
                      minimumSize: const Size(120, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Retour'),
                  ),
                  ElevatedButton(
                    onPressed: canProceed ? onNext : null,
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}