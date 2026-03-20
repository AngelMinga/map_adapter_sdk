import 'map_latlng.dart';

/// Representa la posición de la cámara del mapa desacoplada de cualquier SDK.
///
/// Equivalente a `CameraPosition` de Google Maps o `CameraOptions` de Mapbox.
class MapCameraPosition {
  /// Centro de la cámara.
  final MapLatLng target;

  /// Nivel de zoom (0–22 típicamente).
  final double zoom;

  /// Rotación del mapa en grados (0 = norte arriba).
  final double bearing;

  /// Inclinación de la cámara en grados (0 = nadir, vista cenital).
  final double tilt;

  const MapCameraPosition({
    required this.target,
    this.zoom = 15.0,
    this.bearing = 0.0,
    this.tilt = 0.0,
  });

  factory MapCameraPosition.fromJson(Map<String, dynamic> json) =>
      MapCameraPosition(
        target: MapLatLng(
          (json['lat'] as num).toDouble(),
          (json['lng'] as num).toDouble(),
        ),
        zoom: (json['zoom'] as num?)?.toDouble() ?? 15.0,
        bearing: (json['bearing'] as num?)?.toDouble() ?? 0.0,
        tilt: (json['tilt'] as num?)?.toDouble() ?? 0.0,
      );

  Map<String, dynamic> toJson() => {
        'lat': target.latitude,
        'lng': target.longitude,
        'zoom': zoom,
        'bearing': bearing,
        'tilt': tilt,
      };

  MapCameraPosition copyWith({
    MapLatLng? target,
    double? zoom,
    double? bearing,
    double? tilt,
  }) =>
      MapCameraPosition(
        target: target ?? this.target,
        zoom: zoom ?? this.zoom,
        bearing: bearing ?? this.bearing,
        tilt: tilt ?? this.tilt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapCameraPosition &&
          target == other.target &&
          zoom == other.zoom &&
          bearing == other.bearing &&
          tilt == other.tilt;

  @override
  int get hashCode => Object.hash(target, zoom, bearing, tilt);

  @override
  String toString() =>
      'MapCameraPosition(target: $target, zoom: $zoom, bearing: $bearing, tilt: $tilt)';
}
