import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:get/get.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:rts_locator/src/location/location_controller.dart';
import 'package:rts_locator/src/location/location_service.dart';

class HomeService {
  CameraController? _cameraController;
  final LocationController locationController =
      Get.put(LocationController(LocationService()));

  // Initialize the camera
  Future<void> initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    _cameraController = CameraController(
      firstCamera,
      ResolutionPreset.high,
    );

    await _cameraController!.initialize();
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
        'Latitude: ${locationController.latitude}\nLongitude: ${locationController.longitude}\nAddress: ${locationController.address}\nNote: $note';
    final watermarkColor = img.ColorRgb8(255, 255, 255);

    final watermark = img.drawString(
      image,
      font: img.arial48,
      x: 10,
      y: 10,
      watermarkText,
      wrap: true,
      color: watermarkColor,
    );

    // Encode the image with the watermark
    return img.encodeJpg(watermark);
  }

  // Dispose the camera
  void disposeCamera() {
    _cameraController?.dispose();
  }

  CameraController? get cameraController => _cameraController;
}
