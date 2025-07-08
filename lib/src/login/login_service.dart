import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class LoginService {
  final Dio dio = Dio();
  final box = GetStorage();

  Future<Map<String, dynamic>> loginAuthentication(
      {required Map<String, dynamic> data, required String apiUrl}) async {
    try {
      final response = await dio.post('$apiUrl/login',
        data: jsonEncode(data),
        options: Options(
          validateStatus: (status) => true,
          headers: {'Content-Type': 'application/json'},
        ));

    dynamic responseData;

    if (response.data is Map) {
      responseData = response.data;
    } else if (response.data is String && response.data.trim().startsWith('{')) {
      responseData = jsonDecode(response.data);
    } else {
      debugPrint('Server returned an invalid response (likely an HTML error page).');
      debugPrint('Response body: ${response.data}');
      return {
        "flag": false,
        "message": "Server error. Check backend logs on Render."
      };
    }

    if (response.statusCode == 200) {
      box.write('token', response.data['token']);
      box.write('user_id', response.data['user']);
      box.write('fullname', response.data['fullname']);
      return {
        "flag": response.data['flag'],
        "message": response.data['message']
      };
    }

    return {"flag": response.data['flag'], "message": response.data['message']};
    }
    catch (e) {
      debugPrint('An error occurred during login authentication: $e');
      return {
        "flag": false,
        "message": "An unexpected error occurred. Please try again."
      };
    }
  }
}
