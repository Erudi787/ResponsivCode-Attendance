import 'package:get/get.dart';
import 'package:rts_locator/src/fluttertoast/fluttertoast_service.dart';

class FluttertoastController extends GetxController {
  final FluttertoastService _fluttertoastService;

  FluttertoastController(this._fluttertoastService);

  Future<void> toastAlertMessage(
      {required String message, required bool flag}) async {
    if (flag) {
      await _fluttertoastService.flutterToastSuccess(message: message);
    } else {
      await _fluttertoastService.flutterToastError(message: message);
    }
  }
}
