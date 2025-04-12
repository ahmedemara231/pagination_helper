import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../generated/assets.dart';

enum AsyncCallStatus {initial, loading, success, error, networkError}

// T is full response, E is specific model is the list
class PaginatedList<T, E> extends StatefulWidget {

  final Future<T> Function(int currentPage) asyncCall;
  final DataListAndPaginationData<E> Function(T response) mapper;

  final Widget Function(List<E> data, int index) builder;
  final Widget? loadingBuilder;
  final Widget? errorBuilder;

  const PaginatedList({
    super.key,
    this.loadingBuilder,
    required this.asyncCall,
    required this.builder,
    this.errorBuilder,
    required this.mapper,
  });

  @override
  State<PaginatedList<T, E>> createState() => _PaginatedListState<T, E>();
}

class _PaginatedListState<T, E> extends State<PaginatedList<T, E>> {
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

  Future<void> _fetchData() async {
    setState(() => status = AsyncCallStatus.loading);
    scrollController.retainOffset();
    try {
      final mapperResult = await _manageMapper();
      setState(() {
        currentPage++;
        setState(() => status = AsyncCallStatus.success);
        newItems.addAll(mapperResult.data);
      });
      scrollController.restoreOffset();
    } on PaginationNetworkError{
      setState(() => status = AsyncCallStatus.networkError);
    }on Exception {
      setState(() => status = AsyncCallStatus.error);
    }
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

  Future<DataListAndPaginationData<E>> _manageMapper()async{
    final result = await _callApi(widget.asyncCall);
    final DataListAndPaginationData<E> mapperResult = widget.mapper(result);

    _manageTotalPagesNumber(mapperResult.paginationData.totalPages?? 0); // should be put in init state
    return mapperResult;
  }

  void _manageTotalPagesNumber(int totalPagesNumber) => totalPages = totalPagesNumber;

  Widget get _buildLoadingView{
    if(newItems.isEmpty){
      return _loadingWidget;
    }else{
      return _listView(true);
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
            const Text(
                'Error occurs!',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500)
            )
          ],
        );
      default:
        return widget.errorBuilder!;
    }
  }


  Widget get _buildSuccessWidget{
    if(newItems.isNotEmpty){
      return _listView(false);
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

  Widget _listView(bool withLoading) {
    return ListView.builder(
      controller: scrollController,
      itemCount: withLoading ? newItems.length + 1 : newItems.length,
      itemBuilder: (context, index) {
        if (index < newItems.length) {
          return widget.builder(newItems, index);
        } else {
          return _loadingWidget;
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: status == AsyncCallStatus.error || status == AsyncCallStatus.networkError?
      _buildErrorWidget : status == AsyncCallStatus.loading?
      _buildLoadingView : _buildSuccessWidget,
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

class PaginatedListError implements Exception{
  final String msg;
  PaginatedListError(this.msg);
}

class PaginationNetworkError extends PaginatedListError{
  PaginationNetworkError(super.msg);
}




// class PaginatedList<T> extends StatefulWidget {
//
//   final int pagesNumber;
//   final Future<List<T>> Function() getItems;
//   final Widget Function(List<T> data, int index) builder;
//   final Widget Function()? loadingBuilder;
//
//   const PaginatedList({
//     super.key,
//     required this.getItems,
//     required this.pagesNumber,
//     required this.builder,
//   }) : loadingBuilder = null;
//
//   const PaginatedList.loadingBuilder({super.key,
//     required this.pagesNumber,
//     required this.getItems,
//     required this.builder,
//     required this.loadingBuilder,
//   });
//
//   @override
//   State<PaginatedList<T>> createState() => _PaginatedListState<T>();
// }
//
// class _PaginatedListState<T> extends State<PaginatedList<T>> {
//   late RetainableScrollController scrollController;
//   bool isLoading = false;
//   int currentPage = 1;
//   List<T> newItems = [];
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
//   void _onScroll() {
//     if (scrollController.position.pixels ==
//         scrollController.position.maxScrollExtent &&
//         !isLoading &&
//         currentPage < widget.pagesNumber) {
//       _fetchData();
//     }
//   }
//
//   Future<void> _fetchData() async {
//     setState(() => isLoading = true);
//     scrollController.retainOffset();
//     final fetchedNewItems = await widget.getItems();
//     setState(() {
//       currentPage++;
//       isLoading = false;
//       newItems.addAll(fetchedNewItems);
//     });
//     scrollController.restoreOffset();
//   }
//
//   Widget _buildLoadingView(){
//     if(widget.loadingBuilder != null){
//       return widget.loadingBuilder!();
//     }
//     return CustomLoading.showLoadingView();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return ListView.builder(
//       controller: scrollController,
//       itemCount: isLoading ? 1 : newItems.length,
//       itemBuilder: (context, index) => isLoading
//           ? _buildLoadingView()
//           : widget.builder(newItems, index).paddingSymmetric(vertical: 50),
//     );
//   }
// }
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