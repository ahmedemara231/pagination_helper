import 'dart:io';
import 'package:dio/dio.dart';

class EasyPaginationError implements Exception{
  final String msg;
  EasyPaginationError(this.msg);
}

class PaginationNetworkError extends EasyPaginationError{
  PaginationNetworkError(super.msg);
}

class ErrorMapper{
  String Function(DioException e)? errorWhenDio;
  String Function(HttpException e)? errorWhenHttp;

  ErrorMapper({this.errorWhenDio, this.errorWhenHttp});
}