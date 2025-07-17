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
  final FacialRecognitionController _controller =
      Get.find<FacialRecognitionController>();
  CameraController? _cameraController;

  // --- State Management ---
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  bool _hasNavigated = false; // Prevent multiple navigation calls

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  /// Navigate back with result
  void _navigateBack(bool result, {File? imageFile}) {
    if (!_hasNavigated) {
      _hasNavigated = true;
      // Dispose camera before navigating
      _cameraController?.dispose();
      // Use Get.back with closeOverlays to ensure all overlays are closed
      Get.back(result: imageFile, closeOverlays: true);
    }
  }

  /// Initializes the camera and starts the automatic verification process.
  Future<void> _initializeCamera() async {
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        _showErrorAndGoBack("Camera permission is required for verification.");
        return;
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _showErrorAndGoBack("No cameras available.");
        return;
      }

      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (!mounted) return;

      setState(() {
        _isCameraInitialized = true;
      });

      // Auto-capture after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && !_isProcessing && !_hasNavigated) {
          _captureAndVerify();
        }
      });
    } catch (e) {
      debugPrint("Camera initialization error: $e");
      _showErrorAndGoBack("Failed to initialize camera: $e");
    }
  }

  /// Captures an image and passes it to the controller for verification.
  Future<void> _captureAndVerify() async {
    if (_isProcessing || _hasNavigated) return;

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _showErrorAndGoBack("Camera not ready.");
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Capture image
      final imageXFile = await _cameraController!.takePicture();
      final imageFile = File(imageXFile.path);

      // Get user info
      final box = GetStorage();
      final personName = box.read('fullname') as String?;

      if (personName == null) {
        _showErrorAndGoBack("User not logged in.");
        return;
      }

      // Verify face
      final success = await _controller.verifyFace(imageFile, personName);

      if (!mounted && !_hasNavigated) {
        _navigateBack(success);
        return;
      }

      if (success) {
        // Show success message briefly
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Face recognized successfully!"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );

        // Wait a bit for the message to show, then navigate
        await Future.delayed(const Duration(milliseconds: 300));
        _navigateBack(true, imageFile: imageFile);
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_controller.recognitionResult.value ??
                "Could not verify face."),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );

        // Wait and navigate back with failure
        await Future.delayed(const Duration(milliseconds: 300));
        _navigateBack(false);
      }
    } catch (e) {
      debugPrint("Face verification error: $e");
      _showErrorAndGoBack("Failed to process image: ${e.toString()}");
    } finally {
      if (mounted && !_hasNavigated) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showErrorAndGoBack(String message) {
    if (!mounted && !_hasNavigated) {
      _navigateBack(false);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      _navigateBack(false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (!_isProcessing) {
          _navigateBack(false);
        }
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text("Face Verification"),
          centerTitle: true,
          backgroundColor: Colors.black,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _isProcessing ? null : () => _navigateBack(false),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Camera Preview
              Expanded(
                flex: 3,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      margin: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                      ),
                      child: ClipOval(
                        child: _isCameraInitialized && _cameraController != null
                            ? CameraPreview(_cameraController!)
                            : const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
              // Status and Button
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Obx(() {
                        final message = _controller.recognitionResult.value ??
                            "Position your face in the frame";
                        final isLoading =
                            _controller.isLoading.value || _isProcessing;

                        return Text(
                          isLoading ? "Verifying..." : message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      }),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: (_isCameraInitialized &&
                                  !_isProcessing &&
                                  !_controller.isLoading.value)
                              ? _captureAndVerify
                              : null,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text("Verify Face"),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 32,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
