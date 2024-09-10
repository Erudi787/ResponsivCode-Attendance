import 'package:get/get.dart';
import 'package:rts_locator/src/permission/permission_service.dart';

class PermissionController extends GetxController {
  final PermissionService _permissionService;
  PermissionController(this._permissionService);

  Future<void> requestPermissions() async {
    await _permissionService.requestPermissions();
  }
}
