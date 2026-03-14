import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'app_release.dart';
import 'app_release_repository.dart';
import 'app_update_exception.dart';

class AppVersionInfo {
  const AppVersionInfo({required this.version, required this.buildNumber});

  final String version;
  final int buildNumber;

  String get label => '$version+$buildNumber';

  factory AppVersionInfo.fromPackageInfo(PackageInfo packageInfo) {
    return AppVersionInfo(
      version: packageInfo.version,
      buildNumber: int.tryParse(packageInfo.buildNumber) ?? 0,
    );
  }
}

class UpdateCheckResult {
  const UpdateCheckResult({
    required this.currentVersion,
    required this.latestRelease,
  });

  final AppVersionInfo currentVersion;
  final AppRelease? latestRelease;

  bool get hasUpdate =>
      latestRelease != null &&
      _compareReleaseToVersion(latestRelease!, currentVersion) > 0;
}

abstract class AppUpdateController {
  bool get supportsSelfUpdate;

  Future<UpdateCheckResult> checkForUpdates();

  Future<void> installUpdate(AppRelease release);
}

class DefaultAppUpdateController implements AppUpdateController {
  DefaultAppUpdateController({
    required AppReleaseRepository releaseRepository,
    http.Client? client,
  }) : _releaseRepository = releaseRepository,
       _client = client ?? http.Client();

  final AppReleaseRepository _releaseRepository;
  final http.Client _client;

  @override
  bool get supportsSelfUpdate =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<UpdateCheckResult> checkForUpdates() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final latestRelease = await _releaseRepository.fetchLatestAndroidRelease();

    return UpdateCheckResult(
      currentVersion: AppVersionInfo.fromPackageInfo(packageInfo),
      latestRelease: latestRelease,
    );
  }

  @override
  Future<void> installUpdate(AppRelease release) async {
    if (!supportsSelfUpdate) {
      throw const AppUpdateException(
        'Self-update is only available on Android builds.',
      );
    }

    final response = await _client.get(release.downloadUrl);
    if (response.statusCode != 200) {
      throw const AppUpdateException('Failed to download the update APK.');
    }

    final tempDirectory = await getTemporaryDirectory();
    final apkFile = File('${tempDirectory.path}/${release.fileName}');
    await apkFile.writeAsBytes(response.bodyBytes, flush: true);

    final result = await OpenFile.open(
      apkFile.path,
      type: 'application/vnd.android.package-archive',
    );
    if (result.type != ResultType.done) {
      throw AppUpdateException(
        result.message.isEmpty
            ? 'Failed to open the update installer.'
            : result.message,
      );
    }
  }
}

int _compareReleaseToVersion(
  AppRelease release,
  AppVersionInfo currentVersion,
) {
  final versionComparison = _compareVersionStrings(
    release.version,
    currentVersion.version,
  );
  if (versionComparison != 0) {
    return versionComparison;
  }

  return release.buildNumber.compareTo(currentVersion.buildNumber);
}

int _compareVersionStrings(String left, String right) {
  final leftParts = left.split('.');
  final rightParts = right.split('.');
  final segmentCount = leftParts.length > rightParts.length
      ? leftParts.length
      : rightParts.length;

  for (var index = 0; index < segmentCount; index++) {
    final leftValue = index < leftParts.length
        ? _parseVersionPart(leftParts[index])
        : 0;
    final rightValue = index < rightParts.length
        ? _parseVersionPart(rightParts[index])
        : 0;
    final comparison = leftValue.compareTo(rightValue);
    if (comparison != 0) {
      return comparison;
    }
  }

  return 0;
}

int _parseVersionPart(String value) {
  final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
  return int.tryParse(digitsOnly) ?? 0;
}
