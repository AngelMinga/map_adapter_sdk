import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../controllers/platform_map_controller.dart';
import '../models/models.dart';

/// Overlay animado que sigue la posición de un punto geográfico en pantalla.
///
/// Se actualiza con cada movimiento de cámara escuchando
/// [PlatformMapController.cameraEvents].
///
/// ### Correcciones respecto al original:
/// - Stream tipado [MapCameraEvent] en lugar de `dynamic`.
/// - Usa [MapLatLng] y [MapScreenCoordinate] del dominio.
/// - La lógica de cálculo de posición está centralizada.
/// - El widget se oculta cuando el punto sale del `visibleRegion`.
class CustomMarkerAnimated extends StatefulWidget {
  const CustomMarkerAnimated({
    super.key,
    required this.child,
    required this.mapController,
    required this.position,
    required this.width,
    required this.height,
    this.onTap,
  });

  final PlatformMapController mapController;
  final MapLatLng position;
  final double width;
  final double height;
  final VoidCallback? onTap;
  final Widget child;

  @override
  State<CustomMarkerAnimated> createState() => _CustomMarkerAnimatedState();
}

class _CustomMarkerAnimatedState extends State<CustomMarkerAnimated> {
  MapScreenCoordinate? _screenCoordinate;
  double _left = 0;
  double _top = 0;
  bool _visible = false;
  StreamSubscription<MapCameraEvent>? _mapSubscription;

  @override
  void initState() {
    super.initState();
    _updatePosition();
    _mapSubscription =
        widget.mapController.cameraEvents.listen((_) => _updatePosition());
  }

  @override
  void dispose() {
    _mapSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_screenCoordinate == null) return const SizedBox.shrink();

    return Visibility(
      visible: _visible,
      child: AnimatedPositioned(
        curve: Curves.easeOut,
        duration: const Duration(milliseconds: 50),
        top: _top,
        left: _left,
        child: GestureDetector(
          onTap: widget.onTap,
          child: SizedBox(
            width: widget.width,
            height: widget.height,
            child: widget.child,
          ),
        ),
      ),
    );
  }

  Future<void> _updatePosition() async {
    if (!mounted) return;

    final dpr =
        Platform.isAndroid ? MediaQuery.of(context).devicePixelRatio : 1.0;

    final visibleRegion =
        await widget.mapController.getVisibleRegion();
    final coordinate = await widget.mapController
        .getScreenCoordinateFromLatLng(widget.position);

    if (!mounted) return;

    final isVisible = visibleRegion.contains(widget.position);

    setState(() {
      _screenCoordinate = coordinate;
      _visible = isVisible;
      _left = (coordinate.x / dpr) - (widget.width / 2);
      _top = (coordinate.y / dpr) - (widget.height / 2);
    });
  }
}
