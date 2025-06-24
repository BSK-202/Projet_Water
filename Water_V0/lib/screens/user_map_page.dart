import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:water_v0/screens/BottomNavigationBar.dart';
import 'package:water_v0/screens/recup_id_famille.dart';
import 'package:water_v0/screens/user_ranking_page.dart';
import '../models/user.dart';
import '../providers/user_provider.dart';

class UserMapPage extends StatefulWidget {
  const UserMapPage({super.key});

  @override
  State<UserMapPage> createState() => _UserMapPageState();
}

class _UserMapPageState extends State<UserMapPage> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late AnimationController _bounceController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<Color?> _colorAnimation;
  String?  CurrentFamilyID = '';
  LatLng? _currentLocation;
  @override
  void initState() {
    super.initState();
    _initializeAsync();
    // Initialiser les animations
    _initAnimations();
    // Charger les données au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().loadUsers();
    });
  }

  Future<void> _initializeAsync() async {
    CurrentFamilyID = await getUserId();
    print('🔹 **************************Current Family ID: $CurrentFamilyID');
    // Obtenir la position actuelle de l'utilisateur
    await getCurrentLocation();
    print('🔹 **************************Current Location: $_currentLocation');
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );

    _colorAnimation = ColorTween(
      begin: const Color(0xFF2E7D32),
      end: const Color(0xFF66BB6A),
    ).animate(_pulseController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  void _onUserMarkerTapped(User user) {
    context.read<UserProvider>().selectUser(user);
    _animationController.forward();
    _bounceController.forward().then((_) => _bounceController.reverse());
    
    _mapController.move(LatLng(user.latitude, user.longitude), 15.0);

  }

  void _closeUserDetails() {
    _animationController.reverse().then((_) {
      context.read<UserProvider>().selectUser(null);
    });
  }

  Color _getLevelColor(String level) {
    switch (level) {
      case 'Expert':
        return const Color(0xFF2E7D32); // Vert foncé
      case 'Avancé':
        return const Color(0xFF26A69A); // Turquoise
      case 'Intermédiaire':
        return const Color(0xFF66BB6A); // Vert clair
      default:
        return const Color(0xFFFF9800); // Orange
    }
  }

  IconData _getLevelIcon(String level) {
    switch (level) {
      case 'Expert':
        return Icons.military_tech; // Médaille
      case 'Avancé':
        return Icons.star; // Étoile
      case 'Intermédiaire':
        return Icons.trending_up; // Flèche montante
      default:
        return Icons.emoji_events; // Trophée
    }
  }
//get current location cherchant dans userProvider
  
   Future<void> getCurrentLocation() async {
    if (CurrentFamilyID == null || CurrentFamilyID!.isEmpty) return;
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:5000/get_location/$CurrentFamilyID'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['latitude'] != null && data['longitude'] != null) {
          setState(() {
            _currentLocation = LatLng(
              data['latitude'] as double,
              data['longitude'] as double,
            );
          });
        }
        else {
          debugPrint('Localisation non trouvée pour l\'ID de famille: $CurrentFamilyID');
          setState(() {
            _currentLocation = LatLng(              
              -7.6316672, // Valeur par défaut si la récupération échoue
              33.5675392,// Valeur par défaut si la récupération échoue
            );
          });
        }
      } else {
        debugPrint('Erreur lors de la récupération de la localisation: ${response.statusCode}');
         setState(() {
            _currentLocation = LatLng(              
              -7.6316672, // Valeur par défaut si la récupération échoue
              33.5675392,// Valeur par défaut si la récupération échoue
            );
          });
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération de la localisation: $e');
    }
  }
// ...e

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
   
   
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          // Afficher un indicateur de chargement
          if (userProvider.isLoading && userProvider.users.isEmpty) {
            return _buildLoadingScreen(theme);
          }

          // Afficher une erreur si nécessaire
          if (userProvider.error != null) {
            return _buildErrorScreen(theme, userProvider.error!, () {
              userProvider.clearError();
              userProvider.loadUsers();
            });
          }

          return Stack(
            children: [
              // Carte principale
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  center: _currentLocation ?? const LatLng(48.8566, 2.3522), // Paris par défaut
                  zoom: 12.0,
                  maxZoom: 18.0,
                  minZoom: 8.0,
                ),
                
                children: [
                TileLayer(
                 urlTemplate:
                    'https://api.mapbox.com/styles/v1/mapbox/dark-v11/tiles/256/{z}/{x}/{y}@2x?access_token=pk.eyJ1IjoiYmludGExMTEyIiwiYSI6ImNtYjJtcGV1NDE4NmEya3M2bHRoZXF4Z3oifQ.Br47nBoitWbpjKO-zjKQ3w',
                  additionalOptions: {
                   'accessToken': 'pk.eyJ1IjoiYmludGExMTEyIiwiYSI6ImNtYjJtcGV1NDE4NmEya3M2bHRoZXF4Z3oifQ.Br47nBoitWbpjKO-zjKQ3w',
                  },
                  userAgentPackageName: 'com.example.app',
            ),
                 Container(
                    color: const Color(0xFF2E7D32).withOpacity(0.1),
                  ),
                  MarkerLayer(
                    markers: userProvider.users.map((user) => _buildGameMarker(user)).toList(),
                  ),
                  MarkerLayer(
                    markers: userProvider.users.map((user) => _buildParticleEffect(user)).toList(),
                  ),
                ],
              ),
              
              // Header avec bouton de rafraîchissement
              _buildGameHeader(theme, userProvider),
              
              // Légende
              _buildGameLegend(theme),
              
              // Compteur de joueurs
              _buildPlayerCounter(theme, userProvider.users.length),
              
              // Détails de l'utilisateur sélectionné
              if (userProvider.selectedUser != null)
                Positioned(
                  bottom: 100,
                  left: 16,
                  right: 16,
                  child: AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: _buildGameUserCard(userProvider.selectedUser!),
                      );
                    },
                  ),
                ),

              // Indicateur de chargement en overlay
              if (userProvider.isLoading && userProvider.users.isNotEmpty)
                Positioned(
                  top: 100,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text('Mise à jour...'),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),

      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: 0,
        userId:  '',
        isChef: false, // Remplacez par la logique appropriée pour déterminer si l'utilisateur est un chef
        onTap: (index) {
          // Optionnel : logique supplémentaire
        },
      ),
      
    );
  }

  Widget _buildLoadingScreen(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.colorScheme.primary.withOpacity(0.1),
            theme.colorScheme.background,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Chargement des explorateurs...',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Découverte en cours',
              style: TextStyle(
                color: theme.colorScheme.primary.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(ThemeData theme, String error, VoidCallback onRetry) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.red.withOpacity(0.1),
            theme.colorScheme.background,
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.wifi_off,
                  size: 50,
                  color: Colors.red[400],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Connexion perdue',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[400],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Impossible de charger les explorateurs',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameHeader(ThemeData theme, UserProvider userProvider) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withOpacity(0.8),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.explore,
                    color: theme.colorScheme.primary,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Explorateur Map',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              offset: const Offset(1, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Découvrez les familles',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Bouton de rafraîchissement
                Container(
                  decoration: BoxDecoration( 
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: IconButton(
                    icon: Icon(
                      userProvider.isLoading ? Icons.hourglass_empty : Icons.refresh,
                      color: Colors.white,
                    ),
                    onPressed: userProvider.isLoading ? null : () {
                      userProvider.refreshUsers();
                    },
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Bouton de recentrage
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.my_location, color: Colors.white),
                    onPressed: () {
                      _mapController.move(const LatLng(48.8566, 2.3522), 12.0);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameLegend(ThemeData theme) {
    return Positioned(
      top: 140,
      right: 16,
      child:Container(
  decoration: BoxDecoration(
    gradient: const LinearGradient(
      colors: [Colors.amber, Colors.orange],
    ),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: Colors.white.withOpacity(0.3)),
    boxShadow: [
      BoxShadow(
        color: Colors.amber.withOpacity(0.4),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  ),
  child: InkWell(
    borderRadius: BorderRadius.circular(20),
    onTap: () {
     Navigator.push(
        context, MaterialPageRoute(builder: (_) => const UserRankingPage()));
    },
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events, color: Colors.white),
          const SizedBox(height: 4),
          const Text(
            'Classement',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  blurRadius: 2,
                  offset: Offset(1, 1),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  ),
),              
    /** */           

    );
  }

  Widget _buildGameLegendItem(String level, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 10),
          Text(
            level,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCounter(ThemeData theme, int userCount) {
    return Positioned(
      bottom: 20,
      left: 16,
      child: AnimatedBuilder(
        animation: _colorAnimation,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _colorAnimation.value ?? theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(Icons.people, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$userCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Familles actives',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Marker _buildGameMarker(User user) {
    final color = _getLevelColor(user.level);
    final icon = _getLevelIcon(user.level);
    final isSelected = context.watch<UserProvider>().selectedUser?.id == user.id;

    return Marker(
      point: LatLng(user.latitude, user.longitude),
      width: 80,
      height: 80,
      child: GestureDetector(
        onTap: () => _onUserMarkerTapped(user),
        child: AnimatedBuilder(
          animation: isSelected ? _bounceAnimation : _pulseAnimation,
          builder: (context, child) {
            final scale = isSelected ? _bounceAnimation.value : 1.0;
            return Transform.scale(
              scale: scale,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Effet de halo pulsant
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Container(
                        width: 60 * _pulseAnimation.value,
                        height: 60 * _pulseAnimation.value,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                      );
                    },
                  ),
                  
                  // Cercle principal du marqueur
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          color.withOpacity(0.8),
                          color,
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.5),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Stack(
                        children: [
                          // Avatar de l'utilisateur
                          Image.network(
                            user.avatarUrl,
                            fit: BoxFit.cover,
                            width: 60,
                            height: 60,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: color,
                                child: Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              );
                            },
                          ),
                          // Overlay avec icône de niveau
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1),
                              ),
                              child: Icon(
                                icon,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Indicateur de rang pour le top 3
                  if (user.rank <= 3)
                    Positioned(
                      top: 0,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: user.rank == 1 
                            ? Colors.amber
                            : user.rank == 2 
                              ? Colors.grey[400]
                              : Colors.orange[700],
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            '${user.rank}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Marker _buildParticleEffect(User user) {
    return Marker(
      point: LatLng(user.latitude, user.longitude),
      width: 100,
      height: 100,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: List.generate(3, (index) {
              final delay = index * 0.3;
              final animationValue = (_pulseController.value + delay) % 1.0;
              return Container(
                width: 20 + (animationValue * 40),
                height: 20 + (animationValue * 40),
                decoration: BoxDecoration(
                  color: _getLevelColor(user.level).withOpacity(0.3 - (animationValue * 0.3)),
                  shape: BoxShape.circle,
                ),
              );
            }),
          );
        },
        child: const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildGameUserCard(User user) {
    final theme = Theme.of(context);
    final levelColor = _getLevelColor(user.level);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            levelColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: levelColor.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: levelColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header avec avatar et infos
            Row(
              children: [
                // Avatar avec effet de niveau
                Stack(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [levelColor.withOpacity(0.3), levelColor],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: ClipOval(
                        child: Image.network(
                          user.avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: levelColor,
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 35,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    // Badge de niveau
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: levelColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(
                          _getLevelIcon(user.level),
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(width: 16),
                
                // Informations utilisateur
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [levelColor, levelColor.withOpacity(0.7)],
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        /*child: Text(
                          user.level,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),*/
                      ),
                    ],
                  ),
                ),
                
                // Bouton de fermeture
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    onPressed: _closeUserDetails,
                    icon: const Icon(Icons.close),
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Statistiques de jeu
            Row(
              children: [
                Expanded(
                  child: _buildGameStatItem(
                    icon: Icons.emoji_events,
                    label: 'Rang',
                    value: '#${user.rank}',
                    color: Colors.amber,
                    gradient: [Colors.amber, Colors.orange],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildGameStatItem(
                    icon: Icons.stars,
                    label: 'Points',
                    value: '${user.points}',
                    color: levelColor,
                    gradient: [levelColor, levelColor.withOpacity(0.7)],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required List<Color> gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}