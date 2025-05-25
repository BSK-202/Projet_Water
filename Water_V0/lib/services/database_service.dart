import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';

abstract class DatabaseService {
  Future<List<User>> getAllUsers();
  Future<User?> getUserById(String id);
  Future<User> createUser(User user);
  Future<User> updateUser(User user);
  Future<bool> deleteUser(String id);
  Future<List<User>> getUsersByLevel(String level);
  Future<List<User>> getUsersInRadius(double lat, double lng, double radiusKm);
}

// Implementation pour API REST
class ApiDatabaseService implements DatabaseService {
  final String baseUrl;
  final Map<String, String> headers;

  ApiDatabaseService({
    required this.baseUrl,
    this.headers = const {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  });

  @override
  Future<List<User>> getAllUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/families'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => User.fromJson(json)).toList();
      } else {
        throw Exception('Erreur lors du chargement des utilisateurs: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur getAllUsers: $e');
      // Retourner des données mock en cas d'erreur
      return _getMockUsers();
    }
  }

  @override
  Future<User?> getUserById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return User.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Erreur lors du chargement de l\'utilisateur: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur getUserById: $e');
      return null;
    }
  }

  @override
  Future<User> createUser(User user) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users'),
        headers: headers,
        body: json.encode(user.toJson()),
      );

      if (response.statusCode == 201) {
        return User.fromJson(json.decode(response.body));
      } else {
        throw Exception('Erreur lors de la création de l\'utilisateur: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur createUser: $e');
      rethrow;
    }
  }

  @override
  Future<User> updateUser(User user) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/${user.id}'),
        headers: headers,
        body: json.encode(user.toJson()),
      );

      if (response.statusCode == 200) {
        return User.fromJson(json.decode(response.body));
      } else {
        throw Exception('Erreur lors de la mise à jour de l\'utilisateur: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur updateUser: $e');
      rethrow;
    }
  }

  @override
  Future<bool> deleteUser(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/users/$id'),
        headers: headers,
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Erreur deleteUser: $e');
      return false;
    }
  }

  @override
  Future<List<User>> getUsersByLevel(String level) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users?level=$level'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => User.fromJson(json)).toList();
      } else {
        throw Exception('Erreur lors du chargement des utilisateurs par niveau: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur getUsersByLevel: $e');
      return [];
    }
  }

  @override
  Future<List<User>> getUsersInRadius(double lat, double lng, double radiusKm) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/nearby?lat=$lat&lng=$lng&radius=$radiusKm'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => User.fromJson(json)).toList();
      } else {
        throw Exception('Erreur lors du chargement des utilisateurs à proximité: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur getUsersInRadius: $e');
      return [];
    }
  }

  // Données mock en cas d'erreur de connexion
  List<User> _getMockUsers() {
    return [
      User(
        id: '1',
        name: 'Alice Martin',
        avatarUrl: 'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=150&h=150&fit=crop&crop=face',
        latitude: 48.8566,
        longitude: 2.3522,
        points: 2450,
        rank: 1,
        level: 'Expert',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        lastActive: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      // ... autres utilisateurs mock
    ];
  }
}

