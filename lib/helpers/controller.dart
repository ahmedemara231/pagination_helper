part of '../pagify.dart';

/// A controller for managing the data and scroll state of a [Pagify] widget.
///
/// This class provides methods for manipulating the item list,
/// controlling the scroll position, and notifying the pagination system
/// when changes occur.
class PagifyController<E> {
  late _PagifyState? _pagifyState;
  void _init(_PagifyState state){
    _pagifyState = state;
  }

  /// remake the last request when its fail for example
  FutureOr<void> retry(){
    if(_pagifyState?._currentPage == 1){
      _pagifyState?._fetchDataFirstTimeOrRefresh();

    }else{
      _pagifyState?._onScroll();
    }
  }

  /// Internal list of items being displayed, wrapped in a [ValueNotifier]
  /// so that widgets can listen for changes.
  final ValueNotifier<List<E>> _items = ValueNotifier<List<E>>([]);

  /// The scroll controller used to retain and manipulate scroll position.
  RetainableScrollController? _scrollController;

  /// Initializes the internal scroll controller if it hasn't been set.
  void _initScrollController() {
    _scrollController ??= _pagifyState?._scrollController;
  }

  /// Smoothly scrolls to the bottom of the list/grid.
  ///
  /// [duration] controls the animation time.
  /// [curve] controls the animation curve.
  Future<void> moveToMaxBottom({
    Duration? duration,
    Curve? curve,
  }) async {
    Frame.addBefore(() async => await _scrollController!.animateTo(
          _scrollController!.position.maxScrollExtent,
          duration: duration ?? const Duration(milliseconds: 300),
          curve: curve ?? Curves.easeOutQuad,
        ));
  }

  /// Smoothly scrolls to the top of the list/grid.
  ///
  /// [duration] controls the animation time.
  /// [curve] controls the animation curve.
  Future<void> moveToMaxTop({
    Duration? duration,
    Curve? curve,
  }) async {
    Frame.addBefore(() async => await _scrollController!.animateTo(
          _scrollController!.position.minScrollExtent,
          duration: duration ?? const Duration(milliseconds: 400),
          curve: curve ?? Curves.easeOutQuad,
        ));
  }

  /// Marks the async call status as [PagifyAsyncCallStatus.success]
  /// after the data changes.
  void _makeActionOnDataChanging() =>
      _pagifyState?._asyncCallState.updateAllStatues(
        PagifyAsyncCallStatus.success,
      );

  /// Updates the internal item list with [newItems].
  ///
  /// If [isReverse] is true, the new items are inserted at the start;
  /// otherwise, they are appended to the end.
  void _updateItems({
    required List<E> newItems,
    bool isReverse = false,
  }) {
    switch (isReverse) {
      case true:
        _items.value.insertAll(0, newItems);
        break;
      case false:
        _items.value.addAll(newItems);
        break;
    }
  }

  /// Returns a random item from the list, or `null` if the list is empty.
  E? getRandomItem() {
    if (_items.value.isEmpty) return null;
    final random = math.Random();
    return _items.value[random.nextInt(_items.value.length)];
  }

  /// Returns a new list containing items that satisfy the [condition].
  List<E> filter(bool Function(E item) condition) {
    return _items.value.where(condition).toList();
  }

  /// Filters the list in-place based on the [condition] and updates listeners.
  void filterAndUpdate(bool Function(E item) condition) {
    _items.value = List.from(filter(condition));
    _makeActionOnDataChanging();
  }

  /// Sorts the list in-place based on the provided [compare] function.
  void sort(int Function(E a, E b) compare) {
    _items.value.sort(compare);
    _makeActionOnDataChanging();
  }

  /// Adds [item] to the end of the list.
  void addItem(E item) {
    _items.value.add(item);
    _makeActionOnDataChanging();
  }

  /// Inserts [item] at the specified [index] in the list.
  void addItemAt(int index, E item) {
    _items.value.insert(index, item);
    _makeActionOnDataChanging();
  }

  /// Inserts [item] at the beginning of the list.
  void addAtBeginning(E item) {
    _items.value.insert(0, item);
    _makeActionOnDataChanging();
  }

  /// Returns the element at the given [index], or `null` if out of range.
  E? accessElement(int index) {
    return _items.value.elementAtOrNull(index);
  }

  /// Replaces the element at [oldItemIndex] with [item].
  void replaceWith(int oldItemIndex, E item) {
    _items.value[oldItemIndex] = item;
    _makeActionOnDataChanging();
  }

  /// Removes [item] from the list.
  void removeItem(E item) {
    _items.value.remove(item);
    _makeActionOnDataChanging();
  }

  /// Removes the element at [index].
  void removeAt(int index) {
    _items.value.removeAt(index);
    _makeActionOnDataChanging();
  }

  /// Removes all elements that satisfy the [condition].
  void removeWhere(bool Function(E item) condition) {
    _items.value.removeWhere(condition);
    _makeActionOnDataChanging();
  }

  /// Clears all items from the list.
  void clear() {
    _items.value.clear();
    _makeActionOnDataChanging();
  }

  /// Disposes the controller and releases resources.
  void dispose() {
    _items.dispose();
  }
}
