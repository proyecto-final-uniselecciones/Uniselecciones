// =====================================================================
//  UniSelecciones · punto de entrada SOLO para ver el diseño
//
//  Para qué sirve: permite recorrer las cinco interfaces sin levantar
//  FastAPI ni PostgreSQL. Sustituye el cliente HTTP de AuthController por
//  uno simulado que responde /health, /universidades, /auth/login y
//  /auth/register con datos fijos.
//
//  Lo que NO hace: no toca ni una línea del código de la aplicación. Ni
//  AuthController, ni las pantallas, ni el router. Es un main aparte.
//  La aplicación de verdad sigue siendo lib/main.dart y sigue hablando
//  con la API real.
//
//  Cómo se usa:
//      flutter run -d chrome -t lib/main_vista_previa.dart
//
//  Cuentas para recorrer los tres paneles (cualquier contraseña sirve
//  aquí, porque no hay base de datos que valide):
//      al999901@edu.uaa.mx  ->  panel de institución
//      al999902@edu.uaa.mx  ->  panel de entrenador
//      al999903@edu.uaa.mx  ->  panel de jugador
//      cualquier otro correo ->  panel de jugador
// =====================================================================

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'app/auth_controller.dart';
import 'app/router.dart';
import 'app/uniselecciones_app.dart';

/// Respuesta JSON en UTF-8, para que los acentos no se rompan.
http.Response _json(Object cuerpo, {int codigo = 200}) {
  return http.Response(
    jsonEncode(cuerpo),
    codigo,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

const _universidades = [
  {'id_univ': 1001, 'nombre': 'Universidad Autónoma de Aguascalientes', 'region': 'AGS'},
  {'id_univ': 1002, 'nombre': 'Instituto Tecnológico de Aguascalientes', 'region': 'AGS'},
  {'id_univ': 1003, 'nombre': 'Universidad Politécnica de Aguascalientes', 'region': 'AGS'},
  {'id_univ': 2001, 'nombre': 'Universidad de Guadalajara', 'region': 'JAL'},
  {'id_univ': 2002, 'nombre': 'Tecnológico de Monterrey Campus Guadalajara', 'region': 'JAL'},
  {'id_univ': 3001, 'nombre': 'Universidad Autónoma de Zacatecas', 'region': 'ZAC'},
  {'id_univ': 3002, 'nombre': 'Universidad Politécnica de Zacatecas', 'region': 'ZAC'},
];

/// Decide el rol a partir del correo, para poder ver los tres paneles.
String _rolPara(String correo) {
  final c = correo.toLowerCase();
  if (c.startsWith('al999901')) return 'institucion';
  if (c.startsWith('al999902')) return 'entrenador';
  return 'jugador';
}

String _nombrePara(String rol) => switch (rol) {
  'institucion' => 'Coordinación Deportiva UAA',
  'entrenador' => 'Obed Loera Quiroz',
  _ => 'Luis Gustavo Martínez Muñoz',
};

http.Client _clienteSimulado() {
  return MockClient((peticion) async {
    final ruta = peticion.url.path;

    if (ruta == '/health') {
      return _json({'status': 'ok', 'database': 'connected'});
    }

    if (ruta == '/universidades') {
      return _json(_universidades);
    }

    if (ruta == '/auth/login' || ruta == '/auth/register') {
      final cuerpo = jsonDecode(peticion.body) as Map<String, dynamic>;
      final correo = (cuerpo['email'] as String? ?? '').trim();
      final rol = ruta == '/auth/register'
          ? (cuerpo['rol'] as String? ?? 'jugador')
          : _rolPara(correo);
      final nombre = ruta == '/auth/register'
          ? (cuerpo['nombre_completo'] as String? ?? 'Invitado')
          : _nombrePara(rol);

      return _json({
        'access_token': 'vista-previa-sin-backend',
        'user': {
          'nombre_completo': nombre,
          'rol': rol,
          'universidad': 'Universidad Autónoma de Aguascalientes',
          'email': correo,
        },
        'message': 'Cuenta creada en modo vista previa.',
      }, codigo: ruta == '/auth/register' ? 201 : 200);
    }

    return _json({'detail': 'Ruta no simulada: $ruta'}, codigo: 404);
  });
}

/// Correo de demostración de cada rol.
String _correoPara(String rol) => switch (rol) {
  'institucion' => 'al999901@edu.uaa.mx',
  'entrenador' => 'al999902@edu.uaa.mx',
  _ => 'al999903@edu.uaa.mx',
};

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final controlador = AuthController(client: _clienteSimulado());

  runApp(
    ChangeNotifierProvider<AuthController>.value(
      value: controlador,
      child: const UniSeleccionesApp(),
    ),
  );

  // Atajo para tomar capturas de pantalla sin teclear:
  //     http://localhost:5599/?rol=jugador
  //     http://localhost:5599/?rol=entrenador
  //     http://localhost:5599/?rol=institucion
  // Entra solo con la cuenta de ese rol y abre su panel. Sin el parámetro
  // la aplicación arranca normal, en la pantalla de acceso.
  final rol = Uri.base.queryParameters['rol'];
  if (rol != null && rol.isNotEmpty) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final entro = await controlador.login(
        email: _correoPara(rol),
        password: 'VistaPrevia#2026',
      );
      if (entro) appRouter.go('/home');
    });
  }
}
