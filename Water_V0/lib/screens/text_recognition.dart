import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class TextRecognitionScreen extends StatefulWidget {
  const TextRecognitionScreen({super.key});

  @override
  State<TextRecognitionScreen> createState() => _TextRecognitionScreenState();
}

class _TextRecognitionScreenState extends State<TextRecognitionScreen> {
  File? _image;
  String text = '';

  Future _pickImage(ImageSource source) async {
    try {
      final image = await ImagePicker().pickImage(source: source);
      if (image == null) return;
      setState(() {
        _image = File(image.path);
      });
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  Future textRecognition(File img) async {
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final inputImage = InputImage.fromFilePath(img.path);
    final RecognizedText recognizedText = await textRecognizer.processImage(
      inputImage,
    );
    setState(() {
      text = recognizedText.text;
    });
    print(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                color: Colors.grey,
                child: Center(
                  child: _image == null
                      ? const Icon(Icons.add_a_photo, size: 60)
                      : Image.file(_image!),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                height: 50,
                color: Colors.teal,
                child: MaterialButton(
                  onPressed: () {
                    _pickImage(ImageSource.camera).then((value) {
                      if (_image != null) {
                        textRecognition(_image!);
                      }
                    });
                  },
                  child: const Text(
                    'prendre une photo avec cam',
                    style: TextStyle(color: Colors.white, fontSize: 23),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                height: 50,
                color: Colors.teal,
                child: MaterialButton(
                  onPressed: () {
                    _pickImage(ImageSource.gallery).then((value) {
                      if (_image != null) {
                        textRecognition(_image!);
                      }
                    });
                  },
                  child: const Text(
                    'choisir une photo',
                    style: TextStyle(color: Colors.white, fontSize: 23),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SelectableText(
                text,
                style: const TextStyle(
                  fontSize: 18,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
