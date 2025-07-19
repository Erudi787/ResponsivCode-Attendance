// lib/src/splash/splash_controller.dart

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:rts_locator/src/facial_recognition/face_data_manager.dart';
import 'package:rts_locator/src/facial_recognition/live_registration_view.dart';
import 'package:rts_locator/src/home/home_controller.dart';
import 'package:rts_locator/src/home/home_service.dart';
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
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      // Close any open overlays
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      if (Get.isSnackbarOpen ?? false) {
        Get.closeCurrentSnackbar();
      }

      if (box.read('token') != null) {
        final fullname = box.read('fullname') as String?;

        // Ensure HomeController is registered
        if (!Get.isRegistered<HomeController>()) {
          Get.put(HomeController(HomeService()));
        }

        if (fullname != null && !_dataManager.containsKey(fullname)) {
          // Dispose cameras before navigation
          try {
            Get.find<HomeController>().disposeCamera();
          } catch (_) {}
          Get.offAll(
            () => LiveRegistrationView(personName: fullname),
            transition: Transition.noTransition,
            duration: Duration.zero,
          );
        } else {
          Get.offAll(
            () => const HomeView(),
            transition: Transition.noTransition,
            duration: Duration.zero,
          );
        }
      } else {
        Get.offAll(
          () => const LoginView(),
          transition: Transition.noTransition,
          duration: Duration.zero,
        );
      }
    } catch (e) {
      print('Splash navigation error: $e');
      Get.offAll(
        () => const LoginView(),
        transition: Transition.noTransition,
        duration: Duration.zero,
      );
    }
  }
}
