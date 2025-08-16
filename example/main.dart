import 'dart:developer';

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
  late PagifyController<String> _pagifyController;
  @override
  void initState() {
    _pagifyController = PagifyController<String>();
    super.initState();
  }

  @override
  void dispose() {
    _pagifyController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Awesome Button Example',
      home: Scaffold(
        appBar: AppBar(title: const Text('Example Usage')),
        body: Pagify<ExampleModel, String>.gridView(
          onLoading: () => log('loading now ...!'),
          onSuccess: (context, data) => log('the data is ready $data'),
          onError: (context, page, e) {
            log('page : $page');
            if(e is PagifyNetworkException){
              log('check your internet connection');

            }else if(e is ApiRequestException){
              log('check your server ${e.msg}');

            }else{
              log('other error ...!');
            }
          },
          childAspectRatio: 2,
          mainAxisSpacing: 10,
          crossAxisCount: 12,
          controller: _pagifyController,
          asyncCall: (context, page)async => await _fetchData(page),
          mapper: (response) => PagifyData(
              data: response.items,
              paginationData: PaginationData(
                totalPages: response.totalPages,
                perPage: 10,
              )
          ),
          errorMapper: PagifyErrorMapper(
            errorWhenDio: (e) => e.response?.data['errorMsg'], // if you using Dio
            errorWhenHttp: (e) => e.message, // if you using Http
          ),
          itemBuilder: (context, data, index, element) => Text(element)
        )
      ),
    );
  }
}