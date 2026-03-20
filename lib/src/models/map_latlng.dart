import 'dart:math' as math;

/// Representa una coordenada geográfica desacoplada de cualquier SDK.
///
/// Usa este modelo en toda la capa de dominio y negocio.
/// La conversión a Google/Mapbox ocurre únicamente dentro de los adapters.
class MapLatLng {
  final double latitude;
  final double longitude;

  const MapLatLng(this.latitude, this.longitude);

  /// Construye desde un mapa JSON estándar `{"lat": ..., "lng": ...}`.
  factory MapLatLng.fromJson(Map<String, dynamic> json) => MapLatLng(
        (json['lat'] as num).toDouble(),
        (json['lng'] as num).toDouble(),
      );

  Map<String, double> toJson() => {'lat': latitude, 'lng': longitude};

  /// Distancia euclídea aproximada (no usa Haversine, solo para comparaciones rápidas).
  double squaredDistanceTo(MapLatLng other) {
    final dx = latitude - other.latitude;
    final dy = longitude - other.longitude;
    return dx * dx + dy * dy;
  }

  /// Distancia Haversine en metros entre dos puntos (precisa).
  double distanceInMetersTo(MapLatLng other) {
    const earthRadius = 6371000.0;
    final dLat = _toRadians(other.latitude - latitude);
    final dLon = _toRadians(other.longitude - longitude);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(latitude)) *
            math.cos(_toRadians(other.latitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapLatLng &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => 'MapLatLng($latitude, $longitude)';

  MapLatLng copyWith({double? latitude, double? longitude}) => MapLatLng(
        latitude ?? this.latitude,
        longitude ?? this.longitude,
      );
}
