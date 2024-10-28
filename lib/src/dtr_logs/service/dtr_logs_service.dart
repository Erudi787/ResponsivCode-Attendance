import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:rts_locator/src/dtr_logs/model/time_logs_model.dart';

class DtrLogsService {
  final dio = Dio();
  final baseUrl =
      'https://servicedesk.responsivcode.com/hris/index.php/attendanceController';

  Future<List<TimeLogsModel>> getTimeLogs(
      {required String employeeId,
      required String dateFrom,
      required String dateTo}) async {
    var response = await dio.get(
        '$baseUrl/timelogs?employee_id=$employeeId&date_from=$dateFrom&date_to=$dateTo',
        options: Options(
          validateStatus: (status) => true,
        ));

    if (response.statusCode == 200) {
      List logs = jsonDecode(response.data);

      List<TimeLogsModel> timeLogs =
          logs.map((log) => TimeLogsModel.fromJson(log)).toList();

      return timeLogs;
    } else {
      return [];
    }
  }
}
