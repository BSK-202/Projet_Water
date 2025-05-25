class User {
  final String id;
  final String name;
  final String avatarUrl;
  final double latitude;
  final double longitude;
  final int points;
  final int rank;
  final String level;
  final DateTime? lastActive;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.latitude,
    required this.longitude,
    required this.points,
    required this.rank,
    required this.level,
    this.lastActive,
    required this.createdAt,
  });



 // Conversion depuis JSON (base de données)
  factory User.fromJson(Map<String, dynamic> json) {
     String coordinates = json['localisation']
        .toString()
        /**************** */
        .replaceAll("(", "")
        .replaceAll(")", "");

    List<String> coord = coordinates.split(",");

    

    return User(
      id: json['id'] as String,
      name: json['nom'] as String,
      avatarUrl: json['avatar'],
      latitude: double.parse(coord[0]),
      longitude: double.parse(coord[1]),
      points: json['score'] as int? ?? 0,
      rank: json['rank'] as int? ?? 0,
      level: 'Expert',//json['level'] as String? ?? 'Débutant',
      lastActive: DateTime.now(),
      createdAt: DateTime.now(),
    );
  }

  // Conversion vers JSON (pour sauvegarder)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar_url': avatarUrl,
      'latitude': latitude,
      'longitude': longitude,
      'points': points,
      'rank': rank,
      'level': level,
      'last_active': lastActive?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Méthode pour copier avec modifications
  User copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    double? latitude,
    double? longitude,
    int? points,
    int? rank,
    String? level,
    DateTime? lastActive,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      points: points ?? this.points,
      rank: rank ?? this.rank,
      level: level ?? this.level,
      lastActive: lastActive ?? this.lastActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, points: $points, rank: $rank)';
  }

}