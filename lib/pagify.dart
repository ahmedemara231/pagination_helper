import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:lottie/lottie.dart';
import 'package:pagify/widgets/text.dart';
import 'generated/assets.dart';
import 'helpers/add_frame.dart';
import 'helpers/data_and_pagination_data.dart';
import 'helpers/errors.dart';
import 'helpers/message_utils.dart';
import 'helpers/scroll_controller.dart';
import 'helpers/status_stream.dart';
part 'helpers/controller.dart';


/// Defines the type of list ranking to use in [Pagify].
enum RankingType {
  /// Displays items in a [GridView].
  gridView,

  /// Displays items in a [ListView].
  listView
}


/// [Response] is the type of the API response.
/// [Model] is the type of each data item in the list.
class Pagify<Response, Model> extends StatefulWidget {
  /// Called whenever the async call status changes.
  final FutureOr<void> Function(PagifyAsyncCallStatus status)? onUpdateStatus;

  /// Whether the list should be displayed in reverse order.
  final bool isReverse;

  /// Whether to show a "No Data" alert when no data is available.
  final bool showNoDataAlert;

  /// Determines the layout type (grid or list).
  final RankingType rankingType;

  /// Background color of the refresh indicator.
  final Color? refreshIndicatorBackgroundColor;

  /// Color of the refresh indicator.
  final Color? refreshIndicatorColor;

  /// Maps network and HTTP errors to messages.
  final ErrorMapper errorMapper;

  /// Callback fired before an async call starts loading.
  final FutureOr<void> Function()? onLoading;

  /// Callback fired when data is successfully fetched.
  final FutureOr<void> Function(int currentPage, List<Model> data)? onSuccess;

  /// Callback fired when an error occurs while fetching data.
  final FutureOr<void> Function(int currentPage, String errorMessage)? onError;

  /// The asynchronous API call to fetch paginated data.
  final Future<Response> Function(int currentPage) asyncCall;

  /// Maps the API [Response] to a [PagifyData] object containing items and pagination info.
  final PagifyData<Model> Function(Response response) mapper;

  /// Builds each list/grid item widget.
  final Widget Function(List<Model> data, int index, Model element) itemBuilder;

  /// Custom loading widget to display while fetching data.
  final Widget? loadingBuilder;

  /// Custom widget to display when an error occurs.
  final Widget Function(String errorMsg)? errorBuilder;

  /// Controller for interacting with the pagination state.
  final PagifyController<Model> controller;

  /// Scroll direction for the list/grid.
  final Axis? scrollDirection;

  /// Whether the list/grid should shrink-wrap its contents.
  final bool? shrinkWrap;

  /// Spacing between rows in [GridView].
  final double? mainAxisSpacing;

  /// Spacing between columns in [GridView].
  final double? crossAxisSpacing;

  /// Aspect ratio for each child in [GridView].
  final double? childAspectRatio;

  /// Number of columns in [GridView].
  final int? crossAxisCount;

  /// Text to display when there is no internet connection.
  final String? noConnectionText;

  /// Text to display when the list is empty.
  final String? emptyListText;

  /// Creates a paginated widget with a [GridView] layout.
  Pagify.gridView({super.key,
    required this.controller,
    required this.asyncCall,
    required this.mapper,
    required this.errorMapper,
    required this.itemBuilder,
    this.onUpdateStatus,
    this.isReverse = false,
    this.onLoading,
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

  /// Creates a paginated widget with a [listView] layout.
  Pagify.listView({super.key,
    required this.controller,
    required this.asyncCall,
    required this.mapper,
    required this.errorMapper,
    required this.itemBuilder,
    this.onUpdateStatus,
    this.isReverse = false,
    this.onLoading,
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
  State<Pagify<Response, Model>> createState() => _PagifyState<Response, Model>();
}

class _PagifyState<Response, Model> extends State<Pagify<Response, Model>> {
  late RetainableScrollController _scrollController;
  late AsyncCallStatusInterceptor asyncCallState;
  late int _totalPages;
  int _currentPage = 1;
  StreamSubscription<PagifyAsyncCallStatus>? _statusSubscription;

  @override
  void initState() {
    super.initState();
    asyncCallState = AsyncCallStatusInterceptor.instance;
    _scrollController = RetainableScrollController();
    _scrollController.addListener(() => _onScroll());
    _listenToNetworkChanges();
    if(widget.onUpdateStatus != null){
      _statusSubscription = asyncCallState.listenStatusChanges.listen((event) => widget.onUpdateStatus!(event));
    }
    _fetchDataFirstTimeOrRefresh();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    asyncCallState.dispose();
    _connectivitySubscription.cancel();
    _statusSubscription?.cancel();
    super.dispose();
  }

  String _errorMsg = '';
  void _logError(Exception e){
    if(e is DioException){
      String prettyJson = const JsonEncoder.withIndent('  ').convert(e.response?.data);
      dev.log('error : $prettyJson');
    }else if(e is HttpException){
      String prettyJson = const JsonEncoder.withIndent('  ').convert(e.message);
      dev.log('error : $prettyJson');
    }
  }

  FutureOr<void> _errorHandler(Exception e){
    dev.log('enter error handler');
    _logError(e);
    widget.onError?.call(_currentPage, _errorMsg);

    if(e is PaginationNetworkError){
      asyncCallState.updateAllStatues(PagifyAsyncCallStatus.networkError);
    }else{
      asyncCallState.updateAllStatues(PagifyAsyncCallStatus.error);
      if(e is DioException){
        _errorMsg = widget.errorMapper.errorWhenDio?.call(e)?? '';

      }else if(e is HttpException){
        _errorMsg = widget.errorMapper.errorWhenHttp?.call(e)?? '';

      }else{
        _errorMsg = 'There is error occur $e';
      }
    }
  }


  // Future<void> _onScroll({bool isRefresh = false}) async{
  //   try {
  //     if(isRefresh){
  //       await _fetchDataFirstTimeOrRefresh();
  //     }else{
  //       await _startScrolling();
  //     }
  //   } on Exception catch(e){
  //     dev.log('_fetchDataFirstTimeOrRefresh error handling');
  //     _errorHandler(e);
  //   }
  // }


  Future<void> _onScroll() async{
    try {
      await _startScrolling();
    } on Exception catch(e){
      _errorHandler(e);
    }
  }

  Future<void> _startScrolling() async{
    switch(widget.isReverse){
      case true:
        if (_scrollController.position.pixels ==
            _scrollController.position.minScrollExtent &&
            !asyncCallState.currentState.isLoading &&
            _currentPage <= _totalPages){
          await _fetchDataWhenScrollUp();
        }
      default:
        if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
            !asyncCallState.currentState.isLoading &&
            _currentPage <= _totalPages) {
          await _fetchDataWhenScrollDown();
        }
    }
  }

  Future<void> _fetchDataWhenScrollUp() async{
    await _fetchDataWhileScrolling((items) =>
        widget.controller._updateItems(newItems: items, isReverse: true)
    );
  }

  Future<void> _fetchDataWhenScrollDown() async{
    await _fetchDataWhileScrolling((items) =>
        widget.controller._updateItems(newItems: items, isReverse: false)
    );
  }

  Future<void> _fetchDataWhileScrolling(void Function(List<Model> items) onUpdate)async{
    await _fetchDataAndMapping(
        whenEnd: (mapperResult) async{
          onUpdate(mapperResult.data);
          await widget.onSuccess?.call(_currentPage, _itemsList);
          _scrollController.restoreOffset(
              isReverse: widget.isReverse,
              subList: mapperResult.data,
              totalCurrentItems: _itemsList.length
          );
        }
    );
  }


  Future<void> _fetchDataAndMapping({
    FutureOr<void> Function()? whenStart,
    FutureOr<void> Function(PagifyData<Model> mapperResult)? whenEnd,
  })async{
    await whenStart?.call();
    asyncCallState.updateAllStatues(PagifyAsyncCallStatus.loading);
    await widget.onLoading?.call();
    _scrollController.retainOffset();
    final mapperResult = await _manageMapper();
    if(_currentPage <= mapperResult.paginationData.totalPages.toInt()){
      setState(() => _currentPage++);
      asyncCallState.updateAllStatues(PagifyAsyncCallStatus.success);
    }
    await whenEnd?.call(mapperResult);
  }

  Future<PagifyData<Model>> _manageMapper()async{
    final result = await _callApi(widget.asyncCall);
    final PagifyData<Model> mapperResult = widget.mapper(result);

    // should be called every time because the total pages may be changed
    _manageTotalPagesNumber(mapperResult.paginationData.totalPages);
    return mapperResult;
  }

  void _manageTotalPagesNumber(int totalPagesNumber) => _totalPages = totalPagesNumber;

  late final Connectivity _connectivity = Connectivity();

  Future<void> _checkAndMake({
    required List<ConnectivityResult> connectivityResult,
    required FutureOr<void> Function() onConnected,
    required FutureOr<void> Function() onDisconnected,
  })async{
    if(connectivityResult.contains(ConnectivityResult.none)){
      await onDisconnected.call();

    }else{
      await onConnected.call();
    }
  }

  Future<Response> _callApi(Future<Response> Function(int currentPage) asyncCall)async{
    late final Response waitingResult;
    final connectivityResult = await _connectivity.checkConnectivity();
    await _checkAndMake(
        connectivityResult: connectivityResult,
        onConnected: () async{
          final Response result = await asyncCall(_currentPage);
          waitingResult = result;
        },
        onDisconnected: () => throw PaginationNetworkError(widget.noConnectionText?? 'Check your internet connection')
    );

    return waitingResult;
  }

  bool isInitialized = false;
  late final StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  void _listenToNetworkChanges(){
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((networkStatus){
      if(isInitialized){
        _checkAndMake(
            connectivityResult: networkStatus,
            onConnected: () => setState(() => asyncCallState.setLastStatusAsCurrent(
                ifLastIsLoading: () async => await _fetchDataFirstTimeOrRefresh()
            )),
            onDisconnected: () => asyncCallState.updateAllStatues(PagifyAsyncCallStatus.networkError)
        );
      }
    });

    Future.delayed(const Duration(seconds: 1), () => isInitialized = true);
  }

  Future<void> _fetchDataFirstTimeOrRefresh() async {
    try {
      await _fetchDataAndMapping(
          whenStart: () {
            if(_currentPage > 1 && _itemsIsNotEmpty){
              _resetDataWhenRefresh();
            }
          },
          whenEnd: (mapperResult) async{
            widget.controller._updateItems(newItems: mapperResult.data);
            widget.controller._initScrollController(_scrollController);
            await widget.onSuccess?.call(_currentPage, _itemsList);
            if(widget.isReverse){
              Frame.addBefore(() => _scrollDownWhileGetDataFirstTimeWhenReverse());
            }
          }
      );
    } on Exception catch(e){
      _errorHandler(e);
    }
  }

  void _scrollDownWhileGetDataFirstTimeWhenReverse(){
    if(_itemsIsNotEmpty){
      _scrollController.jumpTo(
        _scrollController.position.maxScrollExtent,
      );
    }
  }

  void _resetDataWhenRefresh() {
    _currentPage = 1;
    _itemsList.clear();
  }

  Widget _listRanking(){
    if(widget.rankingType == RankingType.gridView){
      return _gridView();
    }
    return _listView();
  }

  bool get _hasMoreData => _currentPage <= _totalPages;
  bool get _shouldShowLoading => _hasMoreData && asyncCallState.currentState.isLoading;
  bool get _shouldShowNoData => widget.showNoDataAlert && !_hasMoreData;
  final Widget _noMoreDataText = const AppText('No more data', textAlign: TextAlign.center, color: Colors.grey);

  Widget _buildExtraItemSuchNoMoreDataOrLoading({Widget? defaultWidget}){
    if(_shouldShowNoData){
      return _noMoreDataText;

    }else if(_shouldShowLoading){
      return _loadingWidget;

    }else{
      return defaultWidget?? const SizedBox.shrink();
    }
  }

  Widget _buildItemBuilder({required int index, required List<Model> value}){
    if (index < value.length) {
      return widget.itemBuilder(value, index, value[index]);
    } else {
      return _buildExtraItemSuchNoMoreDataOrLoading();
    }
  }

  Widget _buildItemBuilderWhenReverse({required int index, required List<Model> value}) {
    if (index == 0 && (_shouldShowLoading || _shouldShowNoData)) {
      return _buildExtraItemSuchNoMoreDataOrLoading();
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
    return Align(
      alignment: widget.isReverse? Alignment.bottomCenter : Alignment.topCenter,
      child: ListView.builder(
          scrollDirection: widget.scrollDirection?? Axis.vertical,
          shrinkWrap: widget.shrinkWrap?? false,
          controller: _scrollController,
          itemCount: _buildItemCount(_itemsList),
          itemBuilder: (context, index) => widget.isReverse?
          _buildItemBuilderWhenReverse(index: index, value: _itemsList) :
          _buildItemBuilder(index: index, value: _itemsList)
      ),
    );
  }

  Widget _gridView() {
    return SingleChildScrollView(
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
              _itemsList.length,
                  (index) => widget.itemBuilder(_itemsList, index, _itemsList[index]),
            ),
          ),
          if(!widget.isReverse)
            _buildExtraItemSuchNoMoreDataOrLoading(),
        ],
      ),
    );
  }
  List<Model> get _itemsList => widget.controller._items.value;
  bool get _itemsIsNotEmpty => _itemsList.isNotEmpty;
  bool get _itemsIsEmpty => _itemsList.isEmpty;

  Widget get _buildLoadingView{
    if(_itemsIsEmpty){
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
            child: const CircularProgressIndicator.adaptive()
        )
        );
      default:
        return widget.loadingBuilder!;
    }
  }

  Widget get _buildErrorWidget{
    if(_itemsIsNotEmpty){
      if(asyncCallState.currentState.isNetworkError){
        MessageUtils. showSimpleToast(msg: widget.noConnectionText?? 'Check your internet connection', color: Colors.red);
      }else{
        MessageUtils.showSimpleToast(msg: _errorMsg, color: Colors.red);
      }
      return _listRanking();
    }else{
      if(asyncCallState.currentState.isNetworkError){
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
                  _errorMsg,
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500)
              )
            ],
          );
        default:
          return widget.errorBuilder!(_errorMsg);
      }
    }
  }

  Widget get _buildSuccessWidget{
    if(_itemsIsNotEmpty){
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

  // Future<void> _manageRefreshIndicator()async{
  //   if(widget.isReverse){
  //     if(currentPage < totalPages){
  //       Future(() => null);
  //     }else{
  //       await _onScroll(isRefresh: true);
  //     }
  //   }else{
  //     await _onScroll(isRefresh: true);
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PagifyAsyncCallStatus>(
        stream: asyncCallState.listenStatusChanges,
        builder: (context, snapshot) => SnapshotHandler(
          snapshot: snapshot,
          loadingWidget: _loadingWidget,
          activeStateCallBack: (snapshot) => snapshot.hasData?
          snapshot.data!.isError || snapshot.data!.isNetworkError?
          _buildErrorWidget : asyncCallState.currentState.isLoading?
          _buildLoadingView : _buildSuccessWidget : AppText('the stream throws an exception'),
        )
    );
  }
}


/// A widget that wraps a [StreamBuilder] to handle [PagifyAsyncCallStatus]
/// and render the appropriate UI state (loading, error, or success).
class SnapshotHandler extends StatelessWidget {

  /// Snapshot from the [StreamBuilder] containing pagination state.
  final AsyncSnapshot<PagifyAsyncCallStatus> snapshot;
  /// Widget to display while loading.
  final Widget loadingWidget;

  /// Callback to build the active UI state when the stream has data.
  final Widget Function(AsyncSnapshot<PagifyAsyncCallStatus> snapshot) activeStateCallBack;


  /// Creates a snapshot handler for managing async call UI states.
  const SnapshotHandler({super.key,
    required this.snapshot,
    required this.loadingWidget,
    required this.activeStateCallBack
  });

  Widget get _checkStreamStatesAndBuildView{
    switch(snapshot.connectionState){
      case ConnectionState.waiting:
        return loadingWidget;

      case ConnectionState.none:
        return AppText('no stream connection!');


      default:
        return activeStateCallBack.call(snapshot);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _checkStreamStatesAndBuildView;
  }
}