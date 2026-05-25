import 'dart:js_interop';
import 'package:flutter/foundation.dart';

@JS('window.location.reload')
external void _windowLocationReload();

void reloadPlatform(VoidCallback fallbackReload) {
  fallbackReload();
  _windowLocationReload();
}
