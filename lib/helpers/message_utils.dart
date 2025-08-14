import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

/// Helper class to show toast messages.
class MessageUtils {

  /// Shows a simple toast message.
  static void showSimpleToast({
    required String msg,
    Color? color,
    Color? textColor,
  }) {
    Fluttertoast.showToast(
      msg: msg,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: color ?? Colors.grey,
      textColor: textColor ?? Colors.white,
      fontSize: 16,
    );
  }
}
