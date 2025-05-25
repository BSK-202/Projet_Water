import 'package:flutter/material.dart';
import 'challenge.dart';
import 'challenge_data.dart';

class ChallengeProvider extends ChangeNotifier {
  final List<Challenge> _challenges = allChallenges;
  int _totalPoints = 0;
  int _completedChallenges = 0;

  List<Challenge> get challenges => _challenges;
  int get totalPoints => _totalPoints;
  int get completedChallenges => _completedChallenges;

  List<Challenge> getChallengesByCategory(String category) {
    return _challenges.where((challenge) => challenge.category == category).toList();
  }

  void updateChallenge(String id, String value) {
    final index = _challenges.indexWhere((challenge) => challenge.id == id);
    if (index != -1) {
      final challenge = _challenges[index];
      if (!challenge.isCompleted) {
        challenge.userInput = value;
        challenge.isCompleted = true;
        _totalPoints += challenge.points;
        _completedChallenges++;
        notifyListeners();
      }
    }
  }

  double getCategoryProgress(String category) {
    final categoryChallenges = getChallengesByCategory(category);
    if (categoryChallenges.isEmpty) return 0.0;
    
    final completed = categoryChallenges.where((c) => c.isCompleted).length;
    return completed / categoryChallenges.length;
  }

  double get overallProgress {
    if (_challenges.isEmpty) return 0.0;
    return _completedChallenges / _challenges.length;
  }
}

