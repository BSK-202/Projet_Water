import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'recup_id_famille.dart';
import 'dart:convert';
import 'EspaceChef.dart';
import 'EspaceMembre.dart';
import 'registration_screen.dart';

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
      "http://127.0.0.1:5000/login"; // Update for your environment

  void _login() async 
  {

    setState(() {
      _isLoading = true;
    });

    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

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

        // Only save family ID if it exists
        if (responseData.containsKey('idFamille') &&
            responseData['idFamille'] != null) {
          await saveUserId(responseData['idFamille']);
          print("🔹 ID Famille stocké : ${responseData['idFamille']}");
        } else {
          print("🔹 Aucun ID Famille trouvé pour cet utilisateur.");
        }

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
              // Chef - Redirect to EspaceChef
              print("🔹 Redirection vers EspaceChef");
              String? userId = await getUserId();
              String email = _emailController.text.trim();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => EspaceChef(userId: userId ?? '', userEmail: email),
                ),
              );
            } else {
              // Member - Redirect to EspaceMembre
              print("🔹 Redirection vers EspaceMembre");
              String email = _emailController.text.trim();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder:
                      (_) => EspaceMembre(memberEmail: email),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Erreur de connexion'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur serveur : ${e.toString()}'),
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
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
