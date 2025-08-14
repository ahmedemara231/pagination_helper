import 'dart:async';
import 'package:flutter/material.dart';

/// flutter frame helper
class Frame {
  /// add flutter frame before build
  static void addBefore(FutureOr Function() function) {
    WidgetsBinding.instance.addPostFrameCallback(
      (timeStamp) async => await function(),
    );
  }
}
