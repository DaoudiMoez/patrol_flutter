import 'package:dio/dio.dart';
import 'package:patrol_management/core/constants/apiConstants.dart';
import 'package:patrol_management/core/utils/logger.dart';

class DioClient {
  static Dio? _dio;

  static Dio get instance {
    if (_dio == null) {
      _dio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: ApiConstants.connectionTimeout,
          receiveTimeout: ApiConstants.receiveTimeout,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      // Add logging interceptor
      _dio!.interceptors.add(
        LogInterceptor(
          request: true,
          requestHeader: true,
          requestBody: true,
          responseHeader: true,
          responseBody: true,
          error: true,
          logPrint: (obj) => AppLogger.debug(obj.toString()),
        ),
      );

      // Add error handling interceptor
      _dio!.interceptors.add(
        InterceptorsWrapper(
          onError: (error, handler) {
            AppLogger.error('API Error', error);
            return handler.next(error);
          },
        ),
      );
    }
    return _dio!;
  }

  static void setApiKey(String apiKey) {
    _dio?.options.headers['X-API-KEY'] = apiKey;
  }

  static void clearApiKey() {
    _dio?.options.headers.remove('X-API-KEY');
  }
}