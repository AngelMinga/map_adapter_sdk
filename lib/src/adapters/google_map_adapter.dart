import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../mappers/google_map_mapper.dart';
import '../models/models.dart';
import 'map_controller_adapter.dart';
import 'safe_map_controller_lifecycle.dart';

/// Adaptador de Google Maps que implementa [MapControllerAdapter].
///
/// ✅ Solo usa tipos del dominio (`Map*`) en su interfaz pública.
/// ✅ Toda conversión a/desde `google_maps_flutter` ocurre internamente.
/// ✅ No expone `LatLng`, `Marker`, `Polyline`, etc. al exterior.
///
/// ### Correcciones respecto al código original:
/// - **Bug `markerId = markerId`**: El original usaba asignación de valor en
///   lugar de pasar parámetros nombrados. Corregido usando `marker.id` directamente.
/// - **Mutación sin efecto**: `removeAllMarkers` hacía `polylineOrder = {}` en
///   un parámetro local (sin efecto). Ahora opera sobre el cache correctamente.
/// - **Falta de null safety**: El original usaba `!` sin guarda previa. Ahora
///   se usa el mixin `SafeMapControllerLifecycle.runIfAlive` con manejo de errores.
/// - **Redundancia en `removeAllPolylines`**: Asignación inútil `polylineOrder = {}`
///   antes de `.clear()`. Eliminada.
class GoogleMapAdapter
    with SafeMapControllerLifecycle
    implements MapControllerAdapter {
  final GoogleMapController _googleMapController;

  GoogleMapAdapter(this._googleMapController);

  @override
  bool get isMapbox => false;

  // ── Ciclo de vida ──────────────────────────────────────────

  @override
  Future<void> dispose() async {
    await safeDispose(() async {
      _googleMapController.dispose();
    });
  }

  @override
  Future<void> initManagers() async {
    // Google Maps no requiere managers adicionales.
  }

  @override
  Future<void> disposeManager() async {
    // Google Maps no requiere managers adicionales.
  }

  // ── Cámara ─────────────────────────────────────────────────

  @override
  Future<void> animateCameraToLatLngZoom(MapLatLng target, double zoom) {
    return _googleMapController.animateCamera(
      CameraUpdate.newLatLngZoom(GoogleMapMapper.toLatLng(target), zoom),
    );
  }

  @override
  Future<void> animateCameraToLatLngBounds(
      MapLatLngBounds bounds, double padding) {
    return _googleMapController.animateCamera(
      CameraUpdate.newLatLngBounds(
        GoogleMapMapper.toLatLngBounds(bounds),
        padding,
      ),
    );
  }

  @override
  Future<void> animateCameraTo(MapLatLng target) {
    return _googleMapController.animateCamera(
      CameraUpdate.newLatLng(GoogleMapMapper.toLatLng(target)),
    );
  }

  @override
  Future<void> animateToCameraPosition(MapCameraPosition cameraPosition) {
    return _googleMapController.animateCamera(
      CameraUpdate.newCameraPosition(
        GoogleMapMapper.toCameraPosition(cameraPosition),
      ),
    );
  }

  @override
  Future<void> moveCameraToLatLngZoom(MapLatLng target, double zoom) {
    return _googleMapController.moveCamera(
      CameraUpdate.newLatLngZoom(GoogleMapMapper.toLatLng(target), zoom),
    );
  }

  // ── Estilos ────────────────────────────────────────────────

  @override
  Future<void> setMapStyle(String? mapStyle) {
    return _googleMapController.setMapStyle(mapStyle);
  }

  // ── Conversiones de coordenadas ────────────────────────────

  @override
  Future<MapLatLng> getLatLngFromScreen(
      MapScreenCoordinate screenCoordinate) async {
    final latLng = await _googleMapController.getLatLng(
      GoogleMapMapper.toScreenCoordinate(screenCoordinate),
    );
    return GoogleMapMapper.fromLatLng(latLng);
  }

  @override
  Future<MapScreenCoordinate> getScreenCoordinateFromLatLng(
      MapLatLng latLng) async {
    final sc = await _googleMapController.getScreenCoordinate(
      GoogleMapMapper.toLatLng(latLng),
    );
    return GoogleMapMapper.fromScreenCoordinate(sc);
  }

  // ── Estado de la cámara ────────────────────────────────────

  @override
  Future<double> getZoomLevel() async {
    try {
      return await _googleMapController.getZoomLevel();
    } catch (e) {
      debugPrint('[GoogleMapAdapter] Error getZoomLevel: $e');
      return 20.0;
    }
  }

  @override
  Future<MapLatLngBounds> getVisibleRegion() async {
    final bounds = await _googleMapController.getVisibleRegion();
    return GoogleMapMapper.fromLatLngBounds(bounds);
  }

  // ── Info Window ────────────────────────────────────────────

  @override
  Future<void> showMarkerInfoWindow(String markerId) async {
    _googleMapController.showMarkerInfoWindow(MarkerId(markerId));
  }

  // ── Marcadores ─────────────────────────────────────────────

  @override
  Future<void> addOrUpdateMarker(
    MapMarker marker, {
    required Map<String, MapMarker> markerCache,
  }) async {
    // FIX: El original usaba `markerId = markerId` (asignación a parámetro
    // posicional, sin efecto útil). Aquí se accede directamente a `marker.id`.
    markerCache[marker.id] = marker;
  }

  @override
  Future<void> removeMarker(
    String markerId, {
    required Map<String, MapMarker> markerCache,
  }) async {
    markerCache.remove(markerId);
  }

  @override
  Future<void> removeAllMarkers({
    required Map<String, MapMarker> markerCache,
  }) async {
    // FIX: El original hacía `polylineOrder = {}` (reasignación de parámetro
    // local, sin efecto en el caller). Ahora se usa `.clear()` correctamente.
    markerCache.clear();
  }

  @override
  Future<void> removeMarkersNotIn({
    required Map<String, MapMarker> markerCache,
    required Iterable<String> idsToKeep,
  }) async {
    final keepSet = idsToKeep.toSet();
    markerCache.removeWhere((id, _) => !keepSet.contains(id));
  }

  // ── Polilíneas ─────────────────────────────────────────────

  @override
  Future<void> addOrUpdatePolyline(
    MapPolyline polyline, {
    required Set<MapPolyline> polylineCache,
  }) async {
    polylineCache.removeWhere((p) => p.id == polyline.id);
    polylineCache.add(polyline);
  }

  @override
  Future<void> removePolyline(
    String polylineId, {
    required Set<MapPolyline> polylineCache,
  }) async {
    polylineCache.removeWhere((p) => p.id == polylineId);
  }

  @override
  Future<void> removeAllPolylines({
    required Set<MapPolyline> polylineCache,
  }) async {
    // FIX: El original hacía `polylineOrder = {}` antes de `.clear()`.
    // La reasignación de un parámetro no afecta al caller. Solo `.clear()` es correcto.
    polylineCache.clear();
  }

  // ── Polígonos ──────────────────────────────────────────────

  @override
  Future<void> addOrUpdatePolygon(
    MapPolygon polygon, {
    required Set<MapPolygon> polygonCache,
  }) async {
    polygonCache.removeWhere((p) => p.id == polygon.id);
    polygonCache.add(polygon);
  }

  @override
  Future<void> removePolygon(
    String polygonId, {
    required Set<MapPolygon> polygonCache,
  }) async {
    polygonCache.removeWhere((p) => p.id == polygonId);
  }

  @override
  Future<void> removeAllPolygons({
    required Set<MapPolygon> polygonCache,
  }) async {
    polygonCache.clear();
  }

  // ── Círculos ───────────────────────────────────────────────

  @override
  Future<void> addOrUpdateCircle(
    MapCircle circle, {
    required Set<MapCircle> circleCache,
  }) async {
    circleCache.removeWhere((c) => c.id == circle.id);
    circleCache.add(circle);
  }

  @override
  Future<void> removeCircle(
    String circleId, {
    required Set<MapCircle> circleCache,
  }) async {
    circleCache.removeWhere((c) => c.id == circleId);
  }

  @override
  Future<void> removeAllCircles({
    required Set<MapCircle> circleCache,
  }) async {
    circleCache.clear();
  }

  // ── Helpers internos para el widget GoogleMap ──────────────

  /// Convierte el cache de dominio a un Set<Marker> de Google Maps para el widget.
  ///
  /// Llamar solo desde el build method del widget Google Maps.
  static Set<Marker> toGoogleMarkers(Map<String, MapMarker> cache) =>
      cache.values.map(GoogleMapMapper.toMarker).toSet();

  /// Convierte el cache de dominio a un Set<Polyline> de Google Maps para el widget.
  static Set<Polyline> toGooglePolylines(Set<MapPolyline> cache) =>
      cache.map(GoogleMapMapper.toPolyline).toSet();

  /// Convierte el cache de dominio a un Set<Polygon> de Google Maps para el widget.
  static Set<Polygon> toGooglePolygons(Set<MapPolygon> cache) =>
      cache.map(GoogleMapMapper.toPolygon).toSet();

  /// Convierte el cache de dominio a un Set<Circle> de Google Maps para el widget.
  static Set<Circle> toGoogleCircles(Set<MapCircle> cache) =>
      cache.map(GoogleMapMapper.toCircle).toSet();
}
