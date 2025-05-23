import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:water_v0/screens/BottomNavigationBar.dart';
import 'recup_id_famille.dart';
import 'package:flutter/services.dart';
import 'local_Info.dart'; // Assurez-vous d'importer LocalFamilleScreen

class MyApp extends StatefulWidget  {
   @override
  _MyAppState createState() => _MyAppState();
}
class _MyAppState extends State<MyApp> {
  Future<Map<String, dynamic>>? _localCheckFuture;

  @override
  void initState() {
    super.initState();
    _refreshCheck();
  }
  void _refreshCheck() {
    setState(() {
      _localCheckFuture = _checkLocalExistence();
    });
  }
  @override
    Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Formulaire Local',
      theme: ThemeData(primarySwatch: Colors.green),
      home: FutureBuilder<Map<String, dynamic>>(
        future: _localCheckFuture, // Utilisez la variable d'état ici
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError || snapshot.data?['error'] != null) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Erreur: ${snapshot.error ?? snapshot.data?['error']}'),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _refreshCheck, // Appel à la méthode de rafraîchissement
                      child: Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            );
          }

          final hasLocal = snapshot.data?['has_local'] ?? false;
          final localData = snapshot.data?['local'];

          if (hasLocal && localData != null) {
            return LocalFamilleScreen(initialLocalData: localData,isChef:true);
          } else {
            return Step1Location();
          }
        },
      ),
    );
  }
}
Future<Map<String, dynamic>> _checkLocalExistence() async {
  print('Début de la vérification du local...');
  final codeFamille = await getUserId();
  print('Code famille récupéré: $codeFamille');
  
  if (codeFamille == null || codeFamille.isEmpty) {
    print('Erreur: Code famille manquant');
    return {'has_local': false, 'error': 'Code famille non disponible'};
  }

  try {
    final uri = Uri.parse('http://127.0.0.1:5000/check-local?code_famille=$codeFamille');
    print('Envoi de la requête à: ${uri.toString()}');
    
    final response = await http.get(uri).timeout(const Duration(seconds: 10));
    print('Réponse reçue - Status: ${response.statusCode}');
    print('Corps de la réponse: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('Données décodées: $data');
      return {
        'has_local': data['exists'] ?? false,
        'local': data['local'] ?? null,
      };
    } else {
      print('Erreur serveur: ${response.statusCode}');
      return {'has_local': false, 'error': 'Erreur serveur ${response.statusCode}'};
    }
  } catch (e) {
    print('Erreur lors de la requête: $e');
    return {'has_local': false, 'error': 'Erreur de connexion: $e'};
  }
}


// Étape 1: Récupération de la localisation
class Step1Location extends StatefulWidget {
  @override
  _Step1LocationState createState() => _Step1LocationState();
}

class _Step1LocationState extends State<Step1Location> {
  final TextEditingController _addressController = TextEditingController();
  bool _loadingLocation = false;
  LatLng _currentPosition = const LatLng(31.7917, -7.0926);
  GoogleMapController? _mapController;
  String _coordinates = "";
  int? _adresseId;

  Future<void> getAddressFromCoordinates(double lat, double lon) async {
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon',
    );

    try {
      final response = await http.get(
        url,
        headers: {'User-Agent': 'FlutterApp'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data["address"];

        if (address != null) {
          String? city =
              address["city"] ?? address["town"] ?? address["village"];
          String? neighbourhood = address["neighbourhood"];
          String? region = address["state_district"];

          setState(() {
            _addressController.text =
                "Ville: ${city ?? 'Inconnue'}\nQuartier: ${neighbourhood ?? 'Inconnu'}\nRégion: ${region ?? 'Inconnue'}";
          });

          _adresseId = await sendLocationData(
            city ?? "Inconnu",
            neighbourhood ?? "Inconnu",
            region ?? "Inconnue",
            lat,
            lon,
          );
        }
      }
    } catch (e) {
      print('Erreur lors de la requête: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _loadingLocation = true);

    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() => _loadingLocation = false);
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      await getAddressFromCoordinates(position.latitude, position.longitude);

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _coordinates =
            "Latitude: ${position.latitude}, Longitude: ${position.longitude}";
        _mapController?.animateCamera(CameraUpdate.newLatLng(_currentPosition));
        _loadingLocation = false;
      });
    } catch (e) {
      setState(() => _loadingLocation = false);
    }
  }

  Future<int?> sendLocationData(
    String city,
    String neighbourhood,
    String region,
    double latitude,
    double longitude,
  ) async {
    final url = Uri.parse("http://127.0.0.1:5000/adresse");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "ville": city,
          "quartier": neighbourhood,
          "region": region,
          "latitude": latitude,
          "longitude": longitude,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['adresse_id'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Étape 1: Localisation")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Localisation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _addressController,
              readOnly: true,
              decoration: InputDecoration(
                hintText: 'Ville, Quartier, Région',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadingLocation ? null : _getCurrentLocation,
              icon: const Icon(Icons.location_on),
              label:
                  _loadingLocation
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Utiliser ma position actuelle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _coordinates,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _currentPosition,
                  zoom: 14,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId("currentLocation"),
                    position: _currentPosition,
                  ),
                },
                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;
                },
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed:
                    _adresseId != null
                        ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      Step2LocalDetails(adresseId: _adresseId!),
                            ),
                          );
                        }
                        : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                ),
                child: const Text('Suivant'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Step2LocalDetails extends StatefulWidget {
  final int adresseId;

  const Step2LocalDetails({Key? key, required this.adresseId})
    : super(key: key);

  @override
  _Step2LocalDetailsState createState() => _Step2LocalDetailsState();
}

class _Step2LocalDetailsState extends State<Step2LocalDetails> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  String _codeFamille = "";
  bool _isLoading = true;
  bool _isSubmitting = false;

  // Contrôleurs
  final TextEditingController _surfaceController = TextEditingController();
  final TextEditingController _nbChambreController = TextEditingController();
  final TextEditingController _nbDoucheController = TextEditingController();
  final TextEditingController _nbCuisineController = TextEditingController();
  final TextEditingController _nbPersonneController = TextEditingController();
  final TextEditingController _nbrToilettesController = TextEditingController();
  final TextEditingController _nbrRobinetController = TextEditingController();
  final TextEditingController _surfaceJardinController =
      TextEditingController();
  final TextEditingController _surfacePiscineController =
      TextEditingController();
  final TextEditingController _nbrSallesDeBainController =
      TextEditingController();
  final TextEditingController _nbrEtagesController = TextEditingController();
  final TextEditingController _nbrChasseEauController = TextEditingController();
  final TextEditingController _agePlomberieController = TextEditingController();
  final TextEditingController _dernierRenovationController =
      TextEditingController();
  final TextEditingController _nbrLaveLingeController = TextEditingController();
  final TextEditingController _nbrLaveVaisselleController =
      TextEditingController();
  final TextEditingController _utilisationNettoyageController =
      TextEditingController();

  // Listes déroulantes
  final List<String> _typesLocal = [
    'Appartement',
    'Maison',
    'Villa',
    'Bureau',
    'Commerce',
    'Autre',
  ];
  final List<String> _typesTuyauterie = [
    'Cuivre',
    'PVC',
    'PER',
    'Acier',
    'Multicouche',
  ];
  final List<String> _typesChauffeEau = [
    'Électrique',
    'Gaz',
    'Solaire',
    'Thermodynamique',
  ];

  // Sélections
  String? _selectedTypeLocal;
  String? _selectedTypeTuyauterie;
  String? _selectedTypeChauffeEau;

  // Cases à cocher
  bool _piscine = false;
  bool _garage = false;
  bool _jardin = false;
  bool _arrosageAutomatique = false;
  bool _statutOccupation = false;

  // Widget personnalisé pour les champs numériques avec flèches
  Widget _buildNumberFieldWithArrows({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    bool isDecimal = false,
    bool isRequired = false,
    double? minValue,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: labelText,
              hintText: hintText,
            ),
            keyboardType:
                isDecimal
                    ? TextInputType.numberWithOptions(decimal: true)
                    : TextInputType.number,
            inputFormatters:
                isDecimal
                    ? [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}'),
                      ),
                    ]
                    : [FilteringTextInputFormatter.digitsOnly],
            validator: (value) {
              if (isRequired && (value?.isEmpty ?? true)) {
                return 'Ce champ est obligatoire';
              }
              if (value?.isNotEmpty ?? false) {
                if (isDecimal) {
                  if (double.tryParse(value!) == null) return 'Nombre invalide';
                  if (minValue != null && double.parse(value) < minValue) {
                    return 'Doit être ≥ $minValue';
                  }
                } else {
                  if (int.tryParse(value!) == null) return 'Nombre invalide';
                  if (minValue != null && int.parse(value) < minValue) {
                    return 'Doit être ≥ $minValue';
                  }
                }
              }
              return null;
            },
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.arrow_drop_up, size: 24),
              onPressed: () {
                final currentValue =
                    isDecimal
                        ? double.tryParse(controller.text) ?? 0
                        : int.tryParse(controller.text) ?? 0;
                final newValue = currentValue + 1;
                controller.text = newValue.toString();
                setState(() {});
              },
            ),
            IconButton(
              icon: Icon(Icons.arrow_drop_down, size: 24),
              onPressed: () {
                final currentValue =
                    isDecimal
                        ? double.tryParse(controller.text) ?? (minValue ?? 0)
                        : int.tryParse(controller.text) ??
                            (minValue ?? 0).toInt();
                final newValue = currentValue - 1;
                if (minValue == null || newValue >= minValue) {
                  controller.text = newValue.toString();
                  setState(() {});
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _loadCodeFamille();
  }

  Future<void> _loadCodeFamille() async {
    final code = await getUserId();
    setState(() {
      _codeFamille = code ?? "";
      _isLoading = false;
    });
  }

  List<Step> _buildSteps() {
    return [
      Step(
        title: const Text('Informations de base'),
        isActive: _currentStep >= 0,
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
        content: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedTypeLocal,
              decoration: const InputDecoration(labelText: 'Type de local*'),
              validator:
                  (value) => value == null ? 'Ce champ est obligatoire' : null,
              items:
                  _typesLocal.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedTypeLocal = newValue;
                });
              },
            ),
            const SizedBox(height: 16),
            _buildNumberFieldWithArrows(
              controller: _surfaceController,
              labelText: 'Surface (m²)*',
              hintText: 'Ex: 120',
              isDecimal: true,
              isRequired: true,
              minValue: 0.01,
            ),
            const SizedBox(height: 16),
            _buildNumberFieldWithArrows(
              controller: _nbPersonneController,
              labelText: 'Nombre de personnes*',
              hintText: 'Ex: 4',
              isRequired: true,
              minValue: 1,
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Local occupé'),
              value: _statutOccupation,
              onChanged: (bool? value) {
                setState(() {
                  _statutOccupation = value ?? false;
                });
              },
            ),
          ],
        ),
      ),
      Step(
        title: const Text('Pièces'),
        isActive: _currentStep >= 1,
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
        content: Column(
          children: [
            _buildNumberFieldWithArrows(
              controller: _nbChambreController,
              labelText: 'Nombre de chambres',
              hintText: 'Ex: 3',
              minValue: 0,
            ),
            const SizedBox(height: 16),
            _buildNumberFieldWithArrows(
              controller: _nbDoucheController,
              labelText: 'Nombre de douches',
              hintText: 'Ex: 2',
              minValue: 0,
            ),
            const SizedBox(height: 16),
            _buildNumberFieldWithArrows(
              controller: _nbCuisineController,
              labelText: 'Nombre de cuisines',
              hintText: 'Ex: 1',
              minValue: 0,
            ),
            const SizedBox(height: 16),
            _buildNumberFieldWithArrows(
              controller: _nbrEtagesController,
              labelText: 'Nombre d\'étages',
              hintText: 'Ex: 2',
              minValue: 0,
            ),
            const SizedBox(height: 16),
            _buildNumberFieldWithArrows(
              controller: _nbrSallesDeBainController,
              labelText: 'Nombre de salles de bain',
              hintText: 'Ex: 2',
              minValue: 0,
            ),
          ],
        ),
      ),
      Step(
        title: const Text('Extérieurs'),
        isActive: _currentStep >= 2,
        state: _currentStep > 2 ? StepState.complete : StepState.indexed,
        content: Column(
          children: [
            CheckboxListTile(
              title: const Text('Piscine'),
              value: _piscine,
              onChanged: (bool? value) {
                setState(() {
                  _piscine = value ?? false;
                });
              },
            ),
            if (_piscine) ...[
              _buildNumberFieldWithArrows(
                controller: _surfacePiscineController,
                labelText: 'Surface piscine (m²)',
                hintText: 'Ex: 15',
                isDecimal: true,
                minValue: 0,
              ),
              const SizedBox(height: 16),
            ],
            CheckboxListTile(
              title: const Text('Garage'),
              value: _garage,
              onChanged: (bool? value) {
                setState(() {
                  _garage = value ?? false;
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Jardin'),
              value: _jardin,
              onChanged: (bool? value) {
                setState(() {
                  _jardin = value ?? false;
                });
              },
            ),
            if (_jardin) ...[
              _buildNumberFieldWithArrows(
                controller: _surfaceJardinController,
                labelText: 'Surface jardin (m²)',
                hintText: 'Ex: 50',
                isDecimal: true,
                minValue: 0,
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Arrosage automatique'),
                value: _arrosageAutomatique,
                onChanged: (bool? value) {
                  setState(() {
                    _arrosageAutomatique = value ?? false;
                  });
                },
              ),
            ],
          ],
        ),
      ),
      Step(
        title: const Text('Plomberie'),
        isActive: _currentStep >= 3,
        state: _currentStep > 3 ? StepState.complete : StepState.indexed,
        content: Column(
          children: [
            _buildNumberFieldWithArrows(
              controller: _nbrToilettesController,
              labelText: 'Nombre de toilettes',
              hintText: 'Ex: 2',
              minValue: 0,
            ),
            const SizedBox(height: 16),
            _buildNumberFieldWithArrows(
              controller: _nbrRobinetController,
              labelText: 'Nombre de robinets',
              hintText: 'Ex: 5',
              minValue: 0,
            ),
            const SizedBox(height: 16),
            _buildNumberFieldWithArrows(
              controller: _nbrChasseEauController,
              labelText: 'Nombre de chasses d\'eau',
              hintText: 'Ex: 2',
              minValue: 0,
            ),
            const SizedBox(height: 16),
            _buildNumberFieldWithArrows(
              controller: _agePlomberieController,
              labelText: 'Âge de la plomberie (années)',
              hintText: 'Ex: 5',
              minValue: 0,
            ),
            const SizedBox(height: 16),
            _buildNumberFieldWithArrows(
              controller: _dernierRenovationController,
              labelText: 'Dernière rénovation plomberie (années)',
              hintText: 'Ex: 2',
              minValue: 0,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedTypeTuyauterie,
              decoration: const InputDecoration(
                labelText: 'Type de tuyauterie',
              ),
              items:
                  _typesTuyauterie.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedTypeTuyauterie = newValue;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedTypeChauffeEau,
              decoration: const InputDecoration(
                labelText: 'Type de chauffe-eau',
              ),
              items:
                  _typesChauffeEau.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedTypeChauffeEau = newValue;
                });
              },
            ),
          ],
        ),
      ),
      Step(
        title: const Text('Équipements'),
        isActive: _currentStep >= 4,
        content: Column(
          children: [
            _buildNumberFieldWithArrows(
              controller: _nbrLaveLingeController,
              labelText: 'Nombre de lave-linge',
              hintText: 'Ex: 1',
              minValue: 0,
            ),
            const SizedBox(height: 16),
            _buildNumberFieldWithArrows(
              controller: _nbrLaveVaisselleController,
              labelText: 'Nombre de lave-vaisselle',
              hintText: 'Ex: 1',
              minValue: 0,
            ),
            const SizedBox(height: 16),
            _buildNumberFieldWithArrows(
              controller: _utilisationNettoyageController,
              labelText: 'Utilisation nettoyage sols (L/mois)',
              hintText: 'Ex: 30',
              isDecimal: true,
              minValue: 0,
            ),
          ],
        ),
      ),
    ];
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _selectedTypeLocal != null &&
            _surfaceController.text.isNotEmpty &&
            _nbPersonneController.text.isNotEmpty;
      default:
        return true;
    }
  }

  void _stepContinue() {
    if (_currentStep == 0 && !_validateCurrentStep()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs obligatoires'),
        ),
      );
      return;
    }

    if (_currentStep < _buildSteps().length - 1) {
      setState(() => _currentStep++);
    } else {
      _submitForm();
    }
  }

  void _stepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _submitForm() async {
    if (_codeFamille.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code famille non disponible')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final localData = {
      "type": _selectedTypeLocal,
      "surface": double.parse(_surfaceController.text),
      "nbChambre":
          _nbChambreController.text.isEmpty
              ? 0
              : int.parse(_nbChambreController.text),
      "nbDouche":
          _nbDoucheController.text.isEmpty
              ? 0
              : int.parse(_nbDoucheController.text),
      "nbCuisine":
          _nbCuisineController.text.isEmpty
              ? 0
              : int.parse(_nbCuisineController.text),
      "piscine": _piscine,
      "garage": _garage,
      "jardin": _jardin,
      "codeFamille": _codeFamille,
      "adress": widget.adresseId,
      "nb_personne": int.parse(_nbPersonneController.text),
      "nbr_toilettes":
          _nbrToilettesController.text.isEmpty
              ? 0
              : int.parse(_nbrToilettesController.text),
      "nbr_robinets":
          _nbrRobinetController.text.isEmpty
              ? 0
              : int.parse(_nbrRobinetController.text),
      "surface_jardin":
          _surfaceJardinController.text.isEmpty
              ? 0.0
              : double.parse(_surfaceJardinController.text),
      "surface_piscine":
          _surfacePiscineController.text.isEmpty
              ? 0.0
              : double.parse(_surfacePiscineController.text),
      "nbr_salles_de_bain":
          _nbrSallesDeBainController.text.isEmpty
              ? 0
              : int.parse(_nbrSallesDeBainController.text),
      "nbr_etages":
          _nbrEtagesController.text.isEmpty
              ? 0
              : int.parse(_nbrEtagesController.text),
      "nbr_chasse_eau":
          _nbrChasseEauController.text.isEmpty
              ? 0
              : int.parse(_nbrChasseEauController.text),
      "age_plomberie":
          _agePlomberieController.text.isEmpty
              ? 0
              : int.parse(_agePlomberieController.text),
      "type_tuyauterie": _selectedTypeTuyauterie,
      "dernier_renovation_plomberie":
          _dernierRenovationController.text.isEmpty
              ? 0
              : int.parse(_dernierRenovationController.text),
      "type_chauffe_eau": _selectedTypeChauffeEau,
      "arrosage_automatique": _arrosageAutomatique,
      "nbr_lave_linge":
          _nbrLaveLingeController.text.isEmpty
              ? 0
              : int.parse(_nbrLaveLingeController.text),
      "nbr_lave_vaisselle":
          _nbrLaveVaisselleController.text.isEmpty
              ? 0
              : int.parse(_nbrLaveVaisselleController.text),
      "utilisation_nettoyage_sols":
          _utilisationNettoyageController.text.isEmpty
              ? 0.0
              : double.parse(_utilisationNettoyageController.text),
      "statut_occupation": _statutOccupation,
    };

    final url = Uri.parse("http://127.0.0.1:5000/local");

    try {
      final response = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(localData),
          )
          .timeout(const Duration(seconds: 10));

     if (response.statusCode == 200) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Local enregistré avec succès!')),
  );
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (context) => MyApp()),
    (route) => false,
  );
} else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur ${response.statusCode}: ${response.body}'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur inattendue: ${e.toString()}')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Nouveau Local - Étape ${_currentStep + 1}/${_buildSteps().length}',
        ),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Stepper(
            currentStep: _currentStep,
            steps: _buildSteps(),
            onStepContinue: _stepContinue,
            onStepCancel: _stepCancel,
            controlsBuilder: (context, details) {
              return Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentStep != 0)
                      ElevatedButton(
                        onPressed: details.onStepCancel,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('PRÉCÉDENT'),
                      ),
                    ElevatedButton(
                      onPressed: details.onStepContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        _currentStep == _buildSteps().length - 1
                            ? 'TERMINER'
                            : 'SUIVANT',
                      ),
                    ),
                  ],
                ),
              );
            },
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

  @override
  void dispose() {
    _surfaceController.dispose();
    _nbChambreController.dispose();
    _nbDoucheController.dispose();
    _nbCuisineController.dispose();
    _nbPersonneController.dispose();
    _nbrToilettesController.dispose();
    _nbrRobinetController.dispose();
    _surfaceJardinController.dispose();
    _surfacePiscineController.dispose();
    _nbrSallesDeBainController.dispose();
    _nbrEtagesController.dispose();
    _nbrChasseEauController.dispose();
    _agePlomberieController.dispose();
    _dernierRenovationController.dispose();
    _nbrLaveLingeController.dispose();
    _nbrLaveVaisselleController.dispose();
    _utilisationNettoyageController.dispose();
    super.dispose();
  }
}