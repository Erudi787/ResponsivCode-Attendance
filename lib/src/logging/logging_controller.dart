// lib/src/logging/logging_controller.dart

import 'package:get/get.dart';
import 'package:rts_locator/src/logging/logging_service.dart';

class LoggingController extends GetxController {
  final LoggingService _loggingService = LoggingService();

  void info(String message) {
    _loggingService.log(message, level: LogLevel.info);
  }

  void warning(String message) {
    _loggingService.log(message, level: LogLevel.warning);
  }

  void error(String message, {StackTrace? stackTrace}) {
    _loggingService.log(message, level: LogLevel.error, stackTrace: stackTrace);
  }
}