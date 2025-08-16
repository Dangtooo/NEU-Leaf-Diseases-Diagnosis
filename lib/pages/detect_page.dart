import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

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

  var baseUrl = 'http://192.168.1.149:5000';

  Future<bool> _requestGalleryPermission() async {
    if (kIsWeb) return true;
    if (Platform.isIOS) return true;

    if (Platform.isAndroid) {
      if (await Permission.photos.isGranted ||
          await Permission.storage.isGranted) {
        return true;
      }

      var status = await Permission.photos.request();
      if (status.isGranted) return true;

      status = await Permission.storage.request();
      return status.isGranted;
    }

    return false;
  }

  Future<bool> _requestCameraPermission() async {
    if (kIsWeb) return true;
    if (Platform.isIOS) return true;

    if (Platform.isAndroid) {
      var status = await Permission.camera.status;
      if (status.isGranted) return true;

      status = await Permission.camera.request();
      return status.isGranted;
    }
    return false;
  }

  Future<void> _pickFromGallery() async {
    if (await _requestGalleryPermission()) {
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
    } else {
      debugPrint("Gallery permission denied");
    }
  }

  Future<void> _pickFromCamera() async {
    if (await _requestCameraPermission()) {
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
    } else {
      debugPrint("Camera permission denied");
    }
  }

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
    var imageWidget = _image == null
        ? const SizedBox.shrink()
        : (kIsWeb
        ? Image.network(_image!.path)
        : Image.file(
      File(_image!.path),
      height: 240,
      fit: BoxFit.contain,
    ));

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
                  : const Text('Send image'),
            ),
            const SizedBox(height: 12),
            if (_result != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.local_hospital),
                  title: Text('Result: ${_result!}'),
                  subtitle: _confidence != null
                      ? Text('Confidence: ${_confidence!}')
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
