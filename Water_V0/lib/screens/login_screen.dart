import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:water_v0/models/challenge_provider.dart';
import 'recup_id_famille.dart';
import 'dart:convert';
import 'EspaceChef.dart';
import 'EspaceMembre.dart';
import 'registration_screen.dart';
import 'edit_password.dart'; // Import de la nouvelle page de réinitialisation de mot de passe

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  // 🛠️ Assurez-vous que l'URL est correcte pour votre environnement
  final String _apiUrl =
      "http://127.0.0.1:5000/login"; // Pour l'émulateur Android

  get userId => null;

  get idUser => null; // Pour Chrome
  // final String _apiUrl = "http://192.168.x.x:5000/login"; // Pour un téléphone physique (remplacez par l'IP du PC)

  void _login() async {
    setState(() {
      _isLoading = true;
    });

    final String email = _emailController.text;
    final String password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer tous les champs !'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final Map<String, dynamic> data = {"email": email, "password": password};

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      print("🔹 Response body: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print("🔹 Données reçues : $responseData");

        await saveIdUser(email);
        print("🔹 Email stocké : $email");

        if (responseData.containsKey('is_chef')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Connexion réussie !'),
              backgroundColor: Color(0xFF2E7D32),
            ),
          );

          Future.delayed(const Duration(seconds: 1), () async {
            print("🔹 Redirection...");
            if (responseData['is_chef'] == true) {
              // Vérification de l'ID utilisateur
              if (responseData['idFamille'] != null) {
                await saveUserId(responseData['idFamille']);
              }
              print("🔹 ID famille : ${responseData['idFamille']}");
              print("🔹 ID utilisateur : ${responseData['idUser']}");

              print("🔹 ??????Redirection vers EspaceChef");
              String? userId = await getUserId();
              String? idUser = await getIdUSer();
              print("🔹 ID utilisateur : $idUser");

              // Utilisation correcte de ChallengeProvider
              final challengeProvider = Provider.of<ChallengeProvider>(
                context,
                listen: false,
              );
              await challengeProvider.fetchChallengesFromAPI(
                context,
                idUser ?? '',
              );

              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => EspaceChef(userId: userId ?? ''),
                ),
              );
            } else {
              print("🔹!!!!!!!! Redirection vers EspaceMembre");
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => EspaceMembre(userId: userId ?? ''),
                ),
              );
            }
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message'] ?? 'Erreur serveur'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        String errorMsg = 'Erreur inconnue';
        try {
          final responseData = json.decode(response.body);
          final backendMsg = responseData['message'] ?? '';
          // Personnalisation stricte du message affiché
          if (backendMsg.contains('Email inexistant')) {
            errorMsg = "L'adresse e-mail saisie n'existe pas dans notre base.";
          } else if (backendMsg.contains('Mot de passe incorrect')) {
            errorMsg = "Le mot de passe est incorrect. Veuillez réessayer.";
          } else if (backendMsg.contains('Champs manquants')) {
            errorMsg = "Veuillez remplir tous les champs.";
          } else {
            errorMsg = backendMsg.isNotEmpty ? backendMsg : errorMsg;
          }
        } catch (_) {
          errorMsg = 'Erreur de communication avec le serveur.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      // Gestion personnalisée pour erreur réseau
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de se connecter au serveur. email ou mot de passe incorrect.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _goToRegistration() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const RegistrationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Connexion',
          style: TextStyle(
            color: Color(0xFF2E7D32),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Rejoignez-nous !',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Faites partie de notre communauté dédiée à l\'économie d\'eau.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                'Votre contribution compte !',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Votre email',
                  hintStyle: TextStyle(color: Colors.grey.shade700),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Mot de passe',
                  hintStyle: TextStyle(color: Colors.grey.shade700),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child:
                    _isLoading
                        ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        )
                        : const Text(
                          'Se connecter',
                          style: TextStyle(fontSize: 18),
                        ),
              ),

              const SizedBox(height: 16),

              TextButton(
                onPressed: _goToRegistration,
                child: const Text(
                  'Créer un compte',
                  style: TextStyle(color: Color(0xFF2E7D32), fontSize: 16),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => EditPasswordScreen()),
                  );
                },
                child: const Text(
                  'Mot de passe oublié ?',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 16,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
