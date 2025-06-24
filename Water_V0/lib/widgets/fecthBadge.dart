import 'package:flutter/material.dart';
import 'package:water_v0/screens/recup_id_famille.dart';
import '../../../models/Badge.dart' as customBadge;
import 'package:http/http.dart' as http;
import 'dart:convert';
Future<List<customBadge.Badge>> fetchUserBadges() async {
  var userId = await getIdUSer();
  print("*******************************************féhéhéhéhéhéhéhéhéh******************************************");
  print(userId);
  final response = await http.get(Uri.parse('http://127.0.0.1:5000/badges/${userId!=null?userId:""}'));

  if (response.statusCode == 200) {
    List<dynamic> data = json.decode(response.body);
    print("**************************************************féhéhéhéhéhéhéhéhéh******************************************");
    var badges = data.map((item) => customBadge.Badge.fromJson(item)).toList();
    print(badges);
    return badges;
  } else {
    throw Exception('Failed to load badges');
  }
}
