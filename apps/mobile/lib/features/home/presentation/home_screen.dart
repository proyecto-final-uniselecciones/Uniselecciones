import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../app/auth_controller.dart';
import 'coach_home_screen.dart';
import 'institution_home_screen.dart';
import 'player_home_screen.dart';

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

class _UnsupportedRoleScreen extends StatelessWidget {
  const _UnsupportedRoleScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('UniSelecciones')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 48),
              const SizedBox(height: 12),
              const Text('No encontramos una interfaz para este perfil.'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  context.read<AuthController>().logout();
                  context.go('/login');
                },
                child: const Text('Cerrar sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
