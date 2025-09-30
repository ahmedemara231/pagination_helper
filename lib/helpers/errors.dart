import 'dart:io';
import 'package:dio/dio.dart';

/// official Pagify [Exception]
class PagifyException implements Exception {
  /// the constructor which accepts a [String] message
  final String msg;

  /// the constructor which accepts a [String] message
  PagifyException(this.msg);
}

/// network [Exception] happens when there is no internet connection
class PagifyNetworkException extends PagifyException {
  /// the constructor which accepts a [String] message
  PagifyNetworkException(super.msg);
}

/// api request [Exception] happens when there is request exception like [DioException]
class ApiRequestException extends PagifyException {
  /// the constructor which accepts a [String] message
  ApiRequestException(this.pagifyFailure) : super('');

  /// [PagifyFailure] instance
  final PagifyFailure pagifyFailure;
}

/// error mapper which extract the api [Exception] message
class PagifyErrorMapper {
  /// [Dio] Package error mapper which extract the [DioException] message
  PagifyFailure Function(DioException e)? errorWhenDio;

  /// [Http] Package error mapper which extract the [HttpException] message
  PagifyFailure Function(HttpException e)? errorWhenHttp;

  /// the constructor which accepts two [Function]
  PagifyErrorMapper({this.errorWhenDio, this.errorWhenHttp});
}

/// error mapping result
class PagifyFailure {

  /// error msg [String]
  final String? errorMsg;
  /// status code [int]
  final int? statusCode;
  /// status msg [String]
  final String? statusMsg;

  /// the constructor which accepts a three params
  PagifyFailure({
    this.errorMsg,
    this.statusCode,
    this.statusMsg,
  });

  /// initial state
  factory PagifyFailure.initial() =>
      PagifyFailure(
        errorMsg: '',
        statusCode: 0,
        statusMsg: '',
      );

  /// copyWith function
  PagifyFailure copyWith({
    String? errorMsg,
    int? statusCode,
    String? statusMsg,
  }) {
    return PagifyFailure(
      errorMsg: errorMsg ?? this.errorMsg,
      statusCode: statusCode ?? this.statusCode,
      statusMsg: statusMsg ?? this.statusMsg,
    );
  }
}

