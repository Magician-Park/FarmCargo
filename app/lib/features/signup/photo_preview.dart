import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import 'photo_preview_io.dart'
    if (dart.library.js_interop) 'photo_preview_web.dart' as platform;

/// 촬영한 사진 경로로 미리보기 위젯을 만든다.
/// 웹은 브라우저가 준 임시 주소(blob)를, 앱은 기기 파일 경로를 읽는다.
typedef PhotoPreviewBuilder = Widget Function(String path);

Widget _fallback(BuildContext context, Object error, StackTrace? stack) =>
    const ColoredBox(
      color: AppColors.surfaceMuted,
      child: Center(child: Icon(Icons.image_outlined, color: Colors.grey)),
    );

final photoPreviewProvider = Provider<PhotoPreviewBuilder>((ref) =>
    (path) => platform.photoImage(path, errorBuilder: _fallback));
