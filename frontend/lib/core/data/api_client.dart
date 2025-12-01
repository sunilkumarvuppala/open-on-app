import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:openon_app/core/data/api_config.dart';
import 'package:openon_app/core/data/token_storage.dart';
import 'package:openon_app/core/errors/app_exceptions.dart';
import 'package:openon_app/core/utils/logger.dart';

/// API client for backend communication
class ApiClient {
  final TokenStorage _tokenStorage = TokenStorage();
  final http.Client _client = http.Client();

  /// Get headers with authentication token
  Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuth) {
      final token = await _tokenStorage.getAccessToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  /// Extract error message from response body
  String? _extractErrorMessage(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      // Try to get detail first, then message, then any error field
      String? errorMessage = json['detail'] as String? ?? 
                             json['message'] as String? ?? 
                             json['error'] as String?;
      
      // If detail is a list (FastAPI validation errors), extract first message
      if (errorMessage == null && json['detail'] is List) {
        final details = json['detail'] as List;
        if (details.isNotEmpty) {
          final firstDetail = details[0];
          if (firstDetail is Map) {
            errorMessage = firstDetail['msg'] as String? ?? firstDetail['message'] as String?;
          } else if (firstDetail is String) {
            errorMessage = firstDetail;
          }
        }
      }
      return errorMessage;
    } catch (_) {
      return body.isNotEmpty ? body : null;
    }
  }

  /// Handle HTTP response and convert to appropriate exceptions
  void _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    final errorMessage = _extractErrorMessage(response.body);

    switch (response.statusCode) {
      case 400:
        throw ValidationException(errorMessage ?? 'Invalid request');
      case 401:
        throw AuthenticationException(errorMessage ?? 'Authentication failed. Please login again.');
      case 403:
        throw AuthenticationException(errorMessage ?? 'Access denied');
      case 404:
        throw NotFoundException(errorMessage ?? 'Resource not found');
      case 422:
        throw ValidationException(errorMessage ?? 'Validation error');
      case 500:
      case 502:
      case 503:
        throw NetworkException(errorMessage ?? 'Server error. Please try again later.');
      default:
        throw NetworkException(
          errorMessage ?? 'Request failed with status ${response.statusCode}',
        );
    }
  }

  /// Handle network connection errors consistently
  Never _handleConnectionError(dynamic error, String endpoint) {
    final errorStr = error.toString();
    if (errorStr.contains('Connection refused') || 
        errorStr.contains('Failed host lookup') ||
        errorStr.contains('SocketException')) {
      throw NetworkException(
        'Cannot connect to backend server. Please ensure the backend is running at ${ApiConfig.baseUrl}',
      );
    }
    throw NetworkException('Network request failed: ${error.toString()}');
  }

  /// GET request
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? queryParams,
    bool includeAuth = true,
  }) async {
    try {
      var url = ApiConfig.buildUrl(endpoint);
      if (queryParams != null && queryParams.isNotEmpty) {
        final uri = Uri.parse(url);
        url = uri.replace(queryParameters: queryParams).toString();
      }

      Logger.debug('GET $url');

      final response = await _client.get(
        Uri.parse(url),
        headers: await _getHeaders(includeAuth: includeAuth),
      );

      _handleResponse(response);

      if (response.body.isEmpty) {
        return {};
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e, stackTrace) {
      Logger.error('GET request failed: $endpoint', error: e, stackTrace: stackTrace);
      if (e is AppException) {
        rethrow;
      }
      _handleConnectionError(e, endpoint);
    }
  }

  /// GET request returning a list
  Future<List<dynamic>> getList(
    String endpoint, {
    Map<String, String>? queryParams,
    bool includeAuth = true,
  }) async {
    try {
      var url = ApiConfig.buildUrl(endpoint);
      if (queryParams != null && queryParams.isNotEmpty) {
        final uri = Uri.parse(url);
        url = uri.replace(queryParameters: queryParams).toString();
      }

      Logger.debug('GET $url');

      final response = await _client.get(
        Uri.parse(url),
        headers: await _getHeaders(includeAuth: includeAuth),
      );

      _handleResponse(response);

      if (response.body.isEmpty) {
        return [];
      }

      return jsonDecode(response.body) as List<dynamic>;
    } catch (e, stackTrace) {
      Logger.error('GET list request failed: $endpoint', error: e, stackTrace: stackTrace);
      if (e is AppException) {
        rethrow;
      }
      _handleConnectionError(e, endpoint);
    }
  }

  /// POST request
  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool includeAuth = true,
  }) async {
    try {
      final url = ApiConfig.buildUrl(endpoint);
      Logger.debug('POST $url');

      final response = await _client.post(
        Uri.parse(url),
        headers: await _getHeaders(includeAuth: includeAuth),
        body: jsonEncode(body),
      );

      _handleResponse(response);

      if (response.body.isEmpty) {
        return {};
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e, stackTrace) {
      Logger.error('POST request failed: $endpoint', error: e, stackTrace: stackTrace);
      if (e is AppException) {
        rethrow;
      }
      _handleConnectionError(e, endpoint);
    }
  }

  /// PUT request
  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body, {
    bool includeAuth = true,
  }) async {
    try {
      final url = ApiConfig.buildUrl(endpoint);
      Logger.debug('PUT $url');

      final response = await _client.put(
        Uri.parse(url),
        headers: await _getHeaders(includeAuth: includeAuth),
        body: jsonEncode(body),
      );

      _handleResponse(response);

      if (response.body.isEmpty) {
        return {};
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e, stackTrace) {
      Logger.error('PUT request failed: $endpoint', error: e, stackTrace: stackTrace);
      if (e is AppException) {
        rethrow;
      }
      _handleConnectionError(e, endpoint);
    }
  }

  /// DELETE request
  Future<void> delete(
    String endpoint, {
    bool includeAuth = true,
  }) async {
    try {
      final url = ApiConfig.buildUrl(endpoint);
      Logger.debug('DELETE $url');

      final response = await _client.delete(
        Uri.parse(url),
        headers: await _getHeaders(includeAuth: includeAuth),
      );

      _handleResponse(response);
    } catch (e, stackTrace) {
      Logger.error('DELETE request failed: $endpoint', error: e, stackTrace: stackTrace);
      if (e is AppException) {
        rethrow;
      }
      _handleConnectionError(e, endpoint);
    }
  }

  void dispose() {
    _client.close();
  }
}

