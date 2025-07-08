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
    // Register the FaceRecognitionService as a singleton. `fenix: true` ensures
    // that the service is re-initialized if it's ever accidentally removed.
    Get.lazyPut<FaceRecognitionService>(() => FaceRecognitionService(), fenix: true);

    // Register the FaceDataManager as a singleton.
    Get.lazyPut<FaceDataManager>(() => FaceDataManager(), fenix: true);

    // Register the FacialRecognitionController. It will be created when first used.
    Get.lazyPut<FacialRecognitionController>(() => FacialRecognitionController());
  }
}