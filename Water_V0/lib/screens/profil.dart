import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:water_v0/screens/login_screen.dart';
import 'dart:convert';
import 'recup_id_famille.dart';
import 'BottomNavigationBar.dart'; // Import du fichier
import 'edit_profile_page.dart';


class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required String userId});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      String? email = await getIdUSer();
      if (email == null || email.isEmpty) {
        setState(() {
          errorMessage = 'Veuillez vous connecter';
          isLoading = false;
        });
        return;
      }
      
      final response = await http
          .get(Uri.parse('http://127.0.0.1:5000/profile?email=$email'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        setState(() {
          userData = json.decode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Erreur serveur: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Erreur de connexion: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Text(errorMessage!)),
      );
    }

    final fullName = '${userData?['prenom'] ?? ''} ${userData?['nom'] ?? ''}'.trim();
    final avatarPath = userData?['avatar'] ?? 'assets/default_avatar.png';
    final isChef = userData?['isChef'] ?? false;
    final userId = userData?['id'] ?? ''; // Assurez-vous que l'id utilisateur est bien présent

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // En-tête du profil
            Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: AssetImage(avatarPath),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      fullName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.military_tech,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Score: ${userData?['score'] ?? 0}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isChef)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Chef',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Famille
                  if (userData?['nomFamille'] != null)
                    _buildFamilySection(context),
                  
                  const SizedBox(height: 24),
                  
                  // Section Habitudes
                  _buildHabitsSection(context),
                  
                  const SizedBox(height: 24),
                  
                  // Section Socio-démographique
                  _buildSocioSection(context),
                  
                  const SizedBox(height: 24),
                  
                  // Paramètres
                  _buildSettingsSection(context),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: 3,
        userId: userId,
        isChef: isChef,
        onTap: (index) {
          if (index == 0) {
            // Remplacez '/home' par le nom de la route de votre page d'accueil si besoin
            Navigator.pushReplacementNamed(context, '/home', arguments: {'userId': userId});
          }
          // Ajoutez ici la logique pour les autres index si nécessaire
        },
      ),
    );
  }

  Widget _buildFamilySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Famille',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              if (userData?['scoreFamille'] != null)
                _buildInfoRow(
                  context,
                  'Family Score',
                  userData!['scoreFamille'].toString(),
                  Icons.family_restroom,
                ),
              if (userData?['waterSaved'] != null) ...[
                const Divider(),
                _buildInfoRow(
                  context,
                  'Water Saved',
                  "${userData!['waterSaved']}%",
                  Icons.trending_down,
                ),
              ],
                if (userData?['score'] != null) ...[
                const Divider(),
                _buildInfoRow(
                  context,
                  'Challenges',
                   userData!['challenge'].toString(),
                  Icons.emoji_events,
                ),
              ],
               if (userData?['scoreFamille'] != null) ...[
                const Divider(),
                _buildInfoRow(
                  context,
                  'Badges',
                  "12",
                  Icons.military_tech,
                ),
              ],
               if (userData?['score'] != null) ...[
                const Divider(),
                _buildInfoRow(
                  context,
                  'your score',
                  "${userData!['score']}",
                  Icons.water_drop,
                ),
              ],
            
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHabitsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Habitudes',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              if (userData?['dureeDouches'] != null)
                _buildInfoRow(
                  context,
                  'Durée moyenne des douches (min)',
                  userData!['dureeDouches'].toString(),
                  Icons.timer,
                ),
              if (userData?['douchesSemaine'] != null) ...[
                const Divider(),
                _buildInfoRow(
                  context,
                  'Douches par semaine',
                  userData!['douchesSemaine'].toString(),
                  Icons.shower,
                ),
              ],
              if (userData?['bainsMois'] != null) ...[
                const Divider(),
                _buildInfoRow(
                  context,
                  'Bains par mois',
                  userData!['bainsMois'].toString(),
                  Icons.bathtub,
                ),
              ],
              if (userData?['consommationCuisine'] != null) ...[
                const Divider(),
                _buildInfoRow(
                  context,
                  'Consommation cuisine',
                  userData!['consommationCuisine'].toString(),
                  Icons.kitchen,
                ),
              ],
              if (userData?['freqToilettes'] != null) ...[
                const Divider(),
                _buildInfoRow(
                  context,
                  'Fréquence vidange toilettes',
                  userData!['freqToilettes'].toString(),
                  Icons.wc,
                ),
              ],
              if (userData?['freqLaveLinge'] != null) ...[
                const Divider(),
                _buildInfoRow(
                  context,
                  'Fréquence lave-linge',
                  userData!['freqLaveLinge'].toString(),
                  Icons.local_laundry_service,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSocioSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profil socio-démographique',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              if (userData?['email'] != null)
                _buildInfoRow(
                  context,
                  'Email',
                  userData!['email'].toString(),
                  Icons.email,
                ),
              if (userData?['revenu'] != null) ...[
                const Divider(),
                _buildInfoRow(
                  context,
                  'Revenu',
                  userData!['revenu'].toString(),
                  Icons.attach_money,
                ),
              ],
              if (userData?['niveauEducation'] != null) ...[
                const Divider(),
                _buildInfoRow(
                  context,
                  'Niveau d\'éducation',
                  userData!['niveauEducation'].toString(),
                  Icons.school,
                ),
              ],
              if (userData?['sensibilisation'] != null) ...[
                const Divider(),
                _buildInfoRow(
                  context,
                  'Sensibilisation environnementale',
                  '${userData!['sensibilisation'].toString()}/10',
                  Icons.eco,
                ),
              ],
              if (userData?['accesPlombier'] != null) ...[
                const Divider(),
                _buildInfoRow(
                  context,
                  'Accès à un plombier',
                  userData!['accesPlombier'] ? 'Oui' : 'Non',
                  Icons.plumbing,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Paramètres',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        _buildSettingsButton(
          context,
          'Modifier le profil',
          Icons.edit,
        ),
        const SizedBox(height: 12),
        _buildSettingsButton(
          context,
          'Déconnexion',
          Icons.logout,
          isLogout: true,
        ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

 Widget _buildSettingsButton(BuildContext context, String label, IconData icon, {bool isLogout = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isLogout ? Colors.red : Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isLogout ? Colors.red : Colors.black87,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
        onTap: () {
          if (isLogout) {
           Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditProfilePage(userData: userData!),
              ),
            ).then((result) {
              if (result != null && result['success'] == true) {
                // Mettre à jour les données locales si la modification a réussi
                setState(() {
                  userData!['prenom'] = result['prenom'];
                  userData!['nom'] = result['nom'];
                  userData!['email'] = result['email'];
                  if (result['avatar'] != null) {
                    userData!['avatar'] = result['avatar'];
                  }
                });
              }
            });
          }
        },
      ),
    );
  }
  
  void _logout(BuildContext context) async {
            MaterialPageRoute(builder: (context) => const LoginScreen());
  }
}