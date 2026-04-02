import 'package:dio/dio.dart';
import 'dart:io';
import '../services/token_service.dart';

class ApiExceptions implements Exception {
  final String message;
  final int? statusCode;

  ApiExceptions(this.message, [this.statusCode]);

  @override
  String toString() => 'ApiExceptions: $message (Status: $statusCode)';
}

class ApiClient {
  late Dio _dio;
  final TokenService _tokenService = TokenService();
  
  static const String _baseUrl = 'http://207.154.222.151';

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _tokenService.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          // Handle token expiration - Logout for now
          await _tokenService.deleteTokens();
        }
        return handler.next(e);
      },
    ));

    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.post(path, data: data, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> multipartPost(String path, File file, String type, {Map<String, dynamic>? extraData}) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path),
        'type': type,
        ...?extraData,
      });
      return await _dio.post(path, data: formData);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> patch(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.patch(path, data: data, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> delete(String path) async {
    try {
      return await _dio.delete(path);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  ApiExceptions _handleError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout || 
        error.type == DioExceptionType.receiveTimeout) {
      return ApiExceptions('Connection timed out', 408);
    }
    
    if (error.response != null) {
      final data = error.response?.data;
      String message = 'Something went wrong';
      if (data is Map && data.containsKey('detail')) {
        message = data['detail'];
      }
      return ApiExceptions(message, error.response?.statusCode);
    }

    if (error.error is SocketException) {
      return ApiExceptions('No Internet connection', 503);
    }

    return ApiExceptions('Unexpected error occurred');
  }
}
