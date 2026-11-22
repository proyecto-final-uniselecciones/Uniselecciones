import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'app/auth_controller.dart';
import 'app/uniselecciones_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthController(),
      child: const UniSeleccionesApp(),
    ),
  );
}
