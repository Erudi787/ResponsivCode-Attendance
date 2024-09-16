import 'package:get/get.dart';
import 'package:rts_locator/src/environment/config_contoller.dart';
import 'package:rts_locator/src/environment/config_service.dart';
import 'package:rts_locator/src/fluttertoast/fluttertoast_controller.dart';
import 'package:rts_locator/src/fluttertoast/fluttertoast_service.dart';
import 'package:rts_locator/src/home/home_view.dart';
import 'package:rts_locator/src/login/login_service.dart';

class LoginController extends GetxController {
  final isLoading = false.obs;
  final LoginService _loginService;
  final ConfigController _configController =
      Get.put(ConfigController(ConfigService()));
  final FluttertoastController _fluttertoastController =
      Get.put(FluttertoastController(FluttertoastService()));

  LoginController(this._loginService);

  Future<void> login(
      {required String username, required String password}) async {
    isLoading.value = true;

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
      Get.offAllNamed(HomeView.routeName);
      update();
    } else {
      isLoading.value = false;
    }
    update();
  }
}
