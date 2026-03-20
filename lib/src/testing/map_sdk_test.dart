import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Ajusta el import al nombre de tu paquete
import '../models/models.dart';
import '../testing/fake_map_controller_adapter.dart';

void main() {
  // ── MapLatLng ──────────────────────────────────────────────
  group('MapLatLng', () {
    test('equality', () {
      const a = MapLatLng(10.0, 20.0);
      const b = MapLatLng(10.0, 20.0);
      const c = MapLatLng(10.0, 21.0);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('distanceInMetersTo returns ~0 for same point', () {
      const p = MapLatLng(0.0, 0.0);
      expect(p.distanceInMetersTo(p), closeTo(0.0, 0.01));
    });

    test('distanceInMetersTo between known points', () {
      // Quito vs Guayaquil ≈ 420 km
      const quito = MapLatLng(-0.2299, -78.5249);
      const guayaquil = MapLatLng(-2.1894, -79.8891);
      final dist = quito.distanceInMetersTo(guayaquil);
      expect(dist, greaterThan(300000));
      expect(dist, lessThan(500000));
    });

    test('copyWith preserves unchanged fields', () {
      const a = MapLatLng(1.0, 2.0);
      final b = a.copyWith(longitude: 99.0);
      expect(b.latitude, equals(1.0));
      expect(b.longitude, equals(99.0));
    });

    test('toJson / fromJson roundtrip', () {
      const a = MapLatLng(3.14, -1.59);
      final json = a.toJson();
      final b = MapLatLng.fromJson(json);
      expect(b, equals(a));
    });
  });

  // ── MapLatLngBounds ────────────────────────────────────────
  group('MapLatLngBounds', () {
    test('fromPoints computes correct min/max', () {
      final points = [
        const MapLatLng(1.0, -1.0),
        const MapLatLng(3.0, 2.0),
        const MapLatLng(-2.0, 5.0),
      ];
      final bounds = MapLatLngBounds.fromPoints(points);
      expect(bounds.southwest, equals(const MapLatLng(-2.0, -1.0)));
      expect(bounds.northeast, equals(const MapLatLng(3.0, 5.0)));
    });

    test('fromPoints throws on empty list', () {
      expect(() => MapLatLngBounds.fromPoints([]), throwsArgumentError);
    });

    test('contains returns true for interior point', () {
      final bounds = MapLatLngBounds(
        northeast: const MapLatLng(10.0, 10.0),
        southwest: const MapLatLng(-10.0, -10.0),
      );
      expect(bounds.contains(const MapLatLng(0.0, 0.0)), isTrue);
      expect(bounds.contains(const MapLatLng(11.0, 0.0)), isFalse);
    });

    test('center returns midpoint', () {
      final bounds = MapLatLngBounds(
        northeast: const MapLatLng(10.0, 10.0),
        southwest: const MapLatLng(0.0, 0.0),
      );
      expect(bounds.center, equals(const MapLatLng(5.0, 5.0)));
    });
  });

  // ── MapCameraPosition ──────────────────────────────────────
  group('MapCameraPosition', () {
    test('copyWith updates only specified fields', () {
      const pos = MapCameraPosition(
          target: MapLatLng(1.0, 2.0), zoom: 10.0, bearing: 45.0);
      final updated = pos.copyWith(zoom: 16.0);
      expect(updated.zoom, 16.0);
      expect(updated.bearing, 45.0);
      expect(updated.target, const MapLatLng(1.0, 2.0));
    });

    test('toJson / fromJson roundtrip', () {
      const pos = MapCameraPosition(
          target: MapLatLng(4.5, -74.1), zoom: 12.0, tilt: 30.0);
      final json = pos.toJson();
      final restored = MapCameraPosition.fromJson(json);
      expect(restored.target, equals(pos.target));
      expect(restored.zoom, equals(pos.zoom));
      expect(restored.tilt, equals(pos.tilt));
    });
  });

  // ── MapMarker ──────────────────────────────────────────────
  group('MapMarker', () {
    test('equality is id-based', () {
      const a = MapMarker(id: 'x', position: MapLatLng(0, 0));
      const b = MapMarker(id: 'x', position: MapLatLng(99, 99));
      const c = MapMarker(id: 'y', position: MapLatLng(0, 0));
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('copyWith does not mutate original', () {
      const original = MapMarker(
          id: 'a', position: MapLatLng(1, 2), rotation: 45.0);
      final copy = original.copyWith(rotation: 90.0);
      expect(original.rotation, 45.0);
      expect(copy.rotation, 90.0);
    });
  });

  // ── MapPolyline ────────────────────────────────────────────
  group('MapPolyline', () {
    test('equality is id-based', () {
      final a = MapPolyline(id: 'route', points: [const MapLatLng(0, 0)]);
      final b = MapPolyline(id: 'route', points: [const MapLatLng(99, 99)]);
      expect(a, equals(b));
    });
  });

  // ── FakeMapControllerAdapter ───────────────────────────────
  group('FakeMapControllerAdapter', () {
    late FakeMapControllerAdapter adapter;
    late Map<String, MapMarker> markerCache;
    late Set<MapPolyline> polylineCache;
    late Set<MapCircle> circleCache;

    setUp(() {
      adapter = FakeMapControllerAdapter();
      markerCache = {};
      polylineCache = {};
      circleCache = {};
    });

    test('addOrUpdateMarker stores in cache and records call', () async {
      final marker = const MapMarker(id: 'm1', position: MapLatLng(1.0, 2.0));
      await adapter.addOrUpdateMarker(marker, markerCache: markerCache);

      expect(markerCache['m1'], equals(marker));
      expect(adapter.wasCalled('addOrUpdateMarker:m1'), isTrue);
      expect(adapter.addedMarkers, contains(marker));
    });

    test('removeMarker removes from cache', () async {
      markerCache['m1'] =
          const MapMarker(id: 'm1', position: MapLatLng(0, 0));
      await adapter.removeMarker('m1', markerCache: markerCache);

      expect(markerCache.containsKey('m1'), isFalse);
      expect(adapter.removedMarkerIds, contains('m1'));
    });

    test('removeMarkersNotIn keeps only specified ids', () async {
      markerCache['a'] = const MapMarker(id: 'a', position: MapLatLng(0, 0));
      markerCache['b'] = const MapMarker(id: 'b', position: MapLatLng(1, 1));
      markerCache['c'] = const MapMarker(id: 'c', position: MapLatLng(2, 2));

      await adapter.removeMarkersNotIn(
        markerCache: markerCache,
        idsToKeep: ['a', 'c'],
      );

      expect(markerCache.keys, containsAll(['a', 'c']));
      expect(markerCache.containsKey('b'), isFalse);
    });

    test('removeAllMarkers clears cache', () async {
      markerCache['a'] = const MapMarker(id: 'a', position: MapLatLng(0, 0));
      markerCache['b'] = const MapMarker(id: 'b', position: MapLatLng(1, 1));

      await adapter.removeAllMarkers(markerCache: markerCache);

      expect(markerCache, isEmpty);
      expect(adapter.wasCalled('removeAllMarkers'), isTrue);
    });

    test('addOrUpdatePolyline stores in cache', () async {
      final polyline = MapPolyline(
        id: 'p1',
        points: [const MapLatLng(0, 0), const MapLatLng(1, 1)],
      );
      await adapter.addOrUpdatePolyline(polyline, polylineCache: polylineCache);

      expect(polylineCache.any((p) => p.id == 'p1'), isTrue);
    });

    test('addOrUpdateCircle stores in cache', () async {
      final circle = const MapCircle(
        id: 'c1',
        center: MapLatLng(0, 0),
        radius: 100,
      );
      await adapter.addOrUpdateCircle(circle, circleCache: circleCache);

      expect(circleCache.any((c) => c.id == 'c1'), isTrue);
    });

    test('simulateDisposed causes getLatLngFromScreen to throw', () async {
      adapter.simulateDisposed = true;
      expect(
        () => adapter.getLatLngFromScreen(const MapScreenCoordinate(x: 0, y: 0)),
        throwsStateError,
      );
    });

    test('getZoomLevel returns simulatedZoom', () async {
      adapter.simulatedZoom = 18.0;
      final zoom = await adapter.getZoomLevel();
      expect(zoom, equals(18.0));
    });

    test('animateCameraTo updates cameraPosition', () async {
      const target = MapLatLng(5.0, 6.0);
      await adapter.animateCameraTo(target);
      expect(adapter.cameraPosition.target, equals(target));
    });

    test('reset clears all recorded state', () async {
      await adapter.addOrUpdateMarker(
        const MapMarker(id: 'x', position: MapLatLng(0, 0)),
        markerCache: markerCache,
      );
      adapter.reset();

      expect(adapter.calls, isEmpty);
      expect(adapter.addedMarkers, isEmpty);
    });

    test('callCount counts correctly', () async {
      final m1 = const MapMarker(id: '1', position: MapLatLng(0, 0));
      final m2 = const MapMarker(id: '2', position: MapLatLng(1, 1));

      await adapter.addOrUpdateMarker(m1, markerCache: markerCache);
      await adapter.addOrUpdateMarker(m2, markerCache: markerCache);

      expect(adapter.callCount('addOrUpdateMarker'), equals(2));
    });
  });

  // ── MapCircle ──────────────────────────────────────────────
  group('MapCircle', () {
    test('copyWith preserves fields', () {
      const c = MapCircle(id: 'x', center: MapLatLng(0, 0), radius: 50.0);
      final updated = c.copyWith(radius: 200.0);
      expect(updated.radius, 200.0);
      expect(updated.id, 'x');
    });

    test('equality is id-based', () {
      const a = MapCircle(id: 'id', center: MapLatLng(0, 0), radius: 10);
      const b = MapCircle(id: 'id', center: MapLatLng(99, 99), radius: 999);
      expect(a, equals(b));
    });
  });

  // ── MapPolygon ─────────────────────────────────────────────
  group('MapPolygon', () {
    test('default fillColor has low opacity', () {
      const p = MapPolygon(
        id: 'poly',
        points: [MapLatLng(0, 0), MapLatLng(1, 0), MapLatLng(1, 1)],
      );
      expect(p.fillColor.opacity, lessThan(0.2));
    });

    test('copyWith updates strokeWidth', () {
      const p = MapPolygon(
        id: 'p',
        points: [MapLatLng(0, 0), MapLatLng(1, 0), MapLatLng(0, 1)],
        strokeWidth: 2,
      );
      expect(p.copyWith(strokeWidth: 8).strokeWidth, equals(8));
    });
  });
}
