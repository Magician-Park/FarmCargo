import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// 쌓인 화면이 있으면 뒤로 가고, 없으면(딥링크 등) [fallback]으로 이동한다.
void popOrGo(BuildContext context, String fallback) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(fallback);
  }
}
