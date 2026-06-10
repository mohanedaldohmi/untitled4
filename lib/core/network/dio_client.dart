import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../utils/logger.dart';

class DioClient {
  static DioClient? _instance;
  late final Dio _dio;

  DioClient._() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        sendTimeout: ApiConstants.sendTimeout,
        headers: {
          'User-Agent': ApiConstants.userAgent,
          'Accept': '*/*',
          'Accept-Language': 'en-US,en;q=0.9',
        },
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    _dio.interceptors.addAll([
      _LoggingInterceptor(),
      _RetryInterceptor(_dio),
    ]);
  }

  static DioClient get instance {
    _instance ??= DioClient._();
    return _instance!;
  }

  Dio get dio => _dio;

  Future<Response<T>> get<T>(
    String url, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.get<T>(
      url,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> post<T>(
    String url, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.post<T>(
      url,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<void> download(
    String url,
    String savePath, {
    ProgressCallback? onReceiveProgress,
    CancelToken? cancelToken,
    Options? options,
    int? startByte,
  }) async {
    final mergedOptions = options ?? Options();
    if (startByte != null && startByte > 0) {
      mergedOptions.headers ??= {};
      mergedOptions.headers!['Range'] = 'bytes=$startByte-';
    }

    await _dio.download(
      url,
      savePath,
      onReceiveProgress: onReceiveProgress,
      cancelToken: cancelToken,
      options: mergedOptions,
      deleteOnError: false,
    );
  }

  Future<int?> getContentLength(String url) async {
    try {
      final response = await _dio.head(url);
      final contentLength = response.headers.value('content-length');
      return contentLength != null ? int.tryParse(contentLength) : null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> supportsRangeRequests(String url) async {
    try {
      final response = await _dio.head(url);
      final acceptRanges = response.headers.value('accept-ranges');
      return acceptRanges == 'bytes';
    } catch (_) {
      return false;
    }
  }
}

class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    AppLogger.debug('[HTTP] ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    AppLogger.debug(
      '[HTTP] Response ${response.statusCode} ${response.requestOptions.uri}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppLogger.error(
      '[HTTP] Error ${err.type.name}: ${err.message}',
      err,
      err.stackTrace,
    );
    handler.next(err);
  }
}

class _RetryInterceptor extends Interceptor {
  _RetryInterceptor(this._dio);

  final Dio _dio;
  static const int _maxRetries = ApiConstants.maxRetries;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final requestOptions = err.requestOptions;
    final retryCount = requestOptions.extra['retryCount'] as int? ?? 0;

    final shouldRetry = retryCount < _maxRetries &&
        (err.type == DioExceptionType.connectionTimeout ||
            err.type == DioExceptionType.receiveTimeout ||
            err.type == DioExceptionType.connectionError);

    if (shouldRetry) {
      requestOptions.extra['retryCount'] = retryCount + 1;
      AppLogger.debug(
        '[HTTP] Retrying request (${retryCount + 1}/$_maxRetries): ${requestOptions.uri}',
      );

      await Future.delayed(
        Duration(seconds: ApiConstants.retryDelay.inSeconds * (retryCount + 1)),
      );

      try {
        final response = await _dio.request<dynamic>(
          requestOptions.path,
          options: Options(
            method: requestOptions.method,
            headers: requestOptions.headers,
            extra: requestOptions.extra,
          ),
          data: requestOptions.data,
          queryParameters: requestOptions.queryParameters,
        );
        handler.resolve(response);
        return;
      } catch (e) {
        // Fall through to next error handler
      }
    }

    handler.next(err);
  }
}
