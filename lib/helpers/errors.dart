import 'dart:io';
import 'package:dio/dio.dart';

/// official Pagify [Exception]
class PagifyError implements Exception{

  /// the constructor which accepts a [String] message
  final String msg;

  /// the constructor which accepts a [String] message
  PagifyError(this.msg);
}

/// network [Exception] happens when there is no internet connection
class PaginationNetworkError extends PagifyError{

  /// the constructor which accepts a [String] message
  PaginationNetworkError(super.msg);
}


/// error mapper which extract the api [Exception] message
class ErrorMapper{

  /// [Dio] Package error mapper which extract the [DioException] message
  String Function(DioException e)? errorWhenDio;

  /// [Http] Package error mapper which extract the [HttpException] message
  String Function(HttpException e)? errorWhenHttp;

  /// the constructor which accepts two [Function]
  ErrorMapper({this.errorWhenDio, this.errorWhenHttp});
}