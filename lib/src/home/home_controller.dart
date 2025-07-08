import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
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

  

 Future<void> captureAndUpload({
    required String note,
    required String attendanceType,
    required double latitude,
    required double longitude,
    required String plusCode,
    required String tabHeader,
    required String address_complete,
  }) async {
    isLoading.value = true;
    Get.showSnackbar(const GetSnackBar(
        message: 'Starting process...', duration: Duration(seconds: 2)));

    // --- Trigger Face Verification ---
  final bool? isVerified = await Get.toNamed(FaceRecognitionView.routeName);

    // If verification fails or the user cancels, stop the process
    if (isVerified != true) {
      isLoading.value = false;
      Get.snackbar("Cancelled", "Face verification failed or was cancelled.");
      return;
    }
    // ---------------------------------

    // --- If verification is successful, continue with original logic ---
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
      throw 'Image capture failed';
    }
    Fluttertoast.showToast(msg: 'Image captured!');

    final dataInDatabase = await _homeService.uploadToDatabase(data: {
      'note': note,
      'attendance_type': attendanceType,
      'long_lat': '$latitude, $longitude',
      'address': plusCode,
      'address_complete': address_complete,
    });

    await Workmanager().registerOneOffTask(
      'uniqueName_${DateTime.now().millisecondsSinceEpoch}', // Ensure unique task name
      'uploadTask',
      constraints: Constraints(networkType: NetworkType.connected),
      inputData: {
        'id': dataInDatabase,
        'filePath': modifiedImage.path,
      },
    );

    print("Done");
    isLoading.value = false;
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
