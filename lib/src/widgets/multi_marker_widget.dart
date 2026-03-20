import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../controllers/platform_map_controller.dart';
import '../models/models.dart';

/// Overlay que renderiza múltiples widgets anclados a coordenadas geográficas.
///
/// Escucha [PlatformMapController.cameraEvents] para reposicionarse.
///
/// Ejemplo:
/// ```dart
/// MultiMarkerWidget(
///   mapController: platformController,
///   width: 80,
///   height: 40,
///   markers: {
///     MapLatLng(-2.19, -79.89): Text('Punto A'),
///     MapLatLng(-2.20, -79.90): Icon(Icons.star),
///   },
/// )
/// ```
class MultiMarkerWidget extends StatefulWidget {
  const MultiMarkerWidget({
    super.key,
    required this.mapController,
    required this.markers,
    required this.width,
    required this.height,
    this.onTap,
  });

  final PlatformMapController mapController;

  /// Mapa de posición → widget que se mostrará en esa coordenada.
  final Map<MapLatLng, Widget> markers;

  final double width;
  final double height;
  final VoidCallback? onTap;

  @override
  State<MultiMarkerWidget> createState() => _MultiMarkerWidgetState();
}

class _MultiMarkerWidgetState extends State<MultiMarkerWidget> {
  StreamSubscription<MapCameraEvent>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = widget.mapController.cameraEvents.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          for (final entry in widget.markers.entries)
            _AnchoredMarker(
              mapController: widget.mapController,
              position: entry.key,
              width: widget.width,
              height: widget.height,
              child: entry.value,
            ),
        ],
      ),
    );
  }
}

// ── Widget individual anclado a un punto ──────────────────────────────────────

class _AnchoredMarker extends StatefulWidget {
  const _AnchoredMarker({
    required this.mapController,
    required this.position,
    required this.width,
    required this.height,
    required this.child,
  });

  final PlatformMapController mapController;
  final MapLatLng position;
  final double width;
  final double height;
  final Widget child;

  @override
  State<_AnchoredMarker> createState() => _AnchoredMarkerState();
}

class _AnchoredMarkerState extends State<_AnchoredMarker> {
  MapScreenCoordinate? _coord;
  double _left = 0;
  double _top = 0;

  @override
  void initState() {
    super.initState();
    _updatePosition();
  }

  @override
  void didUpdateWidget(_AnchoredMarker old) {
    super.didUpdateWidget(old);
    if (old.position != widget.position) _updatePosition();
  }

  @override
  Widget build(BuildContext context) {
    if (_coord == null) return const SizedBox.shrink();

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 50),
      top: _top,
      left: _left,
      child: IgnorePointer(
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: widget.child,
        ),
      ),
    );
  }

  Future<void> _updatePosition() async {
    if (!mounted) return;
    final dpr =
        Platform.isAndroid ? MediaQuery.of(context).devicePixelRatio : 1.0;

    final coord = await widget.mapController
        .getScreenCoordinateFromLatLng(widget.position);

    if (!mounted) return;
    setState(() {
      _coord = coord;
      _left = (coord.x / dpr) - (widget.width / 2);
      _top = (coord.y / dpr) - (widget.height / 2);
    });
  }
}
