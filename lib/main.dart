import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_v2/tflite_v2.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MaskDedector(),
    );
  }
}

class MaskDedector extends StatefulWidget {
  const MaskDedector({super.key});

  @override
  State<MaskDedector> createState() => _MaskDedectorState();
}

class _MaskDedectorState extends State<MaskDedector> {
  final ImagePicker _picker = ImagePicker();
  XFile? _image;
  File? file;
  var _recognitions;
  var veri = "";

  @override
  void initState() {
    super.initState();
    loadmodel().then((value) {
      setState(() {});
    });
  }

  void _showErrorAlert(String errorMessage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(errorMessage),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  loadmodel() async {
    await Tflite.loadModel(
      model: "assets/model_unquant.tflite",
      labels: "assets/labels.txt",
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _image = image;
          file = File(image.path);
        });
        detectimage(file!);
      }
    } catch (e) {
      _showErrorAlert('Resim seçmede hata: $e');
    }
  }

  Future<void> _captureImage() async {
    _pickImage(ImageSource.camera);
  }

  Future<void> detectimage(File image) async {
    int startTime = DateTime.now().millisecondsSinceEpoch;
    var recognitions = await Tflite.runModelOnImage(
        path: image.path,
        numResults: 6,
        threshold: 0.05,
        imageMean: 127.5,
        imageStd: 127.5);
    recognitions?.sort((a, b) => b['confidence'].compareTo(a['confidence']));
    setState(() {
      _recognitions = recognitions;
      var confidence = (recognitions?[0]['confidence'] * 100).toStringAsFixed(4);
      veri = 'Sonuç: ${recognitions?[0]['label']}, Doğruluk oranı: %${confidence}';
    });
    print(_recognitions);
    int endTime = DateTime.now().millisecondsSinceEpoch;
    print("Inference took ${endTime - startTime}ms");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (_image != null)
              Image.file(File(_image!.path),
                  height: 200, width: 200, fit: BoxFit.cover)
            else
              const Text('Alzheimer şüpelisi kişinin röntgen görüntüsü yükle'),
            const SizedBox(height: 100),
            ElevatedButton(
                onPressed: () => _pickImage(ImageSource.gallery),
                child: const Text('Galeriden Resim Seç')),
            const SizedBox(height: 50),
            ElevatedButton(
                onPressed: _captureImage,
                child: const Text('Kameradan Resim Çek')),
            const SizedBox(height: 20),
            Text(
              veri,
              style: const TextStyle(color: Colors.amber),
            ),
          ],
        ),
      ),
    );
  }
}
