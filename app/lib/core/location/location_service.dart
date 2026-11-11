import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 위도·경도.
class GeoPoint {
  final double latitude;
  final double longitude;

  const GeoPoint(this.latitude, this.longitude);

  /// 두 지점 사이 직선거리(km, 하버사인 공식). 도로 거리가 아니다.
  double distanceKmTo(GeoPoint other) {
    const earthKm = 6371.0;
    double rad(double d) => d * math.pi / 180;
    final dLat = rad(other.latitude - latitude);
    final dLng = rad(other.longitude - longitude);
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(latitude)) *
            math.cos(rad(other.latitude)) *
            math.pow(math.sin(dLng / 2), 2);
    return 2 * earthKm * math.asin(math.sqrt(a));
  }
}

/// 현재 위치. 이름(예: '충남 천안시')은 화면 안내용이다.
class CurrentLocation {
  final GeoPoint point;
  final String label;
  final bool isDemo;

  const CurrentLocation(
      {required this.point, required this.label, this.isDemo = false});
}

/// 내 위치를 알려 준다. 웹(브라우저 위치)·앱(기기 GPS)은 권한·구현이 달라
/// 이 인터페이스 뒤에서 따로 연결한다. 위치를 못 얻으면 null.
abstract interface class LocationService {
  Future<CurrentLocation?> currentLocation();
}

/// 실제 위치 연결 전 시연용: 항상 같은 위치를 돌려준다.
class DemoLocationService implements LocationService {
  const DemoLocationService();

  @override
  Future<CurrentLocation?> currentLocation() async => const CurrentLocation(
        point: GeoPoint(36.8151, 127.1139),
        label: '충남 천안시',
        isDemo: true,
      );
}

final locationServiceProvider =
    Provider<LocationService>((ref) => const DemoLocationService());

final currentLocationProvider = FutureProvider<CurrentLocation?>(
    (ref) => ref.watch(locationServiceProvider).currentLocation());
