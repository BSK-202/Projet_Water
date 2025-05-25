import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:water_v0/screens/BottomNavigationBar.dart';
import 'dart:convert';
import 'recup_id_famille.dart';
import 'Local.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocalFamilleScreen extends StatefulWidget {
  final Map<String, dynamic>? initialLocalData;
  final bool isChef; // Nouveau paramètre

const LocalFamilleScreen({
    Key? key, 
    this.initialLocalData,
    required this.isChef, // Marqué comme requis
  }) : super(key: key);

 
  @override
  _LocalFamilleScreenState createState() => _LocalFamilleScreenState();

}

class _LocalFamilleScreenState extends State<LocalFamilleScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _localData;
  bool _isEditing = false;
  // Pour la carte et la localisation
  bool _loadingLocation = false;
  LatLng _currentPosition = const LatLng(
    31.7917,
    -7.0926,
  ); // Position par défaut
  GoogleMapController? _mapController;
  String _coordinates = "";
  // Contrôleurs pour l'édition
  final TextEditingController _typeController = TextEditingController();
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

  // Contrôleurs pour l'adresse
  final TextEditingController _villeController = TextEditingController();
  final TextEditingController _quartierController = TextEditingController();
  final TextEditingController _regionController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();

  // Valeurs des listes déroulantes
  String? _selectedTypeTuyauterie;
  String? _selectedTypeChauffeEau;
  String? _selectedTypeLocal;

  // Cases à cocher
  bool _piscine = false;
  bool _garage = false;
  bool _jardin = false;
  bool _arrosageAutomatique = false;
  bool _statutOccupation = false;

  // Liste des types de local
  final List<String> _typesLocal = [
    'Appartement',
    'Maison',
    'Villa',
    'Bureau',
    'Commerce',
    'Autre',
  ];

  @override
  void initState() {
    super.initState();

    // Si on a reçu des données initiales, on les utilise directement
    if (widget.initialLocalData != null) {
      _localData = widget.initialLocalData;
      _initializeControllers();
      setState(() => _isLoading = false);
    } else {
      // Sinon, on charge les données comme avant
      _loadLocalData();
    }
  }

  Future<void> _loadLocalData() async {
    final codeFamille = await getUserId();
    if (codeFamille == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
          'http://10.0.2.2:5000/check-local?code_famille=$codeFamille',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['has_local']) {
          setState(() {
            _localData = data['local'];
            _initializeControllers();
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur de chargement: $e')));
    }
  }

  void _initializeControllers() {
    if (_localData == null) return;

    _typeController.text = _localData!['type'] ?? '';
    _surfaceController.text = _localData!['surface']?.toString() ?? '';
    _nbChambreController.text = _localData!['nbChambre']?.toString() ?? '';
    _nbDoucheController.text = _localData!['nbDouche']?.toString() ?? '';
    _nbCuisineController.text = _localData!['nbCuisine']?.toString() ?? '';
    _nbPersonneController.text = _localData!['nb_personne']?.toString() ?? '';
    _nbrToilettesController.text =
        _localData!['nbr_toilettes']?.toString() ?? '';
    _nbrRobinetController.text = _localData!['nbr_robinets']?.toString() ?? '';
    _surfaceJardinController.text =
        _localData!['surface_jardin']?.toString() ?? '';
    _surfacePiscineController.text =
        _localData!['surface_piscine']?.toString() ?? '';
    _nbrSallesDeBainController.text =
        _localData!['nbr_salles_de_bain']?.toString() ?? '';
    _nbrEtagesController.text = _localData!['nbr_etages']?.toString() ?? '';
    _nbrChasseEauController.text =
        _localData!['nbr_chasse_eau']?.toString() ?? '';
    _agePlomberieController.text =
        _localData!['age_plomberie']?.toString() ?? '';
    _dernierRenovationController.text =
        _localData!['dernier_renovation_plomberie']?.toString() ?? '';
    _nbrLaveLingeController.text =
        _localData!['nbr_lave_linge']?.toString() ?? '';
    _nbrLaveVaisselleController.text =
        _localData!['nbr_lave_vaisselle']?.toString() ?? '';
    _utilisationNettoyageController.text =
        _localData!['utilisation_nettoyage_sols']?.toString() ?? '';

    // Initialisation des contrôleurs d'adresse
    _villeController.text = _localData!['ville']?.toString() ?? '';
    _quartierController.text = _localData!['quartier']?.toString() ?? '';
    _regionController.text = _localData!['region']?.toString() ?? '';
    _latitudeController.text = _localData!['latitude']?.toString() ?? '';
    _longitudeController.text = _localData!['longitude']?.toString() ?? '';

    _selectedTypeTuyauterie = _localData!['type_tuyauterie'];
    _selectedTypeChauffeEau = _localData!['type_chauffe_eau'];
    _selectedTypeLocal = _localData!['type'];

    _piscine = _localData!['piscine'] ?? false;
    _garage = _localData!['garage'] ?? false;
    _jardin = _localData!['jardin'] ?? false;
    _arrosageAutomatique = _localData!['arrosage_automatique'] ?? false;
    _statutOccupation = _localData!['statut_occupation'] ?? false;
  }

  Future<void> _updateLocal() async {
    if (_localData == null) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.put(
        Uri.parse('http://10.0.2.2:5000/update-local'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'local_id': _localData!['IDlocal'],
          'type': _selectedTypeLocal,
          'surface': double.tryParse(_surfaceController.text),
          'nbChambre': int.tryParse(_nbChambreController.text),
          'nbDouche': int.tryParse(_nbDoucheController.text),
          'nbCuisine': int.tryParse(_nbCuisineController.text),
          'piscine': _piscine,
          'garage': _garage,
          'jardin': _jardin,
          'nb_personne': int.tryParse(_nbPersonneController.text),
          'nbr_toilettes': int.tryParse(_nbrToilettesController.text),
          'nbr_robinets': int.tryParse(_nbrRobinetController.text),
          'surface_jardin': double.tryParse(_surfaceJardinController.text),
          'surface_piscine': double.tryParse(_surfacePiscineController.text),
          'nbr_salles_de_bain': int.tryParse(_nbrSallesDeBainController.text),
          'nbr_etages': int.tryParse(_nbrEtagesController.text),
          'nbr_chasse_eau': int.tryParse(_nbrChasseEauController.text),
          'age_plomberie': int.tryParse(_agePlomberieController.text),
          'type_tuyauterie': _selectedTypeTuyauterie,
          'dernier_renovation_plomberie': int.tryParse(
            _dernierRenovationController.text,
          ),
          'type_chauffe_eau': _selectedTypeChauffeEau,
          'arrosage_automatique': _arrosageAutomatique,
          'nbr_lave_linge': int.tryParse(_nbrLaveLingeController.text),
          'nbr_lave_vaisselle': int.tryParse(_nbrLaveVaisselleController.text),
          'utilisation_nettoyage_sols': double.tryParse(
            _utilisationNettoyageController.text,
          ),
          'statut_occupation': _statutOccupation,
          'ville': _villeController.text,
          'quartier': _quartierController.text,
          'region': _regionController.text,
          'latitude': double.tryParse(_latitudeController.text),
          'longitude': double.tryParse(_longitudeController.text),
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                responseData['message'] ?? 'Local mis à jour avec succès!',
              ),
              backgroundColor: Colors.green[700],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          await _loadLocalData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                responseData['message'] ?? 'La mise à jour a échoué',
              ),
              backgroundColor: Colors.red[700],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } else {
        final errorData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorData['error'] ?? 'Erreur lors de la mise à jour',
            ),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la mise à jour: $e'),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
        _isEditing = false;
      });
    }
  }

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
            _villeController.text = city ?? '';
            _quartierController.text = neighbourhood ?? '';
            _regionController.text = region ?? '';
            _latitudeController.text = lat.toString();
            _longitudeController.text = lon.toString();
          });
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

  // Nouveau style pour les cartes d'information
  Widget _buildInfoCard(String label, String value) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.green.withOpacity(0.2), width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.green[800],
                  fontSize: 15,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Nouveau style pour les titres de section
  Widget _buildSectionTitle(String title) {
    return Container(
      margin: EdgeInsets.only(top: 24, bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.green[700],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green[800],
              letterSpacing: 0.5,
            ),
          ),
          Expanded(
            child: Divider(
              color: Colors.green[200],
              thickness: 1,
              indent: 8,
              endIndent: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditField(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
    IconData? icon,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.green[700],
            fontWeight: FontWeight.w500,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.green, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.green.shade300, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.green.shade700, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey[50],
          prefixIcon:
              icon != null ? Icon(icon, color: Colors.green[600]) : null,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        keyboardType:
            isNumber
                ? TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildNumberField(
    String label,
    TextEditingController controller, {
    double? min,
    double? max,
    IconData? icon,
    String? suffix,
    bool isDecimal = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.green[700],
            fontWeight: FontWeight.w500,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.green, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.green.shade300, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.green.shade700, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey[50],
          prefixIcon:
              icon != null ? Icon(icon, color: Colors.green[600]) : null,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (suffix != null)
                Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Text(
                    suffix,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              Container(
                margin: EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () {
                        final currentValue =
                            isDecimal
                                ? double.tryParse(controller.text) ?? 0
                                : int.tryParse(controller.text) ?? 0;
                        if (max == null || currentValue < max) {
                          controller.text =
                              isDecimal
                                  ? (currentValue + 0.1).toStringAsFixed(1)
                                  : (currentValue + 1).toString();
                        }
                      },
                      child: Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.add,
                          color: Colors.green[700],
                          size: 18,
                        ),
                      ),
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.green.shade200,
                    ),
                    InkWell(
                      onTap: () {
                        final currentValue =
                            isDecimal
                                ? double.tryParse(controller.text) ?? 0
                                : int.tryParse(controller.text) ?? 0;
                        if (min == null || currentValue > min) {
                          controller.text =
                              isDecimal
                                  ? (currentValue - 0.1).toStringAsFixed(1)
                                  : (currentValue - 1).toString();
                        }
                      },
                      child: Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.remove,
                          color: Colors.green[700],
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
        inputFormatters: [
          isDecimal
              ? FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$'))
              : FilteringTextInputFormatter.digitsOnly,
        ],
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildCheckbox(String label, bool value, Function(bool?) onChanged) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: value ? Colors.green.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? Colors.green.shade300 : Colors.grey.shade300,
          width: 1.5,
        ),
      ),
      child: CheckboxListTile(
        title: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: value ? Colors.green[800] : Colors.grey[800],
            fontSize: 16,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: Colors.green[700],
        checkColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        secondary: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:
                value
                    ? Colors.green.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            value ? Icons.check_circle : Icons.circle_outlined,
            color: value ? Colors.green[700] : Colors.grey[600],
            size: 24,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String? value,
    List<String> items,
    Function(String?) onChanged, {
    IconData? icon,
  }) {
    final selectedValue =
        (value == null || !items.contains(value)) ? items.first : value;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        value: selectedValue,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.green[700],
            fontWeight: FontWeight.w500,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.green, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.green.shade300, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.green.shade700, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey[50],
          prefixIcon:
              icon != null ? Icon(icon, color: Colors.green[600]) : null,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        items:
            items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                ),
              );
            }).toList(),
        onChanged: onChanged,
        icon: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.arrow_drop_down, color: Colors.green[700]),
        ),
        dropdownColor: Colors.white,
        style: TextStyle(fontSize: 16, color: Colors.grey[800]),
      ),
    );
  }

  Widget _buildAddressInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_localData!['ville'] != null &&
            _localData!['ville'].toString().isNotEmpty)
          _buildInfoCard('Ville', _localData!['ville'].toString()),
        if (_localData!['quartier'] != null &&
            _localData!['quartier'].toString().isNotEmpty)
          _buildInfoCard('Quartier', _localData!['quartier'].toString()),
        if (_localData!['region'] != null &&
            _localData!['region'].toString().isNotEmpty)
          _buildInfoCard('Région', _localData!['region'].toString()),
        if (_localData!['latitude'] != null && _localData!['longitude'] != null)
          _buildInfoCard(
            'Coordonnées',
            '${_localData!['latitude']}, ${_localData!['longitude']}',
          ),
      ],
    );
  }

  Widget _buildAddressEditFields() {
    return Column(
      children: [
        _buildSectionTitle('Adresse'),
        _buildEditField('Ville', _villeController, icon: Icons.location_city),
        SizedBox(height: 8),
        _buildEditField('Quartier', _quartierController, icon: Icons.home_work),
        SizedBox(height: 8),
        _buildEditField('Région', _regionController, icon: Icons.map),
        SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _loadingLocation ? null : _getCurrentLocation,
          icon: Icon(Icons.location_on),
          label:
              _loadingLocation
                  ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text('Localisation en cours...'),
                    ],
                  )
                  : Text('Utiliser ma position actuelle'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[700],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            elevation: 2,
          ),
        ),
        SizedBox(height: 16),
        if (_coordinates.isNotEmpty)
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on, color: Colors.green[700]),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _coordinates,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.green[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
        SizedBox(height: 16),
        Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade300, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentPosition,
                zoom: 14,
              ),
              markers: {
                Marker(
                  markerId: MarkerId("currentLocation"),
                  position: _currentPosition,
                ),
              },
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
            ),
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildNumberField(
                'Latitude',
                _latitudeController,
                icon: Icons.explore,
                isDecimal: true,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _buildNumberField(
                'Longitude',
                _longitudeController,
                icon: Icons.explore,
                isDecimal: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildViewMode() {
    if (_localData == null) {
      return Center(child: Text('Aucune donnée de local disponible'));
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec informations principales
          Container(
            width: double.infinity,
            margin: EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade700, Colors.green.shade500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _localData!['type'] == 'Appartement'
                              ? Icons.apartment
                              : _localData!['type'] == 'Maison'
                              ? Icons.home
                              : _localData!['type'] == 'Villa'
                              ? Icons.villa
                              : _localData!['type'] == 'Bureau'
                              ? Icons.business
                              : _localData!['type'] == 'Commerce'
                              ? Icons.store
                              : Icons.home_work,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _localData!['type']?.toString() ??
                                  'Type non spécifié',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            if (_localData!['ville'] != null)
                              Text(
                                _localData!['ville']?.toString() ?? '',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      _buildHeaderStat(
                        '${_localData!['surface']?.toString() ?? '0'} m²',
                        'Surface',
                        Icons.square_foot,
                      ),
                      _buildHeaderStat(
                        _localData!['nbChambre']?.toString() ?? '0',
                        'Chambres',
                        Icons.bed,
                      ),
                      _buildHeaderStat(
                        _localData!['nb_personne']?.toString() ?? '0',
                        'Personnes',
                        Icons.people,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Section Adresse en haut
          _buildSectionTitle('Adresse'),
          _buildAddressInfo(),

          _buildSectionTitle('Caractéristiques principales'),
          _buildInfoCard(
            'Surface',
            '${_localData!['surface']?.toString() ?? '0'} m²',
          ),
          _buildInfoCard(
            'Nombre de chambres',
            _localData!['nbChambre']?.toString() ?? '0',
          ),
          _buildInfoCard(
            'Nombre de personnes',
            _localData!['nb_personne']?.toString() ?? '0',
          ),
          _buildInfoCard(
            'Statut occupation',
            _localData!['statut_occupation'] == true ? 'Occupé' : 'Non occupé',
          ),

          _buildSectionTitle('Installations sanitaires'),
          // Grille pour les installations sanitaires
          GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            crossAxisSpacing: 0,
            mainAxisSpacing: 0,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            children: [
              _buildGridInfoCard(
                'Douches',
                _localData!['nbDouche']?.toString() ?? '0',
                Icons.shower,
              ),
              _buildGridInfoCard(
                'Cuisines',
                _localData!['nbCuisine']?.toString() ?? '0',
                Icons.kitchen,
              ),
              _buildGridInfoCard(
                'Toilettes',
                _localData!['nbr_toilettes']?.toString() ?? '0',
                Icons.wc,
              ),
              _buildGridInfoCard(
                'Salles de bain',
                _localData!['nbr_salles_de_bain']?.toString() ?? '0',
                Icons.bathtub,
              ),
              _buildGridInfoCard(
                'Robinets',
                _localData!['nbr_robinets']?.toString() ?? '0',
                Icons.water_drop,
              ),
              _buildGridInfoCard(
                'Chasses d\'eau',
                _localData!['nbr_chasse_eau']?.toString() ?? '0',
                Icons.water,
              ),
            ],
          ),

          _buildSectionTitle('Plomberie'),
          _buildInfoCard(
            'Type tuyauterie',
            _localData!['type_tuyauterie']?.toString() ?? 'Non spécifié',
          ),
          _buildInfoCard(
            'Type chauffe-eau',
            _localData!['type_chauffe_eau']?.toString() ?? 'Non spécifié',
          ),
          _buildInfoCard(
            'Âge plomberie',
            '${_localData!['age_plomberie']?.toString() ?? '0'} ans',
          ),
          _buildInfoCard(
            'Dernière rénovation',
            '${_localData!['dernier_renovation_plomberie']?.toString() ?? '0'} ans',
          ),

          _buildSectionTitle('Équipements'),
          _buildInfoCard(
            'Lave-linge',
            _localData!['nbr_lave_linge']?.toString() ?? '0',
          ),
          _buildInfoCard(
            'Lave-vaisselle',
            _localData!['nbr_lave_vaisselle']?.toString() ?? '0',
          ),
          _buildInfoCard(
            'Nettoyage sols',
            '${_localData!['utilisation_nettoyage_sols']?.toString() ?? '0'} L/mois',
          ),

          _buildSectionTitle('Extérieurs'),
          // Cartes pour les extérieurs
          Row(
            children: [
              Expanded(
                child: _buildFeatureCard(
                  'Piscine',
                  _localData!['piscine'] == true,
                  Icons.pool,
                  _localData!['piscine'] == true
                      ? '${_localData!['surface_piscine']?.toString() ?? '0'} m²'
                      : null,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildFeatureCard(
                  'Garage',
                  _localData!['garage'] == true,
                  Icons.garage,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          _buildFeatureCard(
            'Jardin',
            _localData!['jardin'] == true,
            Icons.grass,
            _localData!['jardin'] == true
                ? '${_localData!['surface_jardin']?.toString() ?? '0'} m² ${_localData!['arrosage_automatique'] == true ? '• Arrosage auto.' : ''}'
                : null,
          ),
  
         // Dans la méthode _buildViewMode(), remplacez la partie du bouton par ceci :
if (widget.isChef) ...[
  SizedBox(height: 30),
Center(
  child: ElevatedButton.icon(
    onPressed: () => setState(() => _isEditing = true),
    icon: Icon(Icons.edit),
    label: Text('Modifier les informations'),
    style: ElevatedButton.styleFrom(
      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 16),
      backgroundColor: Colors.green[700],
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 3,
    ),
  ),

),
],

SizedBox(height: 20),

        ],
      ),
    );
  }

  // Nouveau widget pour les statistiques dans l'en-tête
  Widget _buildHeaderStat(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Nouveau widget pour les cartes de la grille
  Widget _buildGridInfoCard(String label, String value, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.green.withOpacity(0.2), width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.green[700], size: 20),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Nouveau widget pour les cartes de fonctionnalités
  Widget _buildFeatureCard(
    String title,
    bool hasFeature,
    IconData icon, [
    String? details,
  ]) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            hasFeature
                ? Colors.green.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasFeature ? Colors.green.shade300 : Colors.grey.shade300,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      hasFeature
                          ? Colors.green.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: hasFeature ? Colors.green[700] : Colors.grey[600],
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: hasFeature ? Colors.green[800] : Colors.grey[700],
                ),
              ),
              Spacer(),
              Icon(
                hasFeature ? Icons.check_circle : Icons.cancel,
                color: hasFeature ? Colors.green[700] : Colors.grey[400],
                size: 20,
              ),
            ],
          ),
          if (details != null) ...[
            SizedBox(height: 8),
            Text(
              details,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEditMode() {
    final typesTuyauterie = ['Cuivre', 'PVC', 'PER', 'Acier', 'Multicouche'];
    final typesChauffeEau = ['Électrique', 'Gaz', 'Solaire', 'Thermodynamique'];

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // En-tête du mode édition
          Container(
            width: double.infinity,
            margin: EdgeInsets.only(bottom: 24),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.shade300, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.edit_document,
                        color: Colors.green[700],
                        size: 28,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mode Édition',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[800],
                            ),
                          ),
                          Text(
                            'Modifiez les informations de votre local',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          _buildSectionTitle('Type de local'),
          _buildDropdown('Type de local*', _selectedTypeLocal, _typesLocal, (
            value,
          ) {
            setState(() => _selectedTypeLocal = value);
          }, icon: Icons.home),

          // Champs d'adresse en mode édition
          _buildAddressEditFields(),

          _buildSectionTitle('Caractéristiques principales'),
          _buildNumberField(
            'Surface (m²)*',
            _surfaceController,
            icon: Icons.square_foot,
            suffix: 'm²',
            isDecimal: true,
            min: 0,
          ),
          _buildNumberField(
            'Nombre de chambres',
            _nbChambreController,
            icon: Icons.bed,
            min: 0,
          ),
          _buildNumberField(
            'Nombre de personnes*',
            _nbPersonneController,
            icon: Icons.people,
            min: 0,
          ),
          _buildCheckbox('Local occupé', _statutOccupation, (value) {
            setState(() => _statutOccupation = value ?? false);
          }),

          _buildSectionTitle('Installations sanitaires'),
          // Grille pour les champs d'édition des installations sanitaires
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildNumberField(
                      'Douches',
                      _nbDoucheController,
                      icon: Icons.shower,
                      min: 0,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _buildNumberField(
                      'Cuisines',
                      _nbCuisineController,
                      icon: Icons.kitchen,
                      min: 0,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: _buildNumberField(
                      'Toilettes',
                      _nbrToilettesController,
                      icon: Icons.wc,
                      min: 0,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _buildNumberField(
                      'Salles de bain',
                      _nbrSallesDeBainController,
                      icon: Icons.bathtub,
                      min: 0,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: _buildNumberField(
                      'Robinets',
                      _nbrRobinetController,
                      icon: Icons.water_drop,
                      min: 0,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _buildNumberField(
                      'Chasses d\'eau',
                      _nbrChasseEauController,
                      icon: Icons.water,
                      min: 0,
                    ),
                  ),
                ],
              ),
            ],
          ),

          _buildSectionTitle('Plomberie'),
          _buildNumberField(
            'Âge de la plomberie (années)',
            _agePlomberieController,
            icon: Icons.calendar_today,
            suffix: 'ans',
            min: 0,
          ),
          _buildDropdown(
            'Type de tuyauterie',
            _selectedTypeTuyauterie,
            typesTuyauterie,
            (value) {
              setState(() => _selectedTypeTuyauterie = value);
            },
            icon: Icons.plumbing,
          ),
          _buildNumberField(
            'Dernière rénovation (années)',
            _dernierRenovationController,
            icon: Icons.build,
            suffix: 'ans',
            min: 0,
          ),
          _buildDropdown(
            'Type de chauffe-eau',
            _selectedTypeChauffeEau,
            typesChauffeEau,
            (value) {
              setState(() => _selectedTypeChauffeEau = value);
            },
            icon: Icons.hot_tub,
          ),

          _buildSectionTitle('Équipements'),
          _buildNumberField(
            'Nombre de lave-linge',
            _nbrLaveLingeController,
            icon: Icons.local_laundry_service,
            min: 0,
          ),
          _buildNumberField(
            'Nombre de lave-vaisselle',
            _nbrLaveVaisselleController,
            icon: Icons.countertops,
            min: 0,
          ),
          _buildNumberField(
            'Utilisation nettoyage (L/mois)',
            _utilisationNettoyageController,
            icon: Icons.cleaning_services,
            suffix: 'L/mois',
            isDecimal: true,
            min: 0,
          ),

          _buildSectionTitle('Extérieurs'),
          _buildCheckbox('Piscine', _piscine, (value) {
            setState(() => _piscine = value ?? false);
          }),
          if (_piscine)
            _buildNumberField(
              'Surface piscine (m²)',
              _surfacePiscineController,
              icon: Icons.pool,
              suffix: 'm²',
              isDecimal: true,
              min: 0,
            ),

          _buildCheckbox('Garage', _garage, (value) {
            setState(() => _garage = value ?? false);
          }),

          _buildCheckbox('Jardin', _jardin, (value) {
            setState(() => _jardin = value ?? false);
          }),

          if (_jardin) ...[
            _buildNumberField(
              'Surface jardin (m²)',
              _surfaceJardinController,
              icon: Icons.grass,
              suffix: 'm²',
              isDecimal: true,
              min: 0,
            ),
            _buildCheckbox('Arrosage automatique', _arrosageAutomatique, (
              value,
            ) {
              setState(() => _arrosageAutomatique = value ?? false);
            }),
          ],

          SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() => _isEditing = false);
                    _initializeControllers();
                  },
                  icon: Icon(Icons.cancel),
                  label: Text('Annuler'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.grey[800],
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _updateLocal,
                  icon: Icon(Icons.save),
                  label: Text('Enregistrer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

@override
Widget build(BuildContext context) {
  // Create a common bottom navigation bar that we'll use in all states
  final bottomBar = CustomBottomNavigationBar(
    currentIndex: 0,
    userId: '', // You should pass the actual user ID here
    isChef: true, // Adjust this based on your logic
    onTap: (i) {
      // Handle navigation here
    },
  );

  if (_isLoading) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mon Local', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green[700],
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                strokeWidth: 3,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Chargement des données...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.green[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: bottomBar,
    );
  }

  if (_localData == null) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mon Local', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green[700],
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.home, size: 80, color: Colors.green[700]),
            ),
            SizedBox(height: 24),
            Text(
              'Aucun local enregistré',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green[800],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Créez un nouveau local pour commencer',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => Step1Location()),
                );
              },
              icon: Icon(Icons.add_home),
              label: Text('Créer un nouveau local'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: bottomBar,
    );
  }

 return Scaffold(
    appBar: AppBar(
      title: Text('Mon Local', style: TextStyle(color: Colors.white)),
      backgroundColor: Colors.green[700],
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
    ),
    body: _isEditing && widget.isChef ? _buildEditMode() : _buildViewMode(),
    bottomNavigationBar: bottomBar,
  );

}

  @override
  void dispose() {
    _mapController?.dispose();
    _typeController.dispose();
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

    // Dispose des contrôleurs d'adresse
    _villeController.dispose();
    _quartierController.dispose();
    _regionController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();

    super.dispose();
  }
}