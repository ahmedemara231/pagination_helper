import 'dart:async';
import 'package:flutter/material.dart';

class Frame {
  static void addBefore(FutureOr Function() function) {
    WidgetsBinding.instance.addPostFrameCallback(
          (timeStamp) async => await function(),
    );
  }
}