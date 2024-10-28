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
    var result = await _dtrLogsService.getTimeLogs(
        employeeId: employeeId, dateFrom: dateFrom, dateTo: dateTo);

    return {"timelogs": result};
  }
}
