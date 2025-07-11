import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rts_locator/src/facial_recognition/face_data_manager.dart';
import 'package:rts_locator/src/facial_recognition/facial_recognition_service.dart';

/// A GetX controller for managing the state and logic of face recognition.
///
/// This controller orchestrates the `FaceRecognitionService` and `FaceDataManager`
/// to perform tasks such as user registration and face verification.
class FacialRecognitionController extends GetxController {
  // --- Dependencies ---
  final FaceRecognitionService _faceService = Get.find<FaceRecognitionService>();
  final FaceDataManager _dataManager = Get.find<FaceDataManager>();

  // --- Observable State ---
  final RxBool isLoading = false.obs;
  final Rxn<String> recognitionResult = Rxn<String>();
  final RxDouble bestMatchDistance = (0.0).obs;

  /// The confidence threshold for detecting a face in an image.
  static const double _faceDetectionConfidence = 0.75;
  /// The distance threshold for recognizing a face. Lower is stricter.
  static const double _recognitionThreshold = 1.0;

  /// Verifies a user's face against their registered profile.
  ///
  /// - Takes an `imageFile` and the `personName` to verify.
  /// - Returns `true` if the face is a match, `false` otherwise.
  Future<bool> verifyFace(File imageFile, String personName) async {
    isLoading.value = true;
    recognitionResult.value = "Verifying...";
    bestMatchDistance.value = double.infinity;

    try {
      final unknownEmbedding = await _faceService.getFaceEmbedding(
        imageFile,
        confidence: _faceDetectionConfidence,
      );

      if (unknownEmbedding == null) {
        recognitionResult.value = "No face detected. Please try again.";
        return false;
      }

      final registeredAlbum = _dataManager[personName];
      if (registeredAlbum == null || registeredAlbum.isEmpty) {
        recognitionResult.value = "No registered faces found for this user.";
        return false;
      }

      double minDistance = double.infinity;

      for (var registeredFace in registeredAlbum) {
        final knownEmbedding = (registeredFace['embedding'] as List).cast<double>();
        final distance = _faceService.calculateDistance(unknownEmbedding, knownEmbedding);

        if (distance < minDistance) {
          minDistance = distance;
        }
      }
      
      bestMatchDistance.value = minDistance;

      if (minDistance <= _recognitionThreshold) {
        recognitionResult.value = "Welcome, $personName!";
        return true;
      } else {
        recognitionResult.value = "Verification failed. Please try again.";
        return false;
      }
    } catch (e) {
      recognitionResult.value = "An error occurred: $e";
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}