import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Step3PersonalInfo extends StatefulWidget {
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController birthDateController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final VoidCallback onBack;
  final String? selectedAvatar;
  final VoidCallback onSubmit;

  const Step3PersonalInfo({
    super.key,
    required this.firstNameController,
    required this.lastNameController,
    required this.birthDateController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.onBack,
    required this.selectedAvatar,
    required this.onSubmit, required bool canProceed,
  });

  @override
  _Step3PersonalInfoState createState() => _Step3PersonalInfoState();
}

class _Step3PersonalInfoState extends State<Step3PersonalInfo> {
  bool canProceed = false;
  bool isLoading = false;
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    widget.firstNameController.addListener(_updateCanProceed);
    widget.lastNameController.addListener(_updateCanProceed);
    widget.birthDateController.addListener(_updateCanProceed);
    widget.emailController.addListener(_updateCanProceed);
    widget.passwordController.addListener(_updateCanProceed);
    widget.confirmPasswordController.addListener(_updateCanProceed);
  }

  @override
  void dispose() {
    widget.firstNameController.removeListener(_updateCanProceed);
    widget.lastNameController.removeListener(_updateCanProceed);
    widget.birthDateController.removeListener(_updateCanProceed);
    widget.emailController.removeListener(_updateCanProceed);
    widget.passwordController.removeListener(_updateCanProceed);
    widget.confirmPasswordController.removeListener(_updateCanProceed);
    super.dispose();
  }

  void _updateCanProceed() {
    setState(() {
      canProceed =
          widget.firstNameController.text.isNotEmpty &&
          widget.lastNameController.text.isNotEmpty &&
          widget.birthDateController.text.isNotEmpty &&
          _isValidEmail(widget.emailController.text) &&
          widget.passwordController.text.isNotEmpty &&
          widget.confirmPasswordController.text.isNotEmpty &&
          widget.passwordController.text ==
              widget.confirmPasswordController.text;
    });
  }

  bool _isValidEmail(String email) {
    final emailRegEx = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegEx.hasMatch(email);
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale("fr", "FR"),
    );

    if (pickedDate != null) {
      setState(() {
        widget.birthDateController.text = DateFormat('dd/MM/yyyy').format(pickedDate);
      });
    }
  }

  Future<void> _submitData() async {
    setState(() {
      isLoading = true;
    });

    final url = Uri.parse("http://10.0.2.2:5000/register");
    final DateFormat serverFormat = DateFormat('yyyy-MM-dd');
    DateTime parsedDate = DateFormat('dd/MM/yyyy').parse(widget.birthDateController.text);
    String formattedDate = serverFormat.format(parsedDate);

    final Map<String, dynamic> userData = {
      "nom": widget.firstNameController.text,
      "prenom": widget.lastNameController.text,
      "dateNaiss": formattedDate,
      "email": widget.emailController.text,
      "password": widget.passwordController.text,
      "avatar": widget.selectedAvatar, // Ajout de l'avatar sélectionné
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(userData),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Compte créé avec succès !")),
        );
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur : ${response.body}")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur réseau : $e")));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Informations personnelles',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              if (widget.selectedAvatar != null) ...[
                Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: AssetImage(widget.selectedAvatar!),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              _buildTextField('Nom', widget.firstNameController),
              const SizedBox(height: 16),

              _buildTextField('Prénom', widget.lastNameController),
              const SizedBox(height: 16),

              const Text(
                'Date de naissance',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: widget.birthDateController,
                readOnly: true,
                decoration: InputDecoration(
                  hintText: 'JJ/MM/AAAA',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              _buildTextField(
                'Email',
                widget.emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              _buildPasswordField('Mot de passe', widget.passwordController),
              const SizedBox(height: 16),

              _buildPasswordField(
                'Confirmer le mot de passe',
                widget.confirmPasswordController,
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                    onPressed: widget.onBack,
                    child: const Text('Retour'),
                  ),
                  ElevatedButton(
                    onPressed: canProceed ? _submitData : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          canProceed ? Colors.green : Colors.grey.shade300,
                      foregroundColor: Colors.white,
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Créer mon compte'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.text,
      obscureText: isConfirmPasswordVisible
          ? !isConfirmPasswordVisible
          : !isPasswordVisible,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        suffixIcon: IconButton(
          icon: Icon(
            isConfirmPasswordVisible
                ? (isConfirmPasswordVisible
                    ? Icons.visibility
                    : Icons.visibility_off)
                : (isPasswordVisible ? Icons.visibility : Icons.visibility_off),
          ),
          onPressed: () {
            setState(() {
              if (isConfirmPasswordVisible) {
                isConfirmPasswordVisible = !isConfirmPasswordVisible;
              } else {
                isPasswordVisible = !isPasswordVisible;
              }
            });
          },
        ),
      ),
    );
  }
}