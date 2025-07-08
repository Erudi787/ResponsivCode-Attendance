// lib/src/splash/splash_controller.dart

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:rts_locator/src/facial_recognition/face_data_manager.dart';
import 'package:rts_locator/src/facial_recognition/live_registration_view.dart';
import 'package:rts_locator/src/home/home_view.dart';
import 'package:rts_locator/src/login/login_view.dart';
import 'package:rts_locator/src/splash/splash_service.dart';

class SplashController extends GetxController {
  final SplashService _splashService;
  // --- Add FaceDataManager instance ---
  final FaceDataManager _dataManager = Get.find<FaceDataManager>();
  final box = GetStorage();
  // ------------------------------------

  SplashController(this._splashService);

  Future<void> checkToken() async {
    // A short delay to allow services to fully initialize
    await Future.delayed(const Duration(milliseconds: 500));

    if (box.read('token') != null) {
      final fullname = box.read('fullname') as String?;

      // Check if user is logged in and if their face is registered
      if (fullname != null && !_dataManager.containsKey(fullname)) {
        // If not registered, navigate to the registration screen
        Get.offAllNamed(LiveRegistrationView.routeName, arguments: fullname);
      } else {
        // Otherwise, proceed to the home screen
        Get.offAllNamed(HomeView.routeName);
      }
    } else {
      Get.offAllNamed(LoginView.routeName);
    }
  }
}