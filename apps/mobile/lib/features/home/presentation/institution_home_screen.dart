import 'package:material_ui/material_ui.dart';

import 'dashboard_components.dart';

class InstitutionHomeScreen extends StatelessWidget {
  const InstitutionHomeScreen({super.key});

  static const _purple = Color(0xFF7652C8);

  @override
  Widget build(BuildContext context) {
    return RoleDashboardShell(
      roleTitle: 'Institución',
      roleDescription:
          'Coordina la participación de tu universidad y consulta la actividad '
          'de sus selecciones.',
      icon: Icons.account_balance,
      accentColor: _purple,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DashboardSectionTitle(
            title: 'Actividad institucional',
            description: 'Resumen de la participación de tu universidad.',
          ),
          const SizedBox(height: 14),
          const DashboardGrid(
            children: [
              DashboardStatCard(
                icon: Icons.emoji_events,
                label: 'Torneos',
                value: '—',
                detail: 'Datos aún no conectados',
                color: _purple,
              ),
              DashboardStatCard(
                icon: Icons.groups,
                label: 'Selecciones',
                value: '—',
                detail: 'Datos aún no conectados',
                color: _purple,
              ),
              DashboardStatCard(
                icon: Icons.sports_basketball,
                label: 'Partidos',
                value: '—',
                detail: 'Datos aún no conectados',
                color: _purple,
              ),
            ],
          ),
          const SizedBox(height: 28),
          const DashboardSectionTitle(title: 'Gestión universitaria'),
          const SizedBox(height: 14),
          const DashboardGrid(
            childAspectRatio: 2.2,
            children: [
              DashboardFeatureCard(
                icon: Icons.emoji_events,
                title: 'Torneos',
                description: 'Organiza competencias universitarias.',
                color: _purple,
              ),
              DashboardFeatureCard(
                icon: Icons.account_balance,
                title: 'Selecciones',
                description: 'Consulta los equipos de la universidad.',
                color: _purple,
              ),
              DashboardFeatureCard(
                icon: Icons.calendar_month,
                title: 'Calendario',
                description: 'Consulta las fechas de competencia.',
                color: _purple,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
