import 'package:dio/dio.dart';

class AppException implements Exception {
  final String message;
  final String? prefix;
  final String? status;
  final Map<String, dynamic>? data;

  AppException([
    this.message = 'Something went wrong',
    this.prefix,
    this.status,
    this.data,
  ]);

  @override
  String toString() => "${prefix ?? ''}$message";
}

class NetworkException extends AppException {
  NetworkException([String message = 'No Internet Connection'])
    : super(message, 'Network Error: ');
}

class ServerException extends AppException {
  ServerException([
    String message = 'Server Error',
    String? status,
    Map<String, dynamic>? data,
  ]) : super(message, 'Server Error: ', status, data);
}

class DataParsingException extends AppException {
  DataParsingException([String message = 'Data Parsing Error'])
    : super(message, 'Parsing Error: ');
}

class ErrorHandler {
  static AppException handle(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return NetworkException('Connection timeout');
        case DioExceptionType.connectionError:
          return NetworkException(
            "Can't reach the server. Check your internet connection and try again.",
          );
        case DioExceptionType.badResponse:
        case DioExceptionType.badCertificate:
          final data = error.response?.data;
          String message = 'Server error: ${error.response?.statusCode}';
          String? status;
          Map<String, dynamic>? responseData;

          if (data is Map<String, dynamic>) {
            responseData = data;
            // Parse common keys: message, Error, Success, status
            message =
                data['Error']?.toString() ??
                data['Success']?.toString() ??
                data['message']?.toString() ??
                data['status']?.toString() ??
                message;
            status = data['status']?.toString();
          }

          return ServerException(message, status, responseData);
        case DioExceptionType.cancel:
          return AppException('Request cancelled');
        default:
          return NetworkException('Check your internet connection');
      }
    } else if (error is AppException) {
      return error;
    } else {
      return AppException(error.toString());
    }
  }
}
