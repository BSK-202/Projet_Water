import 'package:flutter/material.dart';
import 'text_recognition.dart';

class ScannerPage extends StatelessWidget {
  const ScannerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scanner une Facture d\'Eau')),
      body: const TextRecognitionScreen(),
    );
  }
}
