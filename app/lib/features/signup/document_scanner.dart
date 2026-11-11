import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'signup_models.dart';

/// 서류 사진을 촬영한다. 사용자가 취소하면 null.
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

/// 서류 사진에서 글자를 읽어 항목별 값으로 돌려준다(OCR).
/// 지금은 화주 주민등록증에만 쓴다. 사업자등록증은 차주·화주 모두 사진만 받는다.
abstract interface class DocumentScanner {
  Future<IdCard> scanIdCard(String imagePath);
}

/// 실제 인식 없이 고정된 샘플 값을 돌려주는 데모 구현.
class MockDocumentScanner implements DocumentScanner {
  const MockDocumentScanner();

  Future<void> _delay() =>
      Future<void>.delayed(const Duration(milliseconds: 400));

  @override
  Future<IdCard> scanIdCard(String imagePath) async {
    await _delay();
    return const IdCard(
      name: '박농부',
      residentNumber: '750315-1234568',
      address: '전북 김제시 죽산면 ○○로 1',
      issuedDate: '2019-05-20',
    );
  }
}

final photoCaptureProvider =
    Provider<PhotoCapture>((ref) => const CameraPhotoCapture());

final documentScannerProvider =
    Provider<DocumentScanner>((ref) => const MockDocumentScanner());
