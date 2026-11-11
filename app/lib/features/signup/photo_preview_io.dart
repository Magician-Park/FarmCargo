import 'dart:io';

import 'package:flutter/widgets.dart';

/// Android·iOS: image_picker가 돌려준 기기 파일 경로를 읽는다.
Widget photoImage(String path, {required ImageErrorWidgetBuilder errorBuilder}) =>
    Image.file(File(path), fit: BoxFit.cover, errorBuilder: errorBuilder);
