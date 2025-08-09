import 'package:flutter/material.dart';
import 'package:pagify/helpers/controller.dart';
import 'package:pagify/helpers/data_and_pagination_data.dart';
import 'package:pagify/helpers/errors.dart';
import 'package:pagify/pagination_with_reverse_and_status_stream.dart';

void main() {
  runApp(const EasyPaginationExample());
}

class ExampleModel{
  List<String> items;
  int totalPages;

  ExampleModel({
    required this.items,
    required this.totalPages
  });
}

class EasyPaginationExample extends StatefulWidget {
  const EasyPaginationExample({super.key});

  @override
  State<EasyPaginationExample> createState() => _EasyPaginationExampleState();
}

class _EasyPaginationExampleState extends State<EasyPaginationExample> {
  Future<ExampleModel> _fetchData(int currentPage) async {
    await Future.delayed(const Duration(seconds: 2)); // simulate api call with current page
    final items = List.generate(25, (index) => 'Item $index');
    return ExampleModel(items: items, totalPages: 4);
  }

  late EasyPaginationController<String> _easyPaginationController;
  @override
  void initState() {
    _easyPaginationController = EasyPaginationController<String>();
    super.initState();
  }

  @override
  void dispose() {
    _easyPaginationController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Awesome Button Example',
      home: Scaffold(
        appBar: AppBar(title: const Text('Example Usage')),
        body: EasyPagination<ExampleModel, String>.listView(
          controller: _easyPaginationController,
          asyncCall: (page)async => await _fetchData(page),
          mapper: (response) => DataListAndPaginationData(
              data: response.items,
              paginationData: PaginationData(
                totalPages: response.totalPages,
                perPage: 10,
              )
          ),
          errorMapper: ErrorMapper(
            errorWhenDio: (e) => e.response?.data['errorMsg'], // if you using Dio
            errorWhenHttp: (e) => e.message, // if you using Http
          ),
          itemBuilder: (data, index, element) => Text(data[index])
        )
      ),
    );
  }
}