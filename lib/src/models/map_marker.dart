import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'map_latlng.dart';

/// Representa un marcador en el mapa, desacoplado de Google Maps y Mapbox.
///
/// El campo [icon] es `Uint8List` (imagen renderizada en bytes).
/// Usa `WidgetToImage` para convertir un Widget a bytes antes de crear el marcador.
///
/// El campo [infoWindowTitle] es opcional: en Google Maps se muestra como
/// el InfoWindow nativo; en Mapbox como `textField` en la anotación.
class MapMarker {
  /// Identificador único del marcador. Debe ser único por mapa.
  final String id;

  /// Posición geográfica del marcador.
  final MapLatLng position;

  /// Icono del marcador como bytes (PNG renderizado).
  final Uint8List? icon;

  /// Rotación del icono en grados (0 = sin rotación).
  final double rotation;

  /// Índice de profundidad de renderizado (mayor = encima).
  final double zIndex;

  /// Ancla del icono: (0.5, 0.5) = centro, (0.5, 1.0) = punta inferior.
  final Offset anchor;

  /// Callback cuando el usuario toca el marcador.
  final VoidCallback? onTap;

  /// Título opcional para el InfoWindow (Google) o textField (Mapbox).
  final String? infoWindowTitle;

  /// Subtítulo opcional para el InfoWindow (solo Google Maps).
  final String? infoWindowSnippet;

  /// Si el marcador captura o no los eventos táctiles sin propagarlos.
  final bool consumeTapEvents;

  const MapMarker({
    required this.id,
    required this.position,
    this.icon,
    this.rotation = 0.0,
    this.zIndex = 1.0,
    this.anchor = const Offset(0.5, 0.5),
    this.onTap,
    this.infoWindowTitle,
    this.infoWindowSnippet,
    this.consumeTapEvents = false,
  });

  MapMarker copyWith({
    String? id,
    MapLatLng? position,
    Uint8List? icon,
    double? rotation,
    double? zIndex,
    Offset? anchor,
    VoidCallback? onTap,
    String? infoWindowTitle,
    String? infoWindowSnippet,
    bool? consumeTapEvents,
  }) =>
      MapMarker(
        id: id ?? this.id,
        position: position ?? this.position,
        icon: icon ?? this.icon,
        rotation: rotation ?? this.rotation,
        zIndex: zIndex ?? this.zIndex,
        anchor: anchor ?? this.anchor,
        onTap: onTap ?? this.onTap,
        infoWindowTitle: infoWindowTitle ?? this.infoWindowTitle,
        infoWindowSnippet: infoWindowSnippet ?? this.infoWindowSnippet,
        consumeTapEvents: consumeTapEvents ?? this.consumeTapEvents,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapMarker && id == other.id && position == other.position;

  @override
  int get hashCode => Object.hash(id, position);

  @override
  String toString() => 'MapMarker(id: $id, position: $position)';
}
