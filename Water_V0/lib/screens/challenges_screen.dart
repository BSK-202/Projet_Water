import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:water_v0/models/challenges_screen.dart';
import 'package:water_v0/screens/recup_id_famille.dart';
import '../models/challenge_provider.dart';
import '../widgets/category_card.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key, required this.isChef}) : super(key: key);
  final bool isChef;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  
String? userId;
  @override
  void initState() {
    super.initState();
    _fetchAndUpdateChallenges(); // Charger les données automatiquement
  }

  Future<void> fetchChallengesFromAPI(BuildContext context, String userId) async {
  final habitsUrl = Uri.parse('http://127.0.0.1:5000/get_completed_habits');
  final socioUrl = Uri.parse('http://127.0.0.1:5000/get_socio');

  try {
    final responses = await Future.wait([
      http.post(habitsUrl, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'user_id': userId})),
      http.post(socioUrl, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'user_id': userId})),
    ]);

    final provider = Provider.of<ChallengeProvider>(context, listen: false);

    // Traitement identique pour les habitudes et les données socio
    void processResponse(http.Response response, String category) {
      if (response.statusCode == 200) {
        print('🔹 Réponse $category : ${response.body}');
        
        final List<dynamic> rawData = category == 'habits' 
            ? jsonDecode(response.body)
            : jsonDecode(response.body)['socio'];

        final List<Map<String, String>> processedData = [];

        for (var i = 0; i < rawData.length; i++) {
          final item = rawData[i] as Map<String, dynamic>;
          processedData.add({
            'id': (item['id']?.toString() ?? '0'), // Conversion sécurisée en String
            'attribut': (item['attribut']?.toString() ?? ''),
            'valeur': (item['valeur']?.toString() ?? ''),
          });
        }

        provider.updateChallengesFromAPI(processedData, category);
      }
    }

    // Appliquer le même traitement aux deux réponses
    processResponse(responses[0], 'habits');
    processResponse(responses[1], 'sociodemographic');

  } catch (e) {
    print('❌ Erreur de récupération des données : $e');
  }
}
  Future<void> _fetchAndUpdateChallenges() async {
    final id = await getIdUSer();
    if (id == null) { /* gestion d’erreur */ return; }
    setState(() {
      userId = id;          // **on stocke** l’id récupéré
    });
    await fetchChallengesFromAPI(context, id);
    setState(() { _isLoading = false; });
  

    try {
      // Appeler fetchChallengesFromAPI pour récupérer et mettre à jour les données
      await fetchChallengesFromAPI(context, id);
    } finally {
      setState(() {
        _isLoading = false; // Fin du chargement
      });
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
            onPressed: _fetchAndUpdateChallenges, // Récupérer et mettre à jour les défis
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(), // Indicateur de chargement
            )
          : SingleChildScrollView(
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
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: Colors.white,
                                    ),
                              ),
                              Text(
                                '${provider.completedChallenges}/${provider.challenges.length}',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: Colors.white,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: provider.overallProgress,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            minHeight: 10,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                  ),
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

                    const SizedBox(height: 16),

                    // Category cards
                    CategoryCard(
                      title: 'Structural Housing',
                      description: 'Information about your home\'s plumbing infrastructure',
                      icon: Icons.home,
                      progress: provider.getCategoryProgress('structural'),
                      count: provider.getChallengesByCategory('structural').length,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChallengesScreen(category: 'structural', userId: '', isChef: widget.isChef),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 12),

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
                            builder: (context) => ChallengesScreen(category: 'habits', userId: '', isChef: widget.isChef),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    CategoryCard(
                      title: 'Sociodemographic',
                      description: 'Information about your household',
                      icon: Icons.people,
                      progress: provider.getCategoryProgress('sociodemographic'),
                      count: provider.getChallengesByCategory('sociodemographic').length,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChallengesScreen(category: 'sociodemographic', userId: '', isChef: widget.isChef),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    CategoryCard(
                      title: 'Consumption Analysis',
                      description: 'Analysis of your water bills and usage patterns',
                      icon: Icons.assessment,
                      progress: provider.getCategoryProgress('consumption'),
                      count: provider.getChallengesByCategory('consumption').length,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChallengesScreen(category: 'consumption', userId: '', isChef: widget.isChef),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
   
    );
  }
}