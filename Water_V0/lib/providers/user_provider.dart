import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/database_service.dart';

class UserProvider with ChangeNotifier {
  final DatabaseService _databaseService;
  
  List<User> _users = [];
  User? _selectedUser;
  bool _isLoading = false;
  String? _error;

  UserProvider(this._databaseService);

  // Getters
  List<User> get users => _users;
  User? get selectedUser => _selectedUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  List<User> get topUsers => _users.take(3).toList();
  List<User> get usersByRank => List.from(_users)..sort((a, b) => a.rank.compareTo(b.rank));

  // Charger tous les utilisateurs
  Future<void> loadUsers() async {
    _setLoading(true);
    _setError(null);
    
    try {
      _users = await _databaseService.getAllUsers();
      // Trier par rang
      _users.sort((a, b) => a.rank.compareTo(b.rank));
      notifyListeners();
    } catch (e) {
      _setError('Erreur lors du chargement des utilisateurs: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Rafraîchir les données
  Future<void> refreshUsers() async {
    await loadUsers();
  }

  // Sélectionner un utilisateur
  void selectUser(User? user) {
    _selectedUser = user;
    notifyListeners();
  }

  // Charger les utilisateurs par niveau
  Future<void> loadUsersByLevel(String level) async {
    _setLoading(true);
    _setError(null);
    
    try {
      _users = await _databaseService.getUsersByLevel(level);
      _users.sort((a, b) => a.rank.compareTo(b.rank));
      notifyListeners();
    } catch (e) {
      _setError('Erreur lors du chargement des utilisateurs par niveau: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Charger les utilisateurs à proximité
  Future<void> loadUsersInRadius(double lat, double lng, double radiusKm) async {
    _setLoading(true);
    _setError(null);
    
    try {
      _users = await _databaseService.getUsersInRadius(lat, lng, radiusKm);
      _users.sort((a, b) => a.rank.compareTo(b.rank));
      notifyListeners();
    } catch (e) {
      _setError('Erreur lors du chargement des utilisateurs à proximité: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Créer un utilisateur
  Future<bool> createUser(User user) async {
    _setLoading(true);
    _setError(null);
    
    try {
      final newUser = await _databaseService.createUser(user);
      _users.add(newUser);
      _users.sort((a, b) => a.rank.compareTo(b.rank));
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Erreur lors de la création de l\'utilisateur: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Mettre à jour un utilisateur
  Future<bool> updateUser(User user) async {
    _setLoading(true);
    _setError(null);
    
    try {
      final updatedUser = await _databaseService.updateUser(user);
      final index = _users.indexWhere((u) => u.id == user.id);
      if (index != -1) {
        _users[index] = updatedUser;
        _users.sort((a, b) => a.rank.compareTo(b.rank));
        notifyListeners();
      }
      return true;
    } catch (e) {
      _setError('Erreur lors de la mise à jour de l\'utilisateur: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Supprimer un utilisateur
  Future<bool> deleteUser(String id) async {
    _setLoading(true);
    _setError(null);
    
    try {
      final success = await _databaseService.deleteUser(id);
      if (success) {
        _users.removeWhere((user) => user.id == id);
        if (_selectedUser?.id == id) {
          _selectedUser = null;
        }
        notifyListeners();
      }
      return success;
    } catch (e) {
      _setError('Erreur lors de la suppression de l\'utilisateur: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Méthodes privées
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    if (error != null) {
      notifyListeners();
    }
  }

  // Nettoyer l'erreur
  void clearError() {
    _error = null;
    notifyListeners();
  }
}