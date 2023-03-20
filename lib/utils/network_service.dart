import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:retry/retry.dart';

class NetworkService {
  final int maxTries = 3;
  final FutureOr<void> Function(Exception)? onRetryFunc;

  NetworkService(this.onRetryFunc);

  Future<Result<Response, Exception>> perform(
      FutureOr<Response> Function() func) async {
    Response resp;
    final r = RetryOptions(maxAttempts: 3);

    try {
      resp = await r.retry(
        func,
        retryIf: (e) => e is SocketException || e is TimeoutException,
        onRetry: (e) => onRetryFunc,
      );
    } catch (e) {
      return Error(e as Exception);
    }

    return Success(resp);
  }
}
