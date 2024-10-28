import 'dart:convert';

OtLogsModel otLogsModelFromJson(String str) =>
    OtLogsModel.fromJson(json.decode(str));

String otLogsModelToJson(OtLogsModel data) => json.encode(data.toJson());

class OtLogsModel {
  final String? date;
  final String? otIn;
  final String? otOut;

  OtLogsModel({
    this.date,
    this.otIn,
    this.otOut,
  });

  static String formatTime(String? time) {
    if (time == null || time.isEmpty) return '';

    final parts = time.split(':');
    final int hour = int.parse(parts[0]);
    final int minute = int.parse(parts[1]);
    final int second = int.parse(parts[2]);

    final period = hour >= 12 ? 'PM' : 'AM';
    final adjustedHour = hour % 12 == 0 ? 12 : hour % 12;

    return '${adjustedHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:${second.toString().padLeft(2, '0')} $period';
  }

  factory OtLogsModel.fromJson(Map<String, dynamic> json) => OtLogsModel(
        date: json['date'],
        otIn: formatTime(json['ot_in']),
        otOut: formatTime(json['ot_out']),
      );

  Map<String, dynamic> toJson() => {
        'date': date,
        'ot_in': otIn,
        'ot_out': otOut,
      };
}
