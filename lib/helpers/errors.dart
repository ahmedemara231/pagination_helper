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
class PagifyApiRequestException extends PagifyException {
  /// the constructor which accepts a [String] message
  PagifyApiRequestException(super.msg, {required this.pagifyFailure});

  /// [PagifyFailure] instance
  final PagifyFailure pagifyFailure;

  /// initial constructor to [PagifyApiRequestException]
  factory PagifyApiRequestException.initial() => PagifyApiRequestException(
      '',
      pagifyFailure: PagifyFailure.initial()
  );

  /// copyWith function
  PagifyApiRequestException copyWith({
    String? msg,
    PagifyFailure? pagifyFailure,
}) => PagifyApiRequestException(
      msg?? this.msg,
      pagifyFailure: pagifyFailure?? this.pagifyFailure
  );
}

/// error mapper which extract the api [Exception] message
class PagifyErrorMapper {
  /// [Dio] Package error mapper which extract the [DioException] message
  PagifyApiRequestException Function(DioException e)? errorWhenDio;

  /// [Http] Package error mapper which extract the [HttpException] message
  PagifyApiRequestException Function(HttpException e)? errorWhenHttp;

  /// the constructor which accepts two [Function]
  PagifyErrorMapper({this.errorWhenDio, this.errorWhenHttp});
}

/// error mapping result
class PagifyFailure {
  /// status code [int]
  final int? statusCode;
  /// status msg [String]
  final String? statusMsg;

  /// the constructor which accepts a three params
  PagifyFailure({
    this.statusCode,
    this.statusMsg,
  });

  /// initial state
  factory PagifyFailure.initial() => PagifyFailure(
    statusCode: 0,
    statusMsg: '',
  );

  /// copyWith function
  PagifyFailure copyWith({
    int? statusCode,
    String? statusMsg,
  }) => PagifyFailure(
    statusCode: statusCode ?? this.statusCode,
    statusMsg: statusMsg ?? this.statusMsg,
  );
}

