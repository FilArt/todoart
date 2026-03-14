import 'app_release.dart';

abstract class AppReleaseRepository {
  Future<AppRelease?> fetchLatestAndroidRelease();
}
