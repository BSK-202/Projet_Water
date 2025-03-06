import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Step2Location extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  final bool canProceed;

  const Step2Location({
    Key? key,
    required this.onNext,
    required this.onBack,
    required this.canProceed,
  }) : super(key: key);

  @override
  _Step2LocationState createState() => _Step2LocationState();
}

class _Step2LocationState extends State<Step2Location> {
  final TextEditingController _addressController = TextEditingController();
  bool _loadingLocation = false;
  LatLng _currentPosition = const LatLng(
    31.7917,
    -7.0926,
  ); // Par défaut : Maroc
  GoogleMapController? _mapController;

  // Fonction pour récupérer la position GPS et afficher la carte
  Future<void> _getCurrentLocation() async {
    setState(() => _loadingLocation = true);

    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Permission refusée. Activez la localisation."),
        ),
      );
      setState(() => _loadingLocation = false);
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );

    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (placemarks.isNotEmpty) {
      Placemark place = placemarks.first;
      String address = "${place.street}, ${place.locality}, ${place.country}";

      setState(() {
        _addressController.text = address;
        _currentPosition = LatLng(position.latitude, position.longitude);
        _mapController?.animateCamera(CameraUpdate.newLatLng(_currentPosition));
        _loadingLocation = false;
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
                'Localisation',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Veuillez entrer votre adresse ou utiliser le GPS.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // Champ Adresse
              TextField(
                controller: _addressController,
                decoration: InputDecoration(
                  hintText: 'Adresse',
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

              // Bouton GPS
              ElevatedButton.icon(
                onPressed: _loadingLocation ? null : _getCurrentLocation,
                icon: const Icon(Icons.location_on),
                label:
                    _loadingLocation
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Utiliser ma position actuelle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Carte Google Maps
              Container(
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
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
              ),
              const SizedBox(height: 24),

              // Boutons de navigation
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
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
                  ElevatedButton(
                    onPressed: widget.canProceed ? widget.onNext : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      minimumSize: const Size(120, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Continuer'),
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
