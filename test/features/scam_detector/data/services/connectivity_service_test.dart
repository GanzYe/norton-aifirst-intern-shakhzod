import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:scam_message_detector/features/scam_detector/data/services/connectivity_service.dart';

import '../../../../support/mocks.mocks.dart';

void main() {
  late MockConnectivity connectivity;
  late ConnectivityService service;

  setUp(() {
    connectivity = MockConnectivity();
    service = ConnectivityService(connectivity: connectivity);
  });

  group('ConnectivityService.isOnline', () {
    test('returns true on wifi', () async {
      when(
        connectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.wifi]);
      expect(await service.isOnline(), isTrue);
    });

    test('returns true on mobile', () async {
      when(
        connectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.mobile]);
      expect(await service.isOnline(), isTrue);
    });

    test('returns true on ethernet', () async {
      when(
        connectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.ethernet]);
      expect(await service.isOnline(), isTrue);
    });

    test('returns false when only "none" is reported', () async {
      when(
        connectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.none]);
      expect(await service.isOnline(), isFalse);
    });

    test('returns false when only "bluetooth" is reported', () async {
      when(
        connectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.bluetooth]);
      expect(await service.isOnline(), isFalse);
    });

    test('returns true if at least one transport is connected', () async {
      when(connectivity.checkConnectivity()).thenAnswer(
        (_) async => [ConnectivityResult.bluetooth, ConnectivityResult.wifi],
      );
      expect(await service.isOnline(), isTrue);
    });
  });
}
