import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:rts_locator/src/dtr_logs/model/ot_logs_model.dart';
import 'package:rts_locator/src/dtr_logs/model/time_logs_model.dart';
import 'package:rts_locator/src/environment/config_contoller.dart';
import 'package:rts_locator/src/environment/config_service.dart';
import 'package:rts_locator/src/logging/logging_controller.dart';

class DtrLogsService {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    )
  );
  // final baseUrl =
  //     'https://responsivcode-attendance-api.onrender.com/attendanceController';
  //final baseUrl = 'http://192.168.1.10/hris/index.php/attendanceController';
  //final baseUrl = 'http://10.0.2.2/hris/index.php/attendanceController';
  //final baseUrl = 'http://192.168.1.4/hris/index.php/attendanceController';

  final ConfigController configController =
      Get.put(ConfigController(ConfigService()));

  final LoggingController _loggingController = Get.find<LoggingController>();

  Future<List<TimeLogsModel>> getTimeLogs(
      {required String employeeId,
      required String dateFrom,
      required String dateTo}) async {
    var baseUrl = configController.apiUrl.value;
    try {
      var response = await dio.get(
          '$baseUrl/timelogs?employee_id=$employeeId&date_from=$dateFrom&date_to=$dateTo',
          options: Options(
            validateStatus: (status) => true,
          ));

      if (response.statusCode == 200) {
        try {
          //List logs = jsonDecode(response.data);
          List logs = response.data;
          List<TimeLogsModel> timeLogs =
              logs.map((log) => TimeLogsModel.fromJson(log)).toList();
          timeLogs.sort((a, b) => (b.date ?? "").compareTo(a.date ?? ""));
          _loggingController
              .info('Successfully fetched ${timeLogs.length} time logs.');
          return timeLogs;
        } catch (e, s) {
          _loggingController.error('Error decoding time logs JSON: $e',
              stackTrace: s);
          return [];
        }
      } else {
        _loggingController.error(
            'Failed to fetch time logs. Status: ${response.statusCode}, Body: ${response.data}');
        return [];
      }
    } catch (e, s) {
      _loggingController.error('Exception fetching time logs: $e',
          stackTrace: s);
      return [];
    }
  }

  Future<List<OtLogsModel>> getOtLogs(
      {required String employeeId,
      required String dateFrom,
      required String dateTo}) async {
    var baseUrl = configController.apiUrl.value;
    try {
      var response = await dio.get(
          '$baseUrl/ot_logs?employee_id=$employeeId&date_from=$dateFrom&date_to=$dateTo',
          options: Options(
            validateStatus: (status) => true,
          ));

      if (response.statusCode == 200) {
        try {
          //List logs = jsonDecode(response.data);
          List logs = response.data;
          List<OtLogsModel> otLogs =
              logs.map((log) => OtLogsModel.fromJson(log)).toList();
          otLogs.sort((a, b) => (b.date ?? "").compareTo(a.date ?? ""));
          _loggingController
              .info('Successfully fetched ${otLogs.length} overtime logs.');
          return otLogs;
        } catch (e, s) {
          _loggingController.error('Error decoding overtime logs JSON: $e',
              stackTrace: s);
          return [];
        }
      } else {
        _loggingController.error(
            'Failed to fetch overtime logs. Status: ${response.statusCode}, Body: ${response.data}');
        return [];
      }
    } catch (e, s) {
      _loggingController.error('Exception fetching overtime logs: $e',
          stackTrace: s);
      return [];
    }
  }
}
