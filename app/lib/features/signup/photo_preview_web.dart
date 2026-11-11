import 'package:flutter/widgets.dart';

/// 웹: image_picker가 돌려준 브라우저 임시 주소(blob:)를 읽는다.
Widget photoImage(String path, {required ImageErrorWidgetBuilder errorBuilder}) =>
    Image.network(path, fit: BoxFit.cover, errorBuilder: errorBuilder);
