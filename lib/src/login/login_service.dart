import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:get_storage/get_storage.dart';

class LoginService {
  final Dio dio = Dio();
  final box = GetStorage();

  Future<Map<String, dynamic>> loginAuthentication(
      {required Map<String, dynamic> data, required String apiUrl}) async {
    final response = await dio.post('$apiUrl/login',
        data: jsonEncode(data),
        options: Options(
          validateStatus: (status) => true,
          headers: {'Content-Type': 'application/json'},
        ));

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
}
