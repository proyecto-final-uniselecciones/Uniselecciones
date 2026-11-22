# UniSelecciones Flutter

Aplicación base de UniSelecciones para Android, Windows y web. La primera
pantalla sigue el flujo de acceso de los prototipos. La autenticación todavía
no está conectada a FastAPI: al enviar un formulario válido, la app informa
que el servicio está pendiente y no transmite ni guarda las credenciales.

## Requisitos

- Flutter estable y Dart incluidos en Flutter.
- Para Android: Android SDK y un teléfono conectado o emulador disponible.
- Para Windows: Visual Studio Build Tools con el compilador de C++.
- Para web: Chrome o Edge.

## Ejecutar desde esta carpeta

    flutter pub get
    flutter devices
    flutter run -d chrome

Para ejecutar la aplicación nativa de Windows:

    flutter run -d windows

Para Android, conecta un teléfono con depuración USB y ejecuta flutter devices;
después pasa a flutter run -d <id-del-dispositivo>.

## Organización del código

- lib/app/: tema, router y estado compartido.
- lib/features/: funciones agrupadas por módulo; por ahora está el acceso.
- lib/main.dart: punto de entrada y proveedores globales.

El router reservará la navegación por rol para el momento en que el token real
de la API devuelva el rol de institución, entrenador o jugador.
