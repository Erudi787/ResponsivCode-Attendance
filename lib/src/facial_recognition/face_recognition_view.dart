import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rts_locator/src/facial_recognition/facial_recognition_controller.dart';

/// A screen that performs live face verification.
///
/// It uses the front-facing camera to automatically capture an image and
/// verify it against the logged-in user's registered facial profile.
class FaceRecognitionView extends StatefulWidget {
  static const routeName = '/face_recognition';

  const FaceRecognitionView({super.key});

  @override
  State<FaceRecognitionView> createState() => _FaceRecognitionViewState();
}

class _FaceRecognitionViewState extends State<FaceRecognitionView> {
  // --- Dependencies & Controllers ---
  final FacialRecognitionController _controller = Get.find<FacialRecognitionController>();
  CameraController? _cameraController;

  // --- State Management ---
  bool _isCameraInitialized = false;
  String _message = "Please position your face in the frame";

  @override
  void initState() {
    super.initState();
    _initializeCameraAndVerify();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  /// Initializes the camera and starts the automatic verification process.
  Future<void> _initializeCameraAndVerify() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
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
          // Wait a moment before capturing to allow the user to get ready
          Future.delayed(const Duration(seconds: 2), _captureAndVerify);
        }
      } catch (e) {
        _showErrorAndGoBack("Failed to initialize camera: $e");
      }
    } else {
      _showErrorAndGoBack("Camera permission is required for verification.");
    }
  }

  /// Captures an image and passes it to the controller for verification.
  Future<void> _captureAndVerify() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    setState(() {
      _message = "Verifying...";
    });

    try {
      final imageXFile = await _cameraController!.takePicture();
      final imageFile = File(imageXFile.path);

      final box = GetStorage();
      final personName = box.read('fullname') as String?;

      if (personName == null) {
        _showErrorAndGoBack("User not logged in.");
        return;
      }

      final success = await _controller.verifyFace(imageFile, personName);

      if (mounted) {
        setState(() {
          _message = _controller.recognitionResult.value ?? "Verification Complete";
        });

        if (success) {
           Get.snackbar(
            "Success",
            "Face recognized successfully!",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
          // Return true to the previous screen
          Get.back(result: true);
        } else {
           Get.snackbar(
            "Verification Failed",
            _controller.recognitionResult.value ?? "Could not verify face.",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
           // Return false to the previous screen
          Get.back(result: false);
        }
      }
    } catch (e) {
      _showErrorAndGoBack("Failed to capture image: $e");
    }
  }

  void _showErrorAndGoBack(String message) {
    if (mounted) {
      Get.snackbar(
        "Error",
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      // Return false to indicate failure
      Get.back(result: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Face Verification"),
        centerTitle: true,
        automaticallyImplyLeading: false, // Prevents user from going back manually
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- Camera Preview ---
          Expanded(
            child: Center(
              child: ClipOval(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: MediaQuery.of(context).size.width * 0.8,
                  child: _isCameraInitialized
                      ? CameraPreview(_cameraController!)
                      : const Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
          ),
          // --- Status Message ---
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Obx(() => Text(
                  _controller.isLoading.value ? "Processing..." : _message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                )),
          ),
        ],
      ),
    );
  }
}