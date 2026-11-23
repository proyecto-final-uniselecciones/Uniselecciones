import 'package:material_ui/material_ui.dart';

import 'router.dart';
import 'theme.dart';

class UniSeleccionesApp extends StatelessWidget {
  const UniSeleccionesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'UniSelecciones',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
