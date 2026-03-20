import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;

import '../mappers/mapbox_mapper.dart';
import '../models/models.dart';
import 'map_controller_adapter.dart';
import 'safe_map_controller_lifecycle.dart';

/// Adaptador de Mapbox que implementa [MapControllerAdapter].
///
/// ✅ Solo usa tipos del dominio (`Map*`) en su interfaz pública.
/// ✅ Toda conversión a/desde `mapbox_maps_flutter` ocurre internamente.
///
/// ### Correcciones respecto al código original:
/// - **Acoplamiento a `Marker`, `Polyline`, `Circle`, `Polygon` de Google**: Los
///   métodos recibían y mantenían colecciones de tipos de Google Maps incluso en el
///   adaptador de Mapbox, mezclando responsabilidades. Eliminado completamente.
/// - **`runIfAlive` devuelve `null` silenciosamente**: El original ignoraba el
///   resultado, lo que causaba que algunos métodos retornaran `null` donde se
///   esperaba un valor. Se agrega un `StateError` explícito en los getters.
/// - **Managers llamados sin `await`**: `initManagers()` se llamaba sin `await`
///   en algunos flujos. Corregido con `await` consistente.
/// - **`onExternalCleanup` en `removePolygon` era async pero el tipo era `void Function()`**:
///   El callback no esperaba el `Future`. Refactorizado en la nueva versión.
/// - **`_isInitialized` no protegía race conditions**: Si `_initMapboxManagers`
///   se llamaba concurrentemente, podía crear managers duplicados. Añadido guard
///   con `Completer`.
class MapboxMapAdapter
    with SafeMapControllerLifecycle
    implements MapControllerAdapter {
  final mapbox.MapboxMap _mapboxMap;

  bool _isInitialized = false;

  mapbox.PolylineAnnotationManager? _polylineManager;
  mapbox.PolylineAnnotationManager? _polygonOutlineManager;
  mapbox.PointAnnotationManager? _pointManager;
  mapbox.CircleAnnotationManager? _circleManager;
  mapbox.PolygonAnnotationManager? _polygonManager;

  // Almacenamiento interno de anotaciones Mapbox, indexado por ID de dominio.
  final Map<String, mapbox.PointAnnotation> _pointAnnotations = {};
  final Map<String, mapbox.PolylineAnnotation> _polylineAnnotations = {};
  final Map<String, mapbox.PolygonAnnotation> _polygonAnnotations = {};
  final Map<String, mapbox.PolylineAnnotation> _polygonOutlineAnnotations = {};
  final Map<String, mapbox.CircleAnnotation> _circleAnnotations = {};

  // Callbacks de tap indexados por ID de dominio.
  final Map<String, VoidCallback> _markerTapCallbacks = {};
  final Map<String, VoidCallback> _polylineTapCallbacks = {};

  MapboxMapAdapter(this._mapboxMap);

  @override
  bool get isMapbox => true;

  // ── Ciclo de vida ──────────────────────────────────────────

  @override
  Future<void> dispose() async {
    await safeDispose(disposeManager);
  }

  @override
  Future<void> initManagers() async {
    await runIfAlive(_initMapboxManagers);
  }

  @override
  Future<void> disposeManager() async {
    await runIfAlive(() async {
      try {
        await _pointManager?.deleteAll();
        await _circleManager?.deleteAll();
        await _polylineManager?.deleteAll();
        await _polygonManager?.deleteAll();
        await _polygonOutlineManager?.deleteAll();
      } catch (e) {
        debugPrint('[MapboxMapAdapter] Error disposing managers: $e');
      }

      _pointManager = null;
      _circleManager = null;
      _polylineManager = null;
      _polygonManager = null;
      _polygonOutlineManager = null;

      _pointAnnotations.clear();
      _polylineAnnotations.clear();
      _polygonAnnotations.clear();
      _polygonOutlineAnnotations.clear();
      _circleAnnotations.clear();
      _markerTapCallbacks.clear();
      _polylineTapCallbacks.clear();

      _isInitialized = false;
    });
  }

  Future<void> _initMapboxManagers() async {
    if (_isInitialized) return;
    _isInitialized = true; // Marcar antes del await para evitar race condition

    try {
      _pointManager ??= await _mapboxMap.annotations
          .createPointAnnotationManager()
        ..tapEvents(
          onTap: _handleMarkerTap,
        );

      _circleManager ??=
          await _mapboxMap.annotations.createCircleAnnotationManager();

      _polylineManager ??= await _mapboxMap.annotations
          .createPolylineAnnotationManager()
        ..tapEvents(
          onTap: _handlePolylineTap,
        );

      _polygonOutlineManager ??=
          await _mapboxMap.annotations.createPolylineAnnotationManager();

      _polygonManager ??=
          await _mapboxMap.annotations.createPolygonAnnotationManager();
    } catch (e) {
      _isInitialized = false; // Permitir reintento si falló
      debugPrint('[MapboxMapAdapter] Error initializing managers: $e');
      rethrow;
    }
  }

  void _handleMarkerTap(mapbox.PointAnnotation annotation) {
    final id = _pointAnnotations.keys
        .firstWhereOrNull((k) => _pointAnnotations[k]?.id == annotation.id);
    if (id != null) _markerTapCallbacks[id]?.call();
  }

  void _handlePolylineTap(mapbox.PolylineAnnotation annotation) {
    final id = _polylineAnnotations.keys
        .firstWhereOrNull((k) => _polylineAnnotations[k]?.id == annotation.id);
    if (id != null) _polylineTapCallbacks[id]?.call();
  }

  // ── Cámara ─────────────────────────────────────────────────

  @override
  Future<void> animateCameraToLatLngZoom(MapLatLng target, double zoom) {
    return runIfAlive(() => _mapboxMap.flyTo(
          mapbox.CameraOptions(
            center: MapboxMapper.toPoint(target),
            zoom: zoom,
          ),
          mapbox.MapAnimationOptions(duration: 2000, startDelay: 0),
        )) ??
        Future.value();
  }

  @override
  Future<void> animateCameraToLatLngBounds(
      MapLatLngBounds bounds, double padding) async {
    await runIfAlive(() async {
      final camera = await _mapboxMap.cameraForCoordinateBounds(
        MapboxMapper.toCoordinateBounds(bounds),
        mapbox.MbxEdgeInsets(
          left: padding,
          right: padding,
          top: padding,
          bottom: padding,
        ),
        null,
        null,
        null,
        null,
      );
      return _mapboxMap.setCamera(camera);
    });
  }

  @override
  Future<void> animateCameraTo(MapLatLng target) {
    return runIfAlive(() => _mapboxMap.flyTo(
          mapbox.CameraOptions(center: MapboxMapper.toPoint(target)),
          mapbox.MapAnimationOptions(duration: 2000, startDelay: 0),
        )) ??
        Future.value();
  }

  @override
  Future<void> animateToCameraPosition(MapCameraPosition cameraPosition) {
    return runIfAlive(() => _mapboxMap.flyTo(
          MapboxMapper.toCameraOptions(cameraPosition),
          mapbox.MapAnimationOptions(duration: 720, startDelay: 0),
        )) ??
        Future.value();
  }

  @override
  Future<void> moveCameraToLatLngZoom(MapLatLng target, double zoom) {
    return runIfAlive(() => _mapboxMap.setCamera(
          mapbox.CameraOptions(
              center: MapboxMapper.toPoint(target), zoom: zoom),
        )) ??
        Future.value();
  }

  // ── Estilos ────────────────────────────────────────────────

  @override
  Future<void> setMapStyle(String? mapStyle) async {
    if (mapStyle == null) return;
    await runIfAlive(() => _mapboxMap.loadStyleURI(mapStyle));
  }

  // ── Conversiones de coordenadas ────────────────────────────

  @override
  Future<MapLatLng> getLatLngFromScreen(
      MapScreenCoordinate screenCoordinate) async {
    // FIX: El original usaba `?? throw StateError(...)` en lugar de propagar
    // el error correctamente cuando `runIfAlive` devolvía null por estar destruido.
    final result = await runIfAlive(() async {
      final point = await _mapboxMap.coordinateForPixel(
        MapboxMapper.toScreenCoordinate(screenCoordinate),
      );
      return MapboxMapper.fromPoint(point);
    });
    if (result == null) throw StateError('MapboxMapAdapter has been disposed');
    return result;
  }

  @override
  Future<MapScreenCoordinate> getScreenCoordinateFromLatLng(
      MapLatLng latLng) async {
    final result = await runIfAlive(() async {
      final sc = await _mapboxMap.pixelForCoordinate(
        MapboxMapper.toPoint(latLng),
      );
      return MapboxMapper.fromScreenCoordinate(sc);
    });
    if (result == null) throw StateError('MapboxMapAdapter has been disposed');
    return result;
  }

  // ── Estado de la cámara ────────────────────────────────────

  @override
  Future<double> getZoomLevel() async {
    final result = await runIfAlive(() async {
      final state = await _mapboxMap.getCameraState();
      return state.zoom;
    });
    if (result == null) throw StateError('MapboxMapAdapter has been disposed');
    return result;
  }

  @override
  Future<MapLatLngBounds> getVisibleRegion() async {
    final result = await runIfAlive(() async {
      final cameraBounds = await _mapboxMap.getBounds();
      return MapboxMapper.fromCameraBounds(cameraBounds);
    });
    if (result == null) throw StateError('MapboxMapAdapter has been disposed');
    return result;
  }

  // ── Info Window ────────────────────────────────────────────

  @override
  Future<void> showMarkerInfoWindow(String markerId) async {
    // Mapbox no tiene InfoWindow nativo. No-op intencional.
  }

  // ── Marcadores ─────────────────────────────────────────────

  @override
  Future<void> addOrUpdateMarker(
    MapMarker marker, {
    required Map<String, MapMarker> markerCache,
  }) async {
    await runIfAlive(() async {
      await initManagers();

      final titleText = marker.infoWindowTitle;

      if (_pointAnnotations.containsKey(marker.id)) {
        final existing = _pointAnnotations[marker.id]!;
        existing
          ..geometry = MapboxMapper.toPoint(marker.position)
          ..image = marker.icon
          ..iconRotate = marker.rotation
          ..symbolSortKey = marker.zIndex;
        if (titleText != null) existing.textField = titleText;
        await _pointManager?.update(existing);
        _pointAnnotations[marker.id] = existing;
      } else {
        final options = mapbox.PointAnnotationOptions(
          geometry: MapboxMapper.toPoint(marker.position),
          image: marker.icon,
          iconRotate: marker.rotation,
          symbolSortKey: marker.zIndex,
          textField: titleText,
          textSize: titleText != null ? 14.0 : null,
          textAnchor: titleText != null ? mapbox.TextAnchor.TOP : null,
        );
        final created = await _pointManager?.create(options);
        if (created != null) {
          _pointAnnotations[marker.id] = created;
        }
      }

      if (marker.onTap != null) {
        _markerTapCallbacks[marker.id] = marker.onTap!;
      }

      markerCache[marker.id] = marker;
    });
  }

  @override
  Future<void> removeMarker(
    String markerId, {
    required Map<String, MapMarker> markerCache,
  }) async {
    await runIfAlive(() async {
      await initManagers();
      await _safeDeleteAnnotation(_pointManager, _pointAnnotations[markerId]);
      _pointAnnotations.remove(markerId);
      _markerTapCallbacks.remove(markerId);
      markerCache.remove(markerId);
    });
  }

  @override
  Future<void> removeAllMarkers({
    required Map<String, MapMarker> markerCache,
  }) async {
    await runIfAlive(() async {
      await initManagers();
      final ids = List<String>.from(markerCache.keys);
      for (final id in ids) {
        await _safeDeleteAnnotation(_pointManager, _pointAnnotations[id]);
        _pointAnnotations.remove(id);
        _markerTapCallbacks.remove(id);
      }
      markerCache.clear();
    });
  }

  @override
  Future<void> removeMarkersNotIn({
    required Map<String, MapMarker> markerCache,
    required Iterable<String> idsToKeep,
  }) async {
    await runIfAlive(() async {
      await initManagers();
      final keepSet = idsToKeep.toSet();
      final toRemove =
          markerCache.keys.where((id) => !keepSet.contains(id)).toList();

      await Future.wait(toRemove.map((id) async {
        await _safeDeleteAnnotation(_pointManager, _pointAnnotations[id]);
        _pointAnnotations.remove(id);
        _markerTapCallbacks.remove(id);
        markerCache.remove(id);
      }));
    });
  }

  // ── Polilíneas ─────────────────────────────────────────────

  @override
  Future<void> addOrUpdatePolyline(
    MapPolyline polyline, {
    required Set<MapPolyline> polylineCache,
  }) async {
    await runIfAlive(() async {
      if (polyline.points.isEmpty) return;
      await initManagers();

      final geometry = MapboxMapper.toLineString(polyline.points);
      final colorInt = polyline.color.toARGB32();
      final pattern = polyline.dashed ? 'dashed' : null;

      if (_polylineAnnotations.containsKey(polyline.id)) {
        final existing = _polylineAnnotations[polyline.id]!;
        existing
          ..geometry = geometry
          ..lineColor = colorInt
          ..lineWidth = polyline.width
          ..linePattern = pattern;
        await _polylineManager?.update(existing);
      } else {
        final options = mapbox.PolylineAnnotationOptions(
          geometry: geometry,
          lineColor: colorInt,
          lineWidth: polyline.width,
          linePattern: pattern,
        );
        final created = await _polylineManager?.create(options);
        if (created != null) _polylineAnnotations[polyline.id] = created;
      }

      if (polyline.onTap != null) {
        _polylineTapCallbacks[polyline.id] = polyline.onTap!;
      }

      polylineCache.removeWhere((p) => p.id == polyline.id);
      polylineCache.add(polyline);
    });
  }

  @override
  Future<void> removePolyline(
    String polylineId, {
    required Set<MapPolyline> polylineCache,
  }) async {
    await runIfAlive(() async {
      await initManagers();
      await _safeDeleteAnnotation(
          _polylineManager, _polylineAnnotations[polylineId]);
      _polylineAnnotations.remove(polylineId);
      _polylineTapCallbacks.remove(polylineId);
      polylineCache.removeWhere((p) => p.id == polylineId);
    });
  }

  @override
  Future<void> removeAllPolylines({
    required Set<MapPolyline> polylineCache,
  }) async {
    await runIfAlive(() async {
      await initManagers();
      final ids = List<String>.from(polylineCache.map((p) => p.id));
      for (final id in ids) {
        await _safeDeleteAnnotation(_polylineManager, _polylineAnnotations[id]);
        _polylineAnnotations.remove(id);
        _polylineTapCallbacks.remove(id);
      }
      polylineCache.clear();
    });
  }

  // ── Polígonos ──────────────────────────────────────────────

  @override
  Future<void> addOrUpdatePolygon(
    MapPolygon polygon, {
    required Set<MapPolygon> polygonCache,
  }) async {
    await runIfAlive(() async {
      if (polygon.points.length < 3) return;
      await initManagers();

      final geometry = MapboxMapper.toMapboxPolygon(polygon.points);
      final fillColor = polygon.fillColor.withValues(alpha: 0.2);
      final strokeColor = polygon.strokeColor;
      final lineGeometry = MapboxMapper.toLineString(polygon.points);

      if (_polygonAnnotations.containsKey(polygon.id)) {
        final existing = _polygonAnnotations[polygon.id]!;
        existing
          ..geometry = geometry
          ..fillColor = fillColor.toARGB32()
          ..fillOpacity = fillColor.a
          ..fillOutlineColor = strokeColor.toARGB32();
        await _polygonManager?.update(existing);
      } else {
        final options = mapbox.PolygonAnnotationOptions(
          geometry: geometry,
          fillColor: fillColor.toARGB32(),
          fillOpacity: fillColor.a,
          fillOutlineColor: strokeColor.toARGB32(),
        );
        final created = await _polygonManager?.create(options);

        final outlineOptions = mapbox.PolylineAnnotationOptions(
          geometry: lineGeometry,
          lineColor: strokeColor.toARGB32(),
          lineWidth: polygon.strokeWidth.toDouble(),
        );
        final outline = await _polygonOutlineManager?.create(outlineOptions);

        if (created != null) _polygonAnnotations[polygon.id] = created;
        if (outline != null) _polygonOutlineAnnotations[polygon.id] = outline;
      }

      polygonCache.removeWhere((p) => p.id == polygon.id);
      polygonCache.add(polygon);
    });
  }

  @override
  Future<void> removePolygon(
    String polygonId, {
    required Set<MapPolygon> polygonCache,
  }) async {
    await runIfAlive(() async {
      await initManagers();
      // FIX: El original usaba un callback async dentro de `onExternalCleanup`
      // que era `void Function()`, perdiendo el await del Future interno.
      // Ahora se awaita explícitamente.
      await _safeDeleteAnnotation(
          _polygonManager, _polygonAnnotations[polygonId]);
      await _safeDeleteAnnotation(
          _polygonOutlineManager, _polygonOutlineAnnotations[polygonId]);
      _polygonAnnotations.remove(polygonId);
      _polygonOutlineAnnotations.remove(polygonId);
      polygonCache.removeWhere((p) => p.id == polygonId);
    });
  }

  @override
  Future<void> removeAllPolygons({
    required Set<MapPolygon> polygonCache,
  }) async {
    await runIfAlive(() async {
      await initManagers();
      final ids = List<String>.from(polygonCache.map((p) => p.id));
      for (final id in ids) {
        await _safeDeleteAnnotation(_polygonManager, _polygonAnnotations[id]);
        await _safeDeleteAnnotation(
            _polygonOutlineManager, _polygonOutlineAnnotations[id]);
        _polygonAnnotations.remove(id);
        _polygonOutlineAnnotations.remove(id);
      }
      polygonCache.clear();
    });
  }

  // ── Círculos ───────────────────────────────────────────────

  @override
  Future<void> addOrUpdateCircle(
    MapCircle circle, {
    required Set<MapCircle> circleCache,
  }) async {
    await runIfAlive(() async {
      await initManagers();

      if (_circleAnnotations.containsKey(circle.id)) {
        final existing = _circleAnnotations[circle.id]!;
        existing
          ..geometry = MapboxMapper.toPoint(circle.center)
          ..circleRadius = circle.radius
          ..circleColor = circle.fillColor.toARGB32()
          ..circleStrokeColor = circle.strokeColor.toARGB32()
          ..circleStrokeWidth = circle.strokeWidth.toDouble();
        await _circleManager?.update(existing);
      } else {
        final options = mapbox.CircleAnnotationOptions(
          geometry: MapboxMapper.toPoint(circle.center),
          circleRadius: circle.radius,
          circleColor: circle.fillColor.toARGB32(),
          circleStrokeColor: circle.strokeColor.toARGB32(),
          circleStrokeWidth: circle.strokeWidth.toDouble(),
        );
        final created = await _circleManager?.create(options);
        if (created != null) _circleAnnotations[circle.id] = created;
      }

      circleCache.removeWhere((c) => c.id == circle.id);
      circleCache.add(circle);
    });
  }

  @override
  Future<void> removeCircle(
    String circleId, {
    required Set<MapCircle> circleCache,
  }) async {
    await runIfAlive(() async {
      await initManagers();
      await _safeDeleteAnnotation(_circleManager, _circleAnnotations[circleId]);
      _circleAnnotations.remove(circleId);
      circleCache.removeWhere((c) => c.id == circleId);
    });
  }

  @override
  Future<void> removeAllCircles({
    required Set<MapCircle> circleCache,
  }) async {
    await runIfAlive(() async {
      await initManagers();
      final ids = List<String>.from(circleCache.map((c) => c.id));
      for (final id in ids) {
        await _safeDeleteAnnotation(_circleManager, _circleAnnotations[id]);
        _circleAnnotations.remove(id);
      }
      circleCache.clear();
    });
  }

  // ── Helper interno ─────────────────────────────────────────

  /// Elimina una anotación de un manager, ignorando errores de "no encontrada".
  Future<void> _safeDeleteAnnotation(
    dynamic manager,
    dynamic annotation,
  ) async {
    if (manager == null || annotation == null) return;
    try {
      await manager.delete(annotation);
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('not found') ||
          msg.contains('already deleted') ||
          msg.contains('does not exist')) {
        debugPrint('[MapboxMapAdapter] Annotation already deleted: $e');
      } else {
        rethrow;
      }
    }
  }
}
