import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:rts_locator/src/location/location_controller.dart';
import 'package:rts_locator/src/location/location_service.dart';
import 'home_service.dart';

class HomeController extends GetxController {
  final isLoading = false.obs;
  final HomeService _homeService;

  HomeController(this._homeService);

  CameraController? get cameraController => _homeService.cameraController;
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

  Future<File?> captureImage({required String note}) async {
    isLoading.value = true;
    final image = await _homeService.captureImage(note: note);
    update(); // Notify GetX listeners
    return image;
  }

  Future<String> uploadToCloud({required File imageFile}) async {
    isLoading.value = true;
    // final imageUrl = await _homeService.uploadToCloud(imageFile: imageFile);
    return "imageUrl";
  }

  Future<void> uploadToDatabase({required Map<String, dynamic> data}) async {
    isLoading.value = true;
    // await _homeService.uploadToDatabase(data: data);
  }

  Future<void> captureAndUpload({required String note}) async {
    isLoading.value = true;
    Get.showSnackbar(const GetSnackBar(
        message: 'Starting process...', duration: Duration(seconds: 2)));
    //Capture the image
    final modifiedImage = await captureImage(note: note);

    if (modifiedImage == null) {
      throw 'Image capture failed';
    }
    Fluttertoast.showToast(
      msg: 'Image captured!',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      timeInSecForIosWeb: 2,
      backgroundColor: Colors.black,
      textColor: Colors.white,
      fontSize: 16.0,
    );

    // Upload to Cloudinary
    // final uploadedUrl = await uploadToCloud(imageFile: modifiedImage);
    // if (uploadedUrl.isEmpty) {
    //   throw 'Image upload failed';
    // }
    Fluttertoast.showToast(
      msg: 'Image uploaded to cloud!',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      timeInSecForIosWeb: 2,
      backgroundColor: Colors.black,
      textColor: Colors.white,
      fontSize: 16.0,
    );

    // Upload the image URL to your database
    // await uploadToDatabase(data: {"photo_url": uploadedUrl, 'note': note});
    Fluttertoast.showToast(
      msg: 'Image Recorded!',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      timeInSecForIosWeb: 2,
      backgroundColor: Colors.black,
      textColor: Colors.white,
      fontSize: 16.0,
    );
    // isLoading.value = false;
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
