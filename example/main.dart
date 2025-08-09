import 'package:flutter/material.dart';
import 'package:pagify/helpers/data_and_pagination_data.dart';
import 'package:pagify/helpers/errors.dart';
import 'package:pagify/pagify.dart';

void main() {
  runApp(const PagifyExample());
}

class ExampleModel{
  List<String> items;
  int totalPages;

  ExampleModel({
    required this.items,
    required this.totalPages
  });
}

class PagifyExample extends StatefulWidget {
  const PagifyExample({super.key});

  @override
  State<PagifyExample> createState() => _PagifyExampleState();
}

class _PagifyExampleState extends State<PagifyExample> {
  Future<ExampleModel> _fetchData(int currentPage) async {
    await Future.delayed(const Duration(seconds: 2)); // simulate api call with current page
    final items = List.generate(25, (index) => 'Item $index');
    return ExampleModel(items: items, totalPages: 4);
  }

  //
  late PagifyController<String> _PagifyController;
  @override
  void initState() {
    _PagifyController = PagifyController<String>();
    super.initState();
  }

  @override
  void dispose() {
    _PagifyController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Awesome Button Example',
      home: Scaffold(
        appBar: AppBar(title: const Text('Example Usage')),
        body: Pagify<ExampleModel, String>.gridView(
          childAspectRatio: 2,
          mainAxisSpacing: 10,
          crossAxisCount: 12,
          controller: _PagifyController,
          asyncCall: (page)async => await _fetchData(page),
          mapper: (response) => PagifyData(
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