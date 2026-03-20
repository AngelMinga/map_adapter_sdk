/// Coordenada en píxeles de pantalla, desacoplada del SDK.
///
/// Equivalente a `ScreenCoordinate` de Google Maps o `ScreenCoordinate` de Mapbox.
class MapScreenCoordinate {
  final int x;
  final int y;

  const MapScreenCoordinate({required this.x, required this.y});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapScreenCoordinate && x == other.x && y == other.y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'MapScreenCoordinate(x: $x, y: $y)';
}
