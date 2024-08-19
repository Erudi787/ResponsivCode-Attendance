import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:rts_locator/src/home/home_view.dart';
import 'package:rts_locator/src/login/login_view.dart';

class SplashService {
  final box = GetStorage();

  Future<void> checkToken() async {
    if (box.read('token') != null) {
      Get.offAllNamed(HomeView.routeName);
    } else {
      Get.offAllNamed(LoginView.routeName);
    }
  }
}
