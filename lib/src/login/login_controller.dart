import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:rts_locator/src/environment/config_contoller.dart';
import 'package:rts_locator/src/environment/config_service.dart';
import 'package:rts_locator/src/facial_recognition/face_data_manager.dart';
import 'package:rts_locator/src/facial_recognition/facial_recognition_controller.dart';
import 'package:rts_locator/src/facial_recognition/facial_recognition_service.dart';
import 'package:rts_locator/src/facial_recognition/live_registration_view.dart';
import 'package:rts_locator/src/fluttertoast/fluttertoast_controller.dart';
import 'package:rts_locator/src/fluttertoast/fluttertoast_service.dart';
import 'package:rts_locator/src/home/home_controller.dart';
import 'package:rts_locator/src/home/home_minimal.dart';
import 'package:rts_locator/src/home/home_service.dart';
import 'package:rts_locator/src/home/home_view.dart';
import 'package:rts_locator/src/login/login_service.dart';

class LoginController extends GetxController {
  final isLoading = false.obs;
  final LoginService _loginService;
  final ConfigController _configController =
      Get.put(ConfigController(ConfigService()));
  final FluttertoastController _fluttertoastController =
      Get.put(FluttertoastController(FluttertoastService()));

  final FaceDataManager _dataManager = Get.find<FaceDataManager>();
  final box = GetStorage();

  LoginController(this._loginService);

  Future<void> login(
      {required String username, required String password}) async {
    isLoading.value = true;

    try {
      Map<String, dynamic> formData = {
        "username": username,
        "password": password
      };

      Map<String, dynamic> response = await _loginService.loginAuthentication(
          data: formData, apiUrl: _configController.apiUrl.toString());

      await _fluttertoastController.toastAlertMessage(
          message: response['message'], flag: response['flag']);

      if (response['flag']) {
        isLoading.value = false;
        update();

        final fullname = box.read('fullname') as String?;

        // Ensure all controllers exist
        _ensureControllersExist();

        // Clear any overlays
        Get.closeAllSnackbars();
        if (Get.isDialogOpen ?? false) {
          Get.back();
        }

        // Wait for UI to settle
        await Future.delayed(const Duration(milliseconds: 800));

        // Navigate with clean transition
        if (fullname != null && !_dataManager.containsKey(fullname)) {
          Get.offAll(
            () => LiveRegistrationView(personName: fullname),
            transition: Transition.fade,
            duration: const Duration(milliseconds: 300),
          );
        } else {
          Get.offAll(
            () => const HomeView(),
            transition: Transition.fade,
            duration: const Duration(milliseconds: 300),
          );
        }
      } else {
        isLoading.value = false;
        update();
      }
    } catch (e) {
      debugPrint('Login error: $e');
      isLoading.value = false;
      update();
      await _fluttertoastController.toastAlertMessage(
          message: 'Login failed: ${e.toString()}', flag: false);
    }
  }

  void _ensureControllersExist() {
    // Ensure FaceRecognitionService
    if (!Get.isRegistered<FaceRecognitionService>()) {
      Get.put(FaceRecognitionService(), permanent: true);
    }

    // Ensure FaceDataManager
    if (!Get.isRegistered<FaceDataManager>()) {
      Get.put(FaceDataManager(), permanent: true);
    }

    // Ensure FacialRecognitionController
    if (!Get.isRegistered<FacialRecognitionController>()) {
      Get.put(FacialRecognitionController(), permanent: true);
    }

    // Ensure HomeController
    if (!Get.isRegistered<HomeController>()) {
      Get.put(HomeController(HomeService()));
    }
  }
}
