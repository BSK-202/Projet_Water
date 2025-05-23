import 'package:flutter/material.dart';

class Step2ChooseAvatar extends StatelessWidget {
  final String? selectedAvatar;
  final Function(String) onAvatarSelected;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final bool canProceed;

  Step2ChooseAvatar({
    required this.selectedAvatar,
    required this.onAvatarSelected,
    required this.onNext,
    required this.onBack,
    required this.canProceed,
  });

  final List<String> avatarPaths = [
    'assets/avatar1.png',
    'assets/avatar2.png',
    'assets/avatar3.png',
    'assets/avatar4.png',
    'assets/avatar5.png',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choisissez votre avatar',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              mainAxisSpacing: 15,
              crossAxisSpacing: 15,
              children: avatarPaths.map((path) {
                final isSelected = selectedAvatar == path;
                return GestureDetector(
                  onTap: () => onAvatarSelected(path),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? Colors.green : Colors.transparent,
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Image.asset(path),
                  ),
                );
              }).toList(),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: onBack,
                child: const Text('Retour'),
              ),
              ElevatedButton(
                onPressed: canProceed ? onNext : null,
                child: const Text('Suivant'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}