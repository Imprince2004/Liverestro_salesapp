import 'package:image_picker/image_picker.dart';
import 'logging/app_logger.dart';

/// Camera and Gallery photo capture helper.
class ImagePickerHelper {
  final ImagePicker _picker;

  ImagePickerHelper([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  Future<XFile?> pickFromCamera() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );
    } catch (e, stack) {
      AppLogger.e('Error capturing image from camera: $e', e, stack);
      return null;
    }
  }

  Future<XFile?> pickFromGallery() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );
    } catch (e, stack) {
      AppLogger.e('Error picking image from gallery: $e', e, stack);
      return null;
    }
  }
}
