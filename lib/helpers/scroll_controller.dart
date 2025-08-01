import 'package:flutter/material.dart';

class RetainableScrollController extends ScrollController {
  RetainableScrollController({
    super.initialScrollOffset,
    super.keepScrollOffset,
    super.debugLabel,
  });

  double? _currentOffset;

  void retainOffset() { // before request
    if (hasClients) {
      _currentOffset = offset; // position.pixels
    }
  }


  void restoreOffset({
    required bool isReverse,
    required List subList,
    required int totalCurrentItems
  }) { // after request
    if (_currentOffset != null && hasClients) {
      jumpTo(
          isReverse?
          _getSubListHeight(subList, totalCurrentItems) :
          _currentOffset!
      );
    }
  }

  double _getSubListHeight(List subList, int totalCurrentItems) {
    if (!hasClients || totalCurrentItems == 0) {
      // Fallback to estimated height per item
      return subList.length * 60.0; // Adjust based on your item design
    }

    // Calculate average item height from current list
    double totalContentHeight = position.maxScrollExtent +
        position.viewportDimension;
    double averageItemHeight = totalContentHeight / totalCurrentItems;

    return subList.length * averageItemHeight;
  }
}
