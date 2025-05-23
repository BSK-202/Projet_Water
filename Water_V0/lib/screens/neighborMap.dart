import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:water_v0/models/family.dart';
import 'package:water_v0/screens/BottomNavigationBar.dart';
import 'package:water_v0/screens/getUserLocalisation.dart';
import 'package:water_v0/screens/rankingPage.dart';
import 'package:flutter/scheduler.dart';

import 'package:fl_chart/fl_chart.dart';
import 'package:water_v0/screens/recup_id_famille.dart';

import 'user_details_widget.dart';

class MapUsers extends StatefulWidget {
  const MapUsers({super.key});
  @override
  _MapUsersState createState() => _MapUsersState();
}

class _MapUsersState extends State<MapUsers> {
  final Completer<GoogleMapController> _controller = Completer();
  static LatLng _initialPosition = LatLng(0, 0);
  static List<Family> families = [];
  static Map<MarkerId, Marker> _markers = <MarkerId, Marker>{};
  String? _mapStyle;
  bool _isLoading = true;
  Family? _selectedUser;
  Family? _currentFamily;
  int _currentRank = 0;
  int score = 78962;
  final int rank = 28;
  @override
  void initState() {
    super.initState();
    // _loadMapStyle();
    SchedulerBinding.instance?.addPostFrameCallback((_) {
      rootBundle.loadString('assets/map_style.json').then((string) {
        _mapStyle = string;
        print(
          "*************************************************map style**********************************",
        );
        print(_mapStyle);
      });
    });
    super.initState();
    _getCurrentLocation();
  }

  /*Future<void> _loadMapStyle() async {
    // Chargez le style JSON depuis les assets
    _mapStyle = await rootBundle.loadString('Water_V0/assets/map_style.json');
  }*/

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Location services are disabled. Please enable the services',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permissions are denied'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Location permissions are permanently denied, we cannot request permissions.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    await fetchCurrentUserFamily();
    _initializeUsers();
  }

  Future<void> fetchCurrentUserFamily() async {
    String? userId = "FAM009"; // await getUserId();
    print(
      "*************************************************user id**********************************",
    );
    //print(await getUserId());
    final response = await http.get(
      Uri.parse('http://127.0.0.1:5000/get_family/$userId'),
    );

    if (response.statusCode == 200) {
      setState(() {
        dynamic currentFamily = json.decode(response.body);
        Family fam = Family.fromJson(currentFamily['family']);
        _currentFamily = fam;
        score = fam.score;
        _initialPosition = LatLng(fam.latitude, fam.longitude);
        print(
          "*************************************************initial position**********************************",
        );
        print(fam.score);
        print(fam.latitude);
        print(fam.longitude);
        _isLoading = false;
      });
    } else {
      throw Exception('Échec du chargement des données');
    }
  }

  Future<Uint8List> getBytesFromAsset(String path) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: 80,
      targetHeight: 80,
    );
    ui.FrameInfo fi = await codec.getNextFrame();
    ui.Image image = fi.image;
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint();
    final double radius = 80.0;
    final Rect rect = Rect.fromLTWH(0.0, 0.0, 80, 80);
    final RRect rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    canvas.drawRRect(rrect, paint);
    canvas.clipRRect(rrect);
    canvas.drawImage(image, Offset.zero, paint);

    final ui.Image finalImage = await pictureRecorder.endRecording().toImage(
      80,
      80,
    );
    final ByteData? byteData = await finalImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return byteData!.buffer.asUint8List();
  }

  void addMarkers() async {
    for (Family user in families) {
      Uint8List iconData = await getBytesFromAsset('assets/image.png');
      LatLng position = LatLng(user.latitude, user.longitude);
      Marker marker = Marker(
        markerId: MarkerId(user.id),
        onTap: () async {
          GoogleMapController controller = await _controller.future;
          controller.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(bearing: 0, target: position, zoom: 10.0),
            ),
          );
          setState(() {
            _selectedUser = user;
          });
          _showUserDetails(user);
        },
        position: position,
        icon: BitmapDescriptor.fromBytes(iconData),
      );
      setState(() {
        _markers[MarkerId(user.id)] = marker;
      });
    }
  }

  Future<void> _initializeUsers() async {
    await _loadUsers();
    if (families.isNotEmpty) {
      addMarkers();
      // Calculate current family rank
      if (_currentFamily != null) {
        families.sort((a, b) => b.score.compareTo(a.score));
        for (int i = 0; i < families.length; i++) {
          if (families[i].id == _currentFamily!.id) {
            setState(() {
              _currentRank = i + 1;
            });
            break;
          }
        }
      }
    }
  }

  _loadUsers() async {
    List<Family> usrs = await ApiService.fetchUsers();
    setState(() {
      families = usrs;
      print(families);
    });
  }

  void _showUserDetails(Family user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UserDetailsWidget(user: user),
    );
  }

  void _navigateToNextPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ClassementScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const ui.Color.fromARGB(255, 119, 172, 128),
              const ui.Color.fromARGB(245, 244, 246, 244),
            ],
          ),
        ),
        child:
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(
                    color: Color.fromARGB(255, 65, 122, 108),
                  ),
                )
                : SizedBox(
                  width: width,
                  height: height,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Top frame showing rank and score
                      Positioned(
                        top: 50,
                        left: 10,
                        right: 10,
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.9,
                          padding: EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.3),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.show_chart, color: Colors.green),
                                  SizedBox(width: 8),
                                  Text(
                                    "Dashboard",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Spacer(),
                                  Text(
                                    "Consumption statistics",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Total earned",
                                          style: TextStyle(fontSize: 16),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          "$score",
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),

                                        Row(
                                          children: [
                                            Icon(
                                              Icons.star,
                                              color: Colors.orange,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              "Your Rank",
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              "$rank",
                                              style: TextStyle(fontSize: 16),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width * 0.5,
                                    height: 140,

                                    child: BarChart(
                                      BarChartData(
                                        barGroups: _getBarGroups(),
                                        borderData: FlBorderData(show: false),
                                        titlesData: FlTitlesData(
                                          rightTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: false,
                                            ),
                                          ),
                                          leftTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: false,
                                            ),
                                          ),
                                          topTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: false,
                                            ),
                                          ),
                                          bottomTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              getTitlesWidget: (
                                                double value,
                                                TitleMeta meta,
                                              ) {
                                                const months = [
                                                  'Jan',
                                                  'Feb',
                                                  'Mar',
                                                  'Apr',
                                                  'May',
                                                  'June',
                                                ];
                                                return Text(
                                                  months[value.toInt()],
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Map positioned below the top frame
                      Positioned(
                        top: 360,
                        left: 10,
                        right: 10,
                        bottom: 10,
                        child: Container(
                          width: width,
                          // height: height,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              30,
                            ), // Applique le borderRadius
                            child: googleMap(),
                          ),
                        ),
                      ),

                      // Center navigation button
                      Positioned(
                        top: 280,
                        left: 20,
                        right: 20,
                        child: GestureDetector(
                          onTap: _navigateToNextPage,
                          child: Container(
                            width: 20,
                            height: 60,
                            decoration: BoxDecoration(
                              color: const ui.Color.fromARGB(
                                255,
                                229,
                                234,
                                230,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                'Voir le classement',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Bottom user list
                      Positioned(
                        bottom: 10,
                        left: 10,
                        right: 10,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                          child: Container(
                            width: width,
                            height: 60,
                            decoration: BoxDecoration(
                              color: const ui.Color.fromARGB(255, 96, 224, 128),
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(20),
                                bottomRight: Radius.circular(20),
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                              ),
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              scrollDirection: Axis.horizontal,
                              itemCount: families.length,
                              itemBuilder: (context, index) {
                                return profileCard(families[index]);
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: 0,
        userId: "chef4@gmail.com",
        isChef: true,
        onTap: (index) {
          // Gérer les changements d'index si nécessaire
        },
      ),
    );
  }

  List<BarChartGroupData> _getBarGroups() {
    /**les valeurs de ce tableau seront remplacées par celles de la consommation de la famille */
    List<double> data = [8, 10, 6, 12, 14, 7];
    return List.generate(data.length, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: data[index],
            color: Colors.green,
            width: 16,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });
  }

  Widget googleMap() {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _initialPosition,
        zoom: 15.0,
      ),
      mapType: MapType.terrain,
      onMapCreated: (GoogleMapController controller) {
        _controller.complete(controller);
        _mapStyle = _mapStyle;
        //controller. setMapStyle(_mapStyle);
        //setState(() {});
      },

      markers: Set.of(_markers.values),
      zoomControlsEnabled: false,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      compassEnabled: true,
    );
  }

  Widget profileCard(Family user) {
    final bool isSelected = _selectedUser?.id == user.id;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        InkWell(
          onTap: () {
            final MarkerId markerId = MarkerId(user.id);
            final Marker? marker = _markers[markerId];
            if (marker != null) {
              setState(() {
                _selectedUser = user;
              });
              marker.onTap!();
            }
          },
          child: Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(
                color:
                    isSelected
                        ? Colors.white
                        : const Color.fromARGB(255, 128, 203, 196),
                style: BorderStyle.solid,
              ),
              image: const DecorationImage(
                image: AssetImage('assets/image.png'),
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow:
                  isSelected
                      ? [
                        const BoxShadow(
                          color: Colors.white,
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                      : null,
            ),
          ),
        ),
        if (isSelected)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
      ],
    );
  }
}
/*
year, shower duration week , water consumption week, water consumption month, water consumption year,
ajouter des enquetes 
13813 
plumbing features 
leak features (robine
water usage
yorkshire water
unrelated activities 
the selected values repr
bat and relative activities
washing machine
cooking
number of people
number of toilets
number of showers
persons water 
*/