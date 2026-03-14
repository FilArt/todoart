import 'package:flutter/foundation.dart';

const _configuredTodoApiBaseUrl = String.fromEnvironment('TODO_API_BASE_URL');

String resolveTodoApiBaseUrl() {
  if (_configuredTodoApiBaseUrl.isNotEmpty) {
    return _configuredTodoApiBaseUrl;
  }

  return switch (defaultTargetPlatform) {
    TargetPlatform.android => 'http://10.0.2.2:8000',
    _ => 'http://127.0.0.1:8000',
  };
}
