/// SDK de mapas multi-plataforma (Google Maps + Mapbox).
///
/// Importa este archivo para acceder a toda la API pública del SDK:
/// ```dart
/// import 'package:your_package/map_sdk/map_sdk.dart';
/// ```
///
/// ### Capas del SDK:
/// - **models/**: Tipos del dominio (`MapLatLng`, `MapMarker`, etc.)
/// - **adapters/**: Interfaz y adapters para Google/Mapbox
/// - **controllers/**: `PlatformMapController` y `CustomMapController`
/// - **widgets/**: `CustomMap`, `MarkerInfoWindow`, `CustomMarkerAnimated`
/// - **utils/**: `MapUtils` y extensiones
/// - **testing/**: `FakeMapControllerAdapter` para tests

// ── Modelos de dominio ────────────────────────────────────────
export 'models/map_camera_position.dart';
export 'models/map_latlng.dart';
export 'models/map_latlng_bounds.dart';
export 'models/map_marker.dart';
export 'models/map_screen_coordinate.dart';
export 'models/map_shapes.dart';

// ── Interfaz del adapter (para extensibilidad) ────────────────
export 'adapters/map_controller_adapter.dart';
export 'adapters/safe_map_controller_lifecycle.dart';

// ── Controladores ─────────────────────────────────────────────
export 'controllers/custom_map_controller.dart';
export 'controllers/platform_map_controller.dart';

// ── Widgets ───────────────────────────────────────────────────
export 'widgets/custom_map.dart'
    hide GoogleMapMapper; // GoogleMapMapper es interno
export 'widgets/custom_marker_animated.dart';
export 'widgets/marker_info_window.dart';
export 'widgets/multi_marker_widget.dart';

// ── Utilidades ────────────────────────────────────────────────
export 'utils/map_utils.dart';

// ── Testing (solo importar en test/) ─────────────────────────
// export 'testing/fake_map_controller_adapter.dart';
// Descomenta la línea anterior en tu archivo de test o usa:
// import 'package:your_package/map_sdk/testing/fake_map_controller_adapter.dart';
