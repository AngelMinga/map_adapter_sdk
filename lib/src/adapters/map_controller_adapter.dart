import '../models/models.dart';

/// Interfaz del adaptador de controlador de mapa.
///
/// Define el contrato que deben cumplir [GoogleMapAdapter] y [MapboxMapAdapter].
/// **No contiene ninguna referencia a tipos de SDK externos.**
///
/// Todos los métodos reciben y devuelven exclusivamente tipos del dominio (`Map*`).
/// Las conversiones a/desde Google Maps o Mapbox ocurren únicamente dentro
/// de cada implementación concreta.
abstract interface class MapControllerAdapter {
  /// `true` si el proveedor activo es Mapbox; `false` si es Google Maps.
  bool get isMapbox;

  // ── Ciclo de vida ──────────────────────────────────────────

  /// Libera recursos del controlador de plataforma.
  Future<void> dispose();

  /// Inicializa los managers de anotaciones (necesario para Mapbox).
  Future<void> initManagers();

  /// Libera los managers de anotaciones.
  Future<void> disposeManager();

  // ── Cámara ─────────────────────────────────────────────────

  /// Anima la cámara hacia [target] con el nivel de zoom dado.
  Future<void> animateCameraToLatLngZoom(MapLatLng target, double zoom);

  /// Anima la cámara para encuadrar los [bounds] con [padding] en píxeles.
  Future<void> animateCameraToLatLngBounds(
      MapLatLngBounds bounds, double padding);

  /// Anima la cámara hacia [target] manteniendo el zoom actual.
  Future<void> animateCameraTo(MapLatLng target);

  /// Anima la cámara a una [MapCameraPosition] completa (target, zoom, bearing, tilt).
  Future<void> animateToCameraPosition(MapCameraPosition cameraPosition);

  /// Mueve la cámara sin animación hacia [target] con el nivel de zoom dado.
  Future<void> moveCameraToLatLngZoom(MapLatLng target, double zoom);

  // ── Estilos ────────────────────────────────────────────────

  /// Aplica un estilo de mapa. En Google Maps es un JSON; en Mapbox es un URI de estilo.
  Future<void> setMapStyle(String? mapStyle);

  // ── Conversiones de coordenadas ────────────────────────────

  /// Convierte coordenadas de pantalla a geográficas.
  Future<MapLatLng> getLatLngFromScreen(MapScreenCoordinate screenCoordinate);

  /// Convierte coordenadas geográficas a píxeles de pantalla.
  Future<MapScreenCoordinate> getScreenCoordinateFromLatLng(MapLatLng latLng);

  // ── Estado de la cámara ────────────────────────────────────

  /// Devuelve el nivel de zoom actual.
  Future<double> getZoomLevel();

  /// Devuelve la región visible actual del mapa.
  Future<MapLatLngBounds> getVisibleRegion();

  // ── Info Window ────────────────────────────────────────────

  /// Muestra el InfoWindow del marcador con el [markerId] dado.
  /// En Mapbox esta operación es no-op (no existe info window nativo).
  Future<void> showMarkerInfoWindow(String markerId);

  // ── Marcadores ─────────────────────────────────────────────

  /// Agrega o actualiza un marcador en el mapa.
  ///
  /// - Si ya existe un marcador con [marker.id], actualiza su posición e ícono.
  /// - Los cambios se reflejan en [markerCache] para sincronización del estado UI.
  Future<void> addOrUpdateMarker(
    MapMarker marker, {
    required Map<String, MapMarker> markerCache,
  });

  /// Elimina el marcador con [markerId] del mapa y del [markerCache].
  Future<void> removeMarker(
    String markerId, {
    required Map<String, MapMarker> markerCache,
  });

  /// Elimina todos los marcadores del mapa y limpia el [markerCache].
  Future<void> removeAllMarkers({
    required Map<String, MapMarker> markerCache,
  });

  /// Elimina los marcadores cuyo ID no esté en [idsToKeep].
  Future<void> removeMarkersNotIn({
    required Map<String, MapMarker> markerCache,
    required Iterable<String> idsToKeep,
  });

  // ── Polilíneas ─────────────────────────────────────────────

  /// Agrega o actualiza una polilínea en el mapa.
  Future<void> addOrUpdatePolyline(
    MapPolyline polyline, {
    required Set<MapPolyline> polylineCache,
  });

  /// Elimina la polilínea con [polylineId] del mapa y del [polylineCache].
  Future<void> removePolyline(
    String polylineId, {
    required Set<MapPolyline> polylineCache,
  });

  /// Elimina todas las polilíneas y limpia el [polylineCache].
  Future<void> removeAllPolylines({
    required Set<MapPolyline> polylineCache,
  });

  // ── Polígonos ──────────────────────────────────────────────

  /// Agrega o actualiza un polígono en el mapa.
  Future<void> addOrUpdatePolygon(
    MapPolygon polygon, {
    required Set<MapPolygon> polygonCache,
  });

  /// Elimina el polígono con [polygonId] del mapa y del [polygonCache].
  Future<void> removePolygon(
    String polygonId, {
    required Set<MapPolygon> polygonCache,
  });

  /// Elimina todos los polígonos y limpia el [polygonCache].
  Future<void> removeAllPolygons({
    required Set<MapPolygon> polygonCache,
  });

  // ── Círculos ───────────────────────────────────────────────

  /// Agrega o actualiza un círculo en el mapa.
  Future<void> addOrUpdateCircle(
    MapCircle circle, {
    required Set<MapCircle> circleCache,
  });

  /// Elimina el círculo con [circleId] del mapa y del [circleCache].
  Future<void> removeCircle(
    String circleId, {
    required Set<MapCircle> circleCache,
  });

  /// Elimina todos los círculos y limpia el [circleCache].
  Future<void> removeAllCircles({
    required Set<MapCircle> circleCache,
  });
}
