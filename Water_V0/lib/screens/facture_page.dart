import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Ajouté pour kIsWeb
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:water_v0/screens/BottomNavigationBar.dart';
import 'package:water_v0/screens/recup_id_famille.dart';
import 'login_screen.dart';

class FacturePage extends StatefulWidget {
  const FacturePage({super.key, required this.userId,required this.isChef});
  final String userId;
  final bool isChef;

 
  @override
  State<FacturePage> createState() => _FacturePageState();
}

class _FacturePageState extends State<FacturePage> {
  final List<PlatformFile> _uploadedFiles = []; // Changé pour PlatformFile
  final String _serverUrl = "http://127.0.0.1:5000/extract_pdf";
  final String _factureServerUrl = "http://127.0.0.1:5000/factures";
  Map<String, dynamic>? _jsonData;
  List<dynamic> _factures = [];
  bool _isLoading = true;
  String _errorMessage = '';
  
  get userId => null;

  @override
  void initState() {
    super.initState();
    _fetchFactures();
  }

  Future<void> _uploadPDF() async {
    try {
      String? userId = await getIdUSer();
      print('User ID: $userId');
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() => _uploadedFiles.add(file));

        var request = http.MultipartRequest('POST', Uri.parse(_serverUrl));

        // Ajouter user_id comme champ dans la requête
        request.fields['user_id'] = userId ?? '';
        print('User ID dans la requête: ${request.fields['user_id']}');
        if (kIsWeb) {
          request.files.add(http.MultipartFile.fromBytes(
            'file',
            file.bytes!,
            filename: file.name,
          ));
        } else {
          request.files.add(await http.MultipartFile.fromPath(
            'file',
            file.path!,
            filename: file.name,
          ));
        }

        var response = await request.send();
        final respStr = await response.stream.bytesToString();

        if (response.statusCode == 200) {
          setState(() {
            _jsonData = json.decode(respStr);
          });

          print('Date Début: ${_jsonData?['date_debut']}');
          print('Date Fin: ${_jsonData?['date_fin']}');
          print('Consommation (m3): ${_jsonData?['consommation_en_m3']}');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fichier ${file.name} uploadé !'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          setState(() => _uploadedFiles.removeLast());
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${response.reasonPhrase}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _fetchFactures() async {
    try {
      
          String? userId = await getIdUSer();
      final response = await http.get(
        Uri.parse('$_factureServerUrl?user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
      );
      print('Factuuuuuuuuuuuuuuur Response status: $userId');

      if (response.statusCode == 200) {
        setState(() {
          _factures = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Erreur de chargement: ${response.reasonPhrase}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Filtrer uniquement les attributs date_debut, date_fin, et consommation_en_m3
    List<Map<String, String>> filteredData = [];
    if (_jsonData != null) {
      filteredData = [
        {
          'Date Début': _jsonData?['date_debut'] ?? 'N/A',
          'Date Fin': _jsonData?['date_fin'] ?? 'N/A',
          'Consommation (m3)': _jsonData?['consommation_eau_m3']?.toString() ?? 'N/A',
        },
      ];
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Gestion des Factures'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
             if(widget.isChef) ...[
            GestureDetector(
              onTap: _uploadPDF,
              child: Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
                
                child: Column(
                  children: [
                    Icon(
                      Icons.upload_file,
                      size: 50,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Cliquez pour uploader une facture PDF',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
             ],
            const SizedBox(height: 30),
            // Affichage des données extraites du PDF
            filteredData.isNotEmpty
                ? Column(
              children: [
                Text(
                  'Données extraites du PDF :',
                  style: theme.textTheme.titleLarge,
                ),
                DataTable(
                  columns: const [
                    DataColumn(label: Text('Date Début')),
                    DataColumn(label: Text('Date Fin')),
                    DataColumn(label: Text('Consommation (m3)')),
                  ],
                  rows: filteredData.map((data) {
                    return DataRow(cells: [
                      DataCell(Text(data['Date Début']!)),
                      DataCell(Text(data['Date Fin']!)),
                      DataCell(Text(data['Consommation (m3)']!)),
                    ]);
                  }).toList(),
                ),
              ],
            )
                : const SizedBox(),
            // Affichage des factures existantes
            const SizedBox(height: 30),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
                : _factures.isEmpty
                ? const Center(child: Text('Aucune facture trouvée'))
                : Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Date Facture')),
                    DataColumn(label: Text('Consommation (m³)'), numeric: true),
                  ],
                  rows: _factures.map<DataRow>((facture) {
                    return DataRow(
                      cells: [
                        DataCell(Text(facture['dateFacture']?.toString() ?? 'N/A')),
                        DataCell(Text(facture['consommation_eau_m3']?.toString() ?? 'N/A')),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
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
}
