import 'dart:convert';

import 'package:http/http.dart' as http;

import 'app_release.dart';
import 'app_release_repository.dart';
import 'app_update_exception.dart';

class HttpAppReleaseRepository implements AppReleaseRepository {
  HttpAppReleaseRepository({required String baseUrl, http.Client? client})
    : _baseUri = Uri.parse(baseUrl),
      _client = client ?? http.Client();

  final Uri _baseUri;
  final http.Client _client;

  Uri _uri(String path) => _baseUri.resolve(path);

  @override
  Future<AppRelease?> fetchLatestAndroidRelease() async {
    final response = await _client.get(_uri('/releases/android/latest'));

    if (response.statusCode == 404) {
      return null;
    }

    if (response.statusCode != 200) {
      throw const AppUpdateException('Failed to check for updates.');
    }

    return AppRelease.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}
