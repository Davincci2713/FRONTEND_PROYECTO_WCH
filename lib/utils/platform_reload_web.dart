import 'dart:js_interop';
import 'package:flutter/foundation.dart';

extension type _Location._(JSObject _) implements JSObject {
  external void reload();
}

extension type _Window._(JSObject _) implements JSObject {
  external _Location get location;
}

@JS('window')
external _Window get _jsWindow;

void reloadPlatform(VoidCallback fallbackReload) {
  fallbackReload();
  _jsWindow.location.reload();
}
