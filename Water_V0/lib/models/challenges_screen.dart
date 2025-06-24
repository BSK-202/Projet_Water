import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:water_v0/screens/BottomNavigationBar.dart';
import '../models/challenge_provider.dart';
import '../widgets/challenge_card.dart';
import '../screens/challenge_detail_screen.dart';

class ChallengesScreen extends StatelessWidget {
  final String category;
  final bool isChef;
  const ChallengesScreen({
    Key? key,
    required this.category,
    required String userId,
    required this.isChef
  }) : super(key: key);

  String getCategoryTitle(String category) {
    switch (category) {
      case 'habits':
        return 'Consumption Habits Challenges';
      case 'sociodemographic':
        return 'Sociodemographic Challenges';

      default:
        return 'Challenges';
    }
  }

  IconData getCategoryIcon(String category) {
    switch (category) {
      case 'habits':
        return Icons.opacity;
      case 'sociodemographic':
        return Icons.people;

      default:
        return Icons.emoji_events;
    }
  }

  Future<void> _fetchAndUpdateChallenges(BuildContext context) {
    final provider = Provider.of<ChallengeProvider>(context, listen: false);

    // Configuration des deux requêtes en parallèle
    final habitsFuture = http
        .get(Uri.parse('http://127.0.0.1:5000/get_completed_habits'))
        .then((response) => _handleHabitsResponse(response, provider))
        .catchError((e) => _handleHabitsError(e));

    final socioFuture = http
        .get(Uri.parse('http://127.0.0.1:5000/get_socio'))
        .then((response) => _handleSocioResponse(response, provider))
        .catchError((e) => _handleSocioError(e));

    // Exécution parallèle avec gestion du résultat global
    return Future.wait([habitsFuture, socioFuture])
        .then((_) => _handleFinalUpdate(provider))
        .catchError((e) => _handleGlobalError(e));
  }

  // Gestion des réponses
  void _handleHabitsResponse(
    http.Response response,
    ChallengeProvider provider,
  ) {
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      provider.updateChallengesFromAPI(data['habits'], 'habits');
      print('Habitudes mises à jour avec succès');
    } else {
      print('Statut HTTP habitudes: ${response.statusCode}');
    }
  }

  void _handleSocioResponse(
    http.Response response,
    ChallengeProvider provider,
  ) {
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      provider.updateChallengesFromAPI(data['socio'], 'sociodemographic');
      print('Données socio mises à jour avec succès');
    } else {
      print('Statut HTTP socio: ${response.statusCode}');
    }
  }

  // Gestion des erreurs
  void _handleHabitsError(dynamic error) {
    print('Erreur réseau habitudes: $error');
  }

  void _handleSocioError(dynamic error) {
    print('Erreur réseau socio: $error');
  }

  // Finalisation
  void _handleFinalUpdate(ChallengeProvider provider) {
    provider.notifyListeners();
    print('Toutes les mises à jour terminées');
  }

  void _handleGlobalError(dynamic error) {
    print('Erreur globale dans le processus: $error');
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ChallengeProvider>(context);
    final challenges = provider.getChallengesByCategory(category);
    final completedChallenges = challenges.where((c) => c.isCompleted).length;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          getCategoryTitle(category),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Theme.of(context).colorScheme.primary,
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed:
                () => _fetchAndUpdateChallenges(
                  context,
                ), // Récupérer et mettre à jour les défis
          ),
        ],
      ),
      body: Column(
        children: [
          // Category progress
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Theme.of(context).colorScheme.tertiary,
            child: Row(
              children: [
                Icon(
                  getCategoryIcon(category),
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Progress: $completedChallenges/${challenges.length} challenges',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: completedChallenges / challenges.length,
                        backgroundColor: Colors.white,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                        minHeight: 8,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Challenge list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: challenges.length,
              itemBuilder: (context, index) {
                final challenge = challenges[index];
                return ChallengeCard(
                  challenge: challenge,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                ChallengeDetailScreen(challenge: challenge,isChef: isChef,),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
         bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: 1,
        userId: '',
        isChef: isChef,
        onTap: (i) {/* à gérer si besoin */},
      ),
    );
  }
}
