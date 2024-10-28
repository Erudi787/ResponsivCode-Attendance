import 'dart:convert';

TimeLogsModel timeLogsModelFromJson(String str) =>
    TimeLogsModel.fromJson(json.decode(str));

String timeLogsModelToJson(TimeLogsModel data) => json.encode(data.toJson());

class TimeLogsModel {
  final String? date;
  final String? timeIn;
  final String? breakOut;
  final String? breakIn;
  final String? timeOut;

  TimeLogsModel({
    this.date,
    this.timeIn,
    this.breakOut,
    this.breakIn,
    this.timeOut,
  });

  static String formatTime(String? time) {
    if (time == null || time.isEmpty) return '';

    final parts = time.split(':');
    final int hour = int.parse(parts[0]);
    final int minute = int.parse(parts[1]);

    final period = hour >= 12 ? 'PM' : 'AM';
    final adjustedHour = hour % 12 == 0 ? 12 : hour % 12;

    return '${adjustedHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  factory TimeLogsModel.fromJson(Map<String, dynamic> json) => TimeLogsModel(
        date: json['date'],
        timeIn: formatTime(json['time_in']),
        breakOut: formatTime(json['break_out']),
        breakIn: formatTime(json['break_in']),
        timeOut: formatTime(json['time_out']),
      );

  Map<String, dynamic> toJson() => {
        'date': date,
        'time_in': timeIn,
        'break_out': breakOut,
        'break_in': breakIn,
        'time_out': timeOut,
      };
}
