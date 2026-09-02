import 'package:linko_isolates/api_route_builder.dart';
import 'package:linko_isolates/model/device.dart';
import 'package:test/test.dart';

void main() {
  group('ApiRoute server urls', () {
    test('register', () {
      expect(ApiRoute.register.v1, '/v1/node/handshake');
      expect(ApiRoute.register.v2, '/v1/node/handshake');
    });

    test('prepareUpload', () {
      expect(ApiRoute.prepareUpload.v1, '/v1/transfer/initiate');
      expect(ApiRoute.prepareUpload.v2, '/v1/transfer/initiate');
    });
  });

  group('ApiRoute typed client urls', () {
    test('register', () {
      expect(ApiRoute.register.target(_target(version: '1.0', https: false)), 'http://0.0.0.0:8080/v1/node/handshake');
      expect(ApiRoute.register.target(_target(version: '1.0', https: true)), 'https://0.0.0.0:8080/v1/node/handshake');
      expect(ApiRoute.register.target(_target(version: '2.0', https: false)), 'http://0.0.0.0:8080/v1/node/handshake');
      expect(ApiRoute.register.target(_target(version: '2.0', https: true)), 'https://0.0.0.0:8080/v1/node/handshake');
    });

    test('prepareUpload', () {
      expect(ApiRoute.prepareUpload.target(_target(version: '1.0', https: false)), 'http://0.0.0.0:8080/v1/transfer/initiate');
      expect(ApiRoute.prepareUpload.target(_target(version: '1.0', https: true)), 'https://0.0.0.0:8080/v1/transfer/initiate');
      expect(ApiRoute.prepareUpload.target(_target(version: '2.0', https: false)), 'http://0.0.0.0:8080/v1/transfer/initiate');
      expect(ApiRoute.prepareUpload.target(_target(version: '2.0', https: true)), 'https://0.0.0.0:8080/v1/transfer/initiate');
    });
  });

  group('ApiRoute raw client urls', () {
    test('register', () {
      expect(ApiRoute.register.targetRaw('0.0.0.0', 8080, false, '1.0'), 'http://0.0.0.0:8080/v1/node/handshake');
      expect(ApiRoute.register.targetRaw('0.0.0.0', 8080, true, '1.0'), 'https://0.0.0.0:8080/v1/node/handshake');
      expect(ApiRoute.register.targetRaw('0.0.0.0', 8080, false, '2.0'), 'http://0.0.0.0:8080/v1/node/handshake');
      expect(ApiRoute.register.targetRaw('0.0.0.0', 8080, true, '2.0'), 'https://0.0.0.0:8080/v1/node/handshake');
    });
  });
}

Device _target({
  required String version,
  required bool https,
}) {
  return Device(
    signalingId: null,
    ip: '0.0.0.0',
    version: version,
    port: 8080,
    https: https,
    fingerprint: 'fingerprint',
    alias: 'alias',
    deviceModel: 'deviceModel',
    deviceType: DeviceType.desktop,
    download: false,
    channels: [],
  );
}
