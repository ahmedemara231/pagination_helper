import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:pagination_helper/pagination_helper_refresh_indicator.dart';
import '../../../generated/assets.dart';
import 'message_utils.dart';

enum RankingType {gridView, listView}
enum AsyncCallStatus {initial, loading, success, error, networkError}

// T is full response which includes data list and pagination data
// E is specific model is the list
class EasyPagination<T, E> extends StatefulWidget {
  final RankingType rankingType;
  final Color? refreshIndicatorBackgroundColor;
  final Color? refreshIndicatorColor;
  final Function(List<E> data)? onSuccess;
  final Function(String errorMessage)? onError;
  final Future<T> Function(int currentPage) asyncCall;
  final DataListAndPaginationData<E> Function(T response) mapper;
  final String Function(DioException error) errorMessageMapper;
  final Widget Function(List<E> data, int index) itemBuilder;
  final Widget? loadingBuilder;
  final Widget Function(String errorMsg)? errorBuilder;
  final EasyPaginationController<E>? controller;
  final SliverGridDelegate? gridDelegate;

  // const EasyPagination({
  //   super.key,
  //   this.onSuccess,
  //   this.onError,
  //   this.refreshIndicatorBackgroundColor,
  //   this.refreshIndicatorColor,
  //   this.loadingBuilder,
  //   required this.asyncCall,
  //   required this.itemBuilder,
  //   required this.errorMessageMapper,
  //   this.errorBuilder,
  //   required this.mapper,
  //   this.controller,
  //   this.rankingType
  // });

  const EasyPagination.gridViewRanking({super.key,
    required this.asyncCall,
    required this.mapper,
    required this.errorMessageMapper,
    required this.itemBuilder,
    this.gridDelegate,
    this.onSuccess,
    this.onError,
    this.refreshIndicatorBackgroundColor,
    this.refreshIndicatorColor,
    this.loadingBuilder,
    this.errorBuilder,
    this.controller,
}) : rankingType = RankingType.gridView;

  const EasyPagination.listViewRanking({super.key,
    required this.asyncCall,
    required this.mapper,
    required this.errorMessageMapper,
    required this.itemBuilder,
    this.onSuccess,
    this.onError,
    this.refreshIndicatorBackgroundColor,
    this.refreshIndicatorColor,
    this.loadingBuilder,
    this.errorBuilder,
    this.controller,
  }) : rankingType = RankingType.listView, gridDelegate = null;

  @override
  State<EasyPagination<T, E>> createState() => _EasyPaginationState<T, E>();
}

class _EasyPaginationState<T, E> extends State<EasyPagination<T, E>> {
  late RetainableScrollController scrollController;
  AsyncCallStatus status = AsyncCallStatus.initial;
  int currentPage = 1;
  late int totalPages;
  List<E> newItems = [];


  @override
  void initState() {
    super.initState();
    scrollController = RetainableScrollController();
    scrollController.addListener(_onScroll);
    _fetchData();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  Future<void> _onScroll() async{
    if (scrollController.position.pixels ==
        scrollController.position.maxScrollExtent &&
        status != AsyncCallStatus.loading &&
        currentPage <= totalPages) {
      await _fetchData();
    }
  }

  String errorMsg = '';
  void _logError(DioException e){
    String prettyJson = const JsonEncoder.withIndent('  ').convert(e.response?.data);
    dev.log('error : $prettyJson');
  }

  Future<void> _fetchData() async {
    setState(() => status = AsyncCallStatus.loading);
    scrollController.retainOffset();
    try {
      final mapperResult = await _manageMapper();
      setState(() {
        currentPage++;
        newItems.addAll(mapperResult.data);
        if(widget.controller != null){
          widget.controller!.updateItems(newItems);
        }
        setState(() => status = AsyncCallStatus.success);
      });
      if(widget.onSuccess != null){
        widget.onSuccess!(newItems);
      }
      scrollController.restoreOffset();

    } on PaginationNetworkError{
      setState(() => status = AsyncCallStatus.networkError);
    }on DioException catch(e) {
      _logError(e);
      errorMsg = widget.errorMessageMapper(e);
      if(widget.onError != null){
        widget.onError!(errorMsg);
      }
      setState(() => status = AsyncCallStatus.error);
    }on Exception catch(e){
      errorMsg = 'There is error occur $e';
      setState(() => status = AsyncCallStatus.error);
    }
  }

  Future<void> _fetchDataWhenRefresh() async {
    setState(() => status = AsyncCallStatus.loading);
    currentPage = 1;
    newItems = [];
    scrollController.retainOffset();
    try {
      final mapperResult = await _manageMapper();
      setState(() {
        currentPage++;
        newItems.addAll(mapperResult.data);
        if(widget.controller != null){
          widget.controller!.updateItems(newItems);
        }
        setState(() => status = AsyncCallStatus.success);
      });

      scrollController.restoreOffset();
    } on PaginationNetworkError{
      setState(() => status = AsyncCallStatus.networkError);
    }on DioException catch(e){
      _logError(e);
      errorMsg = widget.errorMessageMapper(e);
      setState(() => status = AsyncCallStatus.error);
    }on Exception catch(e){
      errorMsg = 'There is error occur $e';
      setState(() => status = AsyncCallStatus.error);
    }
  }

  Future<DataListAndPaginationData<E>> _manageMapper()async{
    final result = await _callApi(widget.asyncCall);
    final DataListAndPaginationData<E> mapperResult = widget.mapper(result);

    _manageTotalPagesNumber(mapperResult.paginationData.totalPages?? 0); // should be put in init state
    return mapperResult;
  }

  Future<T> _callApi(Future<T> Function(int currentPage) asyncCall)async{
    final connectivityResult = await Connectivity().checkConnectivity();
    switch(connectivityResult){
      case ConnectivityResult.none:
        throw PaginationNetworkError('Check your internet connection');
      default:
        final T result = await asyncCall(currentPage);
        return result;
    }
  }


  void _manageTotalPagesNumber(int totalPagesNumber) => totalPages = totalPagesNumber;


  Widget _listRanking(bool withLoading){
    if(widget.rankingType == RankingType.gridView){
      return _gridView(withLoading);
    }
    return _listView(withLoading);
  }

  Widget _listView(bool withLoading) {
    return ListView.builder(
      controller: scrollController,
      itemCount: withLoading ? newItems.length + 1 : newItems.length,
      itemBuilder: (context, index) {
        if (index < newItems.length) {
          return widget.itemBuilder(newItems, index);
        } else {
          return _loadingWidget;
        }
      },
    );
  }

  Widget _gridView(bool withLoading) {
    return GridView.builder(
      controller: scrollController,
      gridDelegate: widget.gridDelegate!,
      itemBuilder: (context, index) {
        if (index < newItems.length) {
          return widget.itemBuilder(newItems, index);
        } else {
          return _loadingWidget;
        }
      },
    );
  }

  Widget get _buildLoadingView{
    if(newItems.isEmpty){
      return _loadingWidget;
    }else{
      return _listRanking(true);
    }
  }

  Widget get _loadingWidget{
    switch(widget.loadingBuilder){
      case null:
        return const Center(child: CircularProgressIndicator());
      default:
        return widget.loadingBuilder!;
    }
  }

  Widget get _buildErrorWidget{
    if(newItems.isNotEmpty){
      if(status == AsyncCallStatus.networkError){
        MessageUtils.showSimpleToast(msg: 'Check your internet connection', color: Colors.red);
      }else{
        MessageUtils.showSimpleToast(msg: errorMsg, color: Colors.red);
      }
      return _listRanking(false);
    }else{
      if(status == AsyncCallStatus.networkError){
        return Column(
          children: [
            Lottie.asset(Assets.lottieNoInternet),
            const SizedBox(height: 10),
            const Text(
                'Check your internet connection',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500)
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
    if(newItems.isNotEmpty){
     return _listRanking(false);
    }else{
      return Column(
        children: [
          Lottie.asset(Assets.lottieNoData),
          const SizedBox(height: 10),
          const Text('There is no data right now!')
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: PaginationHelperRefreshIndicator(
        onRefresh: () async => await _fetchDataWhenRefresh(),
        refreshIndicatorBackgroundColor: widget.refreshIndicatorBackgroundColor,
        refreshIndicatorColor: widget.refreshIndicatorColor,
        child: status == AsyncCallStatus.error || status == AsyncCallStatus.networkError?
        _buildErrorWidget : status == AsyncCallStatus.loading?
        _buildLoadingView : _buildSuccessWidget,
      ),
    );
  }
}

class RetainableScrollController extends ScrollController {
  RetainableScrollController({
    super.initialScrollOffset,
    super.keepScrollOffset,
    super.debugLabel,
  });

  double? _initialOffset;

  void retainOffset() {
    if (hasClients) {
      _initialOffset = offset;
    }
  }

  void restoreOffset() {
    if (_initialOffset != null && hasClients) {
      jumpTo(_initialOffset!);
    }
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
  // final int? totalItems;
  // final int? countItems;
  // final int? perPage;
  // final int? currentPage;
  // final String? nextPageUrl;
  final int? totalPages;

  PaginationData({
    // this.totalItems,
    // this.countItems,
    // this.perPage,
    // this.currentPage,
    // this.nextPageUrl,
    this.totalPages,
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
  List<E> _items = [];

  void updateItems(List<E> newItems) {
    _items = newItems;
  }

  E? getRandomItem() {
    if (_items.isEmpty) return null;
    final random = math.Random();
    return _items[random.nextInt(_items.length)];
  }

  List<E> filter(bool Function(E item) condition) {
    return _items.where(condition).toList();
  }

  void sort(int Function(E a, E b) compare) {
    _items.sort(compare);
  }

  void addItem(E item) {
    _items.add(item);
  }

  void removeItem(E item) {
    _items.remove(item);
  }

  void clear() {
    _items.clear();
  }

  // VoidCallback? onRefreshRequested;
  //
  // void refresh() {
  //   if (onRefreshRequested != null) {
  //     onRefreshRequested!();
  //   }
  // }

  // Dispose resources
  // void dispose() {
  //   _streamController.close();
  // }
}