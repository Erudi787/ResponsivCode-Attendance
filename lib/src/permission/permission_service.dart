import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<void> requestPermissions() async {
    try {
      PermissionStatus cameraStatus = await Permission.camera.request();
      _handlePermissionStatus(cameraStatus, "Camera");

      if (cameraStatus.isGranted) {
        PermissionStatus locationStatus = await Permission.location.request();
        _handlePermissionStatus(locationStatus, "Location");

        if (locationStatus.isGranted) {
          PermissionStatus microphoneStatus =
              await Permission.microphone.request();
          _handlePermissionStatus(microphoneStatus, "Microphone");
        }
      }
    } catch (e) {
      Fluttertoast.showToast(
          msg: "Error requesting permissions: $e",
          gravity: ToastGravity.CENTER);
    }
  }

  void _handlePermissionStatus(
      PermissionStatus? status, String permissionName) {
    if (status == PermissionStatus.denied) {
      Fluttertoast.showToast(
          msg: "$permissionName permission is required.",
          gravity: ToastGravity.CENTER);
    } else if (status == PermissionStatus.permanentlyDenied) {
      Fluttertoast.showToast(
          msg: "$permissionName permission is permanently denied",
          gravity: ToastGravity.CENTER);
    }
  }
}
