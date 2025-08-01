import 'package:easy_pagination/helpers/scroll_controller.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'add_frame.dart';

class EasyPaginationController<E> {
  final ValueNotifier<List<E>> items = ValueNotifier<List<E>>([]);
  final ValueNotifier<bool> needToRefresh = ValueNotifier<bool>(false);

  RetainableScrollController? _scrollController;
  void initScrollController(RetainableScrollController controller){
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
    items.notifyListeners();
  }

  void updateItems({
    required List<E> newItems,
    bool isReverse = false
  }) {
    switch(isReverse){
      case true:
        items.value.insertAll(0, newItems);
        break;
      case false:
        items.value.addAll(newItems);
        break;
    }
    _notify();
  }

  E? getRandomItem() {
    if (items.value.isEmpty) return null;
    final random = math.Random();
    return items.value[random.nextInt(items.value.length)];
  }

  List<E> filter(bool Function(E item) condition) {
    return items.value.where(condition).toList();
  }

  void filterAndUpdate(bool Function(E item) condition) {
    items.value = List.from(filter(condition));
    _notify();
  }


  void sort(int Function(E a, E b) compare) {
    items.value.sort(compare);
    _notify();
  }

  void _executeWholeRefresh(){
    needToRefresh.value = !needToRefresh.value;
  }

  void _checkAndNotify(){
    if(items.value.length == 1){
      _executeWholeRefresh();
    }else{
      _notify();
    }
  }

  void addItem(E item) {
    items.value.add(item);
    _checkAndNotify();
  }

  void addItemAt(int index, E item) {
    items.value.insert(index, item);
    _checkAndNotify();
  }

  void addAtBeginning(E item) {
    items.value.insert(0, item);
    _checkAndNotify();
  }

  E? accessElement(int index) {
    return items.value.elementAtOrNull(index);
  }

  void replaceWith(int oldItemIndex, E item) {
    items.value[oldItemIndex] = item;
    _notify();
  }

  void refresh(){
    _notify();
  }

  void _checkAndNotifyAfterRemoving(){
    if(items.value.isEmpty){
      _executeWholeRefresh();
    }else{
      _notify();
    }
  }

  void removeItem(E item) {
    items.value.remove(item);
    _checkAndNotifyAfterRemoving();
  }

  void removeAt(int index){
    items.value.removeAt(index);
    _checkAndNotifyAfterRemoving();
  }

  void removeWhere(bool Function(E item) condition){
    items.value.removeWhere(condition);
    _checkAndNotifyAfterRemoving();
  }

  void clear() {
    items.value.clear();
    _notify();
  }

  void dispose() {
    items.dispose();
  }
}
