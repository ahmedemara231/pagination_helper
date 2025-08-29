part of '../pagify.dart';


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
  void restoreOffset({
    required bool isReverse,
    required List subList,
    required int totalCurrentItems,
    double? itemExtent
  }) {
    // after request
    if (_currentOffset != null && hasClients) {
      jumpTo(
          isReverse ?
          _getSubListHeight(
            subList: subList,
            totalCurrentItems: totalCurrentItems,
            itemExtent: itemExtent
          ) :
          _currentOffset!
      );
    }
  }

  double _getSubListHeight({
    required List subList,
    required int totalCurrentItems,
    double? itemExtent
  }) {
    if(itemExtent.isNotNull){
      return subList.length * itemExtent!;
    }else{
        // Calculate average item height from current list
        double totalContentHeight = position.maxScrollExtent + position.viewportDimension;
        double averageItemHeight = totalContentHeight / totalCurrentItems;

        return subList.length * averageItemHeight;
    }
  }

  // double _getSubListHeight(List subList, int totalCurrentItems) {
  //   // if (!hasClients || totalCurrentItems == 0) {
  //   //   return subList.length * 60.0;
  //   // }
  //
  //   // Calculate average item height from current list
  //   double totalContentHeight = position.maxScrollExtent + position.viewportDimension;
  //   double averageItemHeight = totalContentHeight / totalCurrentItems;
  //
  //   return subList.length * _pagifyState.widget.itemExtent!;
  // }
}
