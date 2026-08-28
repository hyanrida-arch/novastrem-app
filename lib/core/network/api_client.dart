import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';

/// Thin wrapper around [Dio] so every data source shares one configured
/// HTTP client (timeouts, logging interceptor, base error surface) instead
/// of constructing its own.
class ApiClient {
  final Dio dio;

  ApiClient({Dio? dio})
      : dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: AppConstants.connectTimeout,
                receiveTimeout: AppConstants.receiveTimeout,
                // Xtream panels are notoriously inconsistent about
                // Content-Type headers (some send text/html for JSON), so we
                // parse the body ourselves rather than let Dio guess.
                responseType: ResponseType.plain,
                // Some panels reject requests carrying Dio's default
                // "dart/x.x (dart:io)" User-Agent as bot traffic — a plain
                // custom UA is usually enough to get past that filter.
                headers: {'User-Agent': AppConstants.userAgent},
              ),
            ) {
    this.dio.interceptors.add(
          LogInterceptor(
            requestBody: false,
            responseBody: false,
            // Was `(_) {}`, which threw away every HTTP diagnostic and made
            // provider failures impossible to diagnose from a device. Debug
            // builds now print; release stays silent.
            logPrint: (obj) {
              if (!kDebugMode) return;
              // Xtream puts the account's username and password in the query
              // string, so never let a raw URI reach the log.
              final line = obj.toString().replaceAllMapped(
                    RegExp(r'(username|password)=([^&\s]*)'),
                    (m) => '${m[1]}=***',
                  );
              debugPrint('[NovaStream/http] $line');
            },
          ),
        );
  }

  Future<Response<String>> get(Uri uri) {
    return dio.getUri<String>(uri);
  }
}
