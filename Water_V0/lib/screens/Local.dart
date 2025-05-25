import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'recup_id_famille.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Formulaire Local',
      theme: ThemeData(primarySwatch: Colors.green),
      home: Step1Location(),
    );
  }
}

// Étape 1: Récupération de la localisation
class Step1Location extends StatefulWidget {
  const Step1Location({super.key});

  @override
  _Step1LocationState createState() => _Step1LocationState();
}

class _Step1LocationState extends State<Step1Location> {
  final TextEditingController _addressController = TextEditingController();
  bool _loadingLocation = false;
  LatLng _currentPosition = const LatLng(31.7917, -7.0926);
  GoogleMapController? _mapController;
  String _coordinates = "";
  int? _adresseId; // Pour stocker l'ID de l'adresse retourné par le serveur

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

          print('📍 Ville: $city');
          print('🏘 Quartier: $neighbourhood');
          print('🌍 Région: $region');

          setState(() {
            _addressController.text =
                "Ville: ${city ?? 'Inconnue'}\nQuartier: ${neighbourhood ?? 'Inconnu'}\nRégion: ${region ?? 'Inconnue'}";
          });

          // Envoi des données au serveur Flask et récupération de l'ID
          _adresseId = await sendLocationData(
            city ?? "Inconnu",
            neighbourhood ?? "Inconnu",
            region ?? "Inconnue",
            lat,
            lon,
          );
        }
      } else {
        print(
          '⚠ Erreur lors de la récupération de l\'adresse. Code ${response.statusCode}',
        );
      }
    } catch (e) {
      print('🚨 Erreur lors de la requête: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _loadingLocation = true);

    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      print('⛔ Permission de localisation refusée.');
      setState(() => _loadingLocation = false);
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      print(
        '✅ Position GPS obtenue: Latitude ${position.latitude}, Longitude ${position.longitude}',
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
      print('🚨 Erreur lors de la récupération de la localisation: $e');
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
        print("✅ Données envoyées avec succès !");
        final responseData = json.decode(response.body);
        return responseData['adresse_id']; // Supposons que le serveur retourne l'ID
      } else {
        print("❌ Erreur d'envoi : ${response.body}");
        return null;
      }
    } catch (e) {
      print("Erreur lors de l'envoi: $e");
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

            // Champ Adresse
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

            // Bouton GPS
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

            // Affichage des coordonnées
            Text(
              _coordinates,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Carte Google Maps
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

            // Bouton pour passer à l'étape suivante
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

// Étape 2: Détails du local
class Step2LocalDetails extends StatefulWidget {
  final int adresseId;

  const Step2LocalDetails({super.key, required this.adresseId});

  @override
  _Step2LocalDetailsState createState() => _Step2LocalDetailsState();
}

class _Step2LocalDetailsState extends State<Step2LocalDetails> {
  final _formKey = GlobalKey<FormState>();
  String _codeFamille = "";

  // Contrôleurs pour les champs du formulaire
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _surfaceController = TextEditingController();
  final TextEditingController _nbChambreController = TextEditingController();
  final TextEditingController _nbDoucheController = TextEditingController();
  final TextEditingController _nbVoitureController = TextEditingController();
  final TextEditingController _nbCuisineController = TextEditingController();
  final TextEditingController _nbPersonneController = TextEditingController();

  // Valeurs pour les cases à cocher
  bool _piscine = false;
  bool _garage = false;
  bool _jardin = false;

  bool _isSubmitting = false;
  bool _isLoading = true;

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

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_codeFamille.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Code famille non disponible')),
        );
        return;
      }

      setState(() => _isSubmitting = true);

      final localData = {
        "type": _typeController.text,
        "surface": double.parse(_surfaceController.text),
        "nbChambre": int.parse(_nbChambreController.text),
        "nbDouche": int.parse(_nbDoucheController.text),
        "nbVoiture": int.parse(_nbVoitureController.text),
        "nbCuisine": int.parse(_nbCuisineController.text),
        "piscine": _piscine,
        "garage": _garage,
        "jardin": _jardin,
        "codeFamille": _codeFamille,
        "adress": widget.adresseId,
        "nb_personne": int.parse(_nbPersonneController.text),
      };

      final url = Uri.parse("http://127.0.0.1:5000/local");

      try {
        final response = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(localData),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Local enregistré avec succès!')),
          );
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Erreur: ${response.body}')));
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur lors de l\'envoi: $e')));
      } finally {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Étape 2: Détails du Local")),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type de local
                      TextFormField(
                        controller: _typeController,
                        decoration: const InputDecoration(
                          labelText: 'Type de local*',
                          hintText: 'Appartement, Maison, Villa...',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer le type de local';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Surface
                      TextFormField(
                        controller: _surfaceController,
                        decoration: const InputDecoration(
                          labelText: 'Surface (m²)*',
                          hintText: 'Ex: 120',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer la surface';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Veuillez entrer un nombre valide';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Nombre de chambres
                      TextFormField(
                        controller: _nbChambreController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre de chambres*',
                          hintText: 'Ex: 3',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer le nombre de chambres';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Veuillez entrer un nombre valide';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Nombre de douches
                      TextFormField(
                        controller: _nbDoucheController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre de douches*',
                          hintText: 'Ex: 2',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer le nombre de douches';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Veuillez entrer un nombre valide';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Nombre de cuisines
                      TextFormField(
                        controller: _nbCuisineController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre de cuisines*',
                          hintText: 'Ex: 1',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer le nombre de cuisines';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Veuillez entrer un nombre valide';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Nombre de places de voiture
                      TextFormField(
                        controller: _nbVoitureController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre de places de voiture*',
                          hintText: 'Ex: 1',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer le nombre de places de voiture';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Veuillez entrer un nombre valide';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Nombre de personnes
                      TextFormField(
                        controller: _nbPersonneController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre de personnes*',
                          hintText: 'Ex: 4',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer le nombre de personnes';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Veuillez entrer un nombre valide';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Cases à cocher
                      CheckboxListTile(
                        title: const Text('Piscine'),
                        value: _piscine,
                        onChanged: (bool? value) {
                          setState(() {
                            _piscine = value ?? false;
                          });
                        },
                      ),
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
                      const SizedBox(height: 24),

                      // Bouton de soumission
                      Center(
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 15,
                            ),
                          ),
                          child:
                              _isSubmitting
                                  ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                  : const Text('Enregistrer le Local'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  @override
  void dispose() {
    _typeController.dispose();
    _surfaceController.dispose();
    _nbChambreController.dispose();
    _nbDoucheController.dispose();
    _nbVoitureController.dispose();
    _nbCuisineController.dispose();
    _nbPersonneController.dispose();
    super.dispose();
  }
}
