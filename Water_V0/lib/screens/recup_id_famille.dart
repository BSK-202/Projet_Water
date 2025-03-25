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