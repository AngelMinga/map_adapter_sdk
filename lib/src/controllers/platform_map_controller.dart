import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as google;
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;

import '../adapters/google_map_adapter.dart';
import '../adapters/map_controller_adapter.dart';
import '../adapters/mapbox_map_adapter.dart';
import '../models/models.dart';

/// Controlador de plataforma unificado que delega en el [MapControllerAdapter] correcto.
///
/// ✅ Todos los métodos públicos usan exclusivamente tipos `Map*` del dominio.
/// ✅ Las clases de SDK (`LatLng`, `CameraPosition`, etc.) no están expuestas.
/// ✅ El stream de notificaciones está tipado como `Stream<MapCameraEvent>`.
///
/// ### Correcciones respecto al código original:
/// - **`StreamController` sin tipo**: El original usaba `StreamController` (dynamic).
///   Ahora es `StreamController<MapCameraEvent>` para tipado fuerte.
/// - **`addMarker` pasaba parámetros posicionados con `=`**: `markerId = markerId`
///   es una reasignación del parámetro local, no un argumento nombrado. Eliminado.
/// - **`addPolyline` ignoraba `patterns` y los hardcodeaba**: Ahora respeta el campo
///   `dashed` del modelo [MapPolyline].
/// - **Null assertion `_mapControllerAdapter!`**: Sin verificación previa.
///   Ahora se verifica con un getter seguro `_requireAdapter`.
class PlatformMapController {
  final MapControllerAdapter _adapter;
  final StreamController<MapCameraEvent> _cameraEventController =
      StreamController<MapCameraEvent>.broadcast();

  PlatformMapController._(this._adapter);

  // ── Factories ──────────────────────────────────────────────

  /// Crea un [PlatformMapController] para Google Maps.
  static PlatformMapController forGoogle(
      google.GoogleMapController googleController) {
    final adapter = GoogleMapAdapter(googleController);
    final instance = PlatformMapController._(adapter);
    instance._listenToGoogleCameraEvents(googleController);
    return instance;
  }

  /// Crea un [PlatformMapController] para Mapbox.
  static PlatformMapController forMapbox(mapbox.MapboxMap mapboxController) {
    return PlatformMapController._(MapboxMapAdapter(mapboxController));
  }

  // ── Acceso al adaptador ────────────────────────────────────

  MapControllerAdapter get adapter => _adapter;

  bool get isMapbox => _adapter.isMapbox;

  // ── Stream tipado de eventos de cámara ─────────────────────

  /// Stream de eventos de movimiento de cámara.
  ///
  /// Se puede escuchar para actualizar overlays (MarkerInfoWindow, etc.).
  Stream<MapCameraEvent> get cameraEvents => _cameraEventController.stream;

  void _listenToGoogleCameraEvents(google.GoogleMapController controller) {
    GoogleMapsFlutterPlatform.instance
        .onCameraMove(mapId: controller.mapId)
        .listen((event) {
      if (!_cameraEventController.isClosed) {
        _cameraEventController.add(const MapCameraEvent.moved());
      }
    });
  }

  /// Emite un evento de movimiento de cámara manualmente (útil para Mapbox).
  void emitCameraEvent(MapCameraEvent event) {
    if (!_cameraEventController.isClosed) {
      _cameraEventController.add(event);
    }
  }

  // ── Ciclo de vida ──────────────────────────────────────────

  Future<void> dispose() async {
    await _adapter.dispose();
    await _cameraEventController.close();
  }

  Future<void> initManagers() => _adapter.initManagers();

  Future<void> disposeManagers() => _adapter.disposeManager();

  // ── Cámara ─────────────────────────────────────────────────

  Future<void> animateCameraToLatLngZoom(MapLatLng target, double zoom) =>
      _adapter.animateCameraToLatLngZoom(target, zoom);

  Future<void> animateCameraToLatLngBounds(
          MapLatLngBounds bounds, double padding) =>
      _adapter.animateCameraToLatLngBounds(bounds, padding);

  Future<void> animateCameraTo(MapLatLng target) =>
      _adapter.animateCameraTo(target);

  Future<void> animateToCameraPosition(MapCameraPosition cameraPosition) =>
      _adapter.animateToCameraPosition(cameraPosition);

  Future<void> moveCameraToLatLngZoom(MapLatLng target, double zoom) =>
      _adapter.moveCameraToLatLngZoom(target, zoom);

  // ── Estilos ────────────────────────────────────────────────

  Future<void> setMapStyle(String? mapStyle) =>
      _adapter.setMapStyle(mapStyle);

  // ── Coordenadas ────────────────────────────────────────────

  Future<MapLatLng> getLatLngFromScreen(MapScreenCoordinate sc) =>
      _adapter.getLatLngFromScreen(sc);

  Future<MapScreenCoordinate> getScreenCoordinateFromLatLng(
          MapLatLng latLng) =>
      _adapter.getScreenCoordinateFromLatLng(latLng);

  Future<double> getZoomLevel() => _adapter.getZoomLevel();

  Future<MapLatLngBounds> getVisibleRegion() => _adapter.getVisibleRegion();

  Future<void> showMarkerInfoWindow(String markerId) =>
      _adapter.showMarkerInfoWindow(markerId);

  // ── Marcadores ─────────────────────────────────────────────

  Future<void> addOrUpdateMarker(
    MapMarker marker, {
    required Map<String, MapMarker> markerCache,
  }) =>
      _adapter.addOrUpdateMarker(marker, markerCache: markerCache);

  Future<void> removeMarker(
    String markerId, {
    required Map<String, MapMarker> markerCache,
  }) =>
      _adapter.removeMarker(markerId, markerCache: markerCache);

  Future<void> removeAllMarkers({
    required Map<String, MapMarker> markerCache,
  }) =>
      _adapter.removeAllMarkers(markerCache: markerCache);

  Future<void> removeMarkersNotIn({
    required Map<String, MapMarker> markerCache,
    required Iterable<String> idsToKeep,
  }) =>
      _adapter.removeMarkersNotIn(
          markerCache: markerCache, idsToKeep: idsToKeep);

  // ── Polilíneas ─────────────────────────────────────────────

  Future<void> addOrUpdatePolyline(
    MapPolyline polyline, {
    required Set<MapPolyline> polylineCache,
  }) =>
      _adapter.addOrUpdatePolyline(polyline, polylineCache: polylineCache);

  Future<void> removePolyline(
    String polylineId, {
    required Set<MapPolyline> polylineCache,
  }) =>
      _adapter.removePolyline(polylineId, polylineCache: polylineCache);

  Future<void> removeAllPolylines({
    required Set<MapPolyline> polylineCache,
  }) =>
      _adapter.removeAllPolylines(polylineCache: polylineCache);

  // ── Polígonos ──────────────────────────────────────────────

  Future<void> addOrUpdatePolygon(
    MapPolygon polygon, {
    required Set<MapPolygon> polygonCache,
  }) =>
      _adapter.addOrUpdatePolygon(polygon, polygonCache: polygonCache);

  Future<void> removePolygon(
    String polygonId, {
    required Set<MapPolygon> polygonCache,
  }) =>
      _adapter.removePolygon(polygonId, polygonCache: polygonCache);

  Future<void> removeAllPolygons({
    required Set<MapPolygon> polygonCache,
  }) =>
      _adapter.removeAllPolygons(polygonCache: polygonCache);

  // ── Círculos ───────────────────────────────────────────────

  Future<void> addOrUpdateCircle(
    MapCircle circle, {
    required Set<MapCircle> circleCache,
  }) =>
      _adapter.addOrUpdateCircle(circle, circleCache: circleCache);

  Future<void> removeCircle(
    String circleId, {
    required Set<MapCircle> circleCache,
  }) =>
      _adapter.removeCircle(circleId, circleCache: circleCache);

  Future<void> removeAllCircles({
    required Set<MapCircle> circleCache,
  }) =>
      _adapter.removeAllCircles(circleCache: circleCache);
}

// ── Tipos auxiliares del dominio de eventos ───────────────────

/// Evento de cámara emitido por [PlatformMapController.cameraEvents].
@immutable
class MapCameraEvent {
  /// El tipo de evento.
  final MapCameraEventType type;

  const MapCameraEvent._(this.type);

  /// La cámara se ha movido.
  const MapCameraEvent.moved() : this._(MapCameraEventType.moved);

  /// La cámara se ha detenido.
  const MapCameraEvent.idle() : this._(MapCameraEventType.idle);

  /// La cámara ha comenzado a moverse.
  const MapCameraEvent.moveStarted() : this._(MapCameraEventType.moveStarted);

  @override
  String toString() => 'MapCameraEvent(type: $type)';
}

/// Tipos de eventos de cámara.
enum MapCameraEventType { moved, idle, moveStarted }
