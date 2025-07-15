import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rts_locator/src/facial_recognition/face_data_manager.dart';
import 'package:rts_locator/src/facial_recognition/facial_recognition_service.dart';
import 'package:rts_locator/src/home/home_view.dart';

/// A screen that guides the user through a live face registration process.
///
/// It uses the front-facing camera to capture a series of photos at different
/// angles to build a robust facial profile for the user.
class LiveRegistrationView extends StatefulWidget {
  final String personName;
  static const routeName = '/live_registration';

  const LiveRegistrationView({super.key, required this.personName});

  @override
  State<LiveRegistrationView> createState() => _LiveRegistrationViewState();
}

class _LiveRegistrationViewState extends State<LiveRegistrationView> {
  // --- Services and Managers ---
  final FaceRecognitionService _faceService = FaceRecognitionService();
  final FaceDataManager _dataManager = FaceDataManager();

  // --- Camera and State Management ---
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isCapturing = false;
  int _photosCaptured = 0;
  final int _totalPhotos = 10; // Capture more photos for a better profile
  double get _progress => _photosCaptured / _totalPhotos;

  // --- Instructions for User Guidance ---
  final List<String> _instructions = [
    "Look Straight",
    "Look Slightly Left",
    "Look Slightly Right",
    "Look Up",
    "Look Down",
    "Smile!",
    "Open Your Mouth",
    "Close Your Eyes",
    "Tilt Head Left",
    "Tilt Head Right",
  ];
  String _currentInstruction = "Press Start";

  @override
  void initState() {
    super.initState();
    _initialize();
  }
  
  /// Initializes both the camera and the face recognition service.
  Future<void> _initialize() async {
    await _faceService.initialize();
    await _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  /// Initializes the front-facing camera.
  Future<void> _initializeCamera() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first, // Fallback to the first available camera
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      try {
        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      } catch (e) {
        _showError("Failed to initialize camera: $e");
      }
    } else {
      _showError("Camera permission is required for face registration.");
    }
  }

  /// Starts the automated process of capturing a sequence of photos.
  Future<void> _startCaptureProcess() async {
    if (_isCapturing) return;

    setState(() {
      _isCapturing = true;
    });

    for (int i = 0; i < _totalPhotos; i++) {
      if (!mounted) break;
      setState(() {
        _currentInstruction = "Get Ready: ${_instructions[i]}";
      });

      // Give the user time to follow the instruction
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) break;

      final success = await _captureAndProcessImage();

      if (success) {
        setState(() {
          _photosCaptured++;
        });
      } else {
        // If a capture fails, inform the user and retry the same instruction
        _showError("Could not detect a face. Please try again.", duration: 2);
        i--;
      }
    }

    if (mounted) {
      _showSuccessAndNavigate();
    }
  }

  /// Captures a single image, processes it, and saves the face embedding.
  Future<bool> _captureAndProcessImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return false;
    }

    try {
      final XFile imageXFile = await _cameraController!.takePicture();
      File imageFile = File(imageXFile.path);

      // Compress and get embedding
      imageFile = await _faceService.compressImage(imageFile);
      final embedding = await _faceService.getFaceEmbedding(imageFile);

      if (embedding != null && mounted) {
        final savedImagePath = await _faceService.saveImageToAppDirectory(
          imageFile,
          widget.personName,
        );
        final faceData = {'embedding': embedding, 'imagePath': savedImagePath};
        _dataManager.addFace(widget.personName, faceData);
        return true;
      }
    } catch (e) {
      debugPrint("❌ Error capturing or processing image: $e");
    }
    return false;
  }

  // --- UI Helper Methods ---
  void _showError(String message, {int duration = 3}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: Duration(seconds: duration),
        ),
      );
    }
  }

  Future<void> _showSuccessAndNavigate() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("✅ Registration complete for ${widget.personName}!"),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
    // Navigate to the home screen after successful registration
    //Navigator.of(context).pushReplacementNamed(HomeView.routeName);
    await _cameraController?.dispose();
    Get.offAllNamed(HomeView.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Register ${widget.personName}"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // --- Camera Preview ---
          Expanded(
            flex: 3,
            child: _isCameraInitialized
                ? Center(
                    child: ClipOval(
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.8,
                        height: MediaQuery.of(context).size.width * 0.8,
                        child: CameraPreview(_cameraController!),
                      ),
                    ),
                  )
                : const Center(child: CircularProgressIndicator()),
          ),
          // --- Instructions and Progress ---
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _currentInstruction,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  if (_isCapturing) ...[
                    LinearProgressIndicator(
                      value: _progress,
                      minHeight: 10,
                      backgroundColor: Colors.grey[300],
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 10),
                    Text("$_photosCaptured / $_totalPhotos"),
                  ] else ...[
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      ),
                      onPressed: _isCameraInitialized ? _startCaptureProcess : null,
                      child: const Text("Start Registration"),
                    ),
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}