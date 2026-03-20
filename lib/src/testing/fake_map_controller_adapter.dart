import 'package:map_adapter_sdk/src/adapters/map_controller_adapter.dart';

import '../models/models.dart';

/// Implementación falsa de [MapControllerAdapter] para pruebas unitarias.
///
/// No requiere ninguna dependencia de Google Maps o Mapbox.
/// Registra todas las llamadas recibidas para poder hacer aserciones en tests.
///
/// Ejemplo de uso:
/// ```dart
/// void main() {
///   test('addOrUpdateMarker stores marker in cache', () async {
///     final adapter = FakeMapControllerAdapter();
///     final cache = <String, MapMarker>{};
///     final marker = MapMarker(id: 'test', position: MapLatLng(0, 0));
///
///     await adapter.addOrUpdateMarker(marker, markerCache: cache);
///
///     expect(cache['test'], equals(marker));
///     expect(adapter.calls, contains('addOrUpdateMarker:test'));
///   });
/// }
/// ```
class FakeMapControllerAdapter implements MapControllerAdapter {
  // ── Registro de llamadas ───────────────────────────────────

  /// Lista de todas las operaciones llamadas. Útil para verificar en tests.
  final List<String> calls = [];

  /// Historial completo de marcadores añadidos/actualizados.
  final List<MapMarker> addedMarkers = [];

  /// Historial de IDs de marcadores eliminados.
  final List<String> removedMarkerIds = [];

  /// Historial de polilíneas añadidas.
  final List<MapPolyline> addedPolylines = [];

  /// Historial de polígonos añadidos.
  final List<MapPolygon> addedPolygons = [];

  /// Historial de círculos añadidos.
  final List<MapCircle> addedCircles = [];

  /// Posición actual simulada de la cámara.
  MapCameraPosition cameraPosition = const MapCameraPosition(
    target: MapLatLng(0.0, 0.0),
    zoom: 15.0,
  );

  /// Zoom simulado devuelto por [getZoomLevel].
  double simulatedZoom = 15.0;

  /// Región visible simulada devuelta por [getVisibleRegion].
  MapLatLngBounds simulatedVisibleRegion = MapLatLngBounds(
    northeast: const MapLatLng(1.0, 1.0),
    southwest: const MapLatLng(-1.0, -1.0),
  );

  /// Si `true`, [getLatLngFromScreen] y [getScreenCoordinateFromLatLng] lanzarán
  /// un [StateError] simulando un controlador destruido.
  bool simulateDisposed = false;

  // ── Config ─────────────────────────────────────────────────

  @override
  bool get isMapbox => false;

  // ── Ciclo de vida ──────────────────────────────────────────

  @override
  Future<void> dispose() async => calls.add('dispose');

  @override
  Future<void> initManagers() async => calls.add('initManagers');

  @override
  Future<void> disposeManager() async => calls.add('disposeManager');

  // ── Cámara ─────────────────────────────────────────────────

  @override
  Future<void> animateCameraToLatLngZoom(MapLatLng target, double zoom) async {
    calls.add('animateCameraToLatLngZoom:${target.latitude},${target.longitude},z$zoom');
    cameraPosition = MapCameraPosition(target: target, zoom: zoom);
  }

  @override
  Future<void> animateCameraToLatLngBounds(
      MapLatLngBounds bounds, double padding) async {
    calls.add('animateCameraToLatLngBounds:padding=$padding');
    cameraPosition = MapCameraPosition(target: bounds.center, zoom: 14.0);
  }

  @override
  Future<void> animateCameraTo(MapLatLng target) async {
    calls.add('animateCameraTo:${target.latitude},${target.longitude}');
    cameraPosition = cameraPosition.copyWith(target: target);
  }

  @override
  Future<void> animateToCameraPosition(MapCameraPosition pos) async {
    calls.add('animateToCameraPosition:z${pos.zoom}');
    cameraPosition = pos;
  }

  @override
  Future<void> moveCameraToLatLngZoom(MapLatLng target, double zoom) async {
    calls.add('moveCameraToLatLngZoom:${target.latitude},${target.longitude},z$zoom');
    cameraPosition = MapCameraPosition(target: target, zoom: zoom);
  }

  // ── Estilos ────────────────────────────────────────────────

  @override
  Future<void> setMapStyle(String? mapStyle) async {
    calls.add('setMapStyle:${mapStyle?.length ?? 0}chars');
  }

  // ── Coordenadas ────────────────────────────────────────────

  @override
  Future<MapLatLng> getLatLngFromScreen(
      MapScreenCoordinate screenCoordinate) async {
    if (simulateDisposed) throw StateError('Fake adapter is disposed');
    calls.add('getLatLngFromScreen:${screenCoordinate.x},${screenCoordinate.y}');
    // Devuelve el centro de la cámara simulada como aproximación.
    return cameraPosition.target;
  }

  @override
  Future<MapScreenCoordinate> getScreenCoordinateFromLatLng(
      MapLatLng latLng) async {
    if (simulateDisposed) throw StateError('Fake adapter is disposed');
    calls.add('getScreenCoordinateFromLatLng:${latLng.latitude},${latLng.longitude}');
    return const MapScreenCoordinate(x: 100, y: 200);
  }

  @override
  Future<double> getZoomLevel() async {
    calls.add('getZoomLevel');
    return simulatedZoom;
  }

  @override
  Future<MapLatLngBounds> getVisibleRegion() async {
    calls.add('getVisibleRegion');
    return simulatedVisibleRegion;
  }

  // ── Info Window ────────────────────────────────────────────

  @override
  Future<void> showMarkerInfoWindow(String markerId) async {
    calls.add('showMarkerInfoWindow:$markerId');
  }

  // ── Marcadores ─────────────────────────────────────────────

  @override
  Future<void> addOrUpdateMarker(
    MapMarker marker, {
    required Map<String, MapMarker> markerCache,
  }) async {
    calls.add('addOrUpdateMarker:${marker.id}');
    addedMarkers.add(marker);
    markerCache[marker.id] = marker;
  }

  @override
  Future<void> removeMarker(
    String markerId, {
    required Map<String, MapMarker> markerCache,
  }) async {
    calls.add('removeMarker:$markerId');
    removedMarkerIds.add(markerId);
    markerCache.remove(markerId);
  }

  @override
  Future<void> removeAllMarkers({
    required Map<String, MapMarker> markerCache,
  }) async {
    calls.add('removeAllMarkers');
    removedMarkerIds.addAll(markerCache.keys);
    markerCache.clear();
  }

  @override
  Future<void> removeMarkersNotIn({
    required Map<String, MapMarker> markerCache,
    required Iterable<String> idsToKeep,
  }) async {
    final keepSet = idsToKeep.toSet();
    final toRemove =
        markerCache.keys.where((id) => !keepSet.contains(id)).toList();
    calls.add('removeMarkersNotIn:removed=${toRemove.length}');
    removedMarkerIds.addAll(toRemove);
    markerCache.removeWhere((id, _) => !keepSet.contains(id));
  }

  // ── Polilíneas ─────────────────────────────────────────────

  @override
  Future<void> addOrUpdatePolyline(
    MapPolyline polyline, {
    required Set<MapPolyline> polylineCache,
  }) async {
    calls.add('addOrUpdatePolyline:${polyline.id}');
    addedPolylines.add(polyline);
    polylineCache.removeWhere((p) => p.id == polyline.id);
    polylineCache.add(polyline);
  }

  @override
  Future<void> removePolyline(
    String polylineId, {
    required Set<MapPolyline> polylineCache,
  }) async {
    calls.add('removePolyline:$polylineId');
    polylineCache.removeWhere((p) => p.id == polylineId);
  }

  @override
  Future<void> removeAllPolylines({
    required Set<MapPolyline> polylineCache,
  }) async {
    calls.add('removeAllPolylines');
    polylineCache.clear();
  }

  // ── Polígonos ──────────────────────────────────────────────

  @override
  Future<void> addOrUpdatePolygon(
    MapPolygon polygon, {
    required Set<MapPolygon> polygonCache,
  }) async {
    calls.add('addOrUpdatePolygon:${polygon.id}');
    addedPolygons.add(polygon);
    polygonCache.removeWhere((p) => p.id == polygon.id);
    polygonCache.add(polygon);
  }

  @override
  Future<void> removePolygon(
    String polygonId, {
    required Set<MapPolygon> polygonCache,
  }) async {
    calls.add('removePolygon:$polygonId');
    polygonCache.removeWhere((p) => p.id == polygonId);
  }

  @override
  Future<void> removeAllPolygons({
    required Set<MapPolygon> polygonCache,
  }) async {
    calls.add('removeAllPolygons');
    polygonCache.clear();
  }

  // ── Círculos ───────────────────────────────────────────────

  @override
  Future<void> addOrUpdateCircle(
    MapCircle circle, {
    required Set<MapCircle> circleCache,
  }) async {
    calls.add('addOrUpdateCircle:${circle.id}');
    addedCircles.add(circle);
    circleCache.removeWhere((c) => c.id == circle.id);
    circleCache.add(circle);
  }

  @override
  Future<void> removeCircle(
    String circleId, {
    required Set<MapCircle> circleCache,
  }) async {
    calls.add('removeCircle:$circleId');
    circleCache.removeWhere((c) => c.id == circleId);
  }

  @override
  Future<void> removeAllCircles({
    required Set<MapCircle> circleCache,
  }) async {
    calls.add('removeAllCircles');
    circleCache.clear();
  }

  // ── Helpers de test ────────────────────────────────────────

  /// Limpia el historial de llamadas y operaciones para reutilizar entre tests.
  void reset() {
    calls.clear();
    addedMarkers.clear();
    removedMarkerIds.clear();
    addedPolylines.clear();
    addedPolygons.clear();
    addedCircles.clear();
  }

  /// Devuelve `true` si se registró al menos una llamada con el prefijo [prefix].
  bool wasCalled(String prefix) => calls.any((c) => c.startsWith(prefix));

  /// Devuelve cuántas veces se llamó a una operación con el prefijo [prefix].
  int callCount(String prefix) =>
      calls.where((c) => c.startsWith(prefix)).length;
}
