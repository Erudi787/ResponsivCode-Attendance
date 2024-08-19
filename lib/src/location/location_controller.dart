import 'package:get/get.dart';
import 'package:rts_locator/src/environment/config_contoller.dart';
import 'package:rts_locator/src/environment/config_service.dart';
import 'package:rts_locator/src/location/location_service.dart';

class LocationController extends GetxController {
  final LocationService _locationService;
  final ConfigController _configController =
      Get.put(ConfigController(ConfigService()));

  LocationController(this._locationService);

  var latitude = Rxn<double>();
  var longitude = Rxn<double>();
  var plusCode = ''.obs;
  var isLoading = false.obs;

  Future fetchLocation() async {
    isLoading.value = true;
    final result = await _locationService.getLocationAndAddress(
        apiKey: _configController.googleMapApiKey.toString());

    latitude.value = result['latitude'];
    longitude.value = result['longitude'];
    plusCode.value = result['plus_code'];

    isLoading.value = false;
    update();
  }
}
