import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;
import 'package:rts_locator/src/environment/config_contoller.dart';
import 'package:rts_locator/src/environment/config_service.dart';
import 'package:rts_locator/src/location/location_controller.dart';
import 'package:rts_locator/src/location/location_service.dart';

class HomeService {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  final Dio dio = Dio();
  final box = GetStorage();

  final LocationController locationController =
      Get.put(LocationController(LocationService()));
  final ConfigController configController =
      Get.put(ConfigController(ConfigService()));

  // Initialize the camera
  Future<void> initializeCamera() async {
    _cameras = await availableCameras();
    await _initCameraController(_cameras[_selectedCameraIndex]);
  }

  // Initialize the camera controller with the selected camera
  Future<void> _initCameraController(
      CameraDescription cameraDescription) async {
    _cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.high,
    );

    await _cameraController!.initialize();
  }

  // Switch between cameras
  Future<void> switchCamera() async {
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _initCameraController(_cameras[_selectedCameraIndex]);
  }

  Future<void> autoSwitchCamera({required int selectedIndex}) async {
    if (selectedIndex == 0) {
      await _initCameraController(_cameras[_selectedCameraIndex]);
    } else {
      _selectedCameraIndex = 1;
      await _initCameraController(_cameras[_selectedCameraIndex]);
    }
  }

  // Capture an image and save it to the device
  Future<File?> captureImage({required String note}) async {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      // Capture the image
      final XFile? picture = await _cameraController!.takePicture();

      if (picture != null) {
        // Get the directory to save the image
        final Directory directory = await getApplicationDocumentsDirectory();
        final String path =
            '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';

        // Load the captured image
        final File file = File(picture.path);
        final Uint8List imageBytes = await file.readAsBytes();

        // Add watermark
        final Uint8List watermarkedBytes =
            _addWatermark(imageBytes: imageBytes, note: note);

        // Save the watermarked image
        final File newFile = File(path);
        await newFile.writeAsBytes(watermarkedBytes);

        // Optionally, add the image to the gallery
        await ImageGallerySaver.saveFile(newFile.path);

        // Return the path of the saved image
        return newFile;
      }
    }
    return null;
  }

  // Add watermark to the image
  Uint8List _addWatermark(
      {required Uint8List imageBytes, required String note}) {
    // Load the image
    final image = img.decodeImage(imageBytes);

    if (image == null) {
      throw Exception('Failed to decode image');
    }

    // Add watermark
    final watermarkText =
        'Latitude: ${locationController.latitude.value}\nLongitude: ${locationController.longitude.value}\nAddress: ${locationController.plusCode.value}\nNote: $note';
    final watermarkColor = img.ColorRgb8(64, 224, 208);

    final watermark = img.drawString(
      image,
      font: img.arial24,
      x: 10,
      y: 10,
      watermarkText,
      wrap: true,
      color: watermarkColor,
    );

    // Encode the image with the watermark
    return img.encodeJpg(watermark);
  }

  Future<String> uploadToCloud({required File imageFile}) async {
    final cloudinaryResponse = http.MultipartRequest(
        'POST', Uri.parse(configController.cloudinaryUrl.value))
      ..fields['upload_preset'] = configController.locatorPreset.value
      ..fields['api_key'] = configController.apiKey.value
      ..fields['timestamp'] = DateTime.now().millisecondsSinceEpoch.toString()
      ..files.add(
        await http.MultipartFile.fromPath('file', imageFile.path,
            filename: 'uploaded_image'),
      );

    var cloudinaryResponseBody = await cloudinaryResponse.send();
    var cloudinaryRequest =
        await http.Response.fromStream(cloudinaryResponseBody);

    var cloudinaryResult = jsonDecode(cloudinaryRequest.body);

    var uploadedUrl = cloudinaryResult['secure_url'];

    return uploadedUrl;
  }

  Future<void> uploadToDatabase({required Map<String, dynamic> data}) async {
    data['id'] = box.read('user_id');
    data['long_lat'] =
        '${locationController.latitude.value}, ${locationController.longitude.value}';
    data['address'] = locationController.plusCode.value;
    data['picture_type'] = _selectedCameraIndex == 0
        ? "back"
        : data['attendance_type'] != "documentary"
            ? "selfie"
            : "documentary selfie";

    final response =
        await dio.post('${configController.apiUrl.value}/attendance',
            data: jsonEncode(data),
            options: Options(
              validateStatus: (status) => true,
              headers: {'Content-Type': 'application/json'},
            ));

    if (response.statusCode == 200) {
      Fluttertoast.showToast(
        msg: response.data,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 5,
        backgroundColor: Colors.black,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } else {
      Fluttertoast.showToast(
        msg: response.data,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 5,
        backgroundColor: Colors.black,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  // Dispose the camera
  void disposeCamera() {
    _cameraController?.dispose();
  }

  CameraController? get cameraController => _cameraController;
  int? get selectedCameraIndex => _selectedCameraIndex;
}
