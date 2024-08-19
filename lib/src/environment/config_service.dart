import 'package:flutter_dotenv/flutter_dotenv.dart';

class ConfigService {
  // API Configuration
  String apiUrl = dotenv.env['API_URL'] ?? '';
  bool debug = dotenv.env['DEBUG'] == 'true';

  //Google Map Configuration
  String googleMapApiKey = dotenv.env['GOOGLE_MAP_KEY'] ?? '';

  // Cloudinary Configuration
  String cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  String apiKey = dotenv.env['CLOUDINARY_API_KEY'] ?? '';
  String apiSecret = dotenv.env['CLOUDINARY_API_SECRET'] ?? '';
  String cloudinaryUrl = dotenv.env['CLOUDINARY_URL'] ?? '';

  // Cloudinary Upload Presets
  String locatorPreset = dotenv.env['CLOUDINARY_LOCATOR_UPLOAD_PRESET'] ?? '';
  String profilePreset = dotenv.env['CLOUDINARY_PROFILE_UPLOAD_PRESET'] ?? '';

  // Default Values
  String defaultProfile = dotenv.env['DEFAULT_PROFILE'] ?? '';
}
