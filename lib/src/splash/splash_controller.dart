import 'package:get/get.dart';
import 'package:rts_locator/src/splash/splash_service.dart';

class SplashController extends GetxController {
  final SplashService _splashService;

  SplashController(this._splashService);

  Future<void> checkToken() async {
    await _splashService.checkToken();
  }
}
