import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

enum AsyncCallStatus {initial, loading, success, error}

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

  void _onScroll() {
    if (scrollController.position.pixels ==
        scrollController.position.maxScrollExtent &&
        status != AsyncCallStatus.loading &&
        currentPage <= totalPages) {
      _fetchData();
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
    } on Exception {
      setState(() => status = AsyncCallStatus.error);
    }
  }

  Future<T> _callApi(Future<T> Function(int currentPage) asyncCall)async{
    final T result = await asyncCall(currentPage);
    return result;
  }

  Future<DataListAndPaginationData<E>> _manageMapper()async{
    final result = await _callApi(widget.asyncCall);
    final DataListAndPaginationData<E> mapperResult = widget.mapper(result);

    _manageTotalPagesNumber(mapperResult.paginationData.totalPages?? 0); // should be put in init state
    return mapperResult;
  }

  void _manageTotalPagesNumber(int totalPagesNumber) => totalPages = totalPagesNumber;



  Widget get _buildLoadingView{
    switch(widget.loadingBuilder){
      case null:
        return const CircularProgressIndicator();
      default:
        return widget.loadingBuilder!;
    }
  }

  Widget get _buildErrorWidget{
    switch(widget.errorBuilder){
      case null:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset('assets/lottie/api_error.json'),
            SizedBox(height: 10),
            Text('Error occurs')
          ],
        );
      default:
        return widget.errorBuilder!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return status == AsyncCallStatus.error? _buildErrorWidget :
    ListView.builder(
        controller: scrollController,
        itemCount: status == AsyncCallStatus.loading ? 1 : newItems.length,
        itemBuilder: (context, index) => status == AsyncCallStatus.loading ?
        _buildLoadingView : widget.builder(newItems, index)
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