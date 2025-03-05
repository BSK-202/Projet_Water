import 'package:flutter/material.dart';

class Step3PersonalInfo extends StatefulWidget {
  final TextEditingController familySizeController;
  final TextEditingController houseAreaController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final List<String> propertyTypes;
  final bool canProceed;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const Step3PersonalInfo({
    super.key,
    required this.familySizeController,
    required this.houseAreaController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.propertyTypes,
    required this.canProceed,
    required this.onNext,
    required this.onBack,
  });

  @override
  _Step3PersonalInfoState createState() => _Step3PersonalInfoState();
}

class _Step3PersonalInfoState extends State<Step3PersonalInfo> {
  bool canProceed = false;

  @override
  void initState() {
    super.initState();
    widget.familySizeController.addListener(_updateCanProceed);
    widget.houseAreaController.addListener(_updateCanProceed);
    widget.emailController.addListener(_updateCanProceed);
    widget.passwordController.addListener(_updateCanProceed);
    widget.confirmPasswordController.addListener(_updateCanProceed);
  }

  @override
  void dispose() {
    widget.familySizeController.removeListener(_updateCanProceed);
    widget.houseAreaController.removeListener(_updateCanProceed);
    widget.emailController.removeListener(_updateCanProceed);
    widget.passwordController.removeListener(_updateCanProceed);
    widget.confirmPasswordController.removeListener(_updateCanProceed);
    super.dispose();
  }

  void _updateCanProceed() {
    setState(() {
      canProceed = widget.familySizeController.text.isNotEmpty &&
          widget.houseAreaController.text.isNotEmpty &&
          widget.emailController.text.isNotEmpty &&
          widget.passwordController.text.isNotEmpty &&
          widget.confirmPasswordController.text.isNotEmpty &&
          widget.passwordController.text == widget.confirmPasswordController.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Informations personnelles',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nombre de personnes',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: widget.familySizeController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Surface (m²)',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: widget.houseAreaController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Type de logement',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                items: widget.propertyTypes.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  // Mettre à jour la valeur sélectionnée
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Email',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: widget.emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'votre@email.com',
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
              const Text(
                'Mot de passe',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: widget.passwordController,
                obscureText: true,
                decoration: InputDecoration(
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
              const Text(
                'Confirmer le mot de passe',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: widget.confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onBack,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: Colors.grey.shade300),
                        minimumSize: const Size(120, 45),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Retour'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(

                    child: ElevatedButton(
                      onPressed: canProceed
                          ? () {
                        // Rediriger vers la page de connexion après création du compte
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/',
                              (route) => false,
                        );
                      }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canProceed ? Colors.green : Colors.grey.shade300, // Couleur du bouton
                        foregroundColor: Colors.white,
                        minimumSize: const Size(120, 45),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Créer mon compte'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}