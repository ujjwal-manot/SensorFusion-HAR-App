import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';
import '../models/user.dart';

class AuthService {
  final Dio _dio;
  final FlutterSecureStorage _storage;
  static const String _tokenKey = 'auth_token';

  AuthService()
      : _dio = Dio(),
        _storage = const FlutterSecureStorage() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        handler.next(error);
      },
    ));
  }

  String get _baseUrl => AppConfig.serverUrl;

  Future<User> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final token = data['access_token'] as String;
      await _storage.write(key: _tokenKey, value: token);

      final user = User.fromJson(data['user'] as Map<String, dynamic>);
      return user;
    } on DioException catch (e) {
      final message = _extractErrorMessage(e);
      throw AuthException(message);
    }
  }

  Future<User> register(
      String email, String password, String displayName) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/auth/register',
        data: {
          'email': email,
          'password': password,
          'display_name': displayName,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final token = data['access_token'] as String;
      await _storage.write(key: _tokenKey, value: token);

      final user = User.fromJson(data['user'] as Map<String, dynamic>);
      return user;
    } on DioException catch (e) {
      final message = _extractErrorMessage(e);
      throw AuthException(message);
    }
  }

  Future<User> getMe() async {
    try {
      final response = await _dio.get('$_baseUrl/auth/me');
      return User.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final message = _extractErrorMessage(e);
      throw AuthException(message);
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
  }

  Future<String?> getToken() async {
    return _storage.read(key: _tokenKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  String _extractErrorMessage(DioException e) {
    if (e.response?.data is Map<String, dynamic>) {
      final data = e.response!.data as Map<String, dynamic>;
      return data['detail'] as String? ?? 'An unexpected error occurred';
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'Could not connect to server. Check your server URL and network.';
    }
    return 'An unexpected error occurred';
  }
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}
