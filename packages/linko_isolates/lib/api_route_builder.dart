import 'package:linko_isolates/model/device.dart';

/// Type-safe API paths
enum ApiRoute {
  info('/v1/node/status'),
  register('/v1/node/handshake'),
  prepareUpload('/v1/transfer/initiate'),
  upload('/v1/transfer/stream'),
  cancel('/v1/transfer/abort'),
  show('/v1/system/bring-to-front'),
  prepareDownload('/v1/download/initiate'),
  download('/v1/download/stream'),
  ;

  const ApiRoute(this.path);

  final String path;

  /// The server url for v1
  String get v1 => path;

  /// The server url for v2
  String get v2 => path;

  /// The client url
  String target(Device target, {Map<String, String>? query}) {
    return Uri(
      scheme: target.https ? 'https' : 'http',
      host: target.ip,
      port: target.port,
      path: target.version == '1.0' ? v1 : v2,
      queryParameters: query,
    ).toString();
  }

  /// The client url for polling
  String targetRaw(String ip, int port, bool https, String version) {
    final protocol = https ? 'https' : 'http';
    final route = version == '1.0' ? v1 : v2;
    return '$protocol://$ip:$port$route';
  }
}
