import 'dart:io';
import 'package:dio/dio.dart';

class PagifyError implements Exception{
  final String msg;
  PagifyError(this.msg);
}

class PaginationNetworkError extends PagifyError{
  PaginationNetworkError(super.msg);
}

class ErrorMapper{
  String Function(DioException e)? errorWhenDio;
  String Function(HttpException e)? errorWhenHttp;

  ErrorMapper({this.errorWhenDio, this.errorWhenHttp});
}