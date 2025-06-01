// import 'dart:convert';
// import 'dart:developer' as dev;
// import 'dart:io';
// import 'dart:math' as math;
// import 'package:dio/dio.dart';
// import 'package:easy_pagination/widgets/pagination_helper_refresh_indicator.dart';
// import 'package:flutter/material.dart';
// import 'package:lottie/lottie.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import '../../../generated/assets.dart';
// import 'helpers/message_utils.dart';
//
// enum RankingType {gridView, listView}
// enum AsyncCallStatus {initial, loading, success, error, networkError}
//
// // T is full response which includes data list and pagination data
// // E is specific model is the list
// class EasyPagination<T, E> extends StatefulWidget {
//   final ScrollPhysics? scrollPhysics;
//   final bool showNoDataAlert;
//   final RankingType rankingType;
//   final Color? refreshIndicatorBackgroundColor;
//   final Color? refreshIndicatorColor;
//   final ErrorMapper errorMapper;
//   final Function(int currentPage, List<E> data)? onSuccess;
//   final Function(int currentPage, String errorMessage)? onError;
//   final Future<T> Function(int currentPage) asyncCall;
//   final DataListAndPaginationData<E> Function(T response) mapper;
//   final Widget Function(List<E> data, int index) itemBuilder;
//   final Widget? loadingBuilder;
//   final Widget Function(String errorMsg)? errorBuilder;
//   final EasyPaginationController<E> controller;
//   final double? mainAxisSpacing;
//   final double? crossAxisSpacing;
//   final double? childAspectRatio;
//   final Axis? scrollDirection;
//   final int? crossAxisCount;
//   final bool? shrinkWrap;
//
//   const EasyPagination.gridView({super.key,
//     required this.controller,
//     required this.asyncCall,
//     required this.mapper,
//     required this.errorMapper,
//     required this.itemBuilder,
//     this.onSuccess,
//     this.onError,
//     this.scrollPhysics,
//     this.showNoDataAlert = false,
//     this.refreshIndicatorBackgroundColor,
//     this.refreshIndicatorColor,
//     this.loadingBuilder,
//     this.errorBuilder,
//     this.shrinkWrap,
//     this.mainAxisSpacing,
//     this.crossAxisSpacing,
//     this.childAspectRatio,
//     this.scrollDirection,
//     this.crossAxisCount,
//   }) : rankingType = RankingType.gridView;
//
//   const EasyPagination.listView({super.key,
//     required this.controller,
//     required this.asyncCall,
//     required this.mapper,
//     required this.errorMapper,
//     required this.itemBuilder,
//     this.onSuccess,
//     this.onError,
//     this.scrollPhysics,
//     this.showNoDataAlert = false,
//     this.refreshIndicatorBackgroundColor,
//     this.refreshIndicatorColor,
//     this.loadingBuilder,
//     this.errorBuilder,
//     this.shrinkWrap,
//     this.scrollDirection,
//   }) : rankingType = RankingType.listView,
//         crossAxisCount = null,
//         childAspectRatio = null,
//         crossAxisSpacing = null,
//         mainAxisSpacing = null;
//
//   @override
//   State<EasyPagination<T, E>> createState() => _EasyPaginationState<T, E>();
// }
//
// class _EasyPaginationState<T, E> extends State<EasyPagination<T, E>> {
//   late RetainableScrollController scrollController;
//   AsyncCallStatus status = AsyncCallStatus.initial;
//   int currentPage = 1;
//   late int totalPages;
//
//   @override
//   void initState() {
//     super.initState();
//     scrollController = RetainableScrollController();
//     scrollController.addListener(_onScroll);
//     _fetchData();
//   }
//
//   @override
//   void dispose() {
//     scrollController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _onScroll() async{
//     if (scrollController.position.pixels ==
//         scrollController.position.maxScrollExtent &&
//         status != AsyncCallStatus.loading &&
//         currentPage <= totalPages) {
//       await _fetchData();
//     }
//   }
//
//   String errorMsg = '';
//   void _logError(Exception e){
//     if(e is DioException){
//       String prettyJson = const JsonEncoder.withIndent('  ').convert(e.response?.data);
//       dev.log('error : $prettyJson');
//     }else if(e is HttpException){
//       String prettyJson = const JsonEncoder.withIndent('  ').convert(e.message);
//       dev.log('error : $prettyJson');
//     }
//   }
//
//   Future<void> _fetchData({bool isRefresh = false}) async {
//     setState(() => status = AsyncCallStatus.loading);
//     if(isRefresh){
//       resetDataWhenRefresh();
//     }
//     scrollController.retainOffset();
//     try {
//       final mapperResult = await _manageMapper();
//       if(currentPage <= mapperResult.paginationData.totalPages!.toInt()){
//         setState(() {
//           currentPage++;
//           status = AsyncCallStatus.success;
//         });
//       }
//       widget.controller.updateItems(mapperResult.data);
//       if(widget.onSuccess != null){
//         widget.onSuccess!(currentPage, widget.controller._items.value);
//       }
//
//       scrollController.restoreOffset();
//     } on PaginationNetworkError{
//       setState(() => status = AsyncCallStatus.networkError);
//     }on Exception catch(e){
//       if(e is DioException){
//         errorMsg = widget.errorMapper.errorWhenDio!(e);
//       }else if(e is HttpException){
//         errorMsg = widget.errorMapper.errorWhenHttp!(e);
//       }else{
//         errorMsg = 'There is error occur $e';
//       }
//
//       _logError(e);
//       if(widget.onError != null){
//         widget.onError!(currentPage, errorMsg);
//       }
//       setState(() => status = AsyncCallStatus.error);
//     }
//   }
//
//   void resetDataWhenRefresh() {
//     currentPage = 1;
//     widget.controller._items.value.clear();
//   }
//
//   Future<DataListAndPaginationData<E>> _manageMapper()async{
//     final result = await _callApi(widget.asyncCall);
//     final DataListAndPaginationData<E> mapperResult = widget.mapper(result);
//
//     _manageTotalPagesNumber(mapperResult.paginationData.totalPages?? 0); // should be put in init state
//     return mapperResult;
//   }
//
//   Future<T> _callApi(Future<T> Function(int currentPage) asyncCall)async{
//     final connectivityResult = await Connectivity().checkConnectivity();
//     switch(connectivityResult){
//       case ConnectivityResult.none:
//         throw PaginationNetworkError('Check your internet connection');
//       default:
//         final T result = await asyncCall(currentPage);
//         return result;
//     }
//   }
//
//
//   void _manageTotalPagesNumber(int totalPagesNumber) => totalPages = totalPagesNumber;
//
//
//   Widget _listRanking(){
//     if(widget.rankingType == RankingType.gridView){
//       return _gridView();
//     }
//     return _listView();
//   }
//
//   Widget _listView() {
//     return ValueListenableBuilder(
//       valueListenable: widget.controller._items,
//       builder: (context, value, child) => ListView.builder(
//         physics: widget.scrollPhysics?? const AlwaysScrollableScrollPhysics(),
//         scrollDirection: widget.scrollDirection?? Axis.vertical,
//         shrinkWrap: widget.shrinkWrap?? false,
//         controller: scrollController,
//         itemCount: widget.showNoDataAlert? value.length + 1 :
//         status == AsyncCallStatus.loading? value.length + 1 : value.length,
//         itemBuilder: (context, index) {
//           if (index < value.length) {
//             return widget.itemBuilder(value, index);
//           } else {
//             if(widget.showNoDataAlert){
//               return currentPage > totalPages?
//               const Text('No more data', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)) :
//               _loadingWidget;
//             }else{
//               return _loadingWidget;
//             }
//           }
//         },
//       ),
//     );
//   }
//
//   Widget _gridView() {
//     return ValueListenableBuilder(
//       valueListenable: widget.controller._items,
//       builder: (context, value, child) => GridView.count(
//         physics: widget.scrollPhysics?? const AlwaysScrollableScrollPhysics(),
//         shrinkWrap: widget.shrinkWrap?? false,
//         crossAxisCount: widget.crossAxisCount?? 2,
//         mainAxisSpacing: widget.mainAxisSpacing?? 0.0,
//         crossAxisSpacing: widget.crossAxisSpacing?? 0.0,
//         childAspectRatio: widget.childAspectRatio?? 0.0,
//         scrollDirection: widget.scrollDirection?? Axis.vertical,
//         controller: scrollController,
//         children: List.generate(
//           value.length + 1, (index) {
//           if (index < value.length) {
//             return widget.itemBuilder(value, index);
//           } else {
//             if(widget.showNoDataAlert){
//               return currentPage > totalPages?
//               const Text('No more data', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)) :
//               _loadingWidget;
//             }else{
//               return _loadingWidget;
//             }
//           }},
//         ),
//       ),
//     );
//   }
//
//   Widget get _buildLoadingView{
//     if(widget.controller._items.value.isEmpty){
//       return _loadingWidget;
//     }else{
//       return _listRanking();
//     }
//   }
//
//   Widget get _loadingWidget{
//     switch(widget.loadingBuilder){
//       case null:
//         return const Center(child: CircularProgressIndicator());
//       default:
//         return widget.loadingBuilder!;
//     }
//   }
//
//   Widget get _buildErrorWidget{
//     if(widget.controller._items.value.isNotEmpty){
//       if(status == AsyncCallStatus.networkError){
//         MessageUtils.showSimpleToast(msg: 'Check your internet connection', color: Colors.red);
//       }else{
//         MessageUtils.showSimpleToast(msg: errorMsg, color: Colors.red);
//       }
//       return _listRanking();
//     }else{
//       if(status == AsyncCallStatus.networkError){
//         return Column(
//           children: [
//             Lottie.asset(Assets.lottieNoInternet),
//             const SizedBox(height: 10),
//             const Text(
//                 'Check your internet connection',
//                 style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500)
//             )
//           ],
//         );
//       }
//       switch(widget.errorBuilder){
//         case null:
//           return Column(
//             children: [
//               Lottie.asset(Assets.lottieApiError),
//               const SizedBox(height: 10),
//               Text(
//                   errorMsg,
//                   style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500)
//               )
//             ],
//           );
//         default:
//           return widget.errorBuilder!(errorMsg);
//       }
//     }
//   }
//
//
//   Widget get _buildSuccessWidget{
//     dev.log('the list is ${widget.controller._items.value.length}');
//     if(widget.controller._items.value.isNotEmpty){
//       return _listRanking();
//     }else{
//       dev.log('the list is ${widget.controller._items.value.length}');
//       return Column(
//         children: [
//           Lottie.asset(Assets.lottieNoData),
//           const SizedBox(height: 10),
//           const Text('There is no data right now!')
//         ],
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return PaginationHelperRefreshIndicator(
//       onRefresh: () async => await _fetchData(isRefresh: true),
//       refreshIndicatorBackgroundColor: widget.refreshIndicatorBackgroundColor,
//       refreshIndicatorColor: widget.refreshIndicatorColor,
//       child: ValueListenableBuilder(
//         valueListenable: widget.controller._needToRefresh,
//         builder: (context, value, child) =>
//         status == AsyncCallStatus.error || status == AsyncCallStatus.networkError?
//         _buildErrorWidget : status == AsyncCallStatus.loading?
//         _buildLoadingView : _buildSuccessWidget,
//       ),
//     );
//   }
// }
//
// class ErrorMapper{
//   String Function(DioException e)? errorWhenDio;
//   String Function(HttpException e)? errorWhenHttp;
//
//   ErrorMapper({this.errorWhenDio, this.errorWhenHttp});
// }
//
// class RetainableScrollController extends ScrollController {
//   RetainableScrollController({
//     super.initialScrollOffset,
//     super.keepScrollOffset,
//     super.debugLabel,
//   });
//
//   double? _initialOffset;
//
//   void retainOffset() {
//     if (hasClients) {
//       _initialOffset = offset;
//     }
//   }
//
//   void restoreOffset() {
//     if (_initialOffset != null && hasClients) {
//       jumpTo(_initialOffset!);
//     }
//   }
// }
//
// class DataListAndPaginationData<E>{
//   List<E> data;
//   PaginationData paginationData;
//
//   DataListAndPaginationData({
//     required this.data,
//     required this.paginationData,
//   });
// }
//
// class PaginationData{
//   // final int? totalItems;
//   // final int? countItems;
//   // final int? perPage;
//   // final int? currentPage;
//   // final String? nextPageUrl;
//   final int? totalPages;
//
//   PaginationData({
//     // this.totalItems,
//     // this.countItems,
//     // this.perPage,
//     // this.currentPage,
//     // this.nextPageUrl,
//     this.totalPages,
//   });
// }
//
// class EasyPaginationError implements Exception{
//   final String msg;
//   EasyPaginationError(this.msg);
// }
//
// class PaginationNetworkError extends EasyPaginationError{
//   PaginationNetworkError(super.msg);
// }
//
// class EasyPaginationController<E> {
//   // Make items a ValueNotifier
//   final ValueNotifier<List<E>> _items = ValueNotifier<List<E>>([]);
//   final ValueNotifier<bool> _needToRefresh = ValueNotifier<bool>(false);
//
//   void _notify(){
//     _items.notifyListeners();
//   }
//
//   void updateItems(List<E> newItems) {
//     _items.value.addAll(newItems);
//     _notify();
//   }
//
//   E? getRandomItem() {
//     if (_items.value.isEmpty) return null;
//     final random = math.Random();
//     return _items.value[random.nextInt(_items.value.length)];
//   }
//
//   List<E> filter(bool Function(E item) condition) {
//     return _items.value.where(condition).toList();
//   }
//
//   void filterAndUpdate(bool Function(E item) condition) {
//     _items.value = List.from(filter(condition));
//     _notify();
//   }
//
//
//   void sort(int Function(E a, E b) compare) {
//     _items.value.sort(compare);
//     _notify();
//   }
//
//   void _executeWholeRefresh(){
//     _needToRefresh.value = !_needToRefresh.value;
//   }
//
//   void _checkAndNotify(){
//     if(_items.value.length == 1){
//       _executeWholeRefresh();
//     }else{
//       _notify();
//     }
//   }
//
//   void addItem(E item) {
//     _items.value.add(item);
//     _checkAndNotify();
//   }
//
//   void addItemAt(int index, E item) {
//     _items.value.insert(index, item);
//     _checkAndNotify();
//   }
//
//   void addAtBeginning(E item) {
//     _items.value.insert(0, item);
//     _checkAndNotify();
//   }
//
//   E? accessElement(int index) {
//     return _items.value.elementAtOrNull(index);
//   }
//
//   void replaceWith(int oldItemIndex, E item) {
//     _items.value[oldItemIndex] = item;
//     _notify();
//   }
//
//   void refresh(){
//     _notify();
//   }
//
//   void _checkAndNotifyAfterRemoving(){
//     if(_items.value.isEmpty){
//       _executeWholeRefresh();
//     }else{
//       _notify();
//     }
//   }
//
//   void removeItem(E item) {
//     _items.value.remove(item);
//     _checkAndNotifyAfterRemoving();
//   }
//
//   void removeAt(int index){
//     _items.value.removeAt(index);
//     _checkAndNotifyAfterRemoving();
//   }
//
//   void removeWhere(bool Function(E item) condition){
//     _items.value.removeWhere(condition);
//     _checkAndNotifyAfterRemoving();
//   }
//
//   void clear() {
//     _items.value.clear();
//     _notify();
//   }
//
//   void dispose() {
//     _items.dispose();
//   }
// }