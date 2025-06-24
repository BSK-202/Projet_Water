import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class EditPasswordScreen extends StatefulWidget {
  @override
  _EditPasswordScreenState createState() => _EditPasswordScreenState();
}

class _EditPasswordScreenState extends State<EditPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();
  bool _isLoading = false;
  String? _otpId;

  Future<void> _requestChangeAndShowOtpDialog() async {
    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final newPass = _newPassController.text;
    final confirmPass = _confirmPassController.text;

    if (email.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      _showError('Veuillez remplir tous les champs.');
      setState(() {
        _isLoading = false;
      });
      return;
    }
    if (newPass != confirmPass) {
      _showError('Les mots de passe ne correspondent pas.');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/request_password_change'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'new_password': newPass,
          'confirm_password': confirmPass,
        }),
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        _otpId = data['otp_id'];
        _showOtpDialog(email, newPass, confirmPass);
      } else {
        _showError(data['error'] ?? 'Erreur lors de l\'envoi du code.');
      }
    } catch (e) {
      _showError('Erreur serveur : ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showOtpDialog(String email, String newPass, String confirmPass) {
    final TextEditingController _otpController = TextEditingController();
    int secondsLeft = 60;
    Timer? timer;

    void closeDialog() {
      if (timer != null) timer!.cancel();
      Navigator.of(context, rootNavigator: true).pop();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            timer ??= Timer.periodic(Duration(seconds: 1), (t) {
              if (secondsLeft > 0) {
                setStateDialog(() {
                  secondsLeft--;
                });
              } else {
                t.cancel();
                closeDialog();
                _showError('Le code a expiré. Veuillez recommencer.');
              }
            });

            return AlertDialog(
              title: Text('Vérification du code'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Code reçu par email',
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    secondsLeft > 0
                        ? 'Temps restant : $secondsLeft secondes'
                        : 'Le code a expiré.',
                    style: TextStyle(
                      color: secondsLeft > 0 ? Colors.black : Colors.red,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    closeDialog();
                  },
                  child: Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed:
                      secondsLeft > 0
                          ? () async {
                            final otp = _otpController.text.trim();
                            if (otp.isEmpty) {
                              setStateDialog(() {});
                              _showError('Veuillez saisir le code.');
                              return;
                            }
                            final ok = await _verifyAndChangePassword(
                              email,
                              otp,
                              closeDialog,
                            );
                            // Ne ferme la popup que si ok == true
                            if (ok) {
                              closeDialog();
                            }
                          }
                          : null,
                  child: Text('Valider'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> _verifyAndChangePassword(
    String email,
    String otp,
    void Function() closeDialog,
  ) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/verify_and_change_password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'otp': otp, 'otp_id': _otpId}),
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Mot de passe modifié !'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
        return true;
      } else {
        _showError(
          data['error'] ?? 'Erreur lors du changement de mot de passe.',
        );
        return false;
      }
    } catch (e) {
      _showError('Erreur serveur : ${e.toString()}');
      return false;
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Réinitialiser le mot de passe'),
        backgroundColor: Color(0xFF2E7D32),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _newPassController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Nouveau mot de passe'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _confirmPassController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirmer le mot de passe',
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _requestChangeAndShowOtpDialog,
              child:
                  _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Changer le mot de passe'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
