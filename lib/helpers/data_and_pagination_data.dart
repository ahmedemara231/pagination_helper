/// pagination data to Extract the data list and pagination data
class PagifyData<E>{
  /// the list of data items
  List<E> data;

  /// the pagination data
  PaginationData paginationData;


  /// the constructor which accepts two [List] and [PaginationData]
  PagifyData({
    required this.data,
    required this.paginationData,
  });
}


/// the pagination data which contains the [perPage] and [totalPages]
class PaginationData{

  /// number of items can pick in one request
  final int perPage;

  /// total number of pages in database
  final int totalPages;
  // final String? nextPageUrl;

  /// the constructor which accepts two [int]
  PaginationData({
    required this.perPage,
    required this.totalPages,
    // this.nextPageUrl,
  });
}