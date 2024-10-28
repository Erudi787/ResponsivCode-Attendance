import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_expandable_table/flutter_expandable_table.dart';
import 'package:get/get.dart';
import 'package:rts_locator/src/dtr_logs/controller/dtr_logs_controller.dart';
import 'package:rts_locator/src/dtr_logs/model/time_logs_model.dart';
import 'package:rts_locator/src/dtr_logs/service/dtr_logs_service.dart';

class DtrLogsView extends StatefulWidget {
  const DtrLogsView({super.key});

  static const routeName = '/logs';

  @override
  State<DtrLogsView> createState() => _DtrLogsViewState();
}

class _DtrLogsViewState extends State<DtrLogsView> {
  final DtrLogsController dtrLogsController =
      Get.put(DtrLogsController(DtrLogsService()));

  ValueNotifier<List<DateTime?>> dates = ValueNotifier<List<DateTime?>>([]);
  ValueNotifier<List<TimeLogsModel>> timeLogs =
      ValueNotifier<List<TimeLogsModel>>([]);

  List<DataColumn> header = [
    const DataColumn(label: Text('DATE')),
    const DataColumn(label: Text('TIME IN')),
    const DataColumn(label: Text('BREAK OUT')),
    const DataColumn(label: Text('BREAK IN')),
    const DataColumn(label: Text('TIME OUT')),
  ];

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          GestureDetector(
            onTap: () async {
              var results = await showCalendarDatePicker2Dialog(
                context: context,
                config: CalendarDatePicker2WithActionButtonsConfig(
                    calendarType: CalendarDatePicker2Type.range),
                dialogSize: const Size(325, 400),
                value: dates.value,
                borderRadius: BorderRadius.circular(15),
              );

              dates.value = results!;

              var response = await dtrLogsController.fetchLogs(
                employeeId: '21',
                dateFrom: dates.value[0]?.toString().split(' ')[0] ?? '',
                dateTo: dates.value[1]?.toString().split(' ')[0] ?? '',
              );

              timeLogs = ValueNotifier(response['timelogs'] ?? []);
              setState(() {});
              // Log each item's details
              timeLogs.value.forEach((log) {
                print(
                    "Date: ${log.date}, Time In: ${log.timeIn}, Break Out: ${log.breakOut}, Break In: ${log.breakIn}, Time Out: ${log.timeOut}");
              });
            },
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(
                Icons.calendar_month,
                size: 32,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              child: ListView(
                scrollDirection: Axis.vertical,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      alignment: Alignment.topLeft,
                      child: Text(
                        "Time Logs",
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: DataTable(
                      border: TableBorder.all(),
                      columnSpacing: 10, // Adds space between columns
                      headingRowColor: MaterialStateColor.resolveWith(
                          (states) => Colors.blueGrey.shade100),
                      dataRowColor: MaterialStateColor.resolveWith(
                        (states) => states.contains(MaterialState.selected)
                            ? Colors.blueGrey.shade50 // Color on row selection
                            : Colors.grey.shade50,
                      ),
                      columns: const [
                        DataColumn(
                          label: Text(
                            'Date',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Time In',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Break Out',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Break In',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Time Out',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                      rows: List.generate(
                        timeLogs.value.length,
                        (index) => DataRow(
                          cells: [
                            DataCell(Text(timeLogs.value[index].date == ""
                                ? "N/A"
                                : timeLogs.value[index].date!)),
                            DataCell(Text(timeLogs.value[index].timeIn == ""
                                ? "N/A"
                                : timeLogs.value[index].timeIn!)),
                            DataCell(Text(timeLogs.value[index].breakOut == ""
                                ? "N/A"
                                : timeLogs.value[index].breakOut!)),
                            DataCell(Text(timeLogs.value[index].breakIn == ""
                                ? "N/A"
                                : timeLogs.value[index].breakIn!)),
                            DataCell(Text(timeLogs.value[index].timeOut == ""
                                ? "N/A"
                                : timeLogs.value[index].timeOut!)),
                          ],
                          selected: index % 2 ==
                              0, // Optional: select alternating rows
                        ),
                      ),
                      dividerThickness: 1.5, // Sets thickness of row divider
                      showBottomBorder: true, // Adds a bottom border
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Divider(
              thickness: 2,
            ),
          ),
          Expanded(
            child: Container(
              child: ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      alignment: Alignment.topLeft,
                      child: Text(
                        "Overtime Logs",
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: DataTable(
                      border: TableBorder.all(),
                      columnSpacing: 10, // Adds space between columns
                      headingRowColor: MaterialStateColor.resolveWith(
                          (states) => Colors.blueGrey.shade100),
                      dataRowColor: MaterialStateColor.resolveWith(
                        (states) => states.contains(MaterialState.selected)
                            ? Colors.blueGrey.shade50 // Color on row selection
                            : Colors.grey.shade50,
                      ),
                      columns: const [
                        DataColumn(
                          label: Text(
                            'Date',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Overtime In',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Overtime Out',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                      rows: List.generate(
                        timeLogs.value.length,
                        (index) => DataRow(
                          cells: [
                            DataCell(Text(timeLogs.value[index].date == ""
                                ? "N/A"
                                : timeLogs.value[index].date!)),
                            DataCell(Text(timeLogs.value[index].timeIn == ""
                                ? "N/A"
                                : timeLogs.value[index].timeIn!)),
                            DataCell(Text(timeLogs.value[index].breakOut == ""
                                ? "N/A"
                                : timeLogs.value[index].breakOut!)),
                          ],
                          selected: index % 2 ==
                              0, // Optional: select alternating rows
                        ),
                      ),
                      dividerThickness: 1.5, // Sets thickness of row divider
                      showBottomBorder: true, // Adds a bottom border
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Divider(
              thickness: 2,
            ),
          ),
        ],
      ),
    );
  }
}
