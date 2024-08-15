import 'dart:io';

import 'package:camera/camera.dart';
import 'package:get/get.dart';
import 'home_service.dart';

class HomeController extends GetxController {
  final HomeService _homeService;

  HomeController(this._homeService);

  CameraController? get cameraController => _homeService.cameraController;

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
    final image = await _homeService.captureImage(note: note);
    update(); // Notify GetX listeners
    return image;
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
