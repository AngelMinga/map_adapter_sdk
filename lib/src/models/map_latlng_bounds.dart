import 'map_latlng.dart';

/// Representa un rectángulo geográfico definido por dos esquinas.
///
/// Equivalente a `LatLngBounds` de Google Maps o `CoordinateBounds` de Mapbox,
/// pero desacoplado de cualquier SDK externo.
class MapLatLngBounds {
  final MapLatLng northeast;
  final MapLatLng southwest;

  const MapLatLngBounds({
    required this.northeast,
    required this.southwest,
  });

  /// Construye bounds a partir de una lista de puntos (calcula min/max).
  ///
  /// Lanza [ArgumentError] si la lista está vacía.
  factory MapLatLngBounds.fromPoints(List<MapLatLng> points) {
    if (points.isEmpty) throw ArgumentError('points must not be empty');
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    return MapLatLngBounds(
      northeast: MapLatLng(maxLat, maxLng),
      southwest: MapLatLng(minLat, minLng),
    );
  }

  /// Devuelve el centro geográfico aproximado del bounds.
  MapLatLng get center => MapLatLng(
        (northeast.latitude + southwest.latitude) / 2,
        (northeast.longitude + southwest.longitude) / 2,
      );

  /// Verifica si un punto está dentro del bounds.
  bool contains(MapLatLng point) =>
      point.latitude >= southwest.latitude &&
      point.latitude <= northeast.latitude &&
      point.longitude >= southwest.longitude &&
      point.longitude <= northeast.longitude;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapLatLngBounds &&
          northeast == other.northeast &&
          southwest == other.southwest;

  @override
  int get hashCode => Object.hash(northeast, southwest);

  @override
  String toString() =>
      'MapLatLngBounds(northeast: $northeast, southwest: $southwest)';
}
