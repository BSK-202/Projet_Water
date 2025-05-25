import 'package:flutter/material.dart';
import 'package:water_v0/models/Badge.dart' as customBadge;
import 'package:water_v0/screens/BottomNavigationBar.dart';
import 'package:water_v0/widgets/badge_item.dart';
import 'package:water_v0/widgets/fecthBadge.dart';



class BadgesScreen extends StatefulWidget {
  const BadgesScreen({Key? key}) : super(key: key);

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> {
  late Future<List<customBadge.Badge>> _futureBadges;

  @override
  void initState() {
    super.initState();
    _futureBadges = fetchUserBadges();
  }

 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text('Your Badges', style: Theme.of(context).textTheme.headlineMedium),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<List<customBadge.Badge>>(
       
        future: _futureBadges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
             return Center(child: Text("Oops! : ${snapshot.error}"));
          }

          final earned = snapshot.data!.where((b) => b.isLocked == false && b.isEarned==true).toList();
          
          final locked = snapshot.data!.where((b) => b.isLocked== true || (b.progress == null)).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Statistiques
                _buildStats(context, earned.length, snapshot.data!.length),

                const SizedBox(height: 20),
                _buildBadgeSection(context, "Earned Badges", earned),
                
                _buildBadgeSection(context, "Locked Badges", locked),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: 2,
        userId: '',
        isChef: true,
        onTap: (i) {/* à gérer si besoin */},
      ),
    );
  }

  Widget _buildStats(BuildContext context, int earned, int total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatColumn(context, '$earned', 'Earned'),
          _buildDivider(),
          _buildStatColumn(context, '$total', 'Available'),
          _buildDivider(),
          _buildStatColumn(context, '4', 'Rare'), // Tu peux calculer le vrai nombre rare ici
        ],
      ),
    );
  }

  Widget _buildBadgeSection(BuildContext context, String title, List<customBadge.Badge> badges) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 1,
          mainAxisSpacing: 16,
          children: badges.map((badge) {
            return BadgeItem(
              name: badge.name,
              icon: badge.icon,
              color: badge.isLocked ?  const Color(0xFF78909C):const Color(0xFF2E7D32) ,
              isEarned: badge.isEarned,
              progress: badge.progress ?? 0,
              isLocked: badge.isLocked || (badge.progress == null),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStatColumn(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }

  Widget _buildDivider() => Container(height: 40, width: 1, color: Colors.grey.withOpacity(0.3));
}
