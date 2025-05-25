import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/challenge_provider.dart';
import '../widgets/challenge_card.dart';
import '../screens/challenge_detail_screen.dart';

class ChallengesScreen extends StatelessWidget {
  final String category;
  
  const ChallengesScreen({
    super.key,
    required this.category,
  });

  String getCategoryTitle(String category) {
    switch (category) {
      case 'structural':
        return 'Structural Housing Challenges';
      case 'habits':
        return 'Consumption Habits Challenges';
      case 'sociodemographic':
        return 'Sociodemographic Challenges';
      case 'consumption':
        return 'Consumption Analysis Challenges';
      default:
        return 'Challenges';
    }
  }

  IconData getCategoryIcon(String category) {
    switch (category) {
      case 'structural':
        return Icons.home;
      case 'habits':
        return Icons.opacity;
      case 'sociodemographic':
        return Icons.people;
      case 'consumption':
        return Icons.assessment;
      default:
        return Icons.emoji_events;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ChallengeProvider>(context);
    final challenges = provider.getChallengesByCategory(category);
    final completedChallenges = challenges.where((c) => c.isCompleted).length;
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
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
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: completedChallenges / challenges.length,
                        backgroundColor: Colors.white,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
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
                        builder: (context) => ChallengeDetailScreen(challenge: challenge),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

