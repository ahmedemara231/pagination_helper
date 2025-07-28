import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:easy_pagination/helpers/add_frame.dart';
import 'package:easy_pagination/widgets/text.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../generated/assets.dart';
import 'helpers/message_utils.dart';

enum RankingType {gridView, listView}
enum AsyncCallStatus {
  initial,
  loading,
  success,
  error,
  networkError,
}

extension AsyncCallStatusExtension on AsyncCallStatus {
  bool get isLoading => this == AsyncCallStatus.loading;
  bool get isError => this == AsyncCallStatus.error;
  bool get isNetworkError => this == AsyncCallStatus.networkError;
  bool get isSuccess => this == AsyncCallStatus.success;
}

class AsyncCallStatusInterceptor{
  AsyncCallStatus _status;
  AsyncCallStatusInterceptor(this._status);

  final StreamController<AsyncCallStatus> _controller = StreamController<AsyncCallStatus>();
  void updateStatus(AsyncCallStatus status){
    _status = status;
    _controller.add(status);
  }

  Stream<AsyncCallStatus> get stream => _controller.stream;
  Stream<AsyncCallStatus> get listenStatusChanges{
    return stream;
  }

  void dispose(){
    _controller.close();
  }
}

// Response is full response which includes data list and pagination data
// Model is specific model is the list
class EasyPagination<Response, Model> extends StatefulWidget {
  final FutureOr<void> Function(AsyncCallStatus)? onUpdateStatus;
  final bool isReverse;
  final bool showNoDataAlert;
  final RankingType rankingType;
  final Color? refreshIndicatorBackgroundColor;
  final Color? refreshIndicatorColor;
  final ErrorMapper errorMapper;
  final Function(int currentPage, List<Model> data)? onSuccess;
  final Function(int currentPage, String errorMessage)? onError;
  final Future<Response> Function(int currentPage) asyncCall;
  final DataListAndPaginationData<Model> Function(Response response) mapper;
  final Widget Function(List<Model> data, int index, Model element) itemBuilder;
  final Widget? loadingBuilder;
  final Widget Function(String errorMsg)? errorBuilder;
  final EasyPaginationController<Model> controller;
  final Axis? scrollDirection;
  final bool? shrinkWrap;
  final double? mainAxisSpacing;
  final double? crossAxisSpacing;
  final double? childAspectRatio;
  final int? crossAxisCount;
  final String? noConnectionText;
  final String? emptyListText;

  EasyPagination.gridView({super.key,
    required this.controller,
    required this.asyncCall,
    required this.mapper,
    required this.errorMapper,
    required this.itemBuilder,
    this.onUpdateStatus,
    this.isReverse = false,
    this.onSuccess,
    this.onError,
    this.showNoDataAlert = false,
    this.refreshIndicatorBackgroundColor,
    this.refreshIndicatorColor,
    this.loadingBuilder,
    this.errorBuilder,
    this.mainAxisSpacing,
    this.crossAxisSpacing,
    this.childAspectRatio = 1,
    this.scrollDirection,
    this.crossAxisCount,
    this.emptyListText,
    this.noConnectionText
  }) : rankingType = RankingType.gridView, shrinkWrap = true,
        assert(errorMapper.errorWhenHttp != null || errorMapper.errorWhenDio != null);

  EasyPagination.listView({super.key,
    required this.controller,
    required this.asyncCall,
    required this.mapper,
    required this.errorMapper,
    required this.itemBuilder,
    this.onUpdateStatus,
    this.isReverse = false,
    this.onSuccess,
    this.onError,
    this.showNoDataAlert = false,
    this.refreshIndicatorBackgroundColor,
    this.refreshIndicatorColor,
    this.loadingBuilder,
    this.errorBuilder,
    this.shrinkWrap,
    this.scrollDirection,
    this.emptyListText,
    this.noConnectionText
  }) : rankingType = RankingType.listView,
        crossAxisCount = null,
        childAspectRatio = null,
        crossAxisSpacing = null,
        mainAxisSpacing = null,
        assert(errorMapper.errorWhenHttp != null || errorMapper.errorWhenDio != null);


  @override
  State<EasyPagination<Response, Model>> createState() => _EasyPaginationState<Response, Model>();
}

class _EasyPaginationState<Response, Model> extends State<EasyPagination<Response, Model>> {
  late RetainableScrollController _scrollController;
  AsyncCallStatusInterceptor status = AsyncCallStatusInterceptor(AsyncCallStatus.initial);
  // AsyncCallStatus status = AsyncCallStatus.initial;
  int currentPage = 1;
  late int totalPages;

  @override
  void initState() {
    super.initState();
    _scrollController = RetainableScrollController();
    _scrollController.addListener(() => _onScroll());
    if(widget.onUpdateStatus != null){
      status.listenStatusChanges.listen((event) => widget.onUpdateStatus!(event));
    }
    _fetchDataFirstTimeOrRefresh();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    status.dispose();
    super.dispose();
  }

  Future<void> _startScrolling() async{
    switch(widget.isReverse){
      case true:
        if (_scrollController.position.pixels ==
            _scrollController.position.minScrollExtent &&
            !status._status.isLoading &&
            currentPage <= totalPages){
          _fetchDataWhenScrollUp();
        }
      default:
        if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
            !status._status.isLoading &&
            currentPage <= totalPages) {
          await _fetchDataWhenScrollDown();
        }
    }
  }

  Future<void> _onScroll({bool isRefresh = false}) async{
    try {
      if(isRefresh){
        await _fetchDataFirstTimeOrRefresh();
      }else{
        await _startScrolling();
      }
    } on PaginationNetworkError{
      setState(() => status.updateStatus(AsyncCallStatus.networkError));
    }on Exception catch(e){
      if(e is DioException){
        errorMsg = widget.errorMapper.errorWhenDio!(e);
      }else if(e is HttpException){
        errorMsg = widget.errorMapper.errorWhenHttp!(e);
      }else{
        errorMsg = 'There is error occur $e';
      }

      _logError(e);
      if(widget.onError != null){
        widget.onError!(currentPage, errorMsg);
      }
      setState(() => status.updateStatus(AsyncCallStatus.error));
    }
  }

  Future<void> _fetchData(void Function(List<Model> items) onUpdate)async{
    setState(() => status.updateStatus(AsyncCallStatus.loading));
    _scrollController.retainOffset();
    final mapperResult = await _manageMapper();
    if(currentPage <= mapperResult.paginationData.totalPages.toInt()){
      setState(() {
        currentPage++;
        status.updateStatus(AsyncCallStatus.success);
      });
    }
    onUpdate(mapperResult.data);
    if(widget.onSuccess != null){
      widget.onSuccess!(currentPage, widget.controller._items.value);
    }
    _scrollController.restoreOffset(
        isReverse: widget.isReverse,
        subList: mapperResult.data,
        totalCurrentItems: widget.controller._items.value.length
    );
  }

  Future<void> _fetchDataWhenScrollUp() async{
    await _fetchData((items) =>
        widget.controller.updateItems(newItems: items, isReverse: true)
    );
  }

  Future<void> _fetchDataWhenScrollDown() async{
    await _fetchData((items) =>
        widget.controller.updateItems(newItems: items, isReverse: false)
    );
  }

  String errorMsg = '';
  void _logError(Exception e){
    if(e is DioException){
      String prettyJson = const JsonEncoder.withIndent('  ').convert(e.response?.data);
      dev.log('error : $prettyJson');
    }else if(e is HttpException){
      String prettyJson = const JsonEncoder.withIndent('  ').convert(e.message);
      dev.log('error : $prettyJson');
    }
  }

  void _scrollDownWhileGetDataFirstTimeWhenReverse(){
    _scrollController.jumpTo(
      _scrollController.position.maxScrollExtent,
    );
  }

  Future<void> _fetchDataFirstTimeOrRefresh() async {
    if(currentPage > 1 && widget.controller._items.value.isNotEmpty){
      _resetDataWhenRefresh();
    }
    setState(() => status.updateStatus(AsyncCallStatus.loading));
    _scrollController.retainOffset();
    try {
      final mapperResult = await _manageMapper();
      if(currentPage <= mapperResult.paginationData.totalPages.toInt()){
        setState(() {
          currentPage++;
          status.updateStatus(AsyncCallStatus.success);
        });
      }
      widget.controller.updateItems(newItems: mapperResult.data);
      widget.controller._initScrollController(_scrollController);
      if(widget.onSuccess != null){
        widget.onSuccess!(currentPage, widget.controller._items.value);
      }
      if(widget.isReverse){
        Frame.addBefore(() => _scrollDownWhileGetDataFirstTimeWhenReverse());
      }
    } on PaginationNetworkError{
      setState(() => status.updateStatus(AsyncCallStatus.networkError));
    }on Exception catch(e){
      if(e is DioException){
        errorMsg = widget.errorMapper.errorWhenDio!(e);
      }else if(e is HttpException){
        errorMsg = widget.errorMapper.errorWhenHttp!(e);
      }else{
        errorMsg = 'There is error occur $e';
      }

      _logError(e);
      if(widget.onError != null){
        widget.onError!(currentPage, errorMsg);
      }
      setState(() => status.updateStatus(AsyncCallStatus.error));
    }
  }

  void _resetDataWhenRefresh() {
    currentPage = 1;
    widget.controller._items.value.clear();
  }

  Future<DataListAndPaginationData<Model>> _manageMapper()async{
    final result = await _callApi(widget.asyncCall);
    final DataListAndPaginationData<Model> mapperResult = widget.mapper(result);

    // should be called every time because the total pages may be changed
    _manageTotalPagesNumber(mapperResult.paginationData.totalPages);
    return mapperResult;
  }

  Future<Response> _callApi(Future<Response> Function(int currentPage) asyncCall)async{
    final connectivityResult = await Connectivity().checkConnectivity();
    switch(connectivityResult){
      case ConnectivityResult.none:
        throw PaginationNetworkError(widget.noConnectionText?? 'Check your internet connection');
      default:
        final Response result = await asyncCall(currentPage);
        return result;
    }
  }

  void _manageTotalPagesNumber(int totalPagesNumber) => totalPages = totalPagesNumber;

  Widget _listRanking(){
    if(widget.rankingType == RankingType.gridView){
      return _gridView();
    }
    return _listView();
  }


  bool get _hasMoreData => currentPage <= totalPages;
  bool get _shouldShowLoading => _hasMoreData && status._status.isLoading;
  bool get _shouldShowNoData => widget.showNoDataAlert && !_hasMoreData;

  Widget get _noMoreDataTextWidget => const AppText('No more data', textAlign: TextAlign.center, color: Colors.grey);
  Widget _buildExtraItemSuchNoMoreDataOrLoading({Widget defaultWidget = const SizedBox.shrink()}) {
    if(_shouldShowNoData){
      return _noMoreDataTextWidget;
    }else if(_shouldShowLoading){
      return _loadingWidget;
    }else{
      return defaultWidget;
    }
  }

  Widget _buildItemBuilder({required int index, required List<Model> value}){
    if (index < value.length) {
      return widget.itemBuilder(value, index, value[index]);
    } else {
      return _buildExtraItemSuchNoMoreDataOrLoading(defaultWidget: widget.itemBuilder(value, index, value[index]));
    }
  }

  Widget _buildItemBuilderWhenReverse({required int index, required List<Model> value}) {
    if (index == 0 && (_shouldShowLoading || _shouldShowNoData)) {
      _buildExtraItemSuchNoMoreDataOrLoading();
    }

    int dataIndex = (_shouldShowLoading || _shouldShowNoData) ? index - 1 : index;
    return widget.itemBuilder(value, dataIndex, value[dataIndex]);
  }

  int _buildItemCount(List<Model> value){
    if((_shouldShowNoData) || (_shouldShowLoading)){
      return value.length + 1;
    }else{
      return value.length;
    }
  }

  Widget _listView() {
    return ValueListenableBuilder(
      valueListenable: widget.controller._items,
      builder: (context, value, child) => Align(
        alignment: widget.isReverse? Alignment.bottomCenter : Alignment.topCenter,
        child: ListView.builder(
            scrollDirection: widget.scrollDirection?? Axis.vertical,
            shrinkWrap: widget.shrinkWrap?? false,
            controller: _scrollController,
            itemCount: _buildItemCount(value),
            itemBuilder: (context, index) => widget.isReverse?
            _buildItemBuilderWhenReverse(index: index, value: value) :
            _buildItemBuilder(index: index, value: value)
        ),
      ),
    );
  }

  Widget _gridView() {
    return ValueListenableBuilder(
      valueListenable: widget.controller._items,
      builder: (context, value, child) => SingleChildScrollView(
        reverse: true,
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: widget.isReverse?
          MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if(widget.isReverse)
              _buildExtraItemSuchNoMoreDataOrLoading(),
            GridView.count(
              shrinkWrap: widget.shrinkWrap!,
              crossAxisCount: widget.crossAxisCount?? 2,
              mainAxisSpacing: widget.mainAxisSpacing?? 0.0,
              crossAxisSpacing: widget.crossAxisSpacing?? 0.0,
              childAspectRatio: widget.childAspectRatio?? 1,
              scrollDirection: widget.scrollDirection?? Axis.vertical,
              physics: const NeverScrollableScrollPhysics(),
              children: List.generate(
                value.length,
                    (index) => widget.itemBuilder(value, index, value[index]),
              ),
            ),
            if(!widget.isReverse)
              _buildExtraItemSuchNoMoreDataOrLoading(),
          ],
        ),
      ),
    );
  }

  // Widget _gridView() {
  //   return ValueListenableBuilder(
  //     valueListenable: widget.controller._items,
  //     builder: (context, value, child) => Align(
  //       alignment: widget.isReverse? Alignment.bottomCenter : Alignment.topCenter,
  //       child: GridView.count(
  //         shrinkWrap: widget.shrinkWrap?? false,
  //         crossAxisCount: widget.crossAxisCount?? 2,
  //         mainAxisSpacing: widget.mainAxisSpacing?? 0.0,
  //         crossAxisSpacing: widget.crossAxisSpacing?? 0.0,
  //         childAspectRatio: widget.childAspectRatio?? 1,
  //         scrollDirection: widget.scrollDirection?? Axis.vertical,
  //         controller: scrollController,
  //         children: List.generate(
  //           _buildItemCount(value), (index) => widget.isReverse?
  //         _buildItemBuilderWhenReverse(index: index, value: value) :
  //         _buildItemBuilder(index: index, value: value),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget get _buildLoadingView{
    if(widget.controller._items.value.isEmpty){
      return _loadingWidget;
    }else{
      return _listRanking();
    }
  }

  Widget get _loadingWidget{
    switch(widget.loadingBuilder){
      case null:
        return Center(child: SizedBox.square(
            dimension: 30,
            child: const CircularProgressIndicator())
        );
      default:
        return widget.loadingBuilder!;
    }
  }

  Widget get _buildErrorWidget{
    if(widget.controller._items.value.isNotEmpty){
      if(status._status.isNetworkError){
        MessageUtils.showSimpleToast(msg: widget.noConnectionText?? 'Check your internet connection', color: Colors.red);
      }else{
        MessageUtils.showSimpleToast(msg: errorMsg, color: Colors.red);
      }
      return _listRanking();
    }else{
      if(status._status.isNetworkError){
        return Column(
          children: [
            Lottie.asset(Assets.lottieNoInternet),
            const SizedBox(height: 10),
            Text(
                widget.noConnectionText?? 'Check your internet connection',
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500)
            )
          ],
        );
      }
      switch(widget.errorBuilder){
        case null:
          return Column(
            children: [
              Lottie.asset(Assets.lottieApiError),
              const SizedBox(height: 10),
              Text(
                  errorMsg,
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500)
              )
            ],
          );
        default:
          return widget.errorBuilder!(errorMsg);
      }
    }
  }


  Widget get _buildSuccessWidget{
    if(widget.controller._items.value.isNotEmpty){
      return _listRanking();
    }else{
      return Column(
        children: [
          Lottie.asset(Assets.lottieNoData),
          const SizedBox(height: 10),
          Text(widget.emptyListText?? 'There is no data right now!')
        ],
      );
    }
  }

  Future<void> _manageRefreshIndicator()async{
    if(widget.isReverse){
      if(currentPage < totalPages){
        Future(() => null);
      }else{
        await _onScroll(isRefresh: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PaginationHelperRefreshIndicator(
      onRefresh: _manageRefreshIndicator,
      child: ValueListenableBuilder(
        valueListenable: widget.controller._needToRefresh,
        builder: (context, value, child) =>
        status._status.isError || status._status.isNetworkError?
        _buildErrorWidget : status._status.isLoading?
        _buildLoadingView : _buildSuccessWidget,
      ),
    );
  }
}

class ErrorMapper{
  String Function(DioException e)? errorWhenDio;
  String Function(HttpException e)? errorWhenHttp;

  ErrorMapper({this.errorWhenDio, this.errorWhenHttp});
}

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

class DataListAndPaginationData<E>{
  List<E> data;
  PaginationData paginationData;

  DataListAndPaginationData({
    required this.data,
    required this.paginationData,
  });
}

class PaginationData{
  final int perPage;
  final int totalPages;
  // final String? nextPageUrl;

  PaginationData({
    required this.perPage,
    required this.totalPages,
    // this.nextPageUrl,
  });
}

class EasyPaginationError implements Exception{
  final String msg;
  EasyPaginationError(this.msg);
}

class PaginationNetworkError extends EasyPaginationError{
  PaginationNetworkError(super.msg);
}

class EasyPaginationController<E> {
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
    _items.notifyListeners();
  }

  void updateItems({
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

  void _checkAndNotify(){
    if(_items.value.length == 1){
      _executeWholeRefresh();
    }else{
      _notify();
    }
  }

  void addItem(E item) {
    _items.value.add(item);
    _checkAndNotify();
  }

  void addItemAt(int index, E item) {
    _items.value.insert(index, item);
    _checkAndNotify();
  }

  void addAtBeginning(E item) {
    _items.value.insert(0, item);
    _checkAndNotify();
  }

  E? accessElement(int index) {
    return _items.value.elementAtOrNull(index);
  }

  void replaceWith(int oldItemIndex, E item) {
    _items.value[oldItemIndex] = item;
    _notify();
  }

  void refresh(){
    _notify();
  }

  void _checkAndNotifyAfterRemoving(){
    if(_items.value.isEmpty){
      _executeWholeRefresh();
    }else{
      _notify();
    }
  }

  void removeItem(E item) {
    _items.value.remove(item);
    _checkAndNotifyAfterRemoving();
  }

  void removeAt(int index){
    _items.value.removeAt(index);
    _checkAndNotifyAfterRemoving();
  }

  void removeWhere(bool Function(E item) condition){
    _items.value.removeWhere(condition);
    _checkAndNotifyAfterRemoving();
  }

  void clear() {
    _items.value.clear();
    _notify();
  }

  void dispose() {
    _items.dispose();
  }
}


class PaginationHelperRefreshIndicator extends StatelessWidget {

  final Future<void> Function() onRefresh;
  final Widget child;
  final Color? refreshIndicatorBackgroundColor;
  final Color? refreshIndicatorColor;
  const PaginationHelperRefreshIndicator({super.key,
    required this.onRefresh,
    this.refreshIndicatorBackgroundColor,
    this.refreshIndicatorColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator.adaptive(
        backgroundColor: refreshIndicatorBackgroundColor,
        color: refreshIndicatorColor,
        triggerMode: RefreshIndicatorTriggerMode.anywhere,
        onRefresh: onRefresh,
        child: child
    );
  }
}