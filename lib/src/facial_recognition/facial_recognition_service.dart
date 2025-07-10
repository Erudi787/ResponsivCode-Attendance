import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

/// A singleton service for handling face detection and recognition.
///
/// This service loads the TFLite models for face detection (BlazeFace) and
/// face embedding generation (MobileFaceNet). It provides methods to process
/// images, extract facial features, and compare them.
class FaceRecognitionService {
  // --- Singleton Setup ---
  static final FaceRecognitionService _instance = FaceRecognitionService._internal();
  factory FaceRecognitionService() => _instance;
  FaceRecognitionService._internal();

  // --- TFLite Interpreters ---
  Interpreter? _faceNetInterpreter;
  Interpreter? _faceDetectorInterpreter;

  /// Indicates whether the TFLite models have been successfully initialized.
  bool get isInitialized => _faceNetInterpreter != null && _faceDetectorInterpreter != null;

  /// Loads the TFLite models from the app's assets.
  ///
  /// This must be called before any other methods are used.
  Future<void> initialize() async {
    try {
      final options = InterpreterOptions()..threads = 4;
      _faceNetInterpreter = await Interpreter.fromAsset('assets/mobilefacenet.tflite', options: options);
      _faceDetectorInterpreter = await Interpreter.fromAsset('assets/blazeface.tflite', options: options);
      debugPrint("✅ Models loaded successfully.");
    } catch (e) {
      debugPrint("❌ Failed to load models: $e");
      rethrow;
    }
  }

  /// Takes an image file and returns a 192-dimensional embedding vector.
  ///
  /// Returns `null` if no face is detected with sufficient confidence.
  Future<List<double>?> getFaceEmbedding(File imageFile, {double confidence = 0.75}) async {
    if (!isInitialized) {
      throw Exception("Error: Interpreters not initialized. Call initialize() first.");
    }

    try {
      final image = img.decodeImage(await imageFile.readAsBytes());
      if (image == null) return null;

      // --- 1. Face Detection using BlazeFace ---
      final detectorInput = img.copyResize(image, width: 128, height: 128);
      final detectorInputBytes = _imageToByteListFloat32(detectorInput, 128, 127.5, 127.5);

      final detectorOutputs = {
        0: List.filled(1 * 896 * 16, 0).reshape([1, 896, 16]), // Bounding boxes
        1: List.filled(1 * 896 * 1, 0).reshape([1, 896, 1]),   // Confidence scores
      };

      _faceDetectorInterpreter!.runForMultipleInputs([detectorInputBytes], detectorOutputs);

      final scores = (detectorOutputs[1]![0] as List<List<num>>).map((score) => score[0].toDouble()).toList();
      int bestIndex = -1;
      double maxScore = 0;
      for (int i = 0; i < scores.length; i++) {
        if (scores[i] > maxScore) {
          maxScore = scores[i];
          bestIndex = i;
        }
      }

      if (maxScore < confidence) {
        debugPrint("⚠️ No face detected with sufficient confidence ($maxScore).");
        return null;
      }

      // --- 2. Crop the face from the original image ---
      final boxes = (detectorOutputs[0]![0] as List<List<num>>).map((box) => box.map((e) => e.toDouble()).toList()).toList();
      final boundingBox = boxes[bestIndex];
      
      final yCenter = boundingBox[0];
      final xCenter = boundingBox[1];
      final h = boundingBox[2];
      final w = boundingBox[3];

      final x = ((xCenter - w / 2) * image.width).clamp(0, image.width - 1).toInt();
      final y = ((yCenter - h / 2) * image.height).clamp(0, image.height - 1).toInt();
      final width = (w * image.width).clamp(1, image.width - x).toInt();
      final height = (h * image.height).clamp(1, image.height - y).toInt();

      final faceCrop = img.copyCrop(image, x: x, y: y, width: width, height: height);

      // --- 3. Face Embedding Generation using MobileFaceNet ---
      final recognizerInput = img.copyResize(faceCrop, width: 112, height: 112);
      final recognizerInputBytes = _imageToByteListFloat32(recognizerInput, 112, 127.5, 127.5);
      
      final embeddingOutput = List.filled(1 * 192, 0.0).reshape([1, 192]);
      _faceNetInterpreter!.run(recognizerInputBytes, embeddingOutput);

      return embeddingOutput[0].cast<double>();
    } catch (e) {
      debugPrint("❌ Error during getFaceEmbedding: $e");
      return null;
    }
  }

  /// Calculates the Euclidean distance between two face embeddings.
  double calculateDistance(List<double> embedding1, List<double> embedding2) {
    double distance = 0;
    for (int i = 0; i < embedding1.length; i++) {
      final diff = embedding1[i] - embedding2[i];
      distance += diff * diff;
    }
    return sqrt(distance);
  }
  
  /// Converts an `img.Image` to a `Uint8List` for TFLite model input.
  Uint8List _imageToByteListFloat32(img.Image image, int inputSize, double mean, double std) {
    final convertedBytes = Float32List(1 * inputSize * inputSize * 3);
    final buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;
    for (int i = 0; i < inputSize; i++) {
      for (int j = 0; j < inputSize; j++) {
        final pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = (pixel.r - mean) / std;
        buffer[pixelIndex++] = (pixel.g - mean) / std;
        buffer[pixelIndex++] = (pixel.b - mean) / std;
      }
    }
    return convertedBytes.buffer.asUint8List();
  }

  /// Saves a captured image file to the app's local documents directory.
  Future<String> saveImageToAppDirectory(File sourceFile, String personName) async {
    final appDir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final safeFileName = '${personName.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '')}_$timestamp.jpg';
    final newImagePath = p.join(appDir.path, safeFileName);
    final savedFile = await sourceFile.copy(newImagePath);
    return savedFile.path;
  }

  /// Compresses an image file to a target size in kilobytes.
  Future<File> compressImage(File file, {int targetKb = 200}) async {
    final targetBytes = targetKb * 1024;
    Uint8List fileBytes = await file.readAsBytes();

    if (fileBytes.lengthInBytes <= targetBytes) {
      return file;
    }

    img.Image? originalImage = img.decodeImage(fileBytes);
    if (originalImage == null) return file;

    Uint8List compressedBytes;
    int quality = 90;
    do {
      compressedBytes = Uint8List.fromList(img.encodeJpg(originalImage, quality: quality));
      if (quality <= 10) break;
      quality -= 10;
    } while (compressedBytes.lengthInBytes > targetBytes);

    final tempDir = await getTemporaryDirectory();
    final tempPath = p.join(tempDir.path, '${DateTime.now().millisecondsSinceEpoch}.jpg');
    final tempFile = File(tempPath);
    await tempFile.writeAsBytes(compressedBytes);

    debugPrint("✅ Image compressed successfully to ${compressedBytes.lengthInBytes / 1024}KB");
    return tempFile;
  }
  
  /// Disposes of the TFLite interpreters to free up resources.
  void dispose() {
    _faceNetInterpreter?.close();
    _faceDetectorInterpreter?.close();
  }
}