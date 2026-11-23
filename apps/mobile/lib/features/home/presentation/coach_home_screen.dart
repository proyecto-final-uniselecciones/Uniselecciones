import 'package:material_ui/material_ui.dart';

import 'dashboard_components.dart';

class CoachHomeScreen extends StatelessWidget {
  const CoachHomeScreen({super.key});

  static const _green = Color(0xFF16803C);

  @override
  Widget build(BuildContext context) {
    return RoleDashboardShell(
      roleTitle: 'Entrenador',
      roleDescription:
          'Organiza tu selección, prepara entrenamientos y da seguimiento '
          'a tus jugadores.',
      icon: Icons.sports,
      accentColor: _green,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DashboardSectionTitle(
            title: 'Mi selección',
            description: 'Herramientas para organizar a tu equipo.',
          ),
          const SizedBox(height: 14),
          const DashboardGrid(
            children: [
              DashboardStatCard(
                icon: Icons.groups,
                label: 'Jugadores',
                value: '—',
                detail: 'Datos aún no conectados',
                color: _green,
              ),
              DashboardStatCard(
                icon: Icons.fitness_center,
                label: 'Entrenamientos',
                value: '—',
                detail: 'Datos aún no conectados',
                color: _green,
              ),
              DashboardStatCard(
                icon: Icons.emoji_events,
                label: 'Partidos',
                value: '—',
                detail: 'Datos aún no conectados',
                color: _green,
              ),
            ],
          ),
          const SizedBox(height: 28),
          const DashboardSectionTitle(title: 'Administración deportiva'),
          const SizedBox(height: 14),
          const DashboardGrid(
            childAspectRatio: 2.2,
            children: [
              DashboardFeatureCard(
                icon: Icons.groups,
                title: 'Plantilla',
                description: 'Consulta y organiza a los integrantes.',
                color: _green,
              ),
              DashboardFeatureCard(
                icon: Icons.event_available,
                title: 'Entrenamientos',
                description: 'Programa sesiones para tu selección.',
                color: _green,
              ),
              DashboardFeatureCard(
                icon: Icons.fact_check,
                title: 'Asistencia y resultados',
                description: 'Lleva el seguimiento de actividad y partidos.',
                color: _green,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
