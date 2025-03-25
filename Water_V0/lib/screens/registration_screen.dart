import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'step1_account_type.dart';
import 'step3_personal_info.dart'; // Ensure this file exists and contains the Step2PersonalInfo widget

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool? _isChef;

  // Contrôleurs pour les champs de texte
  final TextEditingController _familySizeController = TextEditingController(
    text: '1',
  );
  final TextEditingController _houseAreaController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();

  // Liste des types de logement
  final List<String> _propertyTypes = [
    'Appartement',
    'Maison',
    'Studio',
    'Loft',
    'Duplex',
    'Autre',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _familySizeController.dispose();
    _houseAreaController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep++;
      });
    } else {
      _submitForm();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep--;
      });
    }
  }

  void _submitForm() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Compte créé avec succès!'),
        backgroundColor: Color(0xFF2E7D32),
      ),
    );

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  bool get _canProceedFromStep1 => _isChef != null;

  bool get _canProceedFromStep2 {
    return _familySizeController.text.isNotEmpty &&
        _houseAreaController.text.isNotEmpty &&
        _emailController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty &&
        _passwordController.text == _confirmPasswordController.text;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Inscription',
          style: TextStyle(
            color: Color(0xFF2E7D32),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Créez votre compte',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Rejoignez notre communauté et commencez votre parcours écologique',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  // Indicateur d'étape
                  Row(
                    children: List.generate(2, (index) {
                      bool isActive = _currentStep >= index;
                      bool isLast = index == 1;

                      return Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color:
                                isActive
                                    ? const Color(0xFF2E7D32)
                                    : Colors.grey.shade300,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color:
                                    isActive ? Colors.white : Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            if (!isLast)
                              Expanded(
                                child: Container(
                                  height: 2,
                                  color:
                                  _currentStep > index
                                      ? const Color(0xFF2E7D32)
                                      : Colors.grey.shade300,
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Type de compte',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        'Informations personnelles',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // Étape 1: Type de compte
                  Step1AccountType(
                    isChef: _isChef,
                    onNext: _nextStep,
                    onSelected: (value) {
                      setState(() {
                        _isChef = value;
                      });
                    },
                    canProceed: _canProceedFromStep1,
                    onSkipToStep3: () {
                      _pageController.jumpToPage(2);
                      setState(() {
                        _currentStep = 2;
                      });
                    },
                    onBackToLogin: () {
                      // Rediriger l'utilisateur vers la page de login
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                  ),

                  // Étape 2: Informations personnelles
                  Step3PersonalInfo(
                    firstNameController: _firstNameController,
                    lastNameController: _lastNameController,
                    birthDateController: _birthDateController,
                    emailController: _emailController,
                    passwordController: _passwordController,
                    confirmPasswordController: _confirmPasswordController,
                    canProceed: _canProceedFromStep2,
                    onSubmit: _submitForm,
                    onBack: _previousStep,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}