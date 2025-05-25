import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:water_v0/screens/local_Info.dart';

import 'package:water_v0/screens/neighborMap.dart';
import 'package:water_v0/screens/recompense.dart';
import 'package:water_v0/screens/user_map_page.dart';
import 'package:water_v0/screens/video_list_item.dart';
import 'package:water_v0/screens/water_level_indicator.dart';
import 'BottomNavigationBar.dart';
import 'facture_page.dart';
import 'Local.dart';
import 'card.dart' as FeatureCard;
import 'recup_id_famille.dart';

class EspaceMembre extends StatefulWidget {
  const EspaceMembre({super.key, required this.userId});
  final String userId;

  @override
  _EspaceMembreState createState() => _EspaceMembreState();
}

class _EspaceMembreState extends State<EspaceMembre> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  String? errorMessage;
  bool hasFamily = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final email = await getIdUSer();
      
      if (email == null || email.isEmpty) {
        setState(() {
          errorMessage = 'Veuillez vous connecter';
          isLoading = false;
        });
        return;
      }

      final uri = Uri.parse('http://10.0.2.2:5000/profile?email=$email');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        setState(() {
          userData = data;
          hasFamily = data['id_famille'] != null && data['id_famille'].toString().isNotEmpty;
          print('User data: $userData');
          print('Has family: $hasFamily');
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Erreur serveur ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Erreur de connexion : $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (errorMessage != null) {
      return Scaffold(
        body: Center(child: Text(errorMessage!)),
      );
    }

    final prenom = userData?['prenom'] ?? '';
    final nom = userData?['nom'] ?? '';
    final fullName = '$prenom $nom'.trim();
    final avatarUrl = userData?['avatar'] as String? ?? 'assets/default_avatar.png';
    final waterPoints = userData?['score']?.toString() ?? '0';
    final currentUsage = userData?['currentUsage']?.toString() ?? '0';
    final averageUsage = userData?['averageUsage']?.toString() ?? '0';
    final savedPercent = userData?['savedPercent']?.toString() ?? '0';
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: theme.colorScheme.primary,
                        child: CircleAvatar(
                          radius: 22,
                          backgroundImage: avatarUrl.startsWith('http')
                              ? NetworkImage(avatarUrl)
                              : AssetImage(avatarUrl) as ImageProvider,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(fullName, style: theme.textTheme.titleLarge),
                          Row(
                            children: [
                              Icon(Icons.water_drop, color: theme.colorScheme.primary, size: 16),
                              const SizedBox(width: 4),
                              Text('$waterPoints Water Points', style: theme.textTheme.bodyMedium),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      color: theme.colorScheme.primary,
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
  // Section Usage d'eau
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Votre consommation',
                                style: theme.textTheme.titleLarge
                                    ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text('Ce mois-ci',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (hasFamily) ...[
                        Row(
                          children: [
                            WaterLevelIndicator(
                                percentage: (userData?['savedPercent'] ?? 0) / 100,
                                size: 100),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              _buildUsageRow(context, 'Current: $currentUsage m³',
                                  Icons.water_drop_outlined, Colors.white),
                              const SizedBox(height: 8),
                              _buildUsageRow(
                                  context, 'Average: $averageUsage m³', Icons.people_outline, Colors.white),
                              const SizedBox(height: 8),
                              _buildUsageRow(
                                  context, 'You saved $savedPercent%', Icons.trending_down, Colors.white),
                            ],
                              ),
                            ),
                          ],
                        ),
                      ]],
                    ),
                  ),
                const SizedBox(height: 30),

                // Section Learn & Earn
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Learn & Earn', style: theme.textTheme.headlineMedium),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.tertiary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.play_circle_outline,
                              color: theme.colorScheme.primary, size: 16),
                          const SizedBox(width: 4),
                          Text('Regardez & gagnez',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w600, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                   VideoListItem(
                  title: 'Introduction aux économies d\'eau',
                  videoAsset: 'assets/videos/reduce_consumption.mp4',
                  duration: '1:00',
                  points:30,
                  isWatched: true,
                ),
                const SizedBox(height: 30),
              // Contenu conditionnel
              if (hasFamily) ...[
              
             

                // Section Fonctionnalités
                const Text('Fonctionnalités',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 1.1,
                  children: [
                    FeatureCard.FeatureCard(
                      icon: Icons.star,
                      title: 'Récompenses',
                      color: theme.colorScheme.primary,
                      onTap: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const RewardsPage()));
                      },
                    ),
                    FeatureCard.FeatureCard(
                      icon: Icons.bar_chart_rounded,
                      title: 'Statistiques',
                      color: theme.colorScheme.secondary,
                      onTap: () {
                        Navigator.push(
                            context, MaterialPageRoute(builder: (_) => const UserMapPage()));
                      },
                    ),
                     FeatureCard.FeatureCard(
                    icon: Icons.house,
                    title: 'Local',
                    color: theme.colorScheme.tertiary,
                    onTap: () async {
                     try {
                  
                     print('ID Famille: ${userData!['id_famille']}');
                      // Vérification de l'ID de la famille
                      if (userData!['id_famille'] == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Aucune famille associée')),
                        );
                        return;
                      }
                      
                      // Appel à l'API pour vérifier le local
                final response = await http.get(
                  Uri.parse('http://10.0.2.2:5000/check-local?code_famille=${userData!['id_famille']}'),
                );

                if (response.statusCode == 200) {
                  final data = json.decode(response.body);
                  final hasLocal = data['has_local'] ?? false;

                  if (hasLocal) {
                    print('Local trouvé: $hasLocal');
                    
                    // Debug: afficher la structure des données reçues
                    print('Données reçues: ${data['local']}');
                    
                    // Gestion robuste des données
                    dynamic localData = data['local'];
                    
                    if (localData != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LocalFamilleScreen(
                            initialLocalData: localData is Map<String, dynamic> 
                                ? localData 
                                : null,isChef: false,
                          ),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Step1Location()),
                      );
                    }
                  } 
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur serveur: ${response.statusCode}')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur: ${e.toString()}')),
                );
             }
                  
                    },
                  ),
                    FeatureCard.FeatureCard(
                      icon: Icons.receipt,
                      title: 'Facture',
                      color: Colors.amber[700]!,
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => FacturePage(userId: userData!['id'].toString(), isChef: false,)));
                      },
                    ),
                  ],
                ),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Column(
                      children: [
                        Text(
                          'Vous devez être associé à une famille\npour accéder aux fonctionnalités complètes',
                          style: theme.textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        FeatureCard.FeatureCard(
                          icon: Icons.group_add,
                          title: 'Rejoindre une famille',
                          color: theme.colorScheme.primary,
                          onTap: () {
                            Navigator.push(context,
                                MaterialPageRoute(builder: (_) => Step1Location()));
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: 0,
        userId: userData?['id']?.toString() ?? '',
        isChef:false,
        onTap: (i) {},
      ),
    );
  }

  Widget _buildUsageRow(
          BuildContext context, String text, IconData icon, Color color) =>
      Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
        ],
      );
}