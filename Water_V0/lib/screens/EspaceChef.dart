import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:water_v0/screens/neighborMap.dart';
import 'package:water_v0/screens/recompense.dart';
import 'Local.dart';
import 'login_screen.dart'; // For logout redirection
import 'card.dart' as FeatureCard;
import 'NotificationIcon.dart';
import 'NotificationPage.dart';
import 'InviteMemberPage.dart';
import 'TopNotificationBanner.dart';

// EspaceChef (Home) page
class EspaceChef extends StatefulWidget {
  const EspaceChef({super.key, required this.userId, required this.userEmail});
  final String userId;
  final String userEmail;

  @override
  _EspaceChefState createState() => _EspaceChefState();
  
}

class _EspaceChefState extends State<EspaceChef> {
  int unreadNotifications = 0; // Initial unread notifications count
  int currentIndex = 0; // Index for managing the bottom navigation bar

  // Fetch unread notifications count from the backend
  Future<void> fetchUnreadNotifications() async {
    try {
      final response = await http.get(
        Uri.parse(
          'http://localhost:5000/get_unread_notifications?userId=${widget.userEmail}',
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

  @override
  void initState() {
    super.initState();
    fetchUnreadNotifications();
  }

  Widget _buildMainContent(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with logo and notification icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'EcoApp',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Row(
                  children: [
                    // Notification Icon
                    NotificationIcon(
                      unreadNotifications: unreadNotifications,
                      onTap: () {
                        setState(() {
                          currentIndex = 3;
                        });
                      },
                    ),
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
                                  chefEmail: widget.userEmail,
                                ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 15),
                    // Logout Icon
                    GestureDetector(
                      onTap: () {
                        // Redirect to the login page on tap
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      child: CircleAvatar(
                        backgroundColor: theme.colorScheme.primary.withOpacity(
                          0.1,
                        ),
                        radius: 24,
                        child: Icon(
                          Icons.exit_to_app, // Logout Icon
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Welcome Message
            Text(
              'Bonjour,',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bienvenue dans votre\nespace Chef',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 40),

            // Main Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.eco_outlined,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 15),
                      const Expanded(
                        child: Text(
                          'Commencez votre parcours écologique',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Découvrez comment réduire votre impact environnemental au quotidien',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Commencer',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Section Title
            const Text(
              'Explorez nos fonctionnalités',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Feature Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 1.1,
              children: [
                FeatureCard.FeatureCard(
                  icon: Icons.water_drop_outlined,
                  title: 'Recompenses',
                  color: theme.colorScheme.primary,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => RewardsPage()),
                    );
                  },
                ),
                FeatureCard.FeatureCard(
                  icon: Icons.bar_chart_rounded,
                  title: 'Statistiques',
                  color: theme.colorScheme.secondary,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MapUsers()),
                    );
                  },
                ),
                FeatureCard.FeatureCard(
                  icon: Icons.lightbulb_outline,
                  title: 'Conseils',
                  color: theme.colorScheme.tertiary,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Step1Location()),
                    );
                  },
                ),
                FeatureCard.FeatureCard(
                  icon: Icons.settings_outlined,
                  title: 'Paramètres',
                  color: Colors.amber[700]!,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child:
            currentIndex == 3
                ? NotificationPage(userEmail: widget.userEmail)
                : _buildMainContent(context),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Accueil',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            label: 'Explorer',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profil',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.notifications),
                if (unreadNotifications > 0) // Show red badge only if count > 0
                  Positioned(
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$unreadNotifications',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Notifications',
          ),
        ],
        currentIndex: currentIndex,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
          if (index == 3) {
            fetchUnreadNotifications();
          }
        },
      ),
    );
  }
}
