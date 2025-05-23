import 'package:shared_preferences/shared_preferences.dart';

/*
  Cette fonction permet de stocker l'ID de l'utilisateur dans les préférences partagées.
*/
Future<void> saveUserId(String userId) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('user_id', userId);
}
/*
  Cette fonction permet de récupérer l'ID de l'utilisateur depuis les préférences partagées.
*/
Future<String?> getUserId() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString('user_id');
}

Future<void> saveIdUser(String userId) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('id_user', userId);
}
/*
  Cette fonction permet de récupérer l'ID de l'utilisateur depuis les préférences partagées.
*/
Future<String?> getIdUSer() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final idUser = prefs.getString('id_user');
  print('🔹 ID utilisateur récupéré : $idUser');
  return idUser;
}

Future<void> clearUserSession() async {
  
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear(); // Supprime toutes les données stockées
  print('🔹 Session utilisateur supprimée');
}