import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../models/models.dart';

/// Utilidades de dominio para operaciones geográficas y de mapa.
///
/// No depende de ningún SDK externo.
///
/// Ejemplo:
/// ```dart
/// final dist = MapUtils.distanceInMeters(quito, guayaquil);
/// final bounds = MapUtils.boundsFromPoints(myPoints);
/// final mid = MapUtils.midpoint(a, b);
/// ```
abstract final class MapUtils {
  // ── Distancias ─────────────────────────────────────────────

  /// Distancia Haversine en metros entre dos puntos geográficos.
  ///
  /// Más precisa que la distancia euclídea para puntos distantes.
  static double distanceInMeters(MapLatLng a, MapLatLng b) =>
      a.distanceInMetersTo(b);

  /// Distancia euclídea al cuadrado entre dos puntos.
  ///
  /// Más rápida que Haversine. Útil para comparaciones de movimiento
  /// significativo cuando no se necesita precisión absoluta.
  static double squaredDistance(MapLatLng a, MapLatLng b) =>
      a.squaredDistanceTo(b);

  /// Devuelve `true` si el movimiento entre [previous] y [current] supera
  /// [thresholdMeters] metros. Usa Haversine.
  static bool hasSignificantMovement(
    MapLatLng previous,
    MapLatLng current, {
    double thresholdMeters = 10.0,
  }) =>
      distanceInMeters(previous, current) > thresholdMeters;

  // ── Bounds ─────────────────────────────────────────────────

  /// Calcula el [MapLatLngBounds] que contiene todos los [points].
  ///
  /// Lanza [ArgumentError] si la lista está vacía.
  static MapLatLngBounds boundsFromPoints(List<MapLatLng> points) =>
      MapLatLngBounds.fromPoints(points);

  /// Combina múltiples listas de puntos en un único [MapLatLngBounds].
  ///
  /// Útil para encuadrar ruta + marcadores + polígonos juntos.
  static MapLatLngBounds boundsFromMultiple(
      List<List<MapLatLng>> pointGroups) {
    final all = pointGroups.expand((g) => g).toList();
    return MapLatLngBounds.fromPoints(all);
  }

  /// Expande un [MapLatLngBounds] por un factor de escala.
  ///
  /// Un [factor] de `1.2` expande el bounds un 20% en cada dirección.
  static MapLatLngBounds expandBounds(
      MapLatLngBounds bounds, double factor) {
    final centerLat =
        (bounds.northeast.latitude + bounds.southwest.latitude) / 2;
    final centerLng =
        (bounds.northeast.longitude + bounds.southwest.longitude) / 2;
    final dLat =
        (bounds.northeast.latitude - bounds.southwest.latitude) / 2 * factor;
    final dLng =
        (bounds.northeast.longitude - bounds.southwest.longitude) / 2 * factor;
    return MapLatLngBounds(
      northeast: MapLatLng(centerLat + dLat, centerLng + dLng),
      southwest: MapLatLng(centerLat - dLat, centerLng - dLng),
    );
  }

  // ── Interpolación y geometría ──────────────────────────────

  /// Punto medio geográfico aproximado entre [a] y [b].
  ///
  /// Para distancias cortas (< 100 km) la aproximación lineal es suficiente.
  /// Para distancias largas, considera [midpointHaversine].
  static MapLatLng midpoint(MapLatLng a, MapLatLng b) => MapLatLng(
        (a.latitude + b.latitude) / 2,
        (a.longitude + b.longitude) / 2,
      );

  /// Punto medio esférico preciso (Haversine) entre [a] y [b].
  static MapLatLng midpointHaversine(MapLatLng a, MapLatLng b) {
    final lat1 = _rad(a.latitude);
    final lat2 = _rad(b.latitude);
    final dLng = _rad(b.longitude - a.longitude);

    final bx = math.cos(lat2) * math.cos(dLng);
    final by = math.cos(lat2) * math.sin(dLng);
    final lat3 = math.atan2(
      math.sin(lat1) + math.sin(lat2),
      math.sqrt((math.cos(lat1) + bx) * (math.cos(lat1) + bx) + by * by),
    );
    final lng3 =
        _rad(a.longitude) + math.atan2(by, math.cos(lat1) + bx);

    return MapLatLng(_deg(lat3), _deg(lng3));
  }

  /// Interpola linealmente entre [a] y [b] con factor [t] (0.0 = a, 1.0 = b).
  static MapLatLng lerp(MapLatLng a, MapLatLng b, double t) {
    assert(t >= 0.0 && t <= 1.0, 't must be between 0.0 and 1.0');
    return MapLatLng(
      a.latitude + (b.latitude - a.latitude) * t,
      a.longitude + (b.longitude - a.longitude) * t,
    );
  }

  /// Longitud total en metros de una lista de puntos (polilínea).
  static double totalLengthInMeters(List<MapLatLng> points) {
    if (points.length < 2) return 0.0;
    double total = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      total += distanceInMeters(points[i], points[i + 1]);
    }
    return total;
  }

  /// Genera una lista de [count] puntos interpolados uniformemente a lo largo
  /// de una polilínea definida por [points].
  ///
  /// Útil para animaciones de marcadores a lo largo de una ruta.
  static List<MapLatLng> interpolatePath(
      List<MapLatLng> points, int count) {
    if (points.isEmpty) return [];
    if (points.length == 1) return List.filled(count, points.first);
    if (count <= 1) return [points.first];

    final result = <MapLatLng>[];
    final total = totalLengthInMeters(points);
    final step = total / (count - 1);
    double accumulated = 0;
    int segmentIndex = 0;

    result.add(points.first);

    for (int i = 1; i < count - 1; i++) {
      final target = step * i;
      while (segmentIndex < points.length - 2) {
        final segLen = distanceInMeters(
          points[segmentIndex],
          points[segmentIndex + 1],
        );
        if (accumulated + segLen >= target) break;
        accumulated += segLen;
        segmentIndex++;
      }
      if (segmentIndex >= points.length - 1) {
        result.add(points.last);
        continue;
      }
      final segLen = distanceInMeters(
        points[segmentIndex],
        points[segmentIndex + 1],
      );
      final t = segLen > 0 ? (target - accumulated) / segLen : 0.0;
      result.add(lerp(points[segmentIndex], points[segmentIndex + 1], t));
    }

    result.add(points.last);
    return result;
  }

  // ── Bearing / Heading ──────────────────────────────────────

  /// Calcula el ángulo de rumbo (0–360°) desde [from] hacia [to].
  ///
  /// 0° = Norte, 90° = Este, 180° = Sur, 270° = Oeste.
  static double bearing(MapLatLng from, MapLatLng to) {
    final lat1 = _rad(from.latitude);
    final lat2 = _rad(to.latitude);
    final dLng = _rad(to.longitude - from.longitude);

    final y = math.sin(dLng) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);

    final angle = _deg(math.atan2(y, x));
    return (angle + 360) % 360;
  }

  // ── Zoom ───────────────────────────────────────────────────

  /// Calcula un nivel de zoom aproximado para que [bounds] quepa en una pantalla
  /// de [screenWidthPx] x [screenHeightPx] píxeles.
  ///
  /// El resultado es orientativo; usa `animateCameraToLatLngBounds` con el
  /// padding apropiado para el resultado definitivo.
  static double zoomForBounds(
    MapLatLngBounds bounds, {
    required double screenWidthPx,
    required double screenHeightPx,
    double padding = 50.0,
  }) {
    const tileSize = 256.0;
    final latFraction =
        (bounds.northeast.latitude - bounds.southwest.latitude).abs() / 180.0;
    final lngFraction =
        (bounds.northeast.longitude - bounds.southwest.longitude).abs() / 360.0;

    final latZoom = _zoomForFraction(
        latFraction, screenHeightPx - padding * 2, tileSize);
    final lngZoom = _zoomForFraction(
        lngFraction, screenWidthPx - padding * 2, tileSize);

    return math.min(latZoom, lngZoom).clamp(0.0, 21.0);
  }

  // ── ID helpers ─────────────────────────────────────────────

  /// Genera un ID único basado en timestamp y posición.
  ///
  /// Úsalo para marcadores temporales cuando no tengas un ID de negocio.
  static String generateMarkerId([MapLatLng? position]) {
    final ts = DateTime.now().microsecondsSinceEpoch;
    if (position != null) {
      return '${ts}_${position.latitude.toStringAsFixed(4)}_${position.longitude.toStringAsFixed(4)}';
    }
    return ts.toString();
  }

  // ── Privados ───────────────────────────────────────────────

  static double _rad(double deg) => deg * math.pi / 180;
  static double _deg(double rad) => rad * 180 / math.pi;

  static double _zoomForFraction(
      double fraction, double screenSize, double tileSize) {
    if (fraction <= 0) return 21.0;
    return math.log(screenSize / tileSize / fraction) / math.ln2;
  }
}

/// Extensiones de conveniencia en [MapLatLng] para operaciones comunes.
extension MapLatLngUtils on MapLatLng {
  /// Bearing desde este punto hacia [other].
  double bearingTo(MapLatLng other) => MapUtils.bearing(this, other);

  /// Distancia en metros hacia [other].
  double metersTo(MapLatLng other) => MapUtils.distanceInMeters(this, other);

  /// Punto medio lineal hacia [other].
  MapLatLng midpointTo(MapLatLng other) => MapUtils.midpoint(this, other);

  /// Interpolación lineal hacia [other] con factor [t].
  MapLatLng lerpTo(MapLatLng other, double t) =>
      MapUtils.lerp(this, other, t);

  /// Devuelve `true` si este punto está dentro de [bounds].
  bool isInsideBounds(MapLatLngBounds bounds) => bounds.contains(this);
}

/// Extensiones en [List<MapLatLng>] para operaciones de ruta.
extension MapLatLngListUtils on List<MapLatLng> {
  /// Longitud total de la ruta en metros.
  double get totalLengthInMeters => MapUtils.totalLengthInMeters(this);

  /// Bounds que contiene todos los puntos de la lista.
  MapLatLngBounds get bounds => MapLatLngBounds.fromPoints(this);

  /// Genera [count] puntos interpolados a lo largo de la ruta.
  List<MapLatLng> interpolated(int count) =>
      MapUtils.interpolatePath(this, count);
}
