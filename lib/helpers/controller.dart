part of '../pagify.dart';

class PagifyController<E> {
  final ValueNotifier<List<E>> _items = ValueNotifier<List<E>>([]);

  final ValueNotifier<bool> _needToRefresh = ValueNotifier<bool>(false);


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

  void _notify(){
    final List<E> list = List.from(_items.value);
    _items.value = list;
    // items.notifyListeners();
  }

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
    _notify();
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
    _notify();
  }


  void sort(int Function(E a, E b) compare) {
    _items.value.sort(compare);
    _notify();
  }

  void _executeWholeRefresh(){
    _needToRefresh.value = !_needToRefresh.value;
  }

  void _checkAndNotify(bool Function() condition){
    if(condition.call()){
      _executeWholeRefresh();
    }else{
      _notify();
    }
  }

  void addItem(E item) {
    _items.value.add(item);
    _checkAndNotify(() => _items.value.length == 1);
  }

  void addItemAt(int index, E item) {
    _items.value.insert(index, item);
    _checkAndNotify(() => _items.value.length == 1);
  }

  void addAtBeginning(E item) {
    _items.value.insert(0, item);
    _checkAndNotify(() => _items.value.length == 1);
  }

  E? accessElement(int index) {
    return _items.value.elementAtOrNull(index);
  }

  void replaceWith(int oldItemIndex, E item) {
    _items.value[oldItemIndex] = item;
    _notify();
  }

  void removeItem(E item) {
    _items.value.remove(item);
    _checkAndNotify(() => _items.value.isEmpty);
  }

  void removeAt(int index){
    _items.value.removeAt(index);
    _checkAndNotify(() => _items.value.isEmpty);
  }

  void removeWhere(bool Function(E item) condition){
    _items.value.removeWhere(condition);
    _checkAndNotify(() => _items.value.isEmpty);
  }

  void clear() {
    _items.value.clear();
    _notify();
  }

  void dispose() {
    _items.dispose();
  }
}
