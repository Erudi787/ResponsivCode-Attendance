
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:rts_locator/src/environment/config_contoller.dart';
import 'package:rts_locator/src/environment/config_service.dart';
import 'package:rts_locator/src/facial_recognition/face_data_manager.dart';
import 'package:rts_locator/src/facial_recognition/facial_recognition_binding.dart';
import 'package:rts_locator/src/facial_recognition/facial_recognition_service.dart';
import 'package:rts_locator/src/home/home_service.dart';
import 'package:rts_locator/src/permission/permission_controller.dart';
import 'package:rts_locator/src/permission/permission_service.dart';
import 'package:workmanager/workmanager.dart';

import 'src/app.dart';
import 'src/settings/settings_controller.dart';
import 'src/settings/settings_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print("CallbackDispatcher started");
    try {
      await dotenv.load();
      print("dotenv loaded");

      final homeService = HomeService();
      print("HomeService initialized");

      final filePath = inputData?['filePath'];
      final id = inputData?['id'];
      print("FilePath: $filePath, ID: $id");

      if (filePath != null && File(filePath).existsSync()) {
        final File modifiedImage = File(filePath);
        final uploadedUrl =
            await homeService.uploadToCloud(imageFile: modifiedImage);

        if (uploadedUrl.isNotEmpty) {
          await homeService.updateToDatabase(
            data: {'id': id, 'photo_url': uploadedUrl},
          );
        }
      }
      return Future.value(true);
    } catch (e, stackTrace) {
      print("Error: $e");
      print("StackTrace: $stackTrace");
      return Future.value(false);
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  // --- Initialize Face Recognition Services ---
  // This ensures the services are ready before the app runs.
  await Get.putAsync(() async => FaceRecognitionService()..initialize());
  await Get.putAsync(() async => FaceDataManager()..loadRegisteredFaces());
  // ------------------------------------------

  final settingsController = SettingsController(SettingsService());
  final environmentController = ConfigController(ConfigService());
  final permissionController = PermissionController(PermissionService());

  await settingsController.loadSettings();
  await environmentController.loadCloundConfig();
  await permissionController.requestPermissions();

  Workmanager().initialize(callbackDispatcher, isInDebugMode: true);

  // Set up the bindings for the facial recognition controller
  FacialRecognitionBinding().dependencies();

  runApp(MyApp(settingsController: settingsController));
}