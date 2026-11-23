import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AuthController extends ChangeNotifier {
  AuthController({http.Client? client}) : _client = client ?? http.Client();

  static const _apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  final http.Client _client;
  String? _notice;
  String? _accessToken;
  Map<String, dynamic>? _user;
  List<Map<String, dynamic>> _universities = [];
  String? _universityError;
  bool _noticeIsSuccess = false;
  bool _isLoading = false;
  bool _isLoadingUniversities = false;
  bool _isCheckingDatabase = true;
  bool? _databaseConnected;

  String? get notice => _notice;
  String? get accessToken => _accessToken;
  Map<String, dynamic>? get user => _user;
  List<Map<String, dynamic>> get universities => _universities;
  String? get universityError => _universityError;
  bool get noticeIsSuccess => _noticeIsSuccess;
  bool get isLoading => _isLoading;
  bool get isLoadingUniversities => _isLoadingUniversities;
  bool get isCheckingDatabase => _isCheckingDatabase;
  bool? get databaseConnected => _databaseConnected;
  bool get isAuthenticated => _accessToken != null && _user != null;

  String get firstName {
    final name = (_user?['nombre_completo'] as String? ?? '').trim();
    return name.isEmpty ? 'usuario' : name.split(RegExp(r'\s+')).first;
  }

  String get roleLabel => _roleLabel(_user?['rol'] as String?);
  String get universityName => _user?['universidad'] as String? ?? '';

  Future<void> checkDatabaseConnection() async {
    _isCheckingDatabase = true;
    notifyListeners();

    try {
      final response = await _client
          .get(Uri.parse('$_apiBaseUrl/health'))
          .timeout(const Duration(seconds: 5));
      final payload = _decodeJson(response.body);
      _databaseConnected =
          response.statusCode == 200 && payload?['database'] == 'connected';
    } on Exception {
      _databaseConnected = false;
    } finally {
      _isCheckingDatabase = false;
      notifyListeners();
    }
  }

  Future<void> loadUniversities() async {
    if (_universities.isNotEmpty || _isLoadingUniversities) return;
    _isLoadingUniversities = true;
    _universityError = null;
    notifyListeners();

    try {
      final response = await _client
          .get(Uri.parse('$_apiBaseUrl/universidades'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        _universityError = 'No se pudo cargar el catálogo de universidades.';
        return;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        _universityError = 'La API devolvió un catálogo inválido.';
        return;
      }
      _universities = decoded.whereType<Map<String, dynamic>>().toList(
        growable: false,
      );
      if (_universities.isEmpty) {
        _universityError = 'Aún no hay universidades en el catálogo.';
      }
    } on Exception {
      _universityError =
          'No se pudo conectar con el catálogo de universidades.';
    } finally {
      _isLoadingUniversities = false;
      notifyListeners();
    }
  }

  Future<bool> login({required String email, required String password}) {
    return _sendAuth(
      path: '/auth/login',
      body: {'email': email.trim(), 'password': password},
    );
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required int universityId,
    required String role,
  }) {
    return _sendAuth(
      path: '/auth/register',
      body: {
        'nombre_completo': name.trim(),
        'email': email.trim(),
        'password': password,
        'id_univ': universityId,
        'rol': role,
      },
    );
  }

  Future<bool> _sendAuth({
    required String path,
    required Map<String, dynamic> body,
  }) async {
    _isLoading = true;
    _notice = null;
    _noticeIsSuccess = false;
    notifyListeners();

    try {
      final response = await _client
          .post(
            Uri.parse('$_apiBaseUrl$path'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
      final payload = _decodeJson(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          payload != null) {
        _accessToken = payload['access_token'] as String?;
        _user = payload['user'] as Map<String, dynamic>?;
        _databaseConnected = true;
        _noticeIsSuccess = true;
        _notice = path.endsWith('/register')
            ? payload['message'] as String? ??
                  'Cuenta creada. ¡Bienvenido, $firstName!'
            : 'Inicio de sesión correcto. ¡Hola, $firstName!';
        return true;
      }

      _accessToken = null;
      _user = null;
      if (response.statusCode == 401) {
        _notice = 'Correo o contraseña incorrectos.';
      } else if (response.statusCode == 403) {
        _notice = _detailMessage(payload) ?? 'Esta cuenta está desactivada.';
      } else if (response.statusCode == 409) {
        _notice = 'Ya existe una cuenta con ese correo.';
      } else if (response.statusCode == 422) {
        _notice =
            _detailMessage(payload) ??
            'Revisa los datos del formulario e inténtalo de nuevo.';
      } else if (response.statusCode == 503) {
        _databaseConnected = false;
        _notice = 'La API no pudo consultar la base de datos.';
      } else {
        _notice = 'No se pudo completar la solicitud. Inténtalo de nuevo.';
      }
    } on TimeoutException {
      _accessToken = null;
      _databaseConnected = false;
      _notice = 'La conexión con la API tardó demasiado.';
    } on Exception {
      _accessToken = null;
      _databaseConnected = false;
      _notice = 'No se pudo conectar con la API. Comprueba que esté iniciada.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  void logout() {
    _accessToken = null;
    _user = null;
    clearNotice();
    notifyListeners();
  }

  void clearNotice() {
    if (_notice == null && !_noticeIsSuccess) return;
    _notice = null;
    _noticeIsSuccess = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }

  Map<String, dynamic>? _decodeJson(String body) {
    try {
      final value = jsonDecode(body);
      return value is Map<String, dynamic> ? value : null;
    } on FormatException {
      return null;
    }
  }

  String? _detailMessage(Map<String, dynamic>? payload) {
    final detail = payload?['detail'];
    return detail is String ? detail : null;
  }

  String _roleLabel(String? role) => switch (role) {
    'institucion' => 'Institución',
    'entrenador' => 'Entrenador',
    'jugador' => 'Jugador',
    _ => 'Cuenta',
  };
}
