import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:water_v0/screens/BottomNavigationBar.dart';
import '../models/user.dart';
import '../providers/user_provider.dart';

class UserRankingPage extends StatefulWidget {
  const UserRankingPage({super.key});

  @override
  State<UserRankingPage> createState() => _UserRankingPageState();
}

class _UserRankingPageState extends State<UserRankingPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _refreshController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _rotationAnimation;
  String _selectedLevel = 'Tous';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _refreshController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.forward();

    // Charger les données au démarrage si pas déjà chargées
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = context.read<UserProvider>();
      if (userProvider.users.isEmpty && !userProvider.isLoading) {
        userProvider.loadUsers();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  void _refreshData() async {
    _refreshController.repeat();
    await context.read<UserProvider>().refreshUsers();
    _refreshController.stop();
    _refreshController.reset();
  }

  void _filterByLevel(String level) {
    setState(() {
      _selectedLevel = level;
    });
    
    if (level == 'Tous') {
      context.read<UserProvider>().loadUsers();
    } else {
      context.read<UserProvider>().loadUsersByLevel(level);
    }
  }

  Color _getLevelColor(String level) {
    switch (level) {
      case 'Expert':
        return const Color(0xFF2E7D32);
      case 'Avancé':
        return const Color(0xFF26A69A);
      case 'Intermédiaire':
        return const Color(0xFF66BB6A);
      default:
        return const Color(0xFFFF9800);
    }
  }

  IconData _getLevelIcon(String level) {
    switch (level) {
      case 'Expert':
        return Icons.military_tech;
      case 'Avancé':
        return Icons.star;
      case 'Intermédiaire':
        return Icons.trending_up;
      default:
        return Icons.emoji_events;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          // Afficher un écran de chargement complet
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

          final users = userProvider.usersByRank;
          final topUsers = users.take(3).toList();

          return CustomScrollView(
            slivers: [
              // AppBar avec effet de parallaxe et filtres
              _buildGameAppBar(theme, userProvider),

              // Statistiques générales
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildStatsSection(theme, users),
                ),
              ),

             

              // Podium (Top 3)
              if (topUsers.isNotEmpty)
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: _buildGamePodium(topUsers),
                    ),
                  ),
                ),

              // Titre de la liste complète
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.leaderboard,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Classement ${_selectedLevel != 'Tous' ? _selectedLevel : 'Complet'} (${users.length} participants)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Liste scrollable de TOUS les utilisateurs
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final user = users[index];
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: _buildUserRankCard(user),
                      ),
                    );
                  },
                  childCount: users.length,
                ),
              ),

              // Espace en bas pour le scroll
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),

              // Indicateur de chargement en bas si refresh
              if (userProvider.isLoading && users.isNotEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Mise à jour du classement...',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
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
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      strokeWidth: 4,
                      valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                    ),
                    Icon(
                      Icons.emoji_events,
                      color: theme.colorScheme.primary,
                      size: 30,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Chargement du classement...',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Calcul des rangs en cours',
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
                  Icons.leaderboard_outlined,
                  size: 50,
                  color: Colors.red[400],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Classement indisponible',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[400],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Impossible de charger les données',
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

  Widget _buildGameAppBar(ThemeData theme, UserProvider userProvider) {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: Colors.white,
      actions: [
        AnimatedBuilder(
          animation: _rotationAnimation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _rotationAnimation.value * 2 * 3.14159,
              child: IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: userProvider.isLoading ? null : _refreshData,
              ),
            );
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Classement',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.secondary,
              ],
            ),
          ),
          child: Stack(
            children: [
              // Motif de fond animé
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: 0.1 * _fadeAnimation.value,
                      child: const Stack(
                        children: [
                          Positioned(
                            top: 40,
                            right: 30,
                            child: Icon(
                              Icons.emoji_events,
                              color: Colors.white,
                              size: 60,
                            ),
                          ),
                          Positioned(
                            bottom: 20,
                            left: 30,
                            child: Icon(
                              Icons.star,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                          Positioned(
                            top: 60,
                            left: 50,
                            child: Icon(
                              Icons.military_tech,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection(ThemeData theme, List<User> users) {
    final totalPoints = users.fold(0, (sum, user) => sum + user.points);
    final averagePoints = users.isNotEmpty ? (totalPoints / users.length).round() : 0;
    final leader = users.isNotEmpty ? users.first : null;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            theme.colorScheme.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildGameStatCard(
            icon: Icons.people,
            title: 'Participants',
            value: '${users.length}',
            color: theme.colorScheme.primary,
          ),
          _buildGameStatCard(
            icon: Icons.trending_up,
            title: 'Moy. Points',
            value: '$averagePoints',
            color: theme.colorScheme.secondary,
          ),
          _buildGameStatCard(
            icon: Icons.emoji_events,
            title: 'Leader',
            value: leader?.name.split(' ').first ?? '-',
            color: Colors.amber,
          ),
        ],
      ),
    );
  }

  Widget _buildGameStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
            ),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLevelFilters(ThemeData theme) {
    final levels = ['Tous', 'Expert', 'Avancé', 'Intermédiaire', 'Débutant'];
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: levels.length,
        itemBuilder: (context, index) {
          final level = levels[index];
          final isSelected = _selectedLevel == level;
          final color = level == 'Tous' ? theme.colorScheme.primary : _getLevelColor(level);
          
          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (level != 'Tous')
                    Icon(
                      _getLevelIcon(level),
                      size: 16,
                      color: isSelected ? Colors.white : color,
                    ),
                  if (level != 'Tous') const SizedBox(width: 6),
                  Text(
                    level,
                    style: TextStyle(
                      color: isSelected ? Colors.white : color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) => _filterByLevel(level),
              backgroundColor: Colors.white,
              selectedColor: color,
              checkmarkColor: Colors.white,
              side: BorderSide(color: color.withOpacity(0.5)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGamePodium(List<User> topUsers) {
    return Container(
      height: 340,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Deuxième place (gauche)
          if (topUsers.length > 1)
            Positioned(              
              left: 10,
              bottom: 60,
              child: _buildGamePodiumPlace(
                user: topUsers[1],
                rank: 2,
                height: 100,
                color: Colors.grey[400]!,
              ),
            ),
          
          // Première place (centre)
          Positioned(
            bottom: 60,
            child: _buildGamePodiumPlace(
              user: topUsers[0],
              rank: 1,
              height: 140,
              color: const Color(0xFFFFD700),
            ),
          ),
          
          // Troisième place (droite)
          if (topUsers.length > 2)
            Positioned(
              right: 10,
              bottom: 60,
              child: _buildGamePodiumPlace(
                user: topUsers[2],
                rank: 3,
                height: 80,
                color: const Color(0xFFCD7F32),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGamePodiumPlace({
    required User user,
    required int rank,
    required double height,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar avec couronne pour le premier
        Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [color.withOpacity(0.8), color],
                ),
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.network(
                  user.avatarUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: color,
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
            // Couronne pour le premier
            if (rank == 1)
              Positioned(
                top: -15,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.emoji_events,
                    color: color,
                    size: 24,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Nom
        SizedBox(
          width: 90,
          child: Text(
            user.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        
        // Points avec animation
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Text(
            '${user.points} pts',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Socle du podium avec gradient
        Container(
          width: 90,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color, color.withOpacity(0.8)],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '$rank',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    offset: Offset(1, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserRankCard(User user) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: user.rank <= 3 
          ? const BorderSide(color: Colors.amber, width: 2)
          : BorderSide.none,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: user.rank <= 3 
            ? LinearGradient(
                colors: [Colors.amber.withOpacity(0.1), Colors.white],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Numéro de rang
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: user.rank == 1 
                    ? Colors.amber
                    : user.rank == 2 
                      ? Colors.grey[400]
                      : user.rank == 3 
                        ? Colors.orange[700]
                        : theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    '${user.rank}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: user.rank <= 3 ? Colors.white : theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Avatar
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.secondary,
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: Image.network(
                    user.avatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: theme.colorScheme.secondary,
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 25,
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Informations utilisateur
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (user.rank <= 3)
                          Icon(
                            Icons.emoji_events,
                            color: user.rank == 1 
                              ? Colors.amber
                              : user.rank == 2 
                                ? Colors.grey[400]
                                : Colors.orange[700],
                            size: 20,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.tertiary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      /*child: Text(
                        user.level,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.tertiary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),*/
                    ),
                  ],
                ),
              ),
              
              // Points
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${user.points}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: user.rank <= 3 ? Colors.amber[700] : theme.colorScheme.primary,
                    ),
                  ),
                  const Text(
                    'points',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(width: 8),
              
              // Icône de progression
              Icon(
                Icons.trending_up,
                color: theme.colorScheme.secondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}