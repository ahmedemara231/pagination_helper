import 'package:flutter/material.dart';

/// pagify scroll controller
class RetainableScrollController extends ScrollController {
  /// pagify scroll controller construntor
  RetainableScrollController({
    super.initialScrollOffset,
    super.keepScrollOffset,
    super.debugLabel,
  });

  double? _currentOffset;

  /// retain scroll offset before request
  void retainOffset() {
    // before request
    if (hasClients) {
      _currentOffset = offset; // position.pixels
    }
  }

  /// restore scroll offset after request
  void restoreOffset(
      {required bool isReverse,
      required List subList,
      required int totalCurrentItems}) {
    // after request
    if (_currentOffset != null && hasClients) {
      jumpTo(isReverse
          ? _getSubListHeight(subList, totalCurrentItems)
          : _currentOffset!);
    }
  }

  double _getSubListHeight(List subList, int totalCurrentItems) {
    if (!hasClients || totalCurrentItems == 0) {
      // Fallback to estimated height per item
      return subList.length * 60.0; // Adjust based on your item design
    }

    // Calculate average item height from current list
    double totalContentHeight =
        position.maxScrollExtent + position.viewportDimension;
    double averageItemHeight = totalContentHeight / totalCurrentItems;

    return subList.length * averageItemHeight;
  }
}
