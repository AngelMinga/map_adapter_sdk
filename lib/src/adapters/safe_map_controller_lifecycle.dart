import 'package:flutter/foundation.dart';

/// Mixin que protege el ciclo de vida de un controlador de mapa.
///
/// Garantiza que las operaciones no se ejecuten tras el `dispose()`.
/// Úsalo en cualquier adapter (`GoogleMapAdapter`, `MapboxMapAdapter`) para
/// evitar `StateError` y excepciones de plataforma en cierre de pantallas.
///
/// Ejemplo:
/// ```dart
/// class GoogleMapAdapter with SafeMapControllerLifecycle implements MapControllerAdapter {
///   @override
///   Future<void> dispose() async {
///     await safeDispose(() async { googleController.dispose(); });
///   }
/// }
/// ```
mixin SafeMapControllerLifecycle {
  bool _disposed = false;

  /// `true` si el controlador ya fue descartado.
  bool get isDisposed => _disposed;

  /// Ejecuta [disposeAction] de forma segura y marca el controlador como destruido.
  ///
  /// Si ya fue llamado previamente, es un no-op.
  Future<void> safeDispose(Future<void> Function() disposeAction) async {
    if (_disposed) return;
    _disposed = true;
    try {
      await disposeAction();
    } catch (e, stack) {
      _safeLog('Error during safeDispose: $e\n$stack');
    }
  }

  /// Ejecuta [action] solo si el controlador no ha sido destruido.
  ///
  /// Devuelve `null` si está destruido o si [action] lanza una excepción.
  Future<T?> runIfAlive<T>(Future<T> Function() action) async {
    if (_disposed) return null;
    try {
      return await action();
    } catch (e, stack) {
      _safeLog('Error in runIfAlive: $e\n$stack');
      return null;
    }
  }

  /// Versión síncrona de [runIfAlive].
  void runIfAliveSync(void Function() action) {
    if (_disposed) return;
    try {
      action();
    } catch (e, stack) {
      _safeLog('Error in runIfAliveSync: $e\n$stack');
    }
  }

  void _safeLog(Object message) {
    debugPrint('[SafeMapControllerLifecycle] $message');
  }
}
