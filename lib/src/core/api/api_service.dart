import 'dart:async';
import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:taxi_driver/src/core/utils/app_logger.dart';

class ApiService {
  static const String baseUrl = 'https://taxi-back-rnci.onrender.com/api/';

  late Dio _dio;
  static final ApiService _instance = ApiService._internal();
  final Completer<void> _initCompleter = Completer<void>();
  bool _hasCookieManager = false;
  bool _hasLogInterceptor = false;

  factory ApiService() {
    return _instance;
  }

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    _initCookieManager();
  }

  Future<void> _initCookieManager() async {
    try {
      if (kIsWeb) {
        _ensureLogInterceptor();
        _completeInit();
        return;
      }

      CookieJar jar;

      try {
        final appDocDir = await getApplicationDocumentsDirectory();
        final appDocPath = appDocDir.path;
        jar = PersistCookieJar(
          ignoreExpires: false,
          storage: FileStorage('$appDocPath/.cookies/'),
        );
      } on MissingPluginException catch (e) {
        AppLogger.warning('Path provider not available, using memory cookies: $e');
        jar = CookieJar();
      }

      _ensureCookieManager(jar);
      _ensureLogInterceptor();
      _completeInit();
    } catch (e) {
      AppLogger.error('Error initializing CookieManager', e);
      _ensureCookieManager(CookieJar());
      _ensureLogInterceptor();
      _completeInit();
    }
  }

  void _ensureCookieManager(CookieJar jar) {
    if (kIsWeb || _hasCookieManager) return;
    _dio.interceptors.add(CookieManager(jar));
    _hasCookieManager = true;
  }

  void _ensureLogInterceptor() {
    if (_hasLogInterceptor) return;
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => AppLogger.debug('API: $obj'),
      ),
    );
    _hasLogInterceptor = true;
  }

  void _completeInit() {
    if (!_initCompleter.isCompleted) {
      _initCompleter.complete();
    }
  }

  Future<void> _waitForInit() async {
    await _initCompleter.future;
  }

  void setToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearToken() {
    _dio.options.headers.remove('Authorization');
  }

  Future<dynamic> get(String endpoint) async {
    await _waitForInit();
    try {
      final response = await _dio.get(endpoint);
      return response.data;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<dynamic> post(String endpoint, dynamic data) async {
    await _waitForInit();
    try {
      final response = await _dio.post(endpoint, data: data);
      return response.data;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<dynamic> patch(String endpoint, dynamic data) async {
    await _waitForInit();
    try {
      final response = await _dio.patch(endpoint, data: data);
      return response.data;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<dynamic> put(String endpoint, dynamic data) async {
    await _waitForInit();
    try {
      final response = await _dio.put(endpoint, data: data);
      return response.data;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<dynamic> uploadFile(String endpoint, File file) async {
    await _waitForInit();
    try {
      final fileName = file.path.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
      });

      final response = await _dio.post(endpoint, data: formData);
      return response.data;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  void _handleError(DioException e) {
    var message = 'Something went wrong';
    if (e.response != null) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        message = data['message'] ?? e.response?.statusMessage ?? message;
      } else if (data is String) {
        message = data;
      } else {
        message = e.response?.statusMessage ?? message;
      }
      AppLogger.error('API Error [${e.response?.statusCode}]: $message');
    } else {
      AppLogger.error('API Error: ${e.message}');
    }
  }
}
