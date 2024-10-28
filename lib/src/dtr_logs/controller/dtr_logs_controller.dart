import 'package:get/get.dart';
import 'package:rts_locator/src/dtr_logs/service/dtr_logs_service.dart';

class DtrLogsController extends GetxController {
  final isLoading = false;

  final DtrLogsService _dtrLogsService;

  DtrLogsController(this._dtrLogsService);

  Future<Map<String, dynamic>> fetchLogs(
      {required String employeeId,
      required String dateFrom,
      required String dateTo}) async {
    var timeLogsResult = await _dtrLogsService.getTimeLogs(
        employeeId: employeeId, dateFrom: dateFrom, dateTo: dateTo);

    var otLogsResult = await _dtrLogsService.getOtLogs(employeeId: employeeId, dateFrom: dateFrom, dateTo: dateTo);

    return {"timelogs": timeLogsResult, "ot_logs": otLogsResult};
  }
}
