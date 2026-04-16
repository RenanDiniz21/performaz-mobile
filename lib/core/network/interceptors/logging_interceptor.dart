import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

class AppLoggingInterceptor extends Interceptor {
  final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _logger.i('${options.method} ${options.path}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _logger.d('${response.statusCode} ${response.requestOptions.path}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logger.e('${err.response?.statusCode} ${err.requestOptions.path}',
        error: err.message);
    handler.next(err);
  }
}
