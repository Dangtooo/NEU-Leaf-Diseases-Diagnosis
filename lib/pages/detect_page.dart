import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class DetectPage extends StatefulWidget {
  const DetectPage({super.key});

  @override
  State<DetectPage> createState() => _DetectPageState();
}

class _DetectPageState extends State<DetectPage> {
  final ImagePicker _picker = ImagePicker();
  XFile? _image;
  bool _loading = false;
  String? _result;
  double? _confidence;

  var baseUrl = 'http://ec2-13-250-153-141.ap-southeast-1.compute.amazonaws.com:5000';

  /// Choose image from gallery
  Future<void> _pickFromGallery() async {
    final img = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 95,
    );
    if (img != null) {
      setState(() {
        _image = img;
        _result = null;
        _confidence = null;
      });
    } else {
      debugPrint("User cancelled image selection");
    }
  }

  /// Take image from camera
  Future<void> _pickFromCamera() async {
    final img = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 95,
    );
    if (img != null) {
      setState(() {
        _image = img;
        _result = null;
        _confidence = null;
      });
    } else {
      debugPrint("User cancelled camera");
    }
  }

  /// Send to server
  Future<void> _sendToServer() async {
    if (_image == null) return;
    setState(() {
      _loading = true;
      _result = null;
      _confidence = null;
    });

    try {
      var uri = Uri.parse('$baseUrl/diagnose');
      var request = http.MultipartRequest("POST", uri);

      if (kIsWeb) {
        var bytes = await _image!.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes('image', bytes, filename: _image!.name),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath('image', _image!.path),
        );
      }

      var response = await request.send();

      if (response.statusCode == 200) {
        var respStr = await response.stream.bytesToString();
        var jsonResp = jsonDecode(respStr);

        setState(() {
          _result = jsonResp['result'] as String?;
          _confidence = (jsonResp['confidence'] as num?)?.toDouble();
        });
      } else {
        setState(() {
          _result = 'Error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    if (_image == null) {
      imageWidget = SizedBox.shrink();
    } else {
      if (kIsWeb) {
        imageWidget = Image.network(_image!.path);
      } else {
        imageWidget = Image.file(File(_image!.path));
      }
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Tomato Leaf Diseases Detector')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Wrap(
              spacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: _pickFromGallery,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Choose image'),
                ),
                FilledButton.icon(
                  onPressed: _pickFromCamera,
                  label: const Text('Take image'),
                  icon: const Icon(Icons.camera_alt),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(child: Center(child: imageWidget)),
            FilledButton.icon(
              onPressed: (_image != null && !_loading) ? _sendToServer : null,
              icon: const Icon(Icons.cloud_upload),
              label: _loading
                  ? const Text('Processing...')
                  : const Text('Diagnose'),
            ),
            const SizedBox(height: 12),
            if (_result != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.local_hospital),
                  title: Text('Result: ${_result!}'),
                  subtitle: _confidence != null
                      ? Text('Confidence: ${_confidence!.toStringAsFixed(2)}')
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}