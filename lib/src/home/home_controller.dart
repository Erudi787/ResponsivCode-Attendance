import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:rts_locator/src/dtr_logs/view/dtr_logs_view.dart';
import 'package:rts_locator/src/facial_recognition/face_recognition_view.dart';
import 'package:rts_locator/src/location/location_controller.dart';
import 'package:rts_locator/src/location/location_service.dart';
import 'package:workmanager/workmanager.dart';
import 'home_service.dart';

class HomeController extends GetxController {
  final isLoading = false.obs;
  final HomeService _homeService;

  HomeController(this._homeService);

  CameraController? get cameraController => _homeService.cameraController;
  int? get selectedCameraIndex => _homeService.selectedCameraIndex;

  final LocationController locationController =
      Get.put(LocationController(LocationService()));

  @override
  void onInit() {
    super.onInit();
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    await _homeService.initializeCamera();
    update(); // Notify GetX listeners
  }

  Future<File?> captureImage({
    required String note,
    required double latitude,
    required double longitude,
    required String plusCode,
    required String tabHeader,
    required String address_complete,
  }) async {
    final image = await _homeService.captureImage(
        note: note,
        latitude: latitude,
        longitude: longitude,
        plusCode: plusCode,
        tabHeader: tabHeader,
        address_complete: address_complete);
    update(); // Notify GetX listeners
    return image;
  }

  Future<String> uploadToCloud({required File imageFile}) async {
    final imageUrl = await _homeService.uploadToCloud(imageFile: imageFile);
    return imageUrl;
  }

  Future<void> uploadToDatabase({required Map<String, dynamic> data}) async {
    isLoading.value = true;
    await _homeService.uploadToDatabase(data: data);
  }

//  Future<void> captureAndUpload({
//     required String note,
//     required String attendanceType,
//     required double latitude,
//     required double longitude,
//     required String plusCode,
//     required String tabHeader,
//     required String address_complete,
//   }) async {
//     isLoading.value = true;
//     Get.showSnackbar(const GetSnackBar(
//         message: 'Starting process...', duration: Duration(seconds: 2)));

//     // --- Trigger Face Verification ---
//   //final bool? isVerified = await Get.toNamed(FaceRecognitionView.routeName);
//   final bool? isVerified = await Get.to(() => FaceRecognitionView());

//     // If verification fails or the user cancels, stop the process
//     if (isVerified != true) {
//       isLoading.value = false;
//       Get.snackbar("Cancelled", "Face verification failed or was cancelled.");
//       return;
//     }
//     // ---------------------------------

//     // --- If verification is successful, continue with original logic ---
//     final modifiedImage = await _homeService.captureImage(
//       note: note,
//       latitude: latitude,
//       longitude: longitude,
//       plusCode: plusCode,
//       tabHeader: tabHeader,
//       address_complete: address_complete,
//     );

//     if (modifiedImage == null) {
//       isLoading.value = false;
//       throw 'Image capture failed';
//     }
//     Fluttertoast.showToast(msg: 'Image captured!');

//     final dataInDatabase = await _homeService.uploadToDatabase(data: {
//       'note': note,
//       'attendance_type': attendanceType,
//       'long_lat': '$latitude, $longitude',
//       'address': plusCode,
//       'address_complete': address_complete,
//     });

//     await Workmanager().registerOneOffTask(
//       'uniqueName_${DateTime.now().millisecondsSinceEpoch}', // Ensure unique task name
//       'uploadTask',
//       constraints: Constraints(networkType: NetworkType.connected),
//       inputData: {
//         'id': dataInDatabase,
//         'filePath': modifiedImage.path,
//       },
//     );

//     print("Done");
//     isLoading.value = false;
//     Get.toNamed(DtrLogsView.routeName);
//   }

  // Future<void> captureAndUpload({
  //   required String note,
  //   required String attendanceType,
  //   required double latitude,
  //   required double longitude,
  //   required String plusCode,
  //   required String tabHeader,
  //   required String address_complete,
  // }) async {
  //   try {
  //     isLoading.value = true;

  //     // Show initial loading message
  //     Get.snackbar(
  //       'Processing',
  //       'Starting face verification...',
  //       duration: const Duration(seconds: 1),
  //       snackPosition: SnackPosition.BOTTOM,
  //     );

  //     // Navigate to face recognition and wait for result
  //     final bool? isVerified = await Get.to<bool>(
  //       () => const FaceRecognitionView(),
  //       transition: Transition.rightToLeft,
  //       duration: const Duration(milliseconds: 300),
  //     );

  //     // Check if verification was successful
  //     if (isVerified != true) {
  //       isLoading.value = false;
  //       Get.snackbar(
  //         'Cancelled',
  //         'Face verification failed or was cancelled.',
  //         backgroundColor: Colors.red,
  //         colorText: Colors.white,
  //         snackPosition: SnackPosition.BOTTOM,
  //         duration: const Duration(seconds: 2),
  //       );
  //       return;
  //     }

  //     // Face verification successful - continue with attendance recording
  //     Get.snackbar(
  //       'Processing',
  //       'Recording attendance...',
  //       duration: const Duration(seconds: 1),
  //       snackPosition: SnackPosition.BOTTOM,
  //     );

  //     // Capture the attendance image with overlays
  //     final modifiedImage = await _homeService.captureImage(
  //       note: note,
  //       latitude: latitude,
  //       longitude: longitude,
  //       plusCode: plusCode,
  //       tabHeader: tabHeader,
  //       address_complete: address_complete,
  //     );

  //     if (modifiedImage == null) {
  //       isLoading.value = false;
  //       Get.snackbar(
  //         'Error',
  //         'Failed to capture attendance image',
  //         backgroundColor: Colors.red,
  //         colorText: Colors.white,
  //         snackPosition: SnackPosition.BOTTOM,
  //       );
  //       return;
  //     }

  //     // Show capture success
  //     Fluttertoast.showToast(msg: 'Image captured!');

  //     // Save to database
  //     final dataInDatabase = await _homeService.uploadToDatabase(data: {
  //       'note': note,
  //       'attendance_type': attendanceType,
  //       'long_lat': '$latitude, $longitude',
  //       'address': plusCode,
  //       'address_complete': address_complete,
  //     });

  //     // Schedule background upload
  //     await Workmanager().registerOneOffTask(
  //       'uniqueName_${DateTime.now().millisecondsSinceEpoch}',
  //       'uploadTask',
  //       constraints: Constraints(networkType: NetworkType.connected),
  //       inputData: {
  //         'id': dataInDatabase,
  //         'filePath': modifiedImage.path,
  //       },
  //     );

  //     // Success - navigate to DTR logs
  //     isLoading.value = false;

  //     Get.snackbar(
  //       'Success',
  //       'Attendance recorded successfully!',
  //       backgroundColor: Colors.green,
  //       colorText: Colors.white,
  //       snackPosition: SnackPosition.BOTTOM,
  //       duration: const Duration(seconds: 2),
  //     );

  //     // Navigate to DTR logs
  //     // Use offAll to clear the navigation stack and prevent going back to face recognition
  //     await Get.offAllNamed(DtrLogsView.routeName);
  //   } catch (e) {
  //     isLoading.value = false;
  //     debugPrint('Error in captureAndUpload: $e');
  //     Get.snackbar(
  //       'Error',
  //       'An error occurred: ${e.toString()}',
  //       backgroundColor: Colors.red,
  //       colorText: Colors.white,
  //       snackPosition: SnackPosition.BOTTOM,
  //       duration: const Duration(seconds: 3),
  //     );
  //   }
  // }

  Future<void> captureAndUpload({
    required String note,
    required String attendanceType,
    required double latitude,
    required double longitude,
    required String plusCode,
    required String tabHeader,
    required String address_complete,
  }) async {
    try {
      isLoading.value = true;

      Get.snackbar(
        'Processing',
        'Starting face verification...',
        duration: const Duration(seconds: 1),
        snackPosition: SnackPosition.BOTTOM,
      );

      // Navigate to face recognition and wait for result
      final bool? isVerified = await Get.to<bool>(
        () => const FaceRecognitionView(),
        transition: Transition.rightToLeft,
        duration: const Duration(milliseconds: 300),
      );

      // Check if verification was successful
      if (isVerified != true) {
        isLoading.value = false;
        Get.snackbar(
          'Cancelled',
          'Face verification failed or was cancelled.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
        return;
      }

      // Face verification successful - continue with attendance recording
      Get.snackbar(
        'Processing',
        'Recording attendance...',
        duration: const Duration(seconds: 1),
        snackPosition: SnackPosition.BOTTOM,
      );

      // IMPORTANT: Camera management after face recognition
      debugPrint('Reinitializing camera after face recognition...');

      // Add delay to ensure face recognition camera is fully released
      await Future.delayed(const Duration(seconds: 2));

      // Dispose current camera if any
      disposeCamera();
      await Future.delayed(const Duration(milliseconds: 500));

      // Reinitialize camera
      await initializeCamera();
      await Future.delayed(
          const Duration(milliseconds: 1000)); // Extra delay for stability

      // Verify camera is ready
      if (cameraController == null || !cameraController!.value.isInitialized) {
        // Try one more time
        debugPrint('Camera not ready, trying again...');
        await initializeCamera();
        await Future.delayed(const Duration(milliseconds: 1000));

        if (cameraController == null ||
            !cameraController!.value.isInitialized) {
          throw Exception('Camera failed to initialize after face recognition');
        }
      }

      debugPrint('Camera ready, capturing attendance image...');

      // Now capture the attendance image with overlays
      final modifiedImage = await _homeService.captureImage(
        note: note,
        latitude: latitude,
        longitude: longitude,
        plusCode: plusCode,
        tabHeader: tabHeader,
        address_complete: address_complete,
      );

      if (modifiedImage == null) {
        isLoading.value = false;
        Get.snackbar(
          'Error',
          'Failed to capture attendance image',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      // Show capture success
      Fluttertoast.showToast(msg: 'Image captured!');

      // Save to database
      final dataInDatabase = await _homeService.uploadToDatabase(data: {
        'note': note,
        'attendance_type': attendanceType,
        'long_lat': '$latitude, $longitude',
        'address': plusCode,
        'address_complete': address_complete,
      });

      // Schedule background upload
      await Workmanager().registerOneOffTask(
        'uniqueName_${DateTime.now().millisecondsSinceEpoch}',
        'uploadTask',
        constraints: Constraints(networkType: NetworkType.connected),
        inputData: {
          'id': dataInDatabase,
          'filePath': modifiedImage.path,
        },
      );

      // Success
      debugPrint("Attendance recorded successfully!");
      isLoading.value = false;

      Get.snackbar(
        'Success',
        'Attendance recorded successfully!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );

      // Navigate to DTR logs
      await Future.delayed(const Duration(milliseconds: 300));
      Get.toNamed(DtrLogsView.routeName);
    } catch (e) {
      isLoading.value = false;
      debugPrint('Error in captureAndUpload: $e');
      Get.snackbar(
        'Error',
        'An error occurred: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    }
  }

  // Method to switch between cameras
  Future<void> switchCamera() async {
    await _homeService.switchCamera();
    update(); // Notify GetX listeners
  }

  Future<void> autoSwitchCamera({required int selectedIndex}) async {
    await _homeService.autoSwitchCamera(selectedIndex: selectedIndex);
    update(); // Notify GetX listeners
  }

  @override
  void onClose() {
    disposeCamera();
    super.onClose();
  }

  void disposeCamera() {
    _homeService.disposeCamera();
    update(); // Notify GetX listeners
  }
}
