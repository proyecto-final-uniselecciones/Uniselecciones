import 'package:flutter/foundation.dart';

/// Estado de interfaz de autenticación.
///
/// La autenticación real se conectará cuando esté disponible el contrato de la
/// API. Esta primera pantalla no envía, registra ni persiste credenciales.
class AuthController extends ChangeNotifier {
  String? _notice;

  String? get notice => _notice;

  void announceApiPending() {
    _notice =
        'La API de acceso aún no está conectada. Tus credenciales no se enviaron.';
    notifyListeners();
  }

  void clearNotice() {
    if (_notice == null) return;
    _notice = null;
    notifyListeners();
  }
}
