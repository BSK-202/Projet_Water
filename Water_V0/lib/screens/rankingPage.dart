import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
//import 'navigationBar.dart' as custom;

class ClassementScreen extends StatefulWidget {
  @override
  _ClassementPageState createState() => _ClassementPageState();
}

class _ClassementPageState extends State<ClassementScreen> {
  List families = [];

  @override
  void initState() {
    super.initState();
    fetchClassement();
  }

  Future<void> fetchClassement() async {
    final response = await http.get(Uri.parse('http://192.168.1.17:5000'));

    if (response.statusCode == 200) {
      setState(() {
        families = json.decode(response.body);
      });
    } else {
      throw Exception('Échec du chargement des données');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFF26A69A), const Color(0xFF2E7D32)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text('Top Families', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
        ),
        body:
            families.isEmpty
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                  itemCount: families.length,
                  itemBuilder: (context, index) {
                    final family = families[index];
                    return ClassementCard(
                      rank: index + 1,
                      name:
                          family["nom"], // Assurez-vous que "nom" est la clé correcte
                      username:
                          "@username", // Remplacez par la clé correcte si nécessaire
                      score: family['score'],
                      avatarUrl:
                          "assets/image.png", // Ajoutez l'URL de l'avatar
                    );
                  },
                ),
        // bottomNavigationBar: custom.NavBar(theme: theme),
      ),
    );
  }
}

class ClassementCard extends StatelessWidget {
  final int rank;
  final String name;
  final String username;
  final int score;
  final String? avatarUrl; // Ajoutez l'URL de l'avatar

  const ClassementCard({
    required this.rank,
    required this.name,
    required this.username,
    required this.score,
    this.avatarUrl, // Ajoutez l'URL de l'avatar
  });

  @override
  Widget build(BuildContext context) {
    IconData? icon;
    if (rank == 1) icon = Icons.emoji_events; // 🥇
    if (rank == 2) icon = Icons.emoji_events; // 🥈
    if (rank == 3) icon = Icons.emoji_events; // 🥉

    return Card(
      color: const Color.fromARGB(255, 242, 246, 245),
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading:
            icon != null
                ? Icon(
                  icon,
                  color:
                      rank == 1
                          ? Colors.amber
                          : (rank == 2 ? Colors.grey : Colors.brown),
                )
                : Text(
                  rank.toString(),
                  style: TextStyle(
                    fontSize: 18,
                    color: const Color.fromARGB(255, 17, 14, 14),
                  ),
                ),
        title: Row(
          children: [
            if (avatarUrl != null)
              CircleAvatar(
                backgroundImage: AssetImage(avatarUrl!),
                radius: 16, // Taille de l'avatar
              ),
            SizedBox(width: 8), // Espace entre l'avatar et le nom
            Text(
              name,
              style: TextStyle(
                color: const Color.fromARGB(255, 8, 1, 1),
                fontWeight: FontWeight.bold,
              ),
            ),
            // Text(username, style: TextStyle(color: Colors.grey)),
          ],
        ),

        trailing: Text(
          score.toString(),
          style: TextStyle(
            color: const Color.fromARGB(255, 8, 1, 1),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
