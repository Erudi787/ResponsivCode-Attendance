import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  // Request location permissions
  Future<bool> _requestPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  // Get the current location
  Future<Position?> _getCurrentLocation() async {
    if (await _requestPermission()) {
      try {
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      } catch (e) {
        print('Error getting location: $e');
        return null;
      }
    }
    return null;
  }

  // Get address from coordinates
  Future<String?> _getAddressFromCoordinates(
      double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);
      Placemark place = placemarks.first;
      return '${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}';
    } catch (e) {
      print('Error getting address: $e');
      return null;
    }
  }

  // Get location and address
  Future<Map<String, dynamic>> getLocationAndAddress() async {
    final position = await _getCurrentLocation();
    if (position != null) {
      final latitude = position.latitude;
      final longitude = position.longitude;
      final address = await _getAddressFromCoordinates(latitude, longitude);

      print('Latitude: $latitude');
      print('Longitude: $longitude');
      print('Address: $address');

      return {"latitude": latitude, "longitude": longitude, "address": address};
    }
    return {};
  }
}
