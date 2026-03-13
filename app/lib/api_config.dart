import 'package:flutter/foundation.dart';

String resolveTodoApiBaseUrl() {
  const configuredBaseUrl = String.fromEnvironment('TODO_API_BASE_URL');
  if (configuredBaseUrl.isNotEmpty) {
    return configuredBaseUrl;
  }

  return switch (defaultTargetPlatform) {
    TargetPlatform.android => 'http://10.0.2.2:8000',
    _ => 'http://127.0.0.1:8000',
  };
}
