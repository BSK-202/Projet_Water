import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:water_v0/models/challenges_screen.dart';
import 'package:water_v0/screens/recup_id_famille.dart';
import '../models/challenge_provider.dart';
import '../widgets/category_card.dart';
import 'package:water_v0/screens/BottomNavigationBar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key, required this.isChef}) : super(key: key);
  final bool isChef;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? userId;

  @override
  void initState() {
    super.initState();
    _loadUserIdAndFetchChallenges();
  }

  Future<void> _loadUserIdAndFetchChallenges() async {
    userId = await getIdUSer();
    await _fetchAndUpdateChallenges();
  }

  Future<void> _fetchAndUpdateChallenges() async {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur : Utilisateur non identifié'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // URLs des API
    final habitsUrl = Uri.parse('http://127.0.0.1:5000/get_completed_habits');
    final socioUrl = Uri.parse('http://127.0.0.1:5000/get_socio');

    try {
      // Exécuter les deux requêtes en parallèle
      final responses = await Future.wait([
        http.post(
          habitsUrl,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'user_id': userId}),
        ),
        http.post(
          socioUrl,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'user_id': userId}),
        ),
      ]);

      // Accéder au Provider
      final provider = Provider.of<ChallengeProvider>(context, listen: false);

      // Traiter la réponse pour les habitudes
      final habitsResponse = responses[0];
      if (habitsResponse.statusCode == 200) {
        final habitsData = jsonDecode(habitsResponse.body);
        if (habitsData is List) {
          final completedHabits =
              habitsData
                  .map((habit) {
                    return {
                      "id": habit["id"].toString(),
                      "attribut": habit["attribut"].toString(),
                      "valeur": habit["valeur"].toString(),
                    };
                  })
                  .toList()
                  .cast<Map<String, String>>();
          provider.updateChallengesFromAPI(completedHabits, 'habits');
        }
      }

      // Traiter la réponse pour les socio-démographiques
      final socioResponse = responses[1];
      final socioData = jsonDecode(socioResponse.body);
      if (socioData is List) {
        final List<Map<String, String>> completedSocio = [];
        for (var socio in socioData) {
          try {
            completedSocio.add({
              "id": socio["id"].toString(),
              "attribut": socio["attribut"].toString(),
              "valeur": socio["valeur"].toString(),
            });
          } catch (e) {
            print('Erreur sur une entrée socio: $e');
          }
        }
        provider.updateChallengesFromAPI(completedSocio, 'sociodemographic');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ChallengeProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Water Challenge',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            color: Theme.of(context).colorScheme.primary,
            onPressed: _fetchAndUpdateChallenges,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress overview
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Your Progress',
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(color: Colors.white),
                        ),
                        Text(
                          '${provider.completedChallenges}/${provider.challenges.length > 16 ? 16 : provider.challenges.length}',
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: provider.overallProgress,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                      minHeight: 10,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              '${provider.totalPoints} points',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${(provider.overallProgress * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Challenge Categories',
                style: Theme.of(context).textTheme.titleLarge,
              ),

              const SizedBox(height: 50),

              CategoryCard(
                title: 'Consumption Habits',
                description: 'Your daily water usage behaviors',
                icon: Icons.opacity,
                progress: provider.getCategoryProgress('habits'),
                count: provider.getChallengesByCategory('habits').length,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => ChallengesScreen(
                            category: 'habits',
                            userId: userId ?? '',
                            isChef: widget.isChef,
                          ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 50),

              CategoryCard(
                title: 'Sociodemographic',
                description: 'Information about your household',
                icon: Icons.people,
                progress: provider.getCategoryProgress('sociodemographic'),
                count:
                    provider.getChallengesByCategory('sociodemographic').length,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => ChallengesScreen(
                            category: 'sociodemographic',
                            userId: userId ?? '',
                            isChef: widget.isChef,
                          ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: 1,
        userId: userId ?? '',
        isChef: widget.isChef,
        onTap: (index) {},
      ),
    );
  }
}
