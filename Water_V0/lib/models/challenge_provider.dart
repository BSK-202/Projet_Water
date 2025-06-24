import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'challenge.dart';
import 'challenge_data.dart';

class ChallengeProvider extends ChangeNotifier {
  List<Challenge> _challenges = allChallenges;
  int _totalPoints = 0;
  int _completedChallenges = 0;

  List<Challenge> get challenges => _challenges;
  int get totalPoints => _totalPoints;
  int get completedChallenges => _completedChallenges;

  void resetChallenges() {
    _challenges = allChallenges.map((challenge) {
      challenge.isCompleted = false;
      challenge.userInput = null; // Défini sur null pour éviter les conflits
      return challenge;
    }).toList();
    _totalPoints = 0;
    _completedChallenges = 0;
    notifyListeners();
  }

  // Récupérer les défis depuis l'API
  Future<void> fetchChallengesFromAPI(BuildContext context, String userId) async {
    final habitsUrl = Uri.parse('http://127.0.0.1:5000/get_completed_habits');
    final socioUrl = Uri.parse('http://127.0.0.1:5000/get_socio');

    try {
      final responses = await Future.wait([
        http.post(habitsUrl, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'user_id': userId})),
        http.post(socioUrl, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'user_id': userId})),
      ]);

      // Traitement des habitudes
      final habitsResponse = responses[0];
      if (habitsResponse.statusCode == 200) {
        final List<dynamic> habitsData = jsonDecode(habitsResponse.body); // <-- OK, c'est une liste
        final List<Map<String, String>> completedHabits = [];

        for (final habit in habitsData) {
          completedHabits.add({
            'id': habit['id'].toString(),
            'attribut': habit['attribut'].toString(),
            'valeur': habit['valeur'].toString(),
          });
        }
        print('🔹 Habits récupérés : $completedHabits');
        updateChallengesFromAPI(completedHabits, 'habits');
      } else {
        print('❌ Erreur API Habits : ${habitsResponse.statusCode}');
      }

      // Traitement des données socio
      final socioResponse = responses[1];
      if (socioResponse.statusCode == 200) {
        final Map<String, dynamic> socioData = jsonDecode(socioResponse.body); // <-- ici, c'est un map
        final List<dynamic> socioList = socioData['socio'];
        final List<Map<String, String>> completedSocio = [];

        for (final socio in socioList) {
          completedSocio.add({
            'id': socio['id'].toString(),
            'attribut': socio['attribut'].toString(),
            'valeur': socio['valeur'].toString(),
          });
        }
        print('🔹 Socio récupérés : $completedSocio');
        updateChallengesFromAPI(completedSocio, 'sociodemographic');
      } else {
        print('❌ Erreur API Socio : ${socioResponse.statusCode}');
      }
    } catch (e) {
      print('❌ Erreur de récupération des données : $e');
    }
  }

  void updateChallengesFromAPI(List<Map<String, String>> completedChallenges, String category) {
    int updatedCompletedChallenges = 0;
    int updatedTotalPoints = 0;

    for (var challenge in completedChallenges) {
      final id = challenge["id"];
      final value = challenge["valeur"];
      final index = _challenges.indexWhere((c) => c.id == id && c.category == category);
      if (index != -1 && !_challenges[index].isCompleted) { // Vérifie si le défi n'est pas déjà complété
        _challenges[index].isCompleted = true;
        _challenges[index].userInput = value;
        updatedCompletedChallenges++;
        updatedTotalPoints += _challenges[index].points;

        print('🔹 Défi mis à jour : ${_challenges[index]}');
      } else if (index == -1) {
        print('⚠️ Défi non trouvé pour id: $id et catégorie: $category');
      }
    }

    // Mettre à jour les totaux
    _completedChallenges += updatedCompletedChallenges;
    _totalPoints += updatedTotalPoints;

    notifyListeners();
  }

  // Obtenir les défis par catégorie
  List<Challenge> getChallengesByCategory(String category) {
    final challenges = _challenges.where((challenge) => challenge.category == category).toList();
    print('🔹 Défis pour la catégorie $category : $challenges');
    return challenges;
  }

  // Mettre à jour un défi spécifique
  void updateChallenge(String id, String value) {
    final index = _challenges.indexWhere((challenge) => challenge.id == id);
    if (index != -1) {
      final challenge = _challenges[index];
      if (!challenge.isCompleted) {
        challenge.userInput = value;
        challenge.isCompleted = true;
        _totalPoints += challenge.points;
        _completedChallenges++;
        print('🔹 Défi complété : $challenge');
        notifyListeners();
      }
    } else {
      print('⚠️ Défi non trouvé pour id: $id');
    }
  }

  // Progression par catégorie
  double getCategoryProgress(String category) {
    final categoryChallenges = getChallengesByCategory(category);
    if (categoryChallenges.isEmpty) return 0.0;

    final completed = categoryChallenges.where((c) => c.isCompleted).length;
    final progress = completed / categoryChallenges.length;
    print('🔹 Progression pour $category : $progress');
    return progress;
  }

  double get overallProgress {
    final int maxChallenges = 16; // Définir le maximum de défis
    final int totalChallenges = _challenges.length > maxChallenges ? maxChallenges : _challenges.length;
    final progress = _completedChallenges / totalChallenges;
    print('🔹 Progression globale ajustée : $progress');
    return progress > 1.0 ? 1.0 : progress; // Limiter à 100 %
  }
}