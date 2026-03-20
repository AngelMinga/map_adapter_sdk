import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/models.dart';

/// Conversores entre modelos de dominio y tipos de Google Maps.
///
/// ⚠️ Estas funciones SOLO deben usarse dentro de [GoogleMapAdapter].
/// El dominio nunca debe importar este archivo directamente.
abstract final class GoogleMapMapper {
  // ── MapLatLng ──────────────────────────────────────────────

  static LatLng toLatLng(MapLatLng point) =>
      LatLng(point.latitude, point.longitude);

  static MapLatLng fromLatLng(LatLng latLng) =>
      MapLatLng(latLng.latitude, latLng.longitude);

  // ── MapLatLngBounds ────────────────────────────────────────

  static LatLngBounds toLatLngBounds(MapLatLngBounds bounds) => LatLngBounds(
        northeast: toLatLng(bounds.northeast),
        southwest: toLatLng(bounds.southwest),
      );

  static MapLatLngBounds fromLatLngBounds(LatLngBounds bounds) =>
      MapLatLngBounds(
        northeast: fromLatLng(bounds.northeast),
        southwest: fromLatLng(bounds.southwest),
      );

  // ── MapCameraPosition ──────────────────────────────────────

  static CameraPosition toCameraPosition(MapCameraPosition pos) =>
      CameraPosition(
        target: toLatLng(pos.target),
        zoom: pos.zoom,
        bearing: pos.bearing,
        tilt: pos.tilt,
      );

  static MapCameraPosition fromCameraPosition(CameraPosition pos) =>
      MapCameraPosition(
        target: fromLatLng(pos.target),
        zoom: pos.zoom,
        bearing: pos.bearing,
        tilt: pos.tilt,
      );

  // ── MapScreenCoordinate ────────────────────────────────────

  static ScreenCoordinate toScreenCoordinate(MapScreenCoordinate sc) =>
      ScreenCoordinate(x: sc.x, y: sc.y);

  static MapScreenCoordinate fromScreenCoordinate(ScreenCoordinate sc) =>
      MapScreenCoordinate(x: sc.x, y: sc.y);

  // ── MapMarker ──────────────────────────────────────────────

  /// Convierte un [MapMarker] a un [Marker] de Google Maps.
  ///
  /// Si [marker.icon] es null se usa [BitmapDescriptor.defaultMarker].
  static Marker toMarker(MapMarker marker) {
    final icon = marker.icon != null
        ? BitmapDescriptor.fromBytes(marker.icon!)
        : BitmapDescriptor.defaultMarker;

    final infoWindow = (marker.infoWindowTitle != null)
        ? InfoWindow(
            title: marker.infoWindowTitle,
            snippet: marker.infoWindowSnippet,
          )
        : InfoWindow.noText;

    return Marker(
      markerId: MarkerId(marker.id),
      position: toLatLng(marker.position),
      icon: icon,
      rotation: marker.rotation,
      zIndex: marker.zIndex,
      anchor: marker.anchor,
      onTap: marker.onTap,
      infoWindow: infoWindow,
      consumeTapEvents: marker.consumeTapEvents,
    );
  }

  // ── MapPolyline ────────────────────────────────────────────

  static Polyline toPolyline(MapPolyline polyline) => Polyline(
        polylineId: PolylineId(polyline.id),
        points: polyline.points.map(toLatLng).toList(),
        color: polyline.color,
        width: polyline.width.toInt(),
        geodesic: polyline.geodesic,
        visible: polyline.visible,
        zIndex: polyline.zIndex,
        jointType: JointType.mitered,
        startCap: Cap.buttCap,
        endCap: Cap.buttCap,
        patterns: polyline.dashed
            ? [PatternItem.dash(20), PatternItem.gap(10)]
            : const [],
        onTap: polyline.onTap,
      );

  // ── MapPolygon ─────────────────────────────────────────────

  static Polygon toPolygon(MapPolygon polygon) => Polygon(
        polygonId: PolygonId(polygon.id),
        points: polygon.points.map(toLatLng).toList(),
        fillColor: polygon.fillColor,
        strokeColor: polygon.strokeColor,
        strokeWidth: polygon.strokeWidth,
        visible: polygon.visible,
        zIndex: polygon.zIndex,
        geodesic: polygon.geodesic,
        onTap: polygon.onTap,
        consumeTapEvents: polygon.consumeTapEvents,
      );

  // ── MapCircle ──────────────────────────────────────────────

  static Circle toCircle(MapCircle circle) => Circle(
        circleId: CircleId(circle.id),
        center: toLatLng(circle.center),
        radius: circle.radius,
        fillColor: circle.fillColor,
        strokeColor: circle.strokeColor,
        strokeWidth: circle.strokeWidth,
      );
}

/// Factory methods en [MapLatLng] para construir desde tipos de Google.
extension MapLatLngGoogleExtension on MapLatLng {
  /// Crea un [MapLatLng] desde un [LatLng] de Google Maps.
  static MapLatLng fromGoogle(LatLng latLng) =>
      MapLatLng(latLng.latitude, latLng.longitude);
}

/// Factory methods en [MapCameraPosition] para construir desde tipos de Google.
extension MapCameraPositionGoogleExtension on MapCameraPosition {
  static MapCameraPosition fromGoogle(CameraPosition pos) =>
      MapCameraPosition(
        target: MapLatLng(pos.target.latitude, pos.target.longitude),
        zoom: pos.zoom,
        bearing: pos.bearing,
        tilt: pos.tilt,
      );
}
