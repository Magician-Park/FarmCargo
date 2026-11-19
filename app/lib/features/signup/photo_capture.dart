import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// 서류 사진을 촬영한다. 사용자가 취소하면 null.
/// 웹은 브라우저의 파일·카메라 선택 창, 앱은 기기 카메라를 쓴다.
abstract interface class PhotoCapture {
  Future<String?> capture();
}

class CameraPhotoCapture implements PhotoCapture {
  const CameraPhotoCapture();

  @override
  Future<String?> capture() async {
    final file = await ImagePicker()
        .pickImage(source: ImageSource.camera, imageQuality: 85);
    return file?.path;
  }
}

final photoCaptureProvider =
    Provider<PhotoCapture>((ref) => const CameraPhotoCapture());
