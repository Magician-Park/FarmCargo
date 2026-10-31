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
abstract interface class DocumentScanner {
  Future<FreightLicense> scanFreightLicense(String imagePath);
  Future<IdCard> scanIdCard(String imagePath);
  Future<BusinessRegistration> scanBusinessRegistration(
    String imagePath, {
    required bool includeTaxOffice,
  });
}

/// 실제 인식 없이 고정된 샘플 값을 돌려주는 데모 구현.
class MockDocumentScanner implements DocumentScanner {
  const MockDocumentScanner();

  Future<void> _delay() =>
      Future<void>.delayed(const Duration(milliseconds: 400));

  @override
  Future<FreightLicense> scanFreightLicense(String imagePath) async {
    await _delay();
    return const FreightLicense(
      name: '김기사',
      birthDate: '1975-03-15',
      licenseNumber: '11-1234567-01',
      acquiredDate: '2015-06-01',
    );
  }

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

  @override
  Future<BusinessRegistration> scanBusinessRegistration(
    String imagePath, {
    required bool includeTaxOffice,
  }) async {
    await _delay();
    return BusinessRegistration(
      registrationNumber: '123-45-67891',
      companyName: includeTaxOffice ? '김기사 운송' : '○○농장',
      representativeName: includeTaxOffice ? '김기사' : '박농부',
      birthDate: '1975-03-15',
      openedDate: '2016-03-02',
      address: '서울특별시 강서구 ○○로 123',
      businessType: includeTaxOffice ? '운수업 / 화물자동차 운송업' : '농업 / 곡물 재배업',
      issueReason: '신규',
      coRepresentative: '',
      isConsolidatedTax: false,
      taxInvoiceEmail: 'tax@example.com',
      issuedDate: '2024-01-10',
      taxOffice: includeTaxOffice ? '강서세무서' : '',
    );
  }
}

final photoCaptureProvider =
    Provider<PhotoCapture>((ref) => const CameraPhotoCapture());

final documentScannerProvider =
    Provider<DocumentScanner>((ref) => const MockDocumentScanner());
