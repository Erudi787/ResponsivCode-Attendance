import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class FluttertoastService {
  Future<void> flutterToastSuccess({required String message}) async {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      timeInSecForIosWeb: 2,
      backgroundColor: Colors.black,
      textColor: const Color(0xFFF9A620),
      fontSize: 16.0,
    );
  }

  Future<void> flutterToastError({required String message}) async {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      timeInSecForIosWeb: 2,
      backgroundColor: Colors.black,
      textColor: const Color(0xFFCC0F2B),
      fontSize: 16.0,
    );
  }
}
