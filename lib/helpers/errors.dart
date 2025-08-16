import 'dart:io';
import 'package:dio/dio.dart';

/// official Pagify [Exception]
class PagifyException implements Exception{

  /// the constructor which accepts a [String] message
  final String msg;

  /// the constructor which accepts a [String] message
  PagifyException(this.msg);
}

/// network [Exception] happens when there is no internet connection
class PagifyNetworkException extends PagifyException{

  /// the constructor which accepts a [String] message
  PagifyNetworkException(super.msg);
}


/// api request [Exception] happens when there is request exception like [DioException]
class ApiRequestException extends PagifyException{

  /// the constructor which accepts a [String] message
  ApiRequestException(super.msg);
}


/// error mapper which extract the api [Exception] message
class PagifyErrorMapper{

  /// [Dio] Package error mapper which extract the [DioException] message
  String Function(DioException e)? errorWhenDio;

  /// [Http] Package error mapper which extract the [HttpException] message
  String Function(HttpException e)? errorWhenHttp;

  /// the constructor which accepts two [Function]
  PagifyErrorMapper({this.errorWhenDio, this.errorWhenHttp});
}