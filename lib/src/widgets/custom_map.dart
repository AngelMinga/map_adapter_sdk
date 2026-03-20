import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as google;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:provider/provider.dart';

import '../adapters/google_map_adapter.dart';
import '../controllers/custom_map_controller.dart';
import '../controllers/platform_map_controller.dart';
import '../models/models.dart';
import '../utils/map_utils.dart';

// ── Constantes internas ────────────────────────────────────────────────────────

class _MapConstants {
  static const double defaultZoom = 16.0;
  static const double cameraMovementThresholdMeters = 10.0;
  static const Duration mapInitDelay = Duration(milliseconds: 50);
}

// ─────────────────────────────────────────────────────────────────────────────
// CustomMap
// ─────────────────────────────────────────────────────────────────────────────

/// Widget que abstrae Google Maps y Mapbox con una API unificada basada en
/// modelos de dominio (`Map*`).
///
/// ### Cambios respecto al original:
/// - `onCameraMove` ahora recibe [MapCameraPosition] (sin dependencia de Google).
/// - `onTap` ahora recibe [MapLatLng] (sin dependencia de Google).
/// - `markers`, `polylines`, `polygons`, `circles` usan tipos del dominio.
/// - `CameraTargetBounds` eliminado de la API pública; se reemplaza por
///   [boundsRestriction] de tipo [MapLatLngBounds].
/// - El widget ya no importa `google_maps_flutter` en su interfaz pública.
///
/// Ejemplo de uso:
/// ```dart
/// CustomMap(
///   initialPosition: MapCameraPosition(
///     target: MapLatLng(-2.19, -79.89),
///     zoom: 14,
///   ),
///   markers: myMarkers,
///   onMapCreated: (controller) { ... },
///   onCameraMove: (pos) { print(pos.target); },
/// )
/// ```
class CustomMap extends StatelessWidget {
  const CustomMap({
    super.key,
    required this.initialPosition,
    this.useMapbox = false,
    this.myLocationEnabled = true,
    this.onMapCreated,
    this.onCameraMove,
    this.onCameraIdle,
    this.onCameraMoveStarted,
    this.markers = const {},
    this.polylines = const {},
    this.polygons = const {},
    this.circles = const {},
    this.showPin = true,
    this.showMyPosition = true,
    this.onMoveToMyPosition,
    this.padding = EdgeInsets.zero,
    this.customPin,
    this.onTap,
    this.boundsRestriction,
    this.zoomGesturesEnabled = true,
    this.scrollGesturesEnabled = true,
    this.widgetOverlays,
    this.customMyPositionWidget,
    this.actions,
    this.liteModeEnabled = false,
    this.mapStyle,
  });

  /// Posición inicial de la cámara al crear el mapa.
  final MapCameraPosition initialPosition;

  /// Si `true` usa Mapbox; si `false` (default) usa Google Maps.
  final bool useMapbox;

  final bool myLocationEnabled;

  /// Callback invocado cuando el mapa está listo. Recibe el [PlatformMapController].
  final void Function(PlatformMapController controller)? onMapCreated;

  /// Callback invocado cuando la cámara se mueve. Recibe la [MapCameraPosition] actual.
  final void Function(MapCameraPosition position)? onCameraMove;

  final VoidCallback? onCameraIdle;
  final VoidCallback? onCameraMoveStarted;

  /// Marcadores de dominio. No uses `google_maps_flutter.Marker` aquí.
  final Set<MapMarker> markers;
  final Set<MapPolyline> polylines;
  final Set<MapPolygon> polygons;
  final Set<MapCircle> circles;

  final bool showMyPosition;
  final bool showPin;

  /// Si se provee, se llama antes de mover a la ubicación. Si devuelve `false`,
  /// el movimiento se cancela.
  final Future<bool> Function()? onMoveToMyPosition;

  final EdgeInsets padding;
  final Widget? customPin;

  /// Callback cuando el usuario toca el mapa. Recibe [MapLatLng] del punto tocado.
  final void Function(MapLatLng latLng)? onTap;

  /// Restricción de bounds para la cámara (opcional).
  final MapLatLngBounds? boundsRestriction;

  final bool zoomGesturesEnabled;
  final bool scrollGesturesEnabled;

  /// Widgets superpuestos sobre el mapa (ej: MarkerInfoWindow, CustomMarkerAnimated).
  final List<Widget>? widgetOverlays;

  final Widget? customMyPositionWidget;
  final List<Widget>? actions;
  final bool liteModeEnabled;

  /// URI de estilo para Mapbox o JSON de estilo para Google Maps.
  final String? mapStyle;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CustomMapController>(
      create: (_) => CustomMapController(),
      child: _CustomMapBody(widget: this),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _CustomMapBody
// ─────────────────────────────────────────────────────────────────────────────

class _CustomMapBody extends StatefulWidget {
  const _CustomMapBody({required this.widget});

  final CustomMap widget;

  @override
  State<_CustomMapBody> createState() => _CustomMapBodyState();
}

class _CustomMapBodyState extends State<_CustomMapBody> {
  CustomMapController? _controller;

  // Seguimiento de movimiento de cámara para Mapbox (que no tiene callbacks separados).
  MapLatLng? _previousCameraTarget;
  bool _isCameraMoving = false;
  bool _styleLoaded = false;

  CustomMap get w => widget.widget;

  bool get _isDark {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller ??= context.read<CustomMapController>();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<CustomMapController>();

    return Stack(
      children: [
        if (w.useMapbox) _buildMapbox(ctrl) else _buildGoogle(ctrl),
        if (w.widgetOverlays != null) ...w.widgetOverlays!,
        if (w.showPin) _buildPin(ctrl),
        if (w.showMyPosition) _MyPositionButton(w.onMoveToMyPosition, customWidget: w.customMyPositionWidget),
      ],
    );
  }

  // ── Google Maps ──────────────────────────────────────────────────────────

  Widget _buildGoogle(CustomMapController ctrl) {
    // La conversión a tipos de Google ocurre aquí, en la capa del widget,
    // no en el dominio ni en el adapter.
    final externalMarkers =
        w.markers.map((m) => GoogleMapMapper.toMarker(m)).toSet();
    final externalPolylines =
        w.polylines.map((p) => GoogleMapMapper.toPolyline(p)).toSet();
    final externalPolygons =
        w.polygons.map((p) => GoogleMapMapper.toPolygon(p)).toSet();
    final externalCircles =
        w.circles.map((c) => GoogleMapMapper.toCircle(c)).toSet();

    return google.GoogleMap(
      padding: w.padding,
      initialCameraPosition: google.CameraPosition(
        target: google.LatLng(
          w.initialPosition.target.latitude,
          w.initialPosition.target.longitude,
        ),
        zoom: w.initialPosition.zoom,
      ),
      style: w.mapStyle,
      markers: {...ctrl.getGoogleMarkers(), ...externalMarkers},
      polylines: {...ctrl.getGooglePolylines(), ...externalPolylines},
      polygons: {...ctrl.getGooglePolygons(), ...externalPolygons},
      circles: {...ctrl.getGoogleCircles(), ...externalCircles},
      myLocationEnabled: w.myLocationEnabled,
      myLocationButtonEnabled: false,
      mapToolbarEnabled: false,
      zoomControlsEnabled: false,
      tiltGesturesEnabled: false,
      zoomGesturesEnabled: w.zoomGesturesEnabled,
      scrollGesturesEnabled: w.scrollGesturesEnabled,
      compassEnabled: false,
      buildingsEnabled: false,
      liteModeEnabled: w.liteModeEnabled,
      cameraTargetBounds: w.boundsRestriction != null
          ? google.CameraTargetBounds(
              GoogleMapMapper.toLatLngBounds(w.boundsRestriction!),
            )
          : google.CameraTargetBounds.unbounded,
      onTap: w.onTap != null
          ? (ll) => w.onTap!(GoogleMapMapper.fromLatLng(ll))
          : null,
      onMapCreated: (controller) async {
        await ctrl.onMapCreated(controller);
        final platformCtrl = ctrl.mapController;
        if (w.onMapCreated != null && platformCtrl != null) {
          w.onMapCreated!(platformCtrl);
        }
        await Future.delayed(_MapConstants.mapInitDelay);
        if (mounted) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            _applyGoogleStyle(ctrl);
          });
        }
      },
      onCameraMove: (pos) => w.onCameraMove?.call(
        GoogleMapMapper.fromCameraPosition(pos),
      ),
      onCameraIdle: _handleCameraIdle,
      onCameraMoveStarted: _handleCameraMoveStarted,
    );
  }

  // ── Mapbox ───────────────────────────────────────────────────────────────

  Widget _buildMapbox(CustomMapController ctrl) {
    return mapbox.MapWidget(
      cameraOptions: mapbox.CameraOptions(
        center: mapbox.Point(
          coordinates: mapbox.Position(
            w.initialPosition.target.longitude,
            w.initialPosition.target.latitude,
          ),
        ),
        zoom: w.initialPosition.zoom,
        padding: mapbox.MbxEdgeInsets(
          top: w.padding.top,
          left: w.padding.left,
          bottom: w.padding.bottom,
          right: w.padding.right,
        ),
      ),
      onMapCreated: (controller) async {
        await ctrl.onMapCreatedMapbox(controller);
        final platformCtrl = ctrl.mapController;
        if (w.onMapCreated != null && platformCtrl != null) {
          w.onMapCreated!(platformCtrl);
        }
        controller.location.updateSettings(
          mapbox.LocationComponentSettings(enabled: w.myLocationEnabled),
        );
        controller.scaleBar
            .updateSettings(mapbox.ScaleBarSettings(enabled: false));
        controller.compass
            .updateSettings(mapbox.CompassSettings(enabled: false));
        controller.gestures.updateSettings(mapbox.GesturesSettings(
          scrollEnabled: w.scrollGesturesEnabled,
          pinchToZoomEnabled: w.zoomGesturesEnabled,
          scrollMode: mapbox.ScrollMode.HORIZONTAL_AND_VERTICAL,
        ));
      },
      onCameraChangeListener: (event) {
        final newTarget = MapLatLng(
          event.cameraState.center.coordinates.lat.toDouble(),
          event.cameraState.center.coordinates.lng.toDouble(),
        );

        if (_previousCameraTarget == null ||
            MapUtils.hasSignificantMovement(
              _previousCameraTarget!,
              newTarget,
              thresholdMeters: _MapConstants.cameraMovementThresholdMeters,
            )) {
          _previousCameraTarget = newTarget;
          if (!_isCameraMoving) {
            _isCameraMoving = true;
            ctrl.onCameraMoveStarted(w.showPin);
            w.onCameraMoveStarted?.call();
          }
          // Emitir al stream tipado de PlatformMapController para los overlays.
          ctrl.mapController?.emitCameraEvent(const MapCameraEvent.moved());

          w.onCameraMove?.call(MapCameraPosition(
            target: newTarget,
            zoom: event.cameraState.zoom,
            bearing: event.cameraState.bearing,
            tilt: event.cameraState.pitch,
          ));
        }
      },
      onMapIdleListener: (_) {
        if (_isCameraMoving) {
          _isCameraMoving = false;
          ctrl.onCameraIdle(w.showPin);
          ctrl.mapController?.emitCameraEvent(const MapCameraEvent.idle());
          w.onCameraIdle?.call();
        }
      },
      onTapListener: (event) {
        if (w.onTap != null) {
          w.onTap!(MapLatLng(
            event.point.coordinates.lat.toDouble(),
            event.point.coordinates.lng.toDouble(),
          ));
        }
      },
      onStyleLoadedListener: (_) async {
        if (_styleLoaded) return;
        _styleLoaded = true;
        if (ctrl.mapController != null) {
          await ctrl.updateMapStyle(
            isDark: _isDark,
            styleUri: w.mapStyle,
          );
          await ctrl.initMapManagersIfNeeded();
        }
      },
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _buildPin(CustomMapController ctrl) {
    return Align(
      alignment: Alignment.center,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(
          bottom: ctrl.movingMap ? 16.0 : 0.0,
        ),
        child: w.customPin ?? const _DefaultPin(),
      ),
    );
  }

  void _handleCameraIdle() {
    if (!mounted) return;
    _controller?.onCameraIdle(w.showPin);
    _controller?.mapController?.emitCameraEvent(const MapCameraEvent.idle());
    w.onCameraIdle?.call();
  }

  void _handleCameraMoveStarted() {
    _controller?.onCameraMoveStarted(w.showPin);
    _controller?.mapController
        ?.emitCameraEvent(const MapCameraEvent.moveStarted());
    w.onCameraMoveStarted?.call();
  }

  Future<void> _applyGoogleStyle(CustomMapController ctrl) async {
    if (w.mapStyle != null) {
      await ctrl.updateMapStyle(isDark: _isDark, styleUri: w.mapStyle);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets internos
// ─────────────────────────────────────────────────────────────────────────────

class _DefaultPin extends StatelessWidget {
  const _DefaultPin();

  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.location_pin, size: 40, color: Colors.red);
  }
}

class _MyPositionButton extends StatelessWidget {
  const _MyPositionButton(
    this.onMoveToMyPosition, {
    this.customWidget,
  });

  final Future<bool> Function()? onMoveToMyPosition;
  final Widget? customWidget;

  @override
  Widget build(BuildContext context) {
    final ctrl = context.read<CustomMapController>();

    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 12.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(100),
          onTap: () async {
            bool canMove = true;
            if (onMoveToMyPosition != null) {
              canMove = await onMoveToMyPosition!();
            }
            if (canMove) ctrl.animateTo(ctrl.markers.values.firstOrNull?.position ?? const MapLatLng(0, 0));
          },
          child: customWidget ??
              Card(
                shape: const CircleBorder(),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Icon(
                    Icons.my_location_outlined,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Re-exports del mapper para uso en el widget
// ─────────────────────────────────────────────────────────────────────────────

/// Acceso directo al mapper de Google desde la capa de widget.
/// Solo para uso interno de [_CustomMapBody].
class GoogleMapMapper {
  static google.LatLng toLatLng(MapLatLng p) =>
      google.LatLng(p.latitude, p.longitude);

  static MapLatLng fromLatLng(google.LatLng ll) =>
      MapLatLng(ll.latitude, ll.longitude);

  static google.LatLngBounds toLatLngBounds(MapLatLngBounds b) =>
      google.LatLngBounds(
        northeast: toLatLng(b.northeast),
        southwest: toLatLng(b.southwest),
      );

  static google.Marker toMarker(MapMarker m) {
    return google.Marker(
      markerId: google.MarkerId(m.id),
      position: toLatLng(m.position),
      icon: m.icon != null
          ? google.BitmapDescriptor.fromBytes(m.icon!)
          : google.BitmapDescriptor.defaultMarker,
      rotation: m.rotation,
      zIndex: m.zIndex,
      anchor: m.anchor,
      onTap: m.onTap,
      consumeTapEvents: m.consumeTapEvents,
      infoWindow: m.infoWindowTitle != null
          ? google.InfoWindow(
              title: m.infoWindowTitle, snippet: m.infoWindowSnippet)
          : google.InfoWindow.noText,
    );
  }

  static google.Polyline toPolyline(MapPolyline p) => google.Polyline(
        polylineId: google.PolylineId(p.id),
        points: p.points.map(toLatLng).toList(),
        color: p.color,
        width: p.width.toInt(),
        geodesic: p.geodesic,
        visible: p.visible,
        zIndex: p.zIndex,
      );

  static google.Polygon toPolygon(MapPolygon p) => google.Polygon(
        polygonId: google.PolygonId(p.id),
        points: p.points.map(toLatLng).toList(),
        fillColor: p.fillColor,
        strokeColor: p.strokeColor,
        strokeWidth: p.strokeWidth,
        visible: p.visible,
        zIndex: p.zIndex,
        geodesic: p.geodesic,
        onTap: p.onTap,
        consumeTapEvents: p.consumeTapEvents,
      );

  static google.Circle toCircle(MapCircle c) => google.Circle(
        circleId: google.CircleId(c.id),
        center: toLatLng(c.center),
        radius: c.radius,
        fillColor: c.fillColor,
        strokeColor: c.strokeColor,
        strokeWidth: c.strokeWidth,
      );

  static MapCameraPosition fromCameraPosition(google.CameraPosition pos) =>
      MapCameraPosition(
        target: fromLatLng(pos.target),
        zoom: pos.zoom,
        bearing: pos.bearing,
        tilt: pos.tilt,
      );
}
