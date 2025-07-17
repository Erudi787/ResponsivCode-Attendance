// lib/src/dtr_logs/view/dtr_logs_view.dart

import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:rts_locator/src/dtr_logs/controller/dtr_logs_controller.dart';
import 'package:rts_locator/src/dtr_logs/model/ot_logs_model.dart';
import 'package:rts_locator/src/dtr_logs/model/time_logs_model.dart';
import 'package:rts_locator/src/dtr_logs/service/dtr_logs_service.dart';
import 'package:rts_locator/src/home/home_view.dart';
import 'package:rts_locator/src/logging/logging_controller.dart';

class DtrLogsView extends StatefulWidget {
  const DtrLogsView({super.key});

  static const routeName = '/logs';

  @override
  State<DtrLogsView> createState() => _DtrLogsViewState();
}

class _DtrLogsViewState extends State<DtrLogsView> {
  final box = GetStorage();
  final DtrLogsController dtrLogsController =
      Get.put(DtrLogsController(DtrLogsService()));
  final LoggingController _loggingController = Get.find<LoggingController>();

  late Future<Map<String, dynamic>> _logsFuture;
  List<DateTime?> _dates = [];

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _dates = [today, today];
    _logsFuture = _fetchLogs();
  }

  Future<Map<String, dynamic>> _fetchLogs() {
    _loggingController.info(
        'Fetching logs for dates: ${_dates[0]} to ${_dates.length > 1 ? _dates[1] : _dates[0]}');
    setState(() {
      _logsFuture = dtrLogsController.fetchLogs(
        employeeId: box.read('user_id'),
        dateFrom: _dates[0]?.toIso8601String().split('T')[0] ?? '',
        dateTo: (_dates.length > 1 ? _dates[1] : _dates[0])
                ?.toIso8601String()
                .split('T')[0] ??
            '',
      );
    });
    return _logsFuture;
  }

  void _showCalendar() async {
    final results = await showCalendarDatePicker2Dialog(
      context: context,
      config: CalendarDatePicker2WithActionButtonsConfig(
          calendarType: CalendarDatePicker2Type.range),
      dialogSize: const Size(325, 400),
      value: _dates,
      borderRadius: BorderRadius.circular(15),
    );

    if (results != null && results.isNotEmpty) {
      _dates = results;
      _fetchLogs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        //Get.offAllNamed(HomeView.routeName);
        Get.back();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            //onPressed: () => Get.offAllNamed(HomeView.routeName),
            onPressed: ()=> Get.back(),
          ),
          actions: [
            IconButton(
              onPressed: _showCalendar,
              icon: const Icon(
                Icons.calendar_month,
                size: 32,
              ),
            ),
          ],
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _logsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              _loggingController.error('Error in DTR logs FutureBuilder',
                  stackTrace: snapshot.stackTrace);
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${snapshot.error}'),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _fetchLogs,
                      child: const Text('Retry'),
                    )
                  ],
                ),
              );
            }

            final timeLogs =
                snapshot.data?['timelogs'] as List<TimeLogsModel>? ?? [];
            final otLogs =
                snapshot.data?['ot_logs'] as List<OtLogsModel>? ?? [];

            if (timeLogs.isEmpty && otLogs.isEmpty) {
              _loggingController
                  .info('No logs found for the selected date range.');
              return const Center(
                  child: Text('No logs found for this period.'));
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      "Time Logs",
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: DataTable(
                        border: TableBorder.all(
                            borderRadius: BorderRadius.circular(8)),
                        columns: const [
                          DataColumn(label: Text('Date')),
                          DataColumn(label: Text('Time In')),
                          DataColumn(label: Text('Break Out')),
                          DataColumn(label: Text('Break In')),
                          DataColumn(label: Text('Time Out')),
                        ],
                        rows: timeLogs.map((log) {
                          return DataRow(cells: [
                            DataCell(Text(log.date ?? 'N/A')),
                            DataCell(Text(log.timeIn ?? 'N/A')),
                            DataCell(Text(log.breakOut ?? 'N/A')),
                            DataCell(Text(log.breakIn ?? 'N/A')),
                            DataCell(Text(log.timeOut ?? 'N/A')),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Divider(thickness: 2),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      "Overtime Logs",
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: DataTable(
                        border: TableBorder.all(
                            borderRadius: BorderRadius.circular(8)),
                        columns: const [
                          DataColumn(label: Text('Date')),
                          DataColumn(label: Text('Overtime In')),
                          DataColumn(label: Text('Overtime Out')),
                        ],
                        rows: otLogs.map((log) {
                          return DataRow(cells: [
                            DataCell(Text(log.date ?? 'N/A')),
                            DataCell(Text(log.otIn ?? 'N/A')),
                            DataCell(Text(log.otOut ?? 'N/A')),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// import 'package:calendar_date_picker2/calendar_date_picker2.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:get_storage/get_storage.dart';
// import 'package:rts_locator/src/dtr_logs/controller/dtr_logs_controller.dart';
// import 'package:rts_locator/src/dtr_logs/model/ot_logs_model.dart';
// import 'package:rts_locator/src/dtr_logs/model/time_logs_model.dart';
// import 'package:rts_locator/src/dtr_logs/service/dtr_logs_service.dart';

// class DtrLogsView extends StatefulWidget {
//   const DtrLogsView({super.key});

//   static const routeName = '/logs';

//   @override
//   State<DtrLogsView> createState() => _DtrLogsViewState();
// }

// class _DtrLogsViewState extends State<DtrLogsView> {
//   final box = GetStorage();
//   final DtrLogsController dtrLogsController =
//       Get.put(DtrLogsController(DtrLogsService()));

//   ValueNotifier<List<DateTime?>> dates = ValueNotifier<List<DateTime?>>([]);
//   ValueNotifier<List<TimeLogsModel>> timeLogs =
//       ValueNotifier<List<TimeLogsModel>>([]);
//   ValueNotifier<List<OtLogsModel>> otLogs =
//       ValueNotifier<List<OtLogsModel>>([]);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         elevation: 0,
//         scrolledUnderElevation: 0,
//         actions: [
//           GestureDetector(
//             onTap: () async {
//               var results = await showCalendarDatePicker2Dialog(
//                 context: context,
//                 config: CalendarDatePicker2WithActionButtonsConfig(
//                     calendarType: CalendarDatePicker2Type.range),
//                 dialogSize: const Size(325, 400),
//                 value: dates.value,
//                 borderRadius: BorderRadius.circular(15),
//               );

//               if (results != null) {
//                 dates.value = results;

//                 var response = await dtrLogsController.fetchLogs(
//                   employeeId: box.read('user_id'),
//                   dateFrom: dates.value[0]?.toString().split(' ')[0] ?? '',
//                   dateTo: dates.value[1]?.toString().split(' ')[0] ?? '',
//                 );

//                 timeLogs = ValueNotifier(response['timelogs'] ?? []);
//                 otLogs = ValueNotifier(response['ot_logs'] ?? []);
//                 setState(() {});
//               }

//               // Log each item's details
//             },
//             child: const Padding(
//               padding: EdgeInsets.all(8.0),
//               child: Icon(
//                 Icons.calendar_month,
//                 size: 32,
//               ),
//             ),
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: Container(
//               child: ListView(
//                 scrollDirection: Axis.vertical,
//                 children: [
//                   Padding(
//                     padding: const EdgeInsets.all(8.0),
//                     child: Container(
//                       alignment: Alignment.topLeft,
//                       child: Text(
//                         "Time Logs",
//                         style: TextStyle(
//                             fontSize: 24, fontWeight: FontWeight.w600),
//                       ),
//                     ),
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.all(8.0),
//                     child: SingleChildScrollView(
//                       scrollDirection: Axis.horizontal,
//                       child: DataTable(
//                         border: TableBorder.all(),
//                         dataTextStyle: TextStyle(fontSize: 16),
//                         columns: const [
//                           DataColumn(
//                             label: Text(
//                               'Date',
//                               style: TextStyle(
//                                   fontWeight: FontWeight.bold, fontSize: 18),
//                             ),
//                           ),
//                           DataColumn(
//                             label: Text(
//                               'Time In',
//                               style: TextStyle(
//                                   fontWeight: FontWeight.bold, fontSize: 18),
//                             ),
//                           ),
//                           DataColumn(
//                             label: Text(
//                               'Break Out',
//                               style: TextStyle(
//                                   fontWeight: FontWeight.bold, fontSize: 18),
//                             ),
//                           ),
//                           DataColumn(
//                             label: Text(
//                               'Break In',
//                               style: TextStyle(
//                                   fontWeight: FontWeight.bold, fontSize: 18),
//                             ),
//                           ),
//                           DataColumn(
//                             label: Text(
//                               'Time Out',
//                               style: TextStyle(
//                                   fontWeight: FontWeight.bold, fontSize: 18),
//                             ),
//                           ),
//                         ],
//                         rows: List.generate(
//                           timeLogs.value.length,
//                           (index) => DataRow(
//                             cells: [
//                               DataCell(Text(timeLogs.value[index].date == ""
//                                   ? "N/A"
//                                   : timeLogs.value[index].date!)),
//                               DataCell(Text(timeLogs.value[index].timeIn == ""
//                                   ? "N/A"
//                                   : timeLogs.value[index].timeIn!)),
//                               DataCell(Text(timeLogs.value[index].breakOut == ""
//                                   ? "N/A"
//                                   : timeLogs.value[index].breakOut!)),
//                               DataCell(Text(timeLogs.value[index].breakIn == ""
//                                   ? "N/A"
//                                   : timeLogs.value[index].breakIn!)),
//                               DataCell(Text(timeLogs.value[index].timeOut == ""
//                                   ? "N/A"
//                                   : timeLogs.value[index].timeOut!)),
//                             ],
//                             selected: index % 2 ==
//                                 0, // Optional: select alternating rows
//                           ),
//                         ),
//                         dividerThickness: 1.5, // Sets thickness of row divider
//                         showBottomBorder: true, // Adds a bottom border
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           const Padding(
//             padding: EdgeInsets.all(8.0),
//             child: Divider(
//               thickness: 2,
//             ),
//           ),
//           Expanded(
//             child: Container(
//               child: ListView(
//                 children: [
//                   Padding(
//                     padding: const EdgeInsets.all(8.0),
//                     child: Container(
//                       alignment: Alignment.topLeft,
//                       child: Text(
//                         "Overtime Logs",
//                         style: TextStyle(
//                             fontSize: 24, fontWeight: FontWeight.w600),
//                       ),
//                     ),
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.all(8.0),
//                     child: DataTable(
//                       dataTextStyle: TextStyle(fontSize: 16),
//                       border: TableBorder.all(),
//                       columnSpacing: 10, // Adds space between columns
//                       columns: const [
//                         DataColumn(
//                           label: Text(
//                             'Date',
//                             style: TextStyle(
//                                 fontWeight: FontWeight.bold, fontSize: 18),
//                           ),
//                         ),
//                         DataColumn(
//                           label: Text(
//                             'Overtime In',
//                             style: TextStyle(
//                                 fontWeight: FontWeight.bold, fontSize: 18),
//                           ),
//                         ),
//                         DataColumn(
//                           label: Text(
//                             'Overtime Out',
//                             style: TextStyle(
//                                 fontWeight: FontWeight.bold, fontSize: 18),
//                           ),
//                         ),
//                       ],
//                       rows: List.generate(
//                         otLogs.value.length,
//                         (index) => DataRow(
//                           cells: [
//                             DataCell(Text(otLogs.value[index].date == ""
//                                 ? "N/A"
//                                 : otLogs.value[index].date!)),
//                             DataCell(Text(otLogs.value[index].otIn == ""
//                                 ? "N/A"
//                                 : otLogs.value[index].otIn!)),
//                             DataCell(Text(otLogs.value[index].otOut == ""
//                                 ? "N/A"
//                                 : otLogs.value[index].otOut!)),
//                           ],
//                           selected: index % 2 ==
//                               0, // Optional: select alternating rows
//                         ),
//                       ),
//                       dividerThickness: 1.5, // Sets thickness of row divider
//                       showBottomBorder: true, // Adds a bottom border
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           const Padding(
//             padding: EdgeInsets.all(8.0),
//             child: Divider(
//               thickness: 2,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
