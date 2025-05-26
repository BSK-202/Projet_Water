import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:water_v0/screens/local_Info.dart';


import 'package:water_v0/screens/recompense.dart';
import 'package:water_v0/screens/user_map_page.dart';
import 'package:water_v0/screens/user_ranking_page.dart';
import 'package:water_v0/screens/video_list_item.dart';
import 'package:water_v0/screens/water_level_indicator.dart';
import 'BottomNavigationBar.dart';
import 'facture_page.dart';
import 'Local.dart';
import 'card.dart' as FeatureCard;
import 'recup_id_famille.dart'; // votre helper getIdUser()

import 'NotificationIcon.dart';
import 'NotificationPage.dart';
import 'InviteMemberPage.dart';
import 'TopNotificationBanner.dart';


class EspaceChef extends StatefulWidget {

 const EspaceChef({super.key, required this.userId});
  final String userId;  @override
  _EspaceChefState createState() => _EspaceChefState();
}

class _EspaceChefState extends State<EspaceChef> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  String? errorMessage;
  int unreadNotifications = 0; // Initial unread notifications count
  int currentIndex = 0; // Index for managing the bottom navigation bar
  String? email = '';
/********************************************** */
// Fetch unread notifications count from the backend
  Future<void> fetchUnreadNotifications() async {
    email = await getIdUSer(); // Ensure email is fetched before making the request
    try {
      final response = await http.get(
        Uri.parse(
          'http://10.0.2.2:5000/get_unread_notifications?userId=${email}',
        ),
      );
      print('UnreadCount Response: ${response.body}'); // Debug log
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        int count = 0;
        if (data["unreadCount"] is int) {
          count = data["unreadCount"];
        } else if (data["unreadCount"] is String) {
          count = int.tryParse(data["unreadCount"]) ?? 0;
        } else {
          print(
            'unreadCount is of unexpected type: ${data["unreadCount"].runtimeType}',
          );
        }

        // If new unread notifications appear, show the banner
        if (count > unreadNotifications) {
          showTopNotification("Vous avez une nouvelle notification !", () {
            Navigator.of(context).pop(); // dismiss banner
            setState(() {
              currentIndex = 3; // or navigate to notification page
            });
          });
        }

        setState(() {
          unreadNotifications = count;
        });
      } else {
        print(
          'Failed to fetch unread notifications (status ${response.statusCode})',
        );
      }
    } catch (e) {
      print('Error fetching unread notifications: $e');
    }
  }
  
void showTopNotification(String message, VoidCallback onTap) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: '',
      transitionDuration: Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.topCenter,
          child: TopNotificationBanner(message: message, onTap: onTap),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: Offset(0, -1),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
      },
    );
  }


/************************************************ */
  @override
  void initState() {
    super.initState();
    _loadUserData();
    fetchUnreadNotifications();// Fetch unread notifications count
  }

  Future<void> _loadUserData() async {
    try {
      email = await getIdUSer(); 
      if (email == null || email== '') {
        setState(() {
          errorMessage = 'Veuillez vous connecter';
          isLoading = false;
        });
        return;
      }

      final uri = Uri.parse('http://10.0.2.2:5000/profile?email=$email');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        setState(() {
          userData = json.decode(response.body) as Map<String, dynamic>;
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
    final chef = userData?['is_chef'] ?? false;
    // Usage d'eau
    final currentUsage = userData?['currentUsage']?.toString() ?? '0';
    final averageUsage = userData?['averageUsage']?.toString() ?? '0';
    final savedPercent = userData?['savedPercent']?.toString() ?? '0';

    // Vidéos Learn & Earn

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── En-tête ─────────────────────────────
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
                    /*decoration: BoxDecoration(
                      //color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),*/
                    child: Row(                    
                    children: [
                      // Notification Icon
                     NotificationIcon(
                      unreadNotifications: unreadNotifications,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NotificationPage(
                              userEmail: email ?? '',
                              isMember: false,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 15),
                     IconButton(
                      icon: Icon(
                        Icons.person_add_alt_1,
                        color: theme.colorScheme.primary,
                      ),
                      tooltip: "Inviter un membre",
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => InviteMemberPage(
                                  chefEmail: email!,
                                ),
                          ),
                        );
                      },
                    ),
                  //  const SizedBox(width: 15),
                    ],
                    )
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ─── Usage d'eau ───────────────────────
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
                        Text('Your Water Usage',
                            style: theme.textTheme.titleLarge
                                ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('This Month',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        WaterLevelIndicator(
                            percentage: double.tryParse(savedPercent)! / 100, size: 100),
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
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // ─── Learn & Earn ───────────────────────
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
                        Text('Watch & earn points',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.w600, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Liste dynamique des vidéos
                VideoListItem(
                  title: 'Introduction to Water Conservation',
                  videoAsset: 'assets/videos/reduce_consumption.mp4',
                  duration: '1:00',
                  points:30,
                  isWatched: true,
                ),
              const SizedBox(height: 30),

              // ─── Explorez nos fonctionnalités ──────
              const Text('Explorez nos fonctionnalités',
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
                    title: 'Recompenses',
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
                    String? userId = await getUserId();

                final response = await http.get(
                  Uri.parse('http://10.0.2.2:5000/check-local?code_famille=$userId'),
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
                                : null,isChef: true,
                          ),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Step1Location()),
                      );
                    }
                  } else {
                    print('Aucun local trouvé');
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Step1Location()),
                    );
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
                              builder: (_) => FacturePage(userId: userData!['id'].toString(), isChef: true,)));
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: 0,
        userId: userData!['id'].toString(),
        isChef: true,
        onTap: (i) {/* à gérer si besoin */},
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
