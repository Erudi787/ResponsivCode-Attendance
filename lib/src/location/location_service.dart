import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  // Request location permissions
  Future<bool> _requestPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  // Get the current location
  Future<Position?> _getCurrentLocation() async {
    // if (await _requestPermission()) {
    // try {
    return await Geolocator.getCurrentPosition(
      locationSettings:
          const LocationSettings(accuracy: LocationAccuracy.bestForNavigation),
    );
    // } catch (e) {
    // print('Error getting location: $e');
    // return null;
    // }
    // }
    // return null;
  }

  // Get address from coordinates
  Future<String?> _getPlusCodeFromCoordinates(
      double latitude, double longitude, String apiKey) async {
    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['status'] == 'OK' && data['results'] != null) {
        return data['results'][0]['plus_code']['compound_code'] ??
            data['results'][0]['plus_code'];
      } else {
        return 'Failed to fetch plus_code';
      }
    }
    return null;
  }

  Future<String?> _getAddressFromCoordinates(
      double latitude, double longitude, String apiKey) async {
    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['status'] == 'OK' && data['results'] != null) {
        print('Address: ${data['results'][0]}');
        for (var result in data['results']) {
          if (result['plus_code'] != null && result['plus_code']['compound_code'] != null) {
            return result['plus_code']['compound_code'];
          }
        }
        return 'Failed to fetch plus_code';
      } else {
        return 'Failed to fetch address';
      }
    }
    return null;
  }

  // Get location and address
  Future<Map<String, dynamic>> getLocationAndAddress(
      {required String apiKey}) async {
    final position = await _getCurrentLocation();
    if (position != null) {
      final latitude = position.latitude;
      final longitude = position.longitude;
      final plusCode =
          await _getPlusCodeFromCoordinates(latitude, longitude, apiKey);
      final address_complete =
          await _getAddressFromCoordinates(latitude, longitude, apiKey);

      return {
        "latitude": latitude,
        "longitude": longitude,
        "plus_code": plusCode,
        "address_complete": address_complete,
      };
    }
    return {};
  }
}
