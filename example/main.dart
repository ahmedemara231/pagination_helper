import 'dart:developer';
import 'package:dio/dio.dart';
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

  int count = 0;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Awesome Button Example',
      home: Scaffold(
        appBar: AppBar(title: InkWell(
            onTap: () => _pagifyController.moveToMaxTop(),

            child: const Text('Example Usage'))),
        body: Pagify<ExampleModel, String>.gridView(
          isReverse: false,
          showNoDataAlert: true,
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
            errorWhenDio: (e) {
              String? msg = '';
              switch (e.type) {
                case DioExceptionType.connectionTimeout:
                  msg = 'Connection timeout. Please try again.';

                case DioExceptionType.receiveTimeout:
                  msg = 'Server response timeout.';

                case DioExceptionType.badResponse:
                  msg = 'Server returned ${e.response?.statusCode}';

                default:
                  msg = e.response?.data.toString();
              }

              return PagifyApiRequestException(
                msg ?? 'network error occur',
                pagifyFailure: RequestFailureData(
                  statusCode: e.response?.statusCode,
                  statusMsg: e.response?.statusMessage,
                ),
              );
            } // if you using Dio

            // errorWhenHttp: (e) => PagifyApiRequestException(), // if you using Http
          ),
          itemBuilder: (context, data, index, element) => Center(
              child: InkWell(
                  onTap: (){
                    log('enter here');
                    _pagifyController.addAtBeginning('test');
                  },
                  child: Text(element)
              )
          ),
          onLoading: () => log('loading now ...!'),
          onSuccess: (context, data) => log('the data is ready $data'),
          onError: (context, page, e) async{
            await Future.delayed(const Duration(seconds: 2));
            count++;
            if(count > 3){
              return;
            }

            _pagifyController.retry();
            log('page : $page');

            if(e is PagifyNetworkException){
              log('check your internet connection');

            }else if(e is PagifyApiRequestException){
              e = PagifyApiRequestException(e.msg, pagifyFailure: e.pagifyFailure);
              log(e.msg);
              log(e.pagifyFailure.statusCode.toString());
              log(e.pagifyFailure.statusMsg.toString());

            }else{
              log('other error ...!');
            }
          },

          ignoreErrorBuilderWhenErrorOccursAndListIsNotEmpty: true,
          errorBuilder: (e) => Container(
              color: e is PagifyNetworkException?
              Colors.green: Colors.red,
              child: Text(e.msg)
          ),

          listenToNetworkConnectivityChanges: true,
          onConnectivityChanged: (isConnected) => isConnected?
          log('connected') : log('disconnected'),

          onUpdateStatus: (s) => log('message $s'),
        )
      ),
    );
  }
}