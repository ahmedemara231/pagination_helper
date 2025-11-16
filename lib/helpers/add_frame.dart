part of '../pagify.dart';

/// flutter frame helper
class _Frame {
  /// add flutter frame before build
  static void addBefore(FutureOr Function() function) {
    WidgetsBinding.instance.addPostFrameCallback(
      (timeStamp) async => await function(),
    );
  }
}
