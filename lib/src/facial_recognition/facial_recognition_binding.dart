import 'package:get/get.dart';
import 'package:rts_locator/src/facial_recognition/face_data_manager.dart';
import 'package:rts_locator/src/facial_recognition/facial_recognition_controller.dart';
import 'package:rts_locator/src/facial_recognition/facial_recognition_service.dart';

/// A GetX binding class that sets up the dependencies for the facial recognition feature.
///
/// By using a binding, we can ensure that the necessary services and controllers
/// are initialized and available whenever they are needed, without polluting the global scope.
class FacialRecognitionBinding extends Bindings {
  @override
  void dependencies() {
    // Use Get.put with permanent for immediate registration
    Get.put<FaceRecognitionService>(
      FaceRecognitionService(), 
      permanent: true
    );

    Get.put<FaceDataManager>(
      FaceDataManager(), 
      permanent: true
    );

    // Use lazyPut with fenix for the controller
    Get.lazyPut<FacialRecognitionController>(
      () => FacialRecognitionController(),
      fenix: true // This ensures it's recreated if disposed
    );
  }
}