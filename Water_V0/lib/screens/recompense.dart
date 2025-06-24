import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:water_v0/screens/BottomNavigationBar.dart';
import 'recup_id_famille.dart';

//const String serverUrl = 'http://127.0.0.1:5000';
 const String serverUrl = 'http://127.0.0.1:5000'; // Pour l'émulateur Android

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class RewardsPage extends StatefulWidget {
  const RewardsPage({Key? key}) : super(key: key);

  @override
  _RewardsPageState createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage> {
  Map<String, dynamic>? userData;
  bool isLoading = true;

  Future<void> fetchUserData({bool showError = true}) async {
    setState(() => isLoading = true);

    // Récupération du code famille depuis votre fonction existante
    final String? codeFamille = await getUserId();

    if (codeFamille == null || codeFamille.isEmpty) {
      setState(() => isLoading = false);
      if (showError) {
        scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text('Code famille non disponible')),
        );
      }
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
          '$serverUrl/calculate_rewards?user=$codeFamille',
        ), // Utilisation du code famille
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        setState(() {
          userData = data;
          isLoading = false;
        });
      } else {
        throw Exception('Échec du chargement des données utilisateur');
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (showError) {
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text("Erreur : ${e.toString()}")),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil Utilisateur - Économie d'Eau"),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => fetchUserData(),
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : userData == null || userData!['consommation'] == null
              ? const Center(
                child: Text(
                  "Erreur lors du chargement des données",
                  style: TextStyle(fontSize: 18, color: Colors.red),
                ),
              )
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 50,
                          backgroundImage: AssetImage("assets/avatar1.png"),
                        ),
                        const SizedBox(width: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userData!["nomFamille"] ?? "Famille Inconnue",
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Score : ${userData!['scoreFamille']} points",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildCard(
                      icon: Icons.star,
                      title: "Points Gagnés",
                      subtitle: "${userData!['points']} points 🎉",
                      iconColor: Colors.amber,
                    ),
                    _buildCard(
                      icon: Icons.water_drop,
                      title: "Consommation des 3 Derniers Mois",
                      subtitle:
                          userData!['consommation'] != null &&
                                  userData!['consommation'].isNotEmpty
                              ? "${userData!['consommation'].join(" m³, ")} m³"
                              : "Données de consommation non disponibles",
                      iconColor: Colors.blue,
                    ),
                    _buildCard(
                      icon: Icons.info,
                      title: "Pourquoi avez-vous gagné ces points ?",
                      subtitle:
                          userData!['reasons'] != null &&
                                  userData!['reasons'].isNotEmpty
                              ? "• ${userData!['reasons'].join("\n• ")}"
                              : "Aucune raison disponible",
                      iconColor: Colors.green,
                    ),
                    const SizedBox(height: 20),
                    Expanded(child: _buildChart()),
                  ],
                ),
              ),
     bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: 0,
        userId: "",
        isChef: true,
        onTap: (index) {
          // Gérer les changements d'index si nécessaire
        },
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
  }) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Icon(icon, color: iconColor, size: 40),
        title: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _buildChart() {
    if (userData!['consommation'] == null ||
        userData!['consommation'].isEmpty) {
      return const Center(
        child: Text(
          "Aucune donnée disponible pour le graphique",
          style: TextStyle(fontSize: 16, color: Colors.red),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 1.5,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    "${value.toInt()} m³",
                    style: const TextStyle(fontSize: 12),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  List<String> months = ["M-3", "M-2", "M-1"];
                  if (value.toInt() < 0 || value.toInt() >= months.length) {
                    return const Text("");
                  }
                  return Text(
                    months[value.toInt()],
                    style: const TextStyle(fontSize: 12),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(userData!['consommation'].length, (index) {
                final value = userData!['consommation'][index];
                if (value == null || value is! num) {
                  return FlSpot(index.toDouble(), 0.0);
                }
                return FlSpot(index.toDouble(), value.toDouble());
              }),
              isCurved: true,
              barWidth: 4,
              color: Colors.green,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.green.withOpacity(0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
