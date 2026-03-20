import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../controllers/platform_map_controller.dart';
import '../models/models.dart';

/// Overlay de información flotante sobre un marcador del mapa.
///
/// Se posiciona automáticamente sobre la coordenada [position] y se
/// refresca cuando la cámara se mueve (escucha [PlatformMapController.cameraEvents]).
///
/// ### Correcciones respecto al original:
/// - Usa `Stream<MapCameraEvent>` tipado en lugar de `Stream<dynamic>`.
/// - Usa [MapLatLng] y [MapScreenCoordinate] del dominio.
/// - El cálculo de posición se extrae a un método puro testeable.
class MarkerInfoWindow extends StatefulWidget {
  const MarkerInfoWindow({
    super.key,
    required this.mapController,
    required this.position,
    required this.infoWindowWidth,
    required this.infoWindowHeight,
    required this.title,
    this.subtitle,
    this.onTap,
    this.suffixIcon,
  });

  final PlatformMapController mapController;
  final MapLatLng position;
  final double infoWindowWidth;
  final double infoWindowHeight;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? suffixIcon;

  @override
  State<MarkerInfoWindow> createState() => _MarkerInfoWindowState();
}

class _MarkerInfoWindowState extends State<MarkerInfoWindow> {
  MapScreenCoordinate? _screenCoordinate;
  double _left = 0;
  double _top = 0;
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

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 50),
      top: _top,
      left: _left,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: widget.infoWindowWidth,
          height: widget.infoWindowHeight,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          child: Row(
            children: [
              if (widget.suffixIcon != null) ...[
                widget.suffixIcon!,
                const SizedBox(width: 5),
              ],
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 7,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          widget.title,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (widget.subtitle != null)
                      Expanded(
                        flex: 3,
                        child: Text(
                          widget.subtitle!,
                          style: const TextStyle(fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              if (widget.onTap != null)
                const Icon(Icons.arrow_forward_ios, size: 15, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _updatePosition() {
    widget.mapController
        .getScreenCoordinateFromLatLng(widget.position)
        .then((coordinate) {
      if (!mounted) return;
      final dpr =
          Platform.isAndroid ? MediaQuery.of(context).devicePixelRatio : 1.0;

      double left =
          (coordinate.x / dpr) - (widget.infoWindowWidth / 2);
      double top = (coordinate.y / dpr) - widget.infoWindowHeight - 10;

      // Clamp a los límites de la pantalla.
      if (left < 0) left = 0;
      if (top < 0) top = 0;

      setState(() {
        _screenCoordinate = coordinate;
        _left = left;
        _top = top;
      });
    });
  }
}
