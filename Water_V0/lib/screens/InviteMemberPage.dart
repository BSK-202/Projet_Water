import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:water_v0/screens/BottomNavigationBar.dart';

class InviteMemberPage extends StatefulWidget {
  final String chefEmail;
  const InviteMemberPage({Key? key, required this.chefEmail}) : super(key: key);

  @override
  State<InviteMemberPage> createState() => _InviteMemberPageState();
}

class _InviteMemberPageState extends State<InviteMemberPage> {
  final TextEditingController _emailController = TextEditingController();
  String? _message;
  bool _loading = false;

  bool isValidEmail(String email) {
    final RegExp emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
    return emailRegex.hasMatch(email);
  }

  Future<void> _sendInvitation() async {
    setState(() {
      _message = null;
    });
    final memberEmail = _emailController.text.trim();
    if (memberEmail.isEmpty) {
      setState(() {
        _message = "Veuillez entrer un email.";
      });
      return;
    }
    if (!isValidEmail(memberEmail)) {
      setState(() {
        _message = "Veuillez entrer un email valide.";
      });
      return;
    }
    setState(() {
      _loading = true;
    });
    try {
      print("****************Envoi de l'invitation à $memberEmail");
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/send_invitation'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'senderId': widget.chefEmail,
          'receiverId': memberEmail,
        }),
      );
      setState(() {
        _loading = false;
      });
      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        setState(() {
          _message = "Invitation envoyée !";
        });
      } else if (data['message'] == "Member does not exist") {
        setState(() {
          _message = "Le membre n'existe pas.";
        });
      } else {
        setState(() {
          _message = "Une erreur est survenue. Veuillez réessayer.";
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _message = "Une erreur est survenue. Veuillez réessayer.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Inviter un membre"),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 5,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.email_outlined,
                  size: 38,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 18),
                Text(
                  "Renseignez l'email du membre à inviter",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    color: theme.colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _emailController,
                  enabled: !_loading,
                  decoration: InputDecoration(
                    labelText: "Email du membre",
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.send),
                    label:
                        _loading
                            ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Text("Envoyer l'invitation"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _loading ? null : _sendInvitation,
                  ),
                ),
                if (_message != null) ...[
                  const SizedBox(height: 18),
                  Text(
                    _message!,
                    style: TextStyle(
                      color:
                          _message == "Invitation envoyée !"
                              ? Colors.green
                              : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),

      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: 0,
        userId: '',
        isChef: true,
        onTap: (i) {/* à gérer si besoin */},
      ),
    );
  }
}
