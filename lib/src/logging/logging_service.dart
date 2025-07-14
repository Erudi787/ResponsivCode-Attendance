// lib/src/logging/logging_service.dart

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:rts_locator/src/environment/config_contoller.dart';
import 'package:rts_locator/src/environment/config_service.dart';

enum LogLevel { info, warning, error }

class LoggingService {
  final Dio _dio = Dio();
  final ConfigController _configController =
      Get.put(ConfigController(ConfigService()));

  Future<void> log(String message,
      {LogLevel level = LogLevel.info, StackTrace? stackTrace}) async {
    try {
      final apiUrl = _configController.apiUrl.value;
      if (apiUrl.isEmpty) {
        debugPrint("API URL is not configured. Cannot send log.");
        return;
      }

      await _dio.post(
        '$apiUrl/logging/log', // New endpoint for logging
        data: {
          'message': message,
          'level': level.toString().split('.').last,
          'timestamp': DateTime.now().toIso8601String(),
          'stackTrace': stackTrace?.toString(),
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
          validateStatus: (status) => status! < 500,
        ),
      );
    } catch (e) {
      // Print to console if logging to the backend fails
      debugPrint('Failed to send log to backend: $e');
    }
  }
}