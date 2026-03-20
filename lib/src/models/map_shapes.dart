import 'package:flutter/material.dart';

import 'map_latlng.dart';

// ─────────────────────────────────────────────────────────────
// MapPolyline
// ─────────────────────────────────────────────────────────────

/// Representa una línea en el mapa compuesta por múltiples puntos.
///
/// Desacoplado de Google Maps (`Polyline`) y Mapbox (`PolylineAnnotation`).
class MapPolyline {
  /// Identificador único de la polilínea.
  final String id;

  /// Lista de puntos que forman la polilínea (mínimo 2).
  final List<MapLatLng> points;

  /// Color de la línea.
  final Color color;

  /// Grosor de la línea en píxeles lógicos.
  final double width;

  /// Si la línea sigue la curvatura terrestre.
  final bool geodesic;

  /// Si la línea es visible.
  final bool visible;

  /// Índice de profundidad de renderizado.
  final int zIndex;

  /// Si la línea es punteada. En Mapbox se mapea a `linePattern`.
  final bool dashed;

  /// Callback cuando el usuario toca la polilínea.
  final VoidCallback? onTap;

  const MapPolyline({
    required this.id,
    required this.points,
    this.color = Colors.blue,
    this.width = 5.0,
    this.geodesic = false,
    this.visible = true,
    this.zIndex = 0,
    this.dashed = false,
    this.onTap,
  });

  MapPolyline copyWith({
    String? id,
    List<MapLatLng>? points,
    Color? color,
    double? width,
    bool? geodesic,
    bool? visible,
    int? zIndex,
    bool? dashed,
    VoidCallback? onTap,
  }) =>
      MapPolyline(
        id: id ?? this.id,
        points: points ?? this.points,
        color: color ?? this.color,
        width: width ?? this.width,
        geodesic: geodesic ?? this.geodesic,
        visible: visible ?? this.visible,
        zIndex: zIndex ?? this.zIndex,
        dashed: dashed ?? this.dashed,
        onTap: onTap ?? this.onTap,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is MapPolyline && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'MapPolyline(id: $id, points: ${points.length})';
}

// ─────────────────────────────────────────────────────────────
// MapPolygon
// ─────────────────────────────────────────────────────────────

/// Representa un polígono cerrado en el mapa.
///
/// Requiere al menos 3 puntos. El cierre (primer == último) lo manejan los adapters.
class MapPolygon {
  /// Identificador único del polígono.
  final String id;

  /// Vértices del polígono (mínimo 3). No es necesario repetir el primero.
  final List<MapLatLng> points;

  /// Color de relleno.
  final Color fillColor;

  /// Color del borde.
  final Color strokeColor;

  /// Ancho del borde en píxeles lógicos.
  final int strokeWidth;

  /// Si el polígono es visible.
  final bool visible;

  /// Índice de profundidad de renderizado.
  final int zIndex;

  /// Si sigue la curvatura terrestre.
  final bool geodesic;

  /// Callback cuando el usuario toca el polígono.
  final VoidCallback? onTap;

  /// Si el polígono captura eventos táctiles.
  final bool consumeTapEvents;

  const MapPolygon({
    required this.id,
    required this.points,
    this.fillColor = const Color(0x1A000000), // negro 10% opacidad
    this.strokeColor = Colors.black,
    this.strokeWidth = 3,
    this.visible = true,
    this.zIndex = 0,
    this.geodesic = false,
    this.onTap,
    this.consumeTapEvents = false,
  });

  MapPolygon copyWith({
    String? id,
    List<MapLatLng>? points,
    Color? fillColor,
    Color? strokeColor,
    int? strokeWidth,
    bool? visible,
    int? zIndex,
    bool? geodesic,
    VoidCallback? onTap,
    bool? consumeTapEvents,
  }) =>
      MapPolygon(
        id: id ?? this.id,
        points: points ?? this.points,
        fillColor: fillColor ?? this.fillColor,
        strokeColor: strokeColor ?? this.strokeColor,
        strokeWidth: strokeWidth ?? this.strokeWidth,
        visible: visible ?? this.visible,
        zIndex: zIndex ?? this.zIndex,
        geodesic: geodesic ?? this.geodesic,
        onTap: onTap ?? this.onTap,
        consumeTapEvents: consumeTapEvents ?? this.consumeTapEvents,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is MapPolygon && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'MapPolygon(id: $id, points: ${points.length})';
}

// ─────────────────────────────────────────────────────────────
// MapCircle
// ─────────────────────────────────────────────────────────────

/// Representa un círculo geográfico en el mapa.
class MapCircle {
  /// Identificador único del círculo.
  final String id;

  /// Centro del círculo.
  final MapLatLng center;

  /// Radio en metros.
  final double radius;

  /// Color de relleno.
  final Color fillColor;

  /// Color del borde.
  final Color strokeColor;

  /// Ancho del borde.
  final int strokeWidth;

  const MapCircle({
    required this.id,
    required this.center,
    required this.radius,
    this.fillColor = const Color(0x1A2196F3), // azul 10%
    this.strokeColor = Colors.blue,
    this.strokeWidth = 1,
  });

  MapCircle copyWith({
    String? id,
    MapLatLng? center,
    double? radius,
    Color? fillColor,
    Color? strokeColor,
    int? strokeWidth,
  }) =>
      MapCircle(
        id: id ?? this.id,
        center: center ?? this.center,
        radius: radius ?? this.radius,
        fillColor: fillColor ?? this.fillColor,
        strokeColor: strokeColor ?? this.strokeColor,
        strokeWidth: strokeWidth ?? this.strokeWidth,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is MapCircle && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'MapCircle(id: $id, center: $center, radius: $radius)';
}
