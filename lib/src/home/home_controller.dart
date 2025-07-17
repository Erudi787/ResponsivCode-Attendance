// lib/src/home/home_controller.dart

import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:rts_locator/src/dtr_logs/model/time_logs_model.dart';
import 'package:rts_locator/src/dtr_logs/service/dtr_logs_service.dart';
import 'package:rts_locator/src/dtr_logs/view/dtr_logs_view.dart';
import 'package:rts_locator/src/facial_recognition/facial_recognition_controller.dart';
import 'package:rts_locator/src/location/location_controller.dart';
import 'package:rts_locator/src/location/location_service.dart';
import 'package:rts_locator/src/splash/splash_view.dart';
import 'package:workmanager/workmanager.dart';
import 'home_service.dart';

class HomeController extends GetxController {
  final isLoading = false.obs;
  final HomeService _homeService;
  final DtrLogsService _dtrLogsService = DtrLogsService();
  final FacialRecognitionController _faceController =
      Get.find<FacialRecognitionController>();

  HomeController(this._homeService);

  final box = GetStorage();

  final tabAvailability = {
    'documentary': true.obs,
    'time_in': true.obs,
    'break_out': false.obs,
    'break_in': false.obs,
    'time_out': false.obs,
    'ot_in': false.obs,
    'ot_out': false.obs,
  }.obs;

  CameraController? get cameraController => _homeService.cameraController;
  int? get selectedCameraIndex => _homeService.selectedCameraIndex;

  final LocationController locationController =
      Get.put(LocationController(LocationService()));

  @override
  void onInit() {
    super.onInit();
    initializeCamera();
    checkAttendanceStatus();
  }

  Future<void> checkAttendanceStatus() async {
    final today = DateTime.now();
    final dateFrom = today.toIso8601String().split('T')[0];
    final dateTo = today.toIso8601String().split('T')[0];
    final employeeId = box.read('user_id');

    if (employeeId != null) {
      final timeLogs = await _dtrLogsService.getTimeLogs(
        employeeId: employeeId,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );

      updateTabAvailability(timeLogs.isNotEmpty ? timeLogs.first : null);
    }
  }

  void updateTabAvailability(TimeLogsModel? log) {
    if (log == null) {
      // No logs for today, so only time in is allowed
      tabAvailability['time_in']?.value = true;
      tabAvailability['break_out']?.value = false;
      tabAvailability['break_in']?.value = false;
      tabAvailability['time_out']?.value = false;
      tabAvailability['ot_in']?.value = false;
      tabAvailability['ot_out']?.value = false;
      return;
    }

    final hasTimeIn = log.timeIn != null && log.timeIn!.isNotEmpty;
    final hasBreakOut = log.breakOut != null && log.breakOut!.isNotEmpty;
    final hasBreakIn = log.breakIn != null && log.breakIn!.isNotEmpty;
    final hasTimeOut = log.timeOut != null && log.timeOut!.isNotEmpty;

    tabAvailability['time_in']?.value = !hasTimeIn;
    tabAvailability['break_out']?.value = hasTimeIn && !hasBreakOut;
    tabAvailability['break_in']?.value = hasBreakOut && !hasBreakIn;
    tabAvailability['time_out']?.value = hasBreakIn && !hasTimeOut;
  }

  Future<void> initializeCamera() async {
    await _homeService.initializeCamera();
    update(); // Notify GetX listeners
  }

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
      File? modifiedImage;
      final personName = box.read('fullname') as String?;

      if (personName == null) {
        Get.snackbar('Error', 'User not logged in.',
            backgroundColor: Colors.red, colorText: Colors.white);
        isLoading.value = false;
        return;
      }

      // --- Unified Face Verification and Capture Logic ---
      if (attendanceType != 'documentary') {
        // For all types except 'documentary', perform face verification first
        Get.snackbar(
          'Processing',
          'Verifying face...',
          duration: const Duration(seconds: 2),
          snackPosition: SnackPosition.BOTTOM,
        );
        final XFile? imageXFile = await cameraController?.takePicture();
        if (imageXFile == null) {
          isLoading.value = false;
          return;
        }
        final File imageFile = File(imageXFile.path);
        final bool isVerified =
            await _faceController.verifyFace(imageFile, personName);

        if (!isVerified) {
          Get.snackbar(
            'Verification Failed',
            _faceController.recognitionResult.value ??
                'Could not verify your face.',
            backgroundColor: Colors.red,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
          );
          isLoading.value = false;
          return;
        }
        // If verification is successful, use this image
        modifiedImage = imageFile;
      }

      // Capture image (handles both documentary and verified images)
      modifiedImage ??= await _homeService.captureImage(
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
          'Failed to capture image.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      // Add watermark to the verified or captured image
      modifiedImage = await _homeService.addWatermarkAndSave(
        imageFile: modifiedImage,
        note: note,
        latitude: latitude,
        longitude: longitude,
        plusCode: plusCode,
        tabHeader: tabHeader,
        address_complete: address_complete,
      );

      // --- FIX: Add a null check after watermarking ---
      if (modifiedImage == null) {
        isLoading.value = false;
        Get.snackbar(
          'Error',
          'Failed to process image with watermark.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      Fluttertoast.showToast(msg: 'Image processed successfully!');

      final dataInDatabase = await _homeService.uploadToDatabase(data: {
        'note': note,
        'attendance_type': attendanceType,
        'long_lat': '$latitude, $longitude',
        'address': plusCode,
        'address_complete': address_complete,
      });

      await Workmanager().registerOneOffTask(
        'uniqueName_${DateTime.now().millisecondsSinceEpoch}',
        'uploadTask',
        constraints: Constraints(networkType: NetworkType.connected),
        inputData: {
          'id': dataInDatabase,
          'filePath': modifiedImage.path, // This is now safe
        },
      );

      isLoading.value = false;
      Get.snackbar(
        'Success',
        'Attendance recorded successfully!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );

      await checkAttendanceStatus(); // Re-check status after an action
      if (attendanceType == 'documentary') {
        Get.offAllNamed(DtrLogsView.routeName);
      } else {
        Get.offAllNamed(SplashView.routeName);
      }
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