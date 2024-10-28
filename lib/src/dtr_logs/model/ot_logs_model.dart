import 'dart:convert';

import 'package:intl/intl.dart';

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

    final period = hour >= 12 ? 'PM' : 'AM';
    final adjustedHour = hour % 12 == 0 ? 12 : hour % 12;

    return '${adjustedHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  static String formatDate(String? date) {
    if (date == null || date.isEmpty) return '';

    try {
      final DateTime parsedDate = DateTime.parse(date);
      final DateFormat formatter = DateFormat('MMM dd, yyyy');
      return formatter.format(parsedDate); // e.g., "April 05, 2023"
    } catch (e) {
      return date; // Return the original string if parsing fails
    }
  }

  factory OtLogsModel.fromJson(Map<String, dynamic> json) => OtLogsModel(
        date: formatDate(json['date']),
        otIn: formatTime(json['ot_in']),
        otOut: formatTime(json['ot_out']),
      );

  Map<String, dynamic> toJson() => {
        'date': date,
        'ot_in': otIn,
        'ot_out': otOut,
      };
}
