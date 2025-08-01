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