// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

void reloadPlatform(VoidCallback fallbackReload) {
  html.window.location.reload();
}
