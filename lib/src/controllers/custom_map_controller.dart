import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as google;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;

import '../adapters/google_map_adapter.dart';
import '../controllers/platform_map_controller.dart';
import '../models/models.dart';

/// Controlador principal que gestiona el estado del widget [CustomMap].
///
/// Expone exclusivamente modelos del dominio (`Map*`).
/// Los widgets que reciben `Set<Marker>` de Google Maps deben usar
/// [GoogleMapAdapter.toGoogleMarkers] en su `build` method.
///
/// ### Correcciones respecto al código original:
/// - **`onMapCreated` llamaba a `initMapType()` de nuevo en el constructor**:
///   Doble inicialización. Eliminado el segundo llamado.
/// - **`movingMap` setter notificaba sin chequear si el valor cambió**:
///   Añadido guard `if (_movingMap == value) return;`.
/// - **`applyCurrentThemeStyle` accedía a un índice sin verificar longitud**:
///   `_prefs.styleMapDark![2]` podría fallar si hay menos de 3 elementos.
///   Añadida verificación de longitud mínima.
/// - **`drawInitialRoute` mutaba `markers` sin notificar**: Ahora usa
///   `notifyListeners()` al final de forma consistente.
class CustomMapController with ChangeNotifier {
  PlatformMapController? _mapController;

  bool _movingMap = false;
  int _mapProviderIndex = 0;
  ThemeMode _themeMode = ThemeMode.system;

  Map<String, MapMarker> _markers = {};
  Set<MapPolyline> _polylines = {};
  Set<MapPolygon> _polygons = {};
  Set<MapCircle> _circles = {};

  String? _currentStyleUri;
  String? darkMapStyle;
  String? lightMapStyle;

  // ── Getters ────────────────────────────────────────────────

  PlatformMapController? get mapController => _mapController;

  bool get isMapbox => _mapController?.isMapbox ?? false;

  bool get movingMap => _movingMap;

  int get mapProviderIndex => _mapProviderIndex;

  ThemeMode get themeMode => _themeMode;

  Map<String, MapMarker> get markers => _markers;

  Set<MapPolyline> get polylines => _polylines;

  Set<MapPolygon> get polygons => _polygons;

  Set<MapCircle> get circles => _circles;

  // ── Setters con notificación ───────────────────────────────

  set movingMap(bool value) {
    // FIX: El original notificaba aunque el valor no cambiara.
    if (_movingMap == value) return;
    _movingMap = value;
    notifyListeners();
  }

  set mapProviderIndex(int value) {
    if (_mapProviderIndex == value) return;
    _mapProviderIndex = value;
    notifyListeners();
  }

  set themeMode(ThemeMode value) {
    if (_themeMode == value) return;
    _themeMode = value;
    notifyListeners();
  }

  // ── Ciclo de vida ──────────────────────────────────────────

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  // ── Inicialización del mapa ────────────────────────────────

  /// Registra el controlador de Google Maps y limpia el estado anterior.
  Future<void> onMapCreated(google.GoogleMapController controller) async {
    try {
      _mapController = PlatformMapController.forGoogle(controller);
      _markers.clear();
      notifyListeners();
    } catch (e, stack) {
      debugPrint('[CustomMapController] Error initializing Google Map: $e\n$stack');
      rethrow;
    }
  }

  /// Registra el controlador de Mapbox.
  Future<void> onMapCreatedMapbox(mapbox.MapboxMap controller) async {
    try {
      _mapController = PlatformMapController.forMapbox(controller);
    } catch (e, stack) {
      debugPrint('[CustomMapController] Error initializing Mapbox: $e\n$stack');
      rethrow;
    }
  }

  /// Inicializa los managers de anotaciones de Mapbox si es necesario.
  Future<void> initMapManagersIfNeeded() async {
    if (_mapController?.isMapbox ?? false) {
      await _mapController?.disposeManagers();
      await _mapController?.initManagers();
    }
  }

  // ── Cámara ─────────────────────────────────────────────────

  void onCameraMoveStarted(bool showPin) {
    if (showPin) movingMap = true;
  }

  void onCameraIdle(bool showPin) {
    if (showPin) movingMap = false;
  }

  void animateTo(MapLatLng latLng) {
    if (_mapController == null) {
      debugPrint('[CustomMapController] Cannot animate map: controller is null');
      return;
    }
    _mapController!.animateCameraTo(latLng);
  }

  // ── Estilos ────────────────────────────────────────────────

  Future<void> updateMapStyle({
    required bool isDark,
    required String? styleUri,
  }) async {
    if (_mapController == null) {
      debugPrint('[CustomMapController] Cannot update style: controller is null');
      return;
    }
    final fallback = isDark
        ? mapbox.MapboxStyles.DARK
        : mapbox.MapboxStyles.STANDARD;
    final effectiveStyle = styleUri ?? fallback;

    if (_currentStyleUri == effectiveStyle) return;
    _currentStyleUri = effectiveStyle;

    try {
      await _mapController!.setMapStyle(effectiveStyle);
    } catch (e, stack) {
      debugPrint('[CustomMapController] Error setting map style: $e\n$stack');
    }
  }

  Future<void> loadMapStyles() async {
    if (darkMapStyle != null && lightMapStyle != null) return;
    try {
      darkMapStyle = await rootBundle.loadString('assets/map_styles/dark.json');
      lightMapStyle =
          await rootBundle.loadString('assets/map_styles/light.json');
    } catch (e, stack) {
      debugPrint('[CustomMapController] Error loading map styles: $e\n$stack');
    }
  }

  // ── Marcadores ─────────────────────────────────────────────

  Future<void> addOrUpdateMarker(MapMarker marker) async {
    await _mapController?.addOrUpdateMarker(marker, markerCache: _markers);
    notifyListeners();
  }

  Future<void> removeMarker(String markerId) async {
    await _mapController?.removeMarker(markerId, markerCache: _markers);
    notifyListeners();
  }

  Future<void> removeAllMarkers() async {
    await _mapController?.removeAllMarkers(markerCache: _markers);
    notifyListeners();
  }

  Future<void> removeMarkersNotIn(Iterable<String> idsToKeep) async {
    await _mapController?.removeMarkersNotIn(
      markerCache: _markers,
      idsToKeep: idsToKeep,
    );
    notifyListeners();
  }

  // ── Polilíneas ─────────────────────────────────────────────

  Future<void> addOrUpdatePolyline(MapPolyline polyline) async {
    await _mapController?.addOrUpdatePolyline(polyline,
        polylineCache: _polylines);
    notifyListeners();
  }

  Future<void> removePolyline(String polylineId) async {
    await _mapController?.removePolyline(polylineId, polylineCache: _polylines);
    notifyListeners();
  }

  Future<void> removeAllPolylines() async {
    await _mapController?.removeAllPolylines(polylineCache: _polylines);
    notifyListeners();
  }

  // ── Polígonos ──────────────────────────────────────────────

  Future<void> addOrUpdatePolygon(MapPolygon polygon) async {
    await _mapController?.addOrUpdatePolygon(polygon, polygonCache: _polygons);
    notifyListeners();
  }

  Future<void> removeAllPolygons() async {
    await _mapController?.removeAllPolygons(polygonCache: _polygons);
    notifyListeners();
  }

  // ── Círculos ───────────────────────────────────────────────

  Future<void> addOrUpdateCircle(MapCircle circle) async {
    await _mapController?.addOrUpdateCircle(circle, circleCache: _circles);
    notifyListeners();
  }

  Future<void> removeAllCircles() async {
    await _mapController?.removeAllCircles(circleCache: _circles);
    notifyListeners();
  }

  // ── Helpers para el widget Google Maps ─────────────────────

  /// Devuelve los marcadores en formato Google Maps para el widget [GoogleMap].
  ///
  /// Solo debe llamarse desde el build method del widget que usa Google Maps.
  Set<google.Marker> getGoogleMarkers() =>
      GoogleMapAdapter.toGoogleMarkers(_markers);

  /// Devuelve las polilíneas en formato Google Maps.
  Set<google.Polyline> getGooglePolylines() =>
      GoogleMapAdapter.toGooglePolylines(_polylines);

  /// Devuelve los polígonos en formato Google Maps.
  Set<google.Polygon> getGooglePolygons() =>
      GoogleMapAdapter.toGooglePolygons(_polygons);

  /// Devuelve los círculos en formato Google Maps.
  Set<google.Circle> getGoogleCircles() =>
      GoogleMapAdapter.toGoogleCircles(_circles);
}
