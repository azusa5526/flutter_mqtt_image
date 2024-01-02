import 'dart:developer';
import 'package:flutter/material.dart' show debugPrint;

void log(Object? val) {
  var now = DateTime.now().toString();
  var perfix = '[log $now](${val.runtimeType}):';
  if (val == null) {
    debugPrint('$perfix null');
    return;
  }
  if (val is num) {
    debugPrint('$perfix ${val.toString()}');
    return;
  }
  if (val is String) {
    debugPrint('$perfix $val');
    return;
  }
  inspect(val);
}
