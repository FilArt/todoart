class AppRelease {
  const AppRelease({
    required this.version,
    required this.buildNumber,
    required this.notes,
    required this.downloadUrl,
    required this.publishedAt,
  });

  final String version;
  final int buildNumber;
  final String notes;
  final Uri downloadUrl;
  final DateTime publishedAt;

  String get label => '$version+$buildNumber';

  String get fileName {
    if (downloadUrl.pathSegments.isEmpty) {
      return 'todoart-update.apk';
    }

    return downloadUrl.pathSegments.last;
  }

  factory AppRelease.fromJson(Map<String, dynamic> json) {
    return AppRelease(
      version: json['version'] as String,
      buildNumber: json['build_number'] as int,
      notes: json['notes'] as String? ?? '',
      downloadUrl: Uri.parse(json['download_url'] as String),
      publishedAt: DateTime.parse(json['published_at'] as String),
    );
  }
}
