part of '../pagify.dart';

class PagifyController<E> {
  final ValueNotifier<List<E>> _items = ValueNotifier<List<E>>([]);

  RetainableScrollController? _scrollController;
  void _initScrollController(RetainableScrollController controller){
    _scrollController ??= controller;
  }

  Future<void> moveToMaxBottom({
    Duration? duration,
    Curve? curve
  })async{
    Frame.addBefore(() async => await _scrollController!.animateTo(
        _scrollController!.position.maxScrollExtent,
        duration: duration?? const Duration(milliseconds: 300),
        curve: curve?? Curves.easeOutQuad
    ));
  }

  Future<void> moveToMaxTop({
    Duration? duration,
    Curve? curve
  })async{
    Frame.addBefore(() async => await _scrollController!.animateTo(
        _scrollController!.position.minScrollExtent,
        duration: duration?? const Duration(milliseconds: 400),
        curve: curve?? Curves.easeOutQuad
    ));
  }

  void _makeActionOnDataChanging() => AsyncCallStatusInterceptor.instance.updateAllStatues(PagifyAsyncCallStatus.success);

  void _updateItems({
    required List<E> newItems,
    bool isReverse = false
  }) {
    switch(isReverse){
      case true:
        _items.value.insertAll(0, newItems);
        break;
      case false:
        _items.value.addAll(newItems);
        break;
    }
  }

  E? getRandomItem() {
    if (_items.value.isEmpty) return null;
    final random = math.Random();
    return _items.value[random.nextInt(_items.value.length)];
  }

  List<E> filter(bool Function(E item) condition) {
    return _items.value.where(condition).toList();
  }

  void filterAndUpdate(bool Function(E item) condition) {
    _items.value = List.from(filter(condition));
    _makeActionOnDataChanging();
  }


  void sort(int Function(E a, E b) compare) {
    _items.value.sort(compare);
    _makeActionOnDataChanging();
  }

  void addItem(E item) {
    _items.value.add(item);
    _makeActionOnDataChanging();
  }

  void addItemAt(int index, E item) {
    _items.value.insert(index, item);
    _makeActionOnDataChanging();
  }

  void addAtBeginning(E item) {
    _items.value.insert(0, item);
    _makeActionOnDataChanging();
  }

  E? accessElement(int index) {
    return _items.value.elementAtOrNull(index);
  }

  void replaceWith(int oldItemIndex, E item) {
    _items.value[oldItemIndex] = item;
    _makeActionOnDataChanging();
  }

  void removeItem(E item) {
    _items.value.remove(item);
    _makeActionOnDataChanging();
  }

  void removeAt(int index){
    _items.value.removeAt(index);
    _makeActionOnDataChanging();
  }

  void removeWhere(bool Function(E item) condition){
    _items.value.removeWhere(condition);
    _makeActionOnDataChanging();
  }

  void clear() {
    _items.value.clear();
    _makeActionOnDataChanging();
  }

  void dispose() {
    _items.dispose();
  }
}
