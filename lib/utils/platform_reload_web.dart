import 'dart:html' as html;
import 'package:flutter/foundation.dart';

void reloadPlatform(VoidCallback fallbackReload) {
  fallbackReload();
  html.window.location.reload();
}

