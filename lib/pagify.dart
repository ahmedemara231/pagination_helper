import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:lottie/lottie.dart';
import 'package:pagify/helpers/extensions/null_extension.dart';
import 'package:pagify/helpers/extensions/zero_extension.dart';
import 'package:pagify/widgets/text.dart';
import 'generated/assets.dart';
import 'helpers/add_frame.dart';
import 'helpers/custom_bool.dart';
import 'helpers/data_and_pagination_data.dart';
import 'helpers/errors.dart';
import 'helpers/status_stream.dart';
part 'helpers/controller.dart';
part 'helpers/ranking.dart';
part 'helpers/scroll_controller.dart';


/// [FullResponse] is the type of the API response.
/// [Model] is the type of each data item in the list.
class Pagify<FullResponse, Model> extends StatefulWidget {
  /// [padding] property in list and grid view
  final EdgeInsetsGeometry padding;

  /// [itemExtent] property in list and grid view
  final double? itemExtent;

  /// [cacheExtent] property in list and grid view
  final double? cacheExtent;

  /// Called whenever the async call status changes.
  final FutureOr<void> Function(PagifyAsyncCallStatus status)? onUpdateStatus;

  /// Whether the list should be displayed in reverse order.
  final bool isReverse;

  /// Whether to show a "No Data" alert when no data is available.
  final bool showNoDataAlert;

  /// Determines the layout type (grid or list).
  final _RankingType _rankingType;

  /// Maps network and HTTP errors to messages.
  final PagifyErrorMapper errorMapper;

  /// Callback to handle scroll position changes.
  final void Function(ScrollPosition position)? onScrollPositionChanged;

  /// listen to network connectivity changes
  final bool listenToNetworkConnectivityChanges;

  /// make action when connectivity changed
  final FutureOr<void> Function(bool isConnected)? onConnectivityChanged;

  /// Callback fired before an async call starts loading.
  final FutureOr<void> Function()? onLoading;

  /// Callback fired when data is successfully fetched.
  final FutureOr<void> Function(BuildContext context, List<Model> data)? onSuccess;

  /// Callback fired when an error occurs while fetching data.
  final FutureOr<void> Function(BuildContext context, int currentPage, PagifyException exception)? onError;

  /// The asynchronous API call to fetch paginated data.
  final Future<FullResponse> Function(BuildContext context, int currentPage) asyncCall;

  /// Maps the API [FullResponse] to a [PagifyData] object containing items and pagination info.
  final PagifyData<Model> Function(FullResponse response) mapper;

  /// Builds each list/grid item widget.
  final Widget Function(BuildContext context, List<Model> data, int index, Model element) itemBuilder;

  /// Custom loading widget to display while fetching data.
  final Widget? loadingBuilder;

  /// Custom widget to display when an error occurs.
  final Widget Function(PagifyException e)? errorBuilder;

  /// choose if need to ignore [ErrorBuilder] and keep the list visible when error occurs and list is not empty
  final bool ignoreErrorBuilderWhenErrorOccursAndListIsNotEmpty;

  /// Custom widget to display when the data list is empty.
  final Widget? emptyListView;

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

  /// Creates a paginated widget with a [GridView] layout.
  Pagify.gridView({super.key,
    required this.controller,
    required this.asyncCall,
    required this.mapper,
    required this.errorMapper,
    required this.itemBuilder,
    this.onScrollPositionChanged,
    this.padding = const EdgeInsets.all(0),
    this.cacheExtent,
    this.listenToNetworkConnectivityChanges = false,
    this.onConnectivityChanged,
    this.onUpdateStatus,
    this.isReverse = false,
    this.onLoading,
    this.onSuccess,
    this.onError,
    this.ignoreErrorBuilderWhenErrorOccursAndListIsNotEmpty = false,
    this.showNoDataAlert = false,
    this.loadingBuilder,
    this.errorBuilder,
    this.emptyListView,
    this.mainAxisSpacing,
    this.crossAxisSpacing,
    this.childAspectRatio = 1,
    this.scrollDirection,
    this.crossAxisCount,
    this.noConnectionText
  }) : _rankingType = _RankingType.gridView, shrinkWrap = true, itemExtent = null,
        assert(errorMapper.errorWhenHttp.isNotNull || errorMapper.errorWhenDio.isNotNull),
        assert(cacheExtent.isNotEqualZero),
        assert(
        (listenToNetworkConnectivityChanges && (onConnectivityChanged.isNull || onConnectivityChanged.isNotNull)) ||
            (!listenToNetworkConnectivityChanges && onConnectivityChanged.isNull)
        );

  /// Creates a paginated widget with a [listView] layout.
  Pagify.listView({super.key,
    required this.controller,
    required this.asyncCall,
    required this.mapper,
    required this.errorMapper,
    required this.itemBuilder,
    this.onScrollPositionChanged,
    this.padding = const EdgeInsets.all(0),
    this.itemExtent,
    this.cacheExtent,
    this.listenToNetworkConnectivityChanges = false,
    this.onConnectivityChanged,
    this.onUpdateStatus,
    this.isReverse = false,
    this.onLoading,
    this.onSuccess,
    this.onError,
    this.ignoreErrorBuilderWhenErrorOccursAndListIsNotEmpty = false,
    this.showNoDataAlert = false,
    this.loadingBuilder,
    this.errorBuilder,
    this.emptyListView,
    this.shrinkWrap,
    this.scrollDirection,
    this.noConnectionText
  }) : _rankingType = _RankingType.listView,
        crossAxisCount = null,
        childAspectRatio = null,
        crossAxisSpacing = null,
        mainAxisSpacing = null,
        assert(errorMapper.errorWhenHttp.isNotNull || errorMapper.errorWhenDio.isNotNull),
        assert(itemExtent.isNotEqualZero && cacheExtent.isNotEqualZero),
        assert(
        (listenToNetworkConnectivityChanges && (onConnectivityChanged.isNull || onConnectivityChanged.isNotNull)) ||
            (!listenToNetworkConnectivityChanges && onConnectivityChanged.isNull)
        );


  @override
  State<Pagify<FullResponse, Model>> createState() => _PagifyState<FullResponse, Model>();
}


/// [State] object of pagify widget object
class _PagifyState<FullResponse, Model> extends State<Pagify<FullResponse, Model>> {
  late RetainableScrollController _scrollController;
  late AsyncCallStatusInterceptor _asyncCallState;
  late int _totalPages;
  int _currentPage = 1;
  StreamSubscription<PagifyAsyncCallStatus>? _statusSubscription;

  void _listenStatusChanges(){
    if(widget.onUpdateStatus.isNotNull){
      _statusSubscription = _asyncCallState.listenStatusChanges.listen((event) => widget.onUpdateStatus!(event));
    }
  }

  @override
  void initState() {
    super.initState();
    widget.controller._initPagifyState(this);
    _scrollController = RetainableScrollController();
    _asyncCallState = AsyncCallStatusInterceptor();
    _scrollController.addListener(() => _onScroll());
    if(widget.listenToNetworkConnectivityChanges){
      _listenToNetworkChanges();
    }
    _listenStatusChanges();
    _fetchDataFirstTimeOrRefresh();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _asyncCallState.dispose();
    _connectivitySubscription?.cancel();
    _statusSubscription?.cancel();
    super.dispose();
  }

  late PagifyException _pagifyException;
  late PagifyApiRequestException _failure;

  void _logError(Exception e){
    if(e is DioException){
      String prettyJson = const JsonEncoder.withIndent('  ').convert(e.response?.data);
      dev.log('error : $prettyJson');
    }else if(e is HttpException){
      String prettyJson = const JsonEncoder.withIndent('  ').convert(e.message);
      dev.log('error : $prettyJson');
    }
  }

  PagifyException _getPagifyException(PagifyException e) => e;

  FutureOr<void> _errorHandler(Exception e){
    if(e is PagifyNetworkException){
      _pagifyException = _getPagifyException(e);
      _asyncCallState.updateAllStatues(PagifyAsyncCallStatus.networkError);

    }else{
      if(e is DioException){
        _failure = widget.errorMapper.errorWhenDio?.call(e)?? PagifyApiRequestException.initial();

      }else if(e is HttpException){
        _failure = widget.errorMapper.errorWhenHttp?.call(e)?? PagifyApiRequestException.initial();

      }else{
        _failure = PagifyApiRequestException.initial().copyWith(msg: 'There is error occur $e');
      }

      _pagifyException = _getPagifyException(
          PagifyApiRequestException(
              _failure.msg,
              pagifyFailure: _failure.pagifyFailure
          )
      );

      _asyncCallState.updateAllStatues(PagifyAsyncCallStatus.error);
    }

    _logError(e);
    widget.onError?.call(context, _currentPage, _pagifyException);
  }

  Future<void> _onScroll() async{
    try {
      await _startScrolling();
    } on Exception catch(e){
      _errorHandler(e);
    }
  }

  void _listenToScrollPositionChanges() => widget.onScrollPositionChanged?.call(_scrollController.position);
  Future<void> _startScrolling() async{
    _listenToScrollPositionChanges();
    switch(widget.isReverse){
      case true:
        if (_scrollController.position.pixels ==
            _scrollController.position.minScrollExtent &&
            !_asyncCallState.currentState.isLoading &&
            _currentPage <= _totalPages){
          await _fetchDataWhenScrollUp();
        }
      default:
        if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
            !_asyncCallState.currentState.isLoading &&
            _currentPage <= _totalPages) {
          await _fetchDataWhenScrollDown();
        }
    }
  }

  Future<void> _fetchDataWhenScrollUp() async => await _fetchDataWhileScrolling((items) =>
      widget.controller._updateItems(newItems: items, isReverse: true)
  );

  Future<void> _fetchDataWhenScrollDown() async => await _fetchDataWhileScrolling((items) =>
      widget.controller._updateItems(newItems: items, isReverse: false)
  );

  Future<void> _fetchDataWhileScrolling(void Function(List<Model> items) onUpdate)async => await _fetchDataAndMapping(
      whenEnd: (mapperResult) async{
        onUpdate(mapperResult.data);
        await widget.onSuccess?.call(context, _itemsList);
        _scrollController.restoreOffset(
            isReverse: widget.isReverse,
            subList: mapperResult.data,
            totalCurrentItems: _itemsList.length,
            itemExtent: widget.itemExtent
        );
      }
  );

  Future<void> _fetchDataAndMapping({
    FutureOr<void> Function()? whenStart,
    FutureOr<void> Function(PagifyData<Model> mapperResult)? whenEnd,
  })async{
    await whenStart?.call();
    _asyncCallState.updateAllStatues(PagifyAsyncCallStatus.loading);
    await widget.onLoading?.call();
    _scrollController.retainOffset();
    final mapperResult = await _manageMapper();
    if(_currentPage <= mapperResult.paginationData.totalPages.toInt()){
      setState(() => _currentPage++);
      _asyncCallState.updateAllStatues(PagifyAsyncCallStatus.success);
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

  String get _getNoInternetText => widget.noConnectionText?? 'Check your internet connection';

  PagifyNetworkException get _getNetworkException => PagifyNetworkException(_getNoInternetText);

  Future<FullResponse> _callApi(Future<FullResponse> Function(BuildContext context, int currentPage) asyncCall)async{
    late final FullResponse waitingResult;
    final connectivityResult = await _connectivity.checkConnectivity();
    await _checkAndMake(
        connectivityResult: connectivityResult,
        onConnected: () async{
          final FullResponse result = await asyncCall(context, _currentPage);
          waitingResult = result;
        },

        onDisconnected: () => throw _getNetworkException,
    );

    return waitingResult;
  }

  final CustomBool _isFirstFireToInternetInterceptor = CustomBool(true);

  FutureOr<void> _checkIsFirstTime(CustomBool val, {required FutureOr<void> Function() onNotFirstTime}) async{
    if(val.isFirst){
      val.isFirst = false;
      return;

    }else{
      await onNotFirstTime.call();
    }
  }

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  void _listenToNetworkChanges() =>
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen((networkStatus){
        _checkIsFirstTime(
            _isFirstFireToInternetInterceptor,
            onNotFirstTime: () => _checkAndMake(
                connectivityResult: networkStatus,
                onConnected: () async{
                  _asyncCallState.setLastStatusAsCurrent(
                      ifLastIsLoading: () async {
                        if(_currentPage == 1){
                          await _fetchDataFirstTimeOrRefresh();
                        }else{
                          if(widget.isReverse){
                            widget.controller.moveToMaxTop();

                          }else{
                            widget.controller.moveToMaxBottom();
                          }
                          _onScroll();
                        }
                      }
                  );
                  await widget.onConnectivityChanged?.call(true);
                },
                onDisconnected: ()async {
                  _errorHandler(_getNetworkException);
                  await widget.onConnectivityChanged?.call(false);
                }
            )
        );
      });


  Future<void> _fetchDataFirstTimeOrRefresh() async {
    try {
      await _fetchDataAndMapping(
          // whenStart: () {
          //   if(_currentPage > 1 && _itemsIsNotEmpty){
          //     _resetDataWhenRefresh();
          //   }
          // },
          whenEnd: (mapperResult) async{
            widget.controller._updateItems(newItems: mapperResult.data);
            widget.controller._initScrollController();
            await widget.onSuccess?.call(context, _itemsList);
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

  // void _resetDataWhenRefresh() {
  //   _currentPage = 1;
  //   _itemsList.clear();
  // }

  Widget _listRanking(){
    if(widget._rankingType.isGridView){
      return _gridView();

    }else if(widget._rankingType.isListView){
      return _listView();
    }

    return _listView();
  }

  bool get _hasMoreData => _currentPage <= _totalPages;
  bool get _shouldShowLoading => _hasMoreData && _asyncCallState.currentState.isLoading;
  bool get _shouldShowNoData => widget.showNoDataAlert && !_hasMoreData;
  final Widget _noMoreDataText = const PagifyText('No more data', textAlign: TextAlign.center, color: Colors.grey);

  Widget _buildExtraItemSuchNoMoreDataOrLoading({Widget? defaultWidget}){
    if(_shouldShowNoData){
      return _noMoreDataText;

    }else if(_shouldShowLoading){
      return _loadingWidget;

    }else{
      return defaultWidget?? const SizedBox.shrink();
    }
  }

  Widget _buildItemBuilder({required int index, required List<Model> value}) => index < value.length?
  widget.itemBuilder(context, value, index, value[index]) :
  _buildExtraItemSuchNoMoreDataOrLoading();

  Widget _buildItemBuilderWhenReverse({required int index, required List<Model> value}) {
    if (index.isEqualZero && (_shouldShowLoading || _shouldShowNoData)) {
      return _buildExtraItemSuchNoMoreDataOrLoading();
    }

    int dataIndex = (_shouldShowLoading || _shouldShowNoData) ? index - 1 : index;
    return widget.itemBuilder(context, value, dataIndex, value[dataIndex]);
  }

  int _buildItemCount(List<Model> value){
    if((_shouldShowNoData) || (_shouldShowLoading)){
      return value.length + 1;
    }else{
      return value.length;
    }
  }

  Widget _listView() => Align(
    alignment: widget.isReverse? Alignment.bottomCenter : Alignment.topCenter,
    child: ListView.builder(
        padding: widget.padding,
        itemExtent: widget.itemExtent,
        cacheExtent: widget.cacheExtent,
        scrollDirection: widget.scrollDirection?? Axis.vertical,
        shrinkWrap: widget.shrinkWrap?? false,
        controller: _scrollController,
        itemCount: _buildItemCount(_itemsList),
        itemBuilder: (context, index) => widget.isReverse?
        _buildItemBuilderWhenReverse(index: index, value: _itemsList) :
        _buildItemBuilder(index: index, value: _itemsList)
    ),
  );

  Widget _gridView() => SingleChildScrollView(
    controller: _scrollController,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: widget.isReverse?
      MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if(widget.isReverse)
          _buildExtraItemSuchNoMoreDataOrLoading(),
        GridView.count(
          padding: widget.padding,
          cacheExtent: widget.cacheExtent,
          shrinkWrap: widget.shrinkWrap!,
          crossAxisCount: widget.crossAxisCount?? 2,
          mainAxisSpacing: widget.mainAxisSpacing?? 0.0,
          crossAxisSpacing: widget.crossAxisSpacing?? 0.0,
          childAspectRatio: widget.childAspectRatio?? 1,
          scrollDirection: widget.scrollDirection?? Axis.vertical,
          physics: const NeverScrollableScrollPhysics(),
          children: List.generate(
            _itemsList.length,
                (index) => widget.itemBuilder(context, _itemsList, index, _itemsList[index]),
          ),
        ),
        if(!widget.isReverse)
          _buildExtraItemSuchNoMoreDataOrLoading(),
      ],
    ),
  );

  List<Model> get _itemsList => List.from(widget.controller._items.value);
  bool get _itemsIsNotEmpty => _itemsList.isNotEmpty;
  bool get _itemsIsEmpty => _itemsList.isEmpty;

  Widget get _buildLoadingView => _itemsIsEmpty?
  _loadingWidget : _listRanking();


  Widget get _loadingWidget => widget.loadingBuilder.isNull?
     const Center(child: SizedBox.square(
        dimension: 30,
        child: CircularProgressIndicator.adaptive()
    )) :  widget.loadingBuilder!;



  Widget get _buildErrorWidget => _itemsIsNotEmpty?
  _showListOrErrorBuilderBasedUserNeeds : _buildErrorViewBasedErrorBuilder;


  Widget get _showListOrErrorBuilderBasedUserNeeds => widget.ignoreErrorBuilderWhenErrorOccursAndListIsNotEmpty?
  _listRanking() : _buildErrorViewBasedErrorBuilder;
  
  Widget get _buildErrorViewBasedErrorBuilder => widget.errorBuilder.isNull?
  _buildDefaultErrorView : widget.errorBuilder!.call(_pagifyException);

  Widget get _buildDefaultErrorView => _asyncCallState.currentState.isNetworkError?
  Column(
    children: [
      Lottie.asset(Assets.lottieNoInternet),
      const SizedBox(height: 10),
      Text(
          _getNoInternetText,
          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500)
      )
    ],
  ) : Column(
    spacing: 10,
    children: [
      Lottie.asset(Assets.lottieApiError),
      Text(
          _failure.msg,
          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500)
      )
    ],
  );


  Widget get _buildSuccessWidget => _itemsIsNotEmpty? _listRanking() : _buildEmptyListView;

  Widget get _buildEmptyListView => widget.emptyListView.isNotNull?
  widget.emptyListView! : Column(
    children: [
      Lottie.asset(Assets.lottieNoData),
      const SizedBox(height: 10),
      Text('There is no data right now!')
    ],
  );

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PagifyAsyncCallStatus>(
        stream: _asyncCallState.listenStatusChanges,
        builder: (context, snapshot) => SnapshotHandler(
          snapshot: snapshot,
          loadingWidget: _loadingWidget,
          activeStateCallBack: (snapshot) => snapshot.hasData?
          snapshot.data!.isError || snapshot.data!.isNetworkError?
          _buildErrorWidget : _asyncCallState.currentState.isLoading?
          _buildLoadingView : _buildSuccessWidget : const PagifyText('the stream throws an exception'),
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
        return const PagifyText('no stream connection!');


      default:
        return activeStateCallBack.call(snapshot);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _checkStreamStatesAndBuildView;
  }
}