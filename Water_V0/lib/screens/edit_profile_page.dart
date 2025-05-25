import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'recup_id_famille.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditProfilePage({Key? key, required this.userData}) : super(key: key);

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  File? _imageFile;
  bool _isLoading = false;
  String? _errorMessage;

  // Liste des images disponibles (à adapter selon vos assets)
  final List<String> _availableAvatars = [
    'assets/avatar1.png',
    'assets/avatar2.png',
    'assets/avatar3.png',
    'assets/avatar4.png',
    'assets/avatar5.png',
    // Ajoutez d'autres chemins d'images ici
  ];

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(
      text: widget.userData['prenom'] ?? '',
    );
    _lastNameController = TextEditingController(
      text: widget.userData['nom'] ?? '',
    );
    _emailController = TextEditingController(
      text: widget.userData['email'] ?? '',
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _updateProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String? email = await getIdUSer();
      if (email == null || email.isEmpty) {
        throw Exception('Utilisateur non connecté');
      }

      // Créer les données à envoyer
      final Map<String, dynamic> updateData = {
        'email': email,
        'new_email': _emailController.text,
        'prenom': _firstNameController.text,
        'nom': _lastNameController.text,
      };

      // Créer la requête multipart pour inclure l'image si elle a été sélectionnée
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://10.0.2.2:5000/update_profile'),
      );

      // Ajouter les champs de données
      request.fields.addAll({'data': json.encode(updateData)});

      // Ajouter le fichier image s'il existe
      if (_imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('avatar', _imageFile!.path),
        );
      }

      // Envoyer la requête
      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        // Mise à jour réussie
        final jsonResponse = json.decode(responseData);
        if (jsonResponse['success'] == true) {
          Navigator.pop(context, {
            'success': true,
            'prenom': _firstNameController.text,
            'nom': _lastNameController.text,
            'email': _emailController.text,
            'avatar':
                _imageFile != null
                    ? _imageFile!.path
                    : widget.userData['avatar'],
          });
          return;
        }
      }

      throw Exception(
        json.decode(responseData)['message'] ?? 'Échec de la mise à jour',
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showAvatarSelectionDialog() async {
    String? selectedAvatar = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Choisir une photo de profil'),
          content: SizedBox(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              itemCount: _availableAvatars.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                final avatarPath = _availableAvatars[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop(avatarPath);
                  },
                  child: CircleAvatar(
                    backgroundImage: AssetImage(avatarPath),
                    radius: 32,
                  ),
                );
              },
            ),
          ),
        );
      },
    );

    if (selectedAvatar != null) {
      setState(() {
        _imageFile = null; // On enlève l'image personnalisée si existante
        widget.userData['avatar'] = selectedAvatar;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _updateProfile,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.grey[200],
                            backgroundImage:
                                _imageFile != null
                                    ? FileImage(_imageFile!)
                                    : (widget.userData['avatar'] != null
                                            ? AssetImage(
                                              widget.userData['avatar'],
                                            )
                                            : const AssetImage(
                                              'assets/default_avatar.png',
                                            ))
                                        as ImageProvider,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () async {
                                await _showAvatarSelectionDialog();
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'Prénom',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _updateProfile,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Enregistrer les modifications'),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}