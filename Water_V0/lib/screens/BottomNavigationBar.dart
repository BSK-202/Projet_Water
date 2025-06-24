import 'package:flutter/material.dart';
import 'package:water_v0/screens/EspaceChef.dart';
import 'package:water_v0/screens/EspaceMembre.dart';
import 'package:water_v0/screens/badges_screen.dart';
import 'package:water_v0/screens/home_screen.dart';
import 'package:water_v0/screens/profil.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final String userId;
  final bool isChef;
  final Function(int) onTap;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.userId,
    required this.isChef,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BottomNavigationBar(
      items: [
        BottomNavigationBarItem(
          icon: Icon(
            currentIndex == 0 ? Icons.home_rounded : Icons.home_outlined,
          ),
          label: 'Accueil',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            currentIndex == 1 
              ? Icons.emoji_events 
              : Icons.emoji_events_outlined,
            size: 24,
          ),
          label: 'Challenge',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            currentIndex == 2 
              ? Icons.military_tech 
              : Icons.military_tech_outlined,
          ),
          label: 'Badge',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            currentIndex == 3 ? Icons.person : Icons.person_outline,
          ),
          label: 'Profil',
        ),
      ],
      currentIndex: currentIndex,
      selectedItemColor: theme.colorScheme.primary,
      unselectedItemColor: Colors.grey,
      selectedLabelStyle: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 12,
      ),
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      onTap: (index) {
        if (index == currentIndex) return;
        
        switch (index) {
          case 0:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
               
              builder: (context) {
                if (isChef) {
                  return EspaceChef(userId: userId);
                } else {
                  return EspaceMembre(userId: userId);
                }
              },               
              ),
            );
            break;
          case 1:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomeScreen(isChef: isChef), // Remplacez par HomeScreen(),
              ),
            );
            break;
          case 2:
            // Remplacez par votre écran de badges si disponible
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => BadgesScreen(isChef: isChef), // À remplacer par BadgesScreen()
              ),
            );
            break;
          case 3:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ProfilePage(userId: userId),
              ),
            );
            break;
        }
        onTap(index);
      },
    );
  }
}