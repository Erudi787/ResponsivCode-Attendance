import 'package:get/get.dart';
import 'package:rts_locator/src/location/location_service.dart';

class LocationController extends GetxController {
  final LocationService _locationService;

  LocationController(this._locationService);

  var latitude = Rxn<double>();
  var longitude = Rxn<double>();
  var address = ''.obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchLocation();
  }

  Future fetchLocation() async {
    isLoading.value = true;
    final result = await _locationService.getLocationAndAddress();

    latitude.value = result['latitude'];
    longitude.value = result['longitude'];
    address.value = result['address'];

    isLoading.value = false;
  }
}
