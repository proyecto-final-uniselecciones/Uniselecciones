import 'package:material_ui/material_ui.dart';

import 'dashboard_components.dart';

class PlayerHomeScreen extends StatelessWidget {
  const PlayerHomeScreen({super.key});

  static const _blue = Color(0xFF245FE5);

  @override
  Widget build(BuildContext context) {
    return RoleDashboardShell(
      roleTitle: 'Jugador',
      roleDescription:
          'Consulta tu actividad deportiva, el calendario y el rendimiento '
          'de tu selección.',
      icon: Icons.sports_basketball,
      accentColor: _blue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DashboardSectionTitle(
            title: 'Mi temporada',
            description: 'Un resumen de tu participación universitaria.',
          ),
          const SizedBox(height: 14),
          const DashboardGrid(
            children: [
              DashboardStatCard(
                icon: Icons.groups,
                label: 'Mi selección',
                value: 'Sin asignar',
                detail: 'Tu equipo aparecerá aquí',
                color: _blue,
              ),
              DashboardStatCard(
                icon: Icons.event,
                label: 'Próximo partido',
                value: 'Sin programar',
                detail: 'Revisa el calendario próximamente',
                color: _blue,
              ),
              DashboardStatCard(
                icon: Icons.query_stats,
                label: 'Estadísticas',
                value: 'Sin registros',
                detail: 'Tus resultados deportivos',
                color: _blue,
              ),
            ],
          ),
          const SizedBox(height: 28),
          const DashboardSectionTitle(title: 'Mi espacio deportivo'),
          const SizedBox(height: 14),
          const DashboardGrid(
            childAspectRatio: 2.2,
            children: [
              DashboardFeatureCard(
                icon: Icons.person,
                title: 'Perfil deportivo',
                description: 'Completa tu información y datos de jugador.',
                color: _blue,
              ),
              DashboardFeatureCard(
                icon: Icons.calendar_month,
                title: 'Calendario',
                description: 'Consulta partidos y próximos entrenamientos.',
                color: _blue,
              ),
              DashboardFeatureCard(
                icon: Icons.leaderboard,
                title: 'Mi rendimiento',
                description: 'Revisa tus estadísticas durante la temporada.',
                color: _blue,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
