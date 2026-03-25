import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// API Response model for handling server responses
class ApiResponse {
  final int status;
  final String? message;
  final Map<String, List<String>>? errors;
  final dynamic data;

  ApiResponse({
    required this.status,
    this.message,
    this.errors,
    this.data,
  });

  /// Factory constructor to create ApiResponse from Dio response
  factory ApiResponse.fromResponse(Response response) {
    final data = response.data;
    return ApiResponse(
      status: response.statusCode ?? 0,
      message: data is Map<String, dynamic> ? data['message'] : null,
      errors: data is Map<String, dynamic> ? data['errors'] : null,
      data: data,
    );
  }
}

/// Configuration constants for API service
class ApiConfig {
  static const String baseUrl = 'https://swd392be.io.vn';
  static const Duration timeout = Duration(milliseconds: 30000);
  static const String contentType = 'application/json';
  
  // Toast colors
  static const Color successColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFF44336);
  static const Color textColor = Colors.white;
  
  // Messages
  static const String defaultErrorMessage = 'Đã xảy ra lỗi không xác định.';
  static const String successPrefix = 'Thành công';
  static const String errorPrefix = 'Lỗi';
}

/// Enum for notification behavior
enum NotificationBehavior {
  showAll,      // Show both success and error toasts
  errorsOnly,   // Show only error toasts
  none,         // Show no toasts
}

/// API Service class for handling HTTP requests
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late final Dio _defaultDio;
  late final Dio _skipNotiDio;
  late final Dio _skipAllNotiDio;
  bool _initialized = false;

  /// Initialize the API service
  void initialize() {
    _defaultDio = _createDioInstance(NotificationBehavior.showAll);
    _skipNotiDio = _createDioInstance(NotificationBehavior.errorsOnly);
    _skipAllNotiDio = _createDioInstance(NotificationBehavior.none);
    _initialized = true;
  }

  /// Create Dio instance with specified notification behavior
  Dio _createDioInstance(NotificationBehavior behavior) {
    final dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      contentType: ApiConfig.contentType,
      connectTimeout: ApiConfig.timeout,
      receiveTimeout: ApiConfig.timeout,
      sendTimeout: ApiConfig.timeout,
    ));

    // Add request interceptor for authentication
    dio.interceptors.add(_createAuthInterceptor());
    
    // Add response interceptor based on notification behavior
    dio.interceptors.add(_createResponseInterceptor(behavior));

    return dio;
  }

  /// Create authentication interceptor
  InterceptorsWrapper _createAuthInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('accessToken');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        } catch (e) {
          print('Error getting access token: $e');
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        print('Request interceptor error: ${e.message}');
        return handler.next(e);
      },
    );
  }

  /// Create response interceptor based on notification behavior
  InterceptorsWrapper _createResponseInterceptor(NotificationBehavior behavior) {
    return InterceptorsWrapper(
      onResponse: (response, handler) {
        if (behavior == NotificationBehavior.showAll) {
          _showSuccessToast(response);
        }
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        _logError(e);
        if (behavior != NotificationBehavior.none) {
          _showErrorToast(e);
        }
        return handler.next(e);
      },
    );
  }

  /// Show success toast notification
  void _showSuccessToast(Response response) {
    try {
      final data = response.data;
      if (data is Map<String, dynamic> && data['message'] != null) {
        Fluttertoast.showToast(
          msg: '${ApiConfig.successPrefix}\n${data['message']}',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          backgroundColor: ApiConfig.successColor,
          textColor: ApiConfig.textColor,
        );
      }
    } catch (e) {
      print('Error showing success toast: $e');
    }
  }

  /// Show error toast notification
  void _showErrorToast(DioException e) {
    try {
      String errorMessage = ApiConfig.defaultErrorMessage;
      
      if (e.response?.data is Map<String, dynamic>) {
        final responseData = e.response!.data as Map<String, dynamic>;
        if (responseData['message'] != null) {
          errorMessage = responseData['message'];
        }
      }
      
      Fluttertoast.showToast(
        msg: '${ApiConfig.errorPrefix}\n$errorMessage',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        backgroundColor: ApiConfig.errorColor,
        textColor: ApiConfig.textColor,
      );
    } catch (ex) {
      print('Error showing error toast: $ex');
    }
  }

  /// Log error details
  void _logError(DioException e) {
    print('API Error for ${e.requestOptions.uri}: ${e.response?.data ?? e.message}');
  }

  /// Get Dio instance with full notifications
  Dio get defaultDio {
    if (!_isInitialized) initialize();
    return _defaultDio;
  }

  /// Get Dio instance with error-only notifications
  Dio get skipNotiDio {
    if (!_isInitialized) initialize();
    return _skipNotiDio;
  }

  /// Get Dio instance with no notifications
  Dio get skipAllNotiDio {
    if (!_isInitialized) initialize();
    return _skipAllNotiDio;
  }

  bool get _isInitialized => _initialized;
}

// Global instances for backward compatibility
final defaultDioInstance = ApiService().defaultDio;
final skipNotiDioInstance = ApiService().skipNotiDio;
final skipAllNotiDioInstance = ApiService().skipAllNotiDio;
