import 'package:flutter/material.dart';
class Badge {
  final String name;
  final IconData icon;
  final Color color;
  final bool isEarned;
  final bool isLocked;
  final double? progress;

  Badge({
    required this.name,
    required this.icon,
    required this.color,
    required this.isEarned,
    this.isLocked = false,
    this.progress,
  });

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      name: json['name'],
      icon:  badgeIcons[json['name']] ?? Icons.star, // voir ci-dessous
      color: Color(0xFF2E7D32), // ex: '0xFF2E7D32'
      isEarned: json['completed'],
      isLocked: json['is_locked'] ,
      progress: json['progress']?.toDouble(),
    );
  }
}

// Pour convertir le nom d'icône en IconData
Map<String, IconData> badgeIcons = {
  "Goutte d’Entrée": Icons.water_drop,
  "Éco-Doucheur": Icons.shower,
  "Chasseur de Fuites": Icons.plumbing,
  "Jardinier Responsable": Icons.local_florist,
  "Maître du Robinet": Icons.handyman,
  "Champion du Lavage": Icons.local_laundry_service,
  "Collecteur de Pluie": Icons.cloud,
  "Ambassadeur de l’Eau": Icons.public,
  "Zéro Gaspillage": Icons.block,
  "Survivant Économe": Icons.bolt,
  "Gardien de la Nature": Icons.park,
};


