# UniSelecciones Flutter

Aplicación base de UniSelecciones para Android, Windows y web. La pantalla de
acceso consulta el estado de PostgreSQL a través de FastAPI y envía las
credenciales a `POST /auth/login`. Cuando el servicio autentica la cuenta, la
app muestra el nombre y rol recibidos y conserva el JWT en memoria. También
permite crear una cuenta como jugador, entrenador o institución, elegir
estado y universidad, y continuar al panel correspondiente. Cualquiera de los
tres roles queda activo al completar el registro.

## Requisitos

- Flutter estable y Dart incluidos en Flutter.
- Para Android: Android SDK y un teléfono conectado o emulador disponible.
- Para Windows: Visual Studio Build Tools con el compilador de C++.
- Para web: Chrome o Edge.

## Ejecutar desde esta carpeta

    flutter pub get
    flutter devices
    flutter run -d chrome

Antes de iniciar Flutter, levanta PostgreSQL y FastAPI siguiendo
[`../api/README.md`](../api/README.md). La URL local predeterminada es
`http://127.0.0.1:8000`; puede cambiarse con:

    flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000

Para ejecutar la aplicación nativa de Windows:

    flutter run -d windows

Para Android, conecta un teléfono con depuración USB y ejecuta flutter devices;
después pasa a flutter run -d <id-del-dispositivo>.

## Organización del código

- lib/app/: tema, router y estado compartido.
- lib/features/auth/: registro e inicio de sesión.
- lib/features/home/: paneles distintos para jugador, entrenador e institución.
- lib/main.dart: punto de entrada y proveedores globales.
