import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:easy_pagination/helpers/add_frame.dart';
import 'package:easy_pagination/helpers/controller.dart';
import 'package:easy_pagination/widgets/pagination_helper_refresh_indicator.dart';
import 'package:easy_pagination/widgets/text.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../generated/assets.dart';
import 'helpers/data_and_pagination_data.dart';
import 'helpers/errors.dart';
import 'helpers/message_utils.dart';
import 'helpers/scroll_controller.dart';
import 'helpers/status_stream.dart';


enum RankingType {gridView, listView}


// Response is full response which includes data list and pagination data
// Model is specific model is the list
class EasyPagination<Response, Model> extends StatefulWidget {
  final FutureOr<void> Function(AsyncCallStatus status)? onUpdateStatus;
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

  FutureOr<void> _errorHandler(Exception e){
    dev.log('enter error handler');
    _logError(e);
    widget.onError?.call(currentPage, errorMsg);
    setState(() => status.updateStatus(AsyncCallStatus.error));

    if(e is PaginationNetworkError){
      setState(() => status.updateStatus(AsyncCallStatus.networkError));

    }else if(e is DioException){
      errorMsg = widget.errorMapper.errorWhenDio?.call(e)?? '';

    }else if(e is HttpException){
      errorMsg = widget.errorMapper.errorWhenHttp?.call(e)?? '';

    }else{
      errorMsg = 'There is error occur $e';
    }
  }


  Future<void> _onScroll({bool isRefresh = false}) async{
    try {
      if(isRefresh){
        await _fetchDataFirstTimeOrRefresh();
      }else{
        await _startScrolling();
      }
    } on Exception catch(e){
      _errorHandler(e);
    }
  }

  Future<void> _startScrolling() async{
    switch(widget.isReverse){
      case true:
        if (_scrollController.position.pixels ==
            _scrollController.position.minScrollExtent &&
            !status.currentState.isLoading &&
            currentPage <= totalPages){
          await _fetchDataWhenScrollUp();
        }
      default:
        if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
            !status.currentState.isLoading &&
            currentPage <= totalPages) {
          await _fetchDataWhenScrollDown();
        }
    }
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
      widget.onSuccess!(currentPage, widget.controller.items.value);
    }
    _scrollController.restoreOffset(
        isReverse: widget.isReverse,
        subList: mapperResult.data,
        totalCurrentItems: widget.controller.items.value.length
    );
  }

  Future<DataListAndPaginationData<Model>> _manageMapper()async{
    final result = await _callApi(widget.asyncCall);
    final DataListAndPaginationData<Model> mapperResult = widget.mapper(result);

    // should be called every time because the total pages may be changed
    _manageTotalPagesNumber(mapperResult.paginationData.totalPages);
    return mapperResult;
  }

  void _manageTotalPagesNumber(int totalPagesNumber) => totalPages = totalPagesNumber;

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

  Future<void> _fetchDataFirstTimeOrRefresh() async {
    if(currentPage > 1 && widget.controller.items.value.isNotEmpty){
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
      widget.controller.initScrollController(_scrollController);
      if(widget.onSuccess != null){
        widget.onSuccess!(currentPage, widget.controller.items.value);
      }
      if(widget.isReverse){
        Frame.addBefore(() => _scrollDownWhileGetDataFirstTimeWhenReverse());
      }
    } on Exception catch(e){
      _errorHandler(e);
    }
  }

  void _scrollDownWhileGetDataFirstTimeWhenReverse(){
    _scrollController.jumpTo(
      _scrollController.position.maxScrollExtent,
    );
  }

  void _resetDataWhenRefresh() {
    currentPage = 1;
    widget.controller.items.value.clear();
  }


  Widget _listRanking(){
    if(widget.rankingType == RankingType.gridView){
      return _gridView();
    }
    return _listView();
  }

  bool get _hasMoreData => currentPage <= totalPages;
  bool get _shouldShowLoading => _hasMoreData && status.currentState.isLoading;
  bool get _shouldShowNoData => widget.showNoDataAlert && !_hasMoreData;
  final Widget _noMoreDataText = const AppText('No more data', textAlign: TextAlign.center, color: Colors.grey);

  Widget _buildGridExtraItemSuchNoMoreDataOrLoading({Widget? defaultWidget}){
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
      return _buildGridExtraItemSuchNoMoreDataOrLoading();
    }
  }

  Widget _buildItemBuilderWhenReverse({required int index, required List<Model> value}) {
    if (index == 0 && (_shouldShowLoading || _shouldShowNoData)) {
      return _buildGridExtraItemSuchNoMoreDataOrLoading();
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
      valueListenable: widget.controller.items,
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
      valueListenable: widget.controller.items,
      builder: (context, value, child) => SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: widget.isReverse?
          MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if(widget.isReverse)
              _buildGridExtraItemSuchNoMoreDataOrLoading(),
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
              _buildGridExtraItemSuchNoMoreDataOrLoading(),
          ],
        ),
      ),
    );
  }

  Widget get _buildLoadingView{
    if(widget.controller.items.value.isEmpty){
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
    if(widget.controller.items.value.isNotEmpty){
      if(status.currentState.isNetworkError){
        MessageUtils. showSimpleToast(msg: widget.noConnectionText?? 'Check your internet connection', color: Colors.red);
      }else{
        MessageUtils.showSimpleToast(msg: errorMsg, color: Colors.red);
      }
      return _listRanking();
    }else{
      if(status.currentState.isNetworkError){
        return Column(
          children: [
            // Lottie.asset(Assets.lottieNoInternet),
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
              // Lottie.asset(Assets.lottieApiError),
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
    if(widget.controller.items.value.isNotEmpty){
      return _listRanking();
    }else{
      return Column(
        children: [
          // Lottie.asset(Assets.lottieNoData),
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
    }else{
      await _onScroll(isRefresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PaginationHelperRefreshIndicator(
      onRefresh: _manageRefreshIndicator,
      child: ValueListenableBuilder(
        valueListenable: widget.controller.needToRefresh,
        builder: (context, value, child) =>
        status.currentState.isError || status.currentState.isNetworkError?
        _buildErrorWidget : status.currentState.isLoading?
        _buildLoadingView : _buildSuccessWidget,
      ),
    );
  }
}