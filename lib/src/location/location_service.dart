import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  // Request location permissions
  Future<bool> _requestPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  // Get the current location (can work offline via GPS)
  Future<Position?> _getCurrentLocation() async {
    // Check if location services are enabled.
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services are disabled.');
      return null;
    }

    if (await _requestPermission()) {
      try {
        return await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.bestForNavigation),
        );
      } catch (e) {
        debugPrint('Error getting location: $e');
        return null;
      }
    }
    return null;
  }

  // Get Plus Code from coordinates, with offline handling
  Future<String?> _getPlusCodeFromCoordinates(
      double latitude, double longitude, String apiKey) async {
    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=$apiKey';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'OK' &&
            data['plus_code'] != null &&
            data['plus_code']['compound_code'] != null) {
          return data['plus_code']['compound_code'];
        } else if (data['status'] == 'OK' &&
            data['results'] != null &&
            data['results'].isNotEmpty) {
          for (var result in data['results']) {
            if (result['plus_code'] != null &&
                result['plus_code']['compound_code'] != null) {
              return result['plus_code']['compound_code'];
            }
          }
        }
        return 'Could not find Plus Code';
      }
      return 'API Error (Status: ${response.statusCode})';
    } catch (e) {
      debugPrint('Could not contact Geocoding API for Plus Code: $e');
      return 'Offline - pending sync'; // Placeholder for offline mode
    }
  }

  // Get full address from coordinates, with offline handling
  Future<String?> _getAddressFromCoordinates(
      double latitude, double longitude, String apiKey) async {
    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=$apiKey';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'OK' &&
            data['results'] != null &&
            data['results'].isNotEmpty) {
          return data['results'][0]['formatted_address']; // Return full address
        } else {
          debugPrint('Geocoding API returned status: ${data['status']}');
          return 'Could not find address';
        }
      }
      return 'API Error (Status: ${response.statusCode})';
    } catch (e) {
      debugPrint('Could not contact Geocoding API for Address: $e');
      return 'Offline - pending sync'; // Placeholder for offline mode
    }
  }

  // Main method to get location and address
  Future<Map<String, dynamic>> getLocationAndAddress(
      {required String apiKey}) async {
    final position = await _getCurrentLocation();
    if (position != null) {
      final latitude = position.latitude;
      final longitude = position.longitude;
      
      // These calls will now handle being offline gracefully
      final plusCode =
          await _getPlusCodeFromCoordinates(latitude, longitude, apiKey);
      final addressComplete =
          await _getAddressFromCoordinates(latitude, longitude, apiKey);

      return {
        "latitude": latitude,
        "longitude": longitude,
        "plus_code": plusCode,
        "address_complete": addressComplete,
      };
    }
    return {};
  }
}