import 'dart:math';
import 'package:dio/dio.dart';

class RetryPolicy {
  final int maxRetries;
  final List<int> statusCodesToRetry;
  final List<DioExceptionType> errorTypesToRetry;
  final bool exponentialBackoff;
  final Duration initialBackoff;
  final Duration maxBackoff;
  final double backoffFactor;
  final bool randomizationFactor;

  const RetryPolicy({
    this.maxRetries = 3,
    this.statusCodesToRetry = const [408, 429, 500, 502, 503, 504],
    this.errorTypesToRetry = const [
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.connectionError,
    ],
    this.exponentialBackoff = true,
    this.initialBackoff = const Duration(milliseconds: 500),
    this.maxBackoff = const Duration(seconds: 30),
    this.backoffFactor = 2.0,
    this.randomizationFactor = true,
  });

  bool shouldRetry(DioException error, int currentRetry) {
    // If we've hit the max retries, don't retry
    if (currentRetry >= maxRetries) {
      return false;
    }

    // Check status code
    if (error.response != null &&
        statusCodesToRetry.contains(error.response!.statusCode)) {
      return true;
    }

    // Check error type
    if (errorTypesToRetry.contains(error.type)) {
      return true;
    }

    return false;
  }

  Duration getRetryDelay(int currentRetry) {
    if (!exponentialBackoff) {
      return initialBackoff;
    }

    // Calculate exponential backoff
    final exponentialDelay = initialBackoff.inMilliseconds *
        pow(backoffFactor, currentRetry).toInt();

    // Apply jitter if enabled (helps prevent thundering herd)
    int delayMs = exponentialDelay;
    if (randomizationFactor) {
      final jitter = Random().nextDouble() * 0.3 + 0.85; // 0.85-1.15
      delayMs = (exponentialDelay * jitter).toInt();
    }

    // Cap at max backoff
    delayMs = min(delayMs, maxBackoff.inMilliseconds);

    return Duration(milliseconds: delayMs);
  }
}
