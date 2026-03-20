import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;

import '../models/models.dart';

/// Conversores entre modelos de dominio y tipos de Mapbox.
///
/// ⚠️ Estas funciones SOLO deben usarse dentro de [MapboxMapAdapter].
/// El dominio nunca debe importar este archivo directamente.
abstract final class MapboxMapper {
  // ── MapLatLng ──────────────────────────────────────────────

  static mapbox.Position toPosition(MapLatLng point) =>
      mapbox.Position(point.longitude, point.latitude);

  static mapbox.Point toPoint(MapLatLng point) =>
      mapbox.Point(coordinates: toPosition(point));

  static MapLatLng fromPoint(mapbox.Point point) => MapLatLng(
        point.coordinates.lat.toDouble(),
        point.coordinates.lng.toDouble(),
      );

  // ── MapLatLngBounds ────────────────────────────────────────

  static mapbox.CoordinateBounds toCoordinateBounds(MapLatLngBounds bounds) =>
      mapbox.CoordinateBounds(
        southwest: toPoint(bounds.southwest),
        northeast: toPoint(bounds.northeast),
        infiniteBounds: true,
      );

  static MapLatLngBounds fromCameraBounds(mapbox.CameraBounds cameraBounds) =>
      MapLatLngBounds(
        northeast: MapLatLng(
          cameraBounds.bounds.northeast.coordinates.lat.toDouble(),
          cameraBounds.bounds.northeast.coordinates.lng.toDouble(),
        ),
        southwest: MapLatLng(
          cameraBounds.bounds.southwest.coordinates.lat.toDouble(),
          cameraBounds.bounds.southwest.coordinates.lng.toDouble(),
        ),
      );

  // ── MapCameraPosition ──────────────────────────────────────

  static mapbox.CameraOptions toCameraOptions(MapCameraPosition pos) =>
      mapbox.CameraOptions(
        center: toPoint(pos.target),
        zoom: pos.zoom,
        bearing: pos.bearing,
        pitch: pos.tilt,
      );

  static MapCameraPosition fromCameraState(mapbox.CameraState state) =>
      MapCameraPosition(
        target: MapLatLng(
          state.center.coordinates.lat.toDouble(),
          state.center.coordinates.lng.toDouble(),
        ),
        zoom: state.zoom,
        bearing: state.bearing,
        tilt: state.pitch,
      );

  // ── MapScreenCoordinate ────────────────────────────────────

  static mapbox.ScreenCoordinate toScreenCoordinate(
          MapScreenCoordinate sc) =>
      mapbox.ScreenCoordinate(x: sc.x.toDouble(), y: sc.y.toDouble());

  static MapScreenCoordinate fromScreenCoordinate(
          mapbox.ScreenCoordinate sc) =>
      MapScreenCoordinate(x: sc.x.toInt(), y: sc.y.toInt());

  // ── List<MapLatLng> ────────────────────────────────────────

  static List<mapbox.Position> toPositions(List<MapLatLng> points) =>
      points.map(toPosition).toList();

  static mapbox.LineString toLineString(List<MapLatLng> points) =>
      mapbox.LineString(coordinates: toPositions(points));

  static mapbox.Polygon toMapboxPolygon(List<MapLatLng> points) {
    final closed = [...points];
    if (points.isNotEmpty && points.first != points.last) {
      closed.add(points.first);
    }
    return mapbox.Polygon(coordinates: [toPositions(closed)]);
  }
}

/// Factory methods en [MapLatLng] para construir desde tipos de Mapbox.
extension MapLatLngMapboxExtension on MapLatLng {
  static MapLatLng fromMapboxPoint(mapbox.Point point) => MapLatLng(
        point.coordinates.lat.toDouble(),
        point.coordinates.lng.toDouble(),
      );
}
