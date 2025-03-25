import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:water_v0/models/family.dart';

class ApiService {
  static const String _baseUrl =
      'http://192.168.1.17:5000'; // Adresse de mon servers

  // Fonction pour récupérer les utilisateurs
  static Future<List<Family>> fetchUsers() async {
    final response = await http.get(Uri.parse(_baseUrl));
    if (response.statusCode == 200) {
      // Parse les utilisateurs
      List<dynamic> data = jsonDecode(response.body);

      //debugPrint(data.toString());

      return data.map((family) => Family.fromJson(family)).toList();
    } else {
      throw Exception('Échec de récupération des utilisateurs');
    }
  }
}
