const String kDefaultApiBaseUrl = 'https://api.savantai.net';

/// Allows overriding the backend base URL at build time via:
/// flutter run --dart-define=API_BASE_URL=http://192.168.1.16:8000
const String apiBaseUrl =
    String.fromEnvironment('API_BASE_URL', defaultValue: kDefaultApiBaseUrl);

Uri apiUri(String path) {
  final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
  return Uri.parse('$apiBaseUrl/$normalizedPath');
}
