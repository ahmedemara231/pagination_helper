import 'package:flutter/material.dart';
import '../easy_pagination.dart';

void main() {
  runApp(const EasyPaginationExample());
}

class EasyPaginationExample extends StatelessWidget {
  const EasyPaginationExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Awesome Button Example',
      home: Scaffold(
        appBar: AppBar(title: const Text('Example Usage')),
        body: EasyPagination<ApiResponse, DataModel>.listView(
          asyncCall: (page) => apiService.fetchData(page),
          mapper: (response) => DataListAndPaginationData(
              data: response.items,
              paginationData: PaginationData(
                totalPages: response.totalPages,
              )
          ),
          errorMapper: ErrorMapper(
            errorWhenDio: (e) => e.response?.data['errorMsg'], // if you using Dio
            errorWhenHttp: (e) => e.message, // if you using Http
          ),
          itemBuilder: (data, index) => ListTile(
            title: Text(data[index].title),
            subtitle: Text(data[index].description),
          ),
        )
      ),
    );
  }
}