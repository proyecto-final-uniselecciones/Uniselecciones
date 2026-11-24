import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../app/auth_controller.dart';
import '../../../app/theme.dart';
import 'coach_home_screen.dart';
import 'dashboard_components.dart';
import 'institution_home_screen.dart';
import 'player_home_screen.dart';

/// Selector de panel por rol. Sin sesión, regresa a la pantalla de acceso.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    if (!auth.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/login');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return switch (auth.user?['rol']) {
      'jugador' => const PlayerHomeScreen(),
      'entrenador' => const CoachHomeScreen(),
      'institucion' => const InstitutionHomeScreen(),
      _ => const _UnsupportedRoleScreen(),
    };
  }
}

/// Respaldo para un rol que la aplicación no reconoce. No es una sección
/// de negocio: solo explica qué pasó y deja salir.
class _UnsupportedRoleScreen extends StatelessWidget {
  const _UnsupportedRoleScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UniColors.canvas,
      appBar: AppBar(
        titleSpacing: 20,
        title: const UniBrandMark(compact: true),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: UniColors.surface,
                borderRadius: UniShape.lg,
                border: Border.all(color: UniColors.line),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: UniColors.gold.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      size: 32,
                      color: Color(0xFF8A6200),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'PERFIL NO RECONOCIDO',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'No encontramos una interfaz para este perfil. Comprueba '
                    'el rol de la cuenta con la institución.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: UniColors.inkSoft),
                  ),
                  const SizedBox(height: 26),
                  FilledButton(
                    onPressed: () {
                      context.read<AuthController>().logout();
                      context.go('/login');
                    },
                    child: const Text('CERRAR SESIÓN'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
