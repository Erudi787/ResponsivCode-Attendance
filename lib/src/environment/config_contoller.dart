import 'package:cloudinary_flutter/cloudinary_context.dart';
import 'package:cloudinary_url_gen/cloudinary.dart';
import 'package:get/get.dart';
import 'config_service.dart';

class ConfigController extends GetxController {
  final ConfigService _configService;

  ConfigController(this._configService);
  // Observable variables
  var apiUrl = ''.obs;
  var debug = false.obs;

  var cloudName = ''.obs;
  var apiKey = ''.obs;
  var apiSecret = ''.obs;
  var cloudinaryUrl = ''.obs;

  var locatorPreset = ''.obs;
  var profilePreset = ''.obs;

  var defaultProfile = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadConfig();
  }

  void loadConfig() {
    apiUrl.value = _configService.apiUrl;
    debug.value = _configService.debug;

    cloudName.value = _configService.cloudName;
    apiKey.value = _configService.apiKey;
    apiSecret.value = _configService.apiSecret;
    cloudinaryUrl.value = _configService.cloudinaryUrl;

    locatorPreset.value = _configService.locatorPreset;
    profilePreset.value = _configService.profilePreset;

    defaultProfile.value = _configService.defaultProfile;
  }

  Future<void> loadCloundConfig() async {
    CloudinaryContext.cloudinary =
        Cloudinary.fromCloudName(cloudName: cloudName.value);
    update();
  }
}
