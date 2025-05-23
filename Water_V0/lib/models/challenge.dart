import 'package:flutter/material.dart';

class Challenge {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final int points;
  final String category;
  final String inputType; // text, number, dropdown, slider, radio, checkbox
  final List<String>? options; // For dropdown, radio, checkbox
  final double? min; // For slider, number
  final double? max; // For slider, number
  bool isCompleted;
  String? userInput;

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.points,
    required this.category,
    required this.inputType,
    this.options,
    this.min,
    this.max,
    this.isCompleted = false,
    this.userInput,

  });
}

