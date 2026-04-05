class AppUpdateManifest {
  const AppUpdateManifest({
    required this.versionName,
    required this.versionCode,
    required this.apkUri,
    this.releaseNotes,
    this.mandatory = false,
  });

  final String versionName;
  final int versionCode;
  final Uri apkUri;
  final String? releaseNotes;
  final bool mandatory;

  factory AppUpdateManifest.fromJson(Map<String, dynamic> json) {
    final versionName = (json['versionName'] as String? ?? '').trim();
    final versionCode = json['versionCode'];
    final apkUrl = (json['apkUrl'] as String? ?? '').trim();
    final releaseNotes = (json['releaseNotes'] as String?)?.trim();
    final mandatory = json['mandatory'] == true;
    final apkUri = Uri.tryParse(apkUrl);

    if (versionName.isEmpty) {
      throw const FormatException('versionName ausente no manifesto.');
    }

    if (versionCode is! int || versionCode <= 0) {
      throw const FormatException('versionCode invalido no manifesto.');
    }

    if (apkUri == null || !apkUri.isAbsolute || apkUri.scheme != 'https') {
      throw const FormatException('apkUrl deve ser uma URL https absoluta.');
    }

    return AppUpdateManifest(
      versionName: versionName,
      versionCode: versionCode,
      apkUri: apkUri,
      releaseNotes: releaseNotes == null || releaseNotes.isEmpty
          ? null
          : releaseNotes,
      mandatory: mandatory,
    );
  }
}
