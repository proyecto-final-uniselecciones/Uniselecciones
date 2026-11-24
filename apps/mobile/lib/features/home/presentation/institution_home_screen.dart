import 'package:material_ui/material_ui.dart';

import '../../../app/theme.dart';
import 'dashboard_components.dart';

/// Panel de institución.
///
/// La institución mira hacia arriba, no hacia el vestidor: cuántas
/// selecciones tiene en competencia, qué partidos vienen y en qué sedes.
/// Por eso aquí manda el calendario y la ocupación de sedes.
class InstitutionHomeScreen extends StatelessWidget {
  const InstitutionHomeScreen({super.key});

  static const _accent = UniRoleAccent.institucion;

  @override
  Widget build(BuildContext context) {
    return RoleDashboardShell(
      roleTitle: 'Institución',
      roleDescription:
          'Coordina la participación de tu universidad y consulta la actividad '
          'de sus selecciones.',
      icon: Icons.account_balance,
      accentColor: _accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const UniSampleNotice(),
          const SizedBox(height: 26),

          // --- Resumen institucional ------------------------------------
          const DashboardSectionTitle(
            title: 'Actividad institucional',
            description: 'Resumen de la participación de tu universidad.',
            accent: _accent,
          ),
          const SizedBox(height: 16),
          const DashboardGrid(
            children: [
              DashboardStatCard(
                icon: Icons.emoji_events,
                label: 'Torneos',
                value: '—',
                detail: 'Datos aún no conectados',
                color: _accent,
                tag: UniTag.sinDatos(),
              ),
              DashboardStatCard(
                icon: Icons.groups,
                label: 'Selecciones',
                value: '—',
                detail: 'Datos aún no conectados',
                color: _accent,
                tag: UniTag.sinDatos(),
              ),
              DashboardStatCard(
                icon: Icons.sports_basketball,
                label: 'Partidos',
                value: '—',
                detail: 'Datos aún no conectados',
                color: _accent,
                tag: UniTag.sinDatos(),
              ),
            ],
          ),
          const SizedBox(height: 34),

          // --- Calendario de la jornada ---------------------------------
          const DashboardSectionTitle(
            title: 'Jornada en curso',
            description: 'Los compromisos de tus selecciones esta semana.',
            accent: _accent,
          ),
          const SizedBox(height: 16),
          const DashboardGrid(
            minItemWidth: 320,
            children: [
              UniMatchCard(
                competition: 'Liga ABE · Varonil',
                localName: 'UAA Gallos',
                visitorName: 'UDG Leones',
                status: 'Programado',
                schedule: 'Sáb 29 nov · 18:00',
                venue: 'Gimnasio Universitario',
                accent: _accent,
                isSample: true,
              ),
              UniMatchCard(
                competition: 'Liga ABE · Femenil',
                localName: 'UAZ Tuzas',
                visitorName: 'UAA Gallas',
                status: 'Programado',
                schedule: 'Dom 30 nov · 12:00',
                venue: 'Domo Zacatecas',
                accent: _accent,
                isSample: true,
              ),
              UniMatchCard(
                competition: 'Liga ABE · Varonil',
                localName: 'UAA Gallos',
                visitorName: 'ITA Tigres',
                status: 'Final',
                localScore: '84',
                visitorScore: '77',
                schedule: 'Sáb 22 nov',
                venue: 'Gimnasio Universitario',
                accent: _accent,
                isSample: true,
              ),
            ],
          ),
          const SizedBox(height: 34),

          // --- Sedes -----------------------------------------------------
          const DashboardSectionTitle(
            title: 'Sedes y organización',
            description: 'Dónde se juega y con qué capacidad.',
            accent: _accent,
          ),
          const SizedBox(height: 16),
          UniPanelCard(
            title: 'Sedes de la universidad',
            icon: Icons.stadium_outlined,
            accent: _accent,
            trailing: const UniTag.muestra(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                _VenueRow(
                  name: 'Gimnasio Universitario',
                  detail: 'Aguascalientes · techada',
                  capacity: '1 800',
                ),
                Divider(height: 24, color: UniColors.line),
                _VenueRow(
                  name: 'Domo Auxiliar UAA',
                  detail: 'Aguascalientes · techada',
                  capacity: '600',
                ),
                Divider(height: 24, color: UniColors.line),
                _VenueRow(
                  name: 'Cancha Norte',
                  detail: 'Aguascalientes · descubierta',
                  capacity: '250',
                ),
              ],
            ),
          ),
          const SizedBox(height: 34),

          // --- Módulos futuros ------------------------------------------
          const DashboardSectionTitle(
            title: 'Gestión universitaria',
            description: 'Lo que vas a poder administrar desde aquí.',
            accent: _accent,
          ),
          const SizedBox(height: 16),
          const DashboardGrid(
            children: [
              DashboardFeatureCard(
                icon: Icons.emoji_events,
                title: 'Torneos',
                description: 'Organiza competencias universitarias.',
                color: _accent,
              ),
              DashboardFeatureCard(
                icon: Icons.account_balance,
                title: 'Selecciones',
                description: 'Consulta los equipos de la universidad.',
                color: _accent,
              ),
              DashboardFeatureCard(
                icon: Icons.calendar_month,
                title: 'Calendario',
                description: 'Consulta las fechas de competencia.',
                color: _accent,
              ),
              DashboardFeatureCard(
                icon: Icons.stadium_outlined,
                title: 'Sedes',
                description: 'Administra los espacios y su disponibilidad.',
                color: _accent,
              ),
              DashboardFeatureCard(
                icon: Icons.manage_accounts_outlined,
                title: 'Usuarios',
                description: 'Da de alta entrenadores y jugadores.',
                color: _accent,
              ),
              DashboardFeatureCard(
                icon: Icons.summarize_outlined,
                title: 'Reportes',
                description: 'Resultados y participación por temporada.',
                color: _accent,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Renglón de sede con su capacidad.
class _VenueRow extends StatelessWidget {
  const _VenueRow({
    required this.name,
    required this.detail,
    required this.capacity,
  });

  final String name;
  final String detail;
  final String capacity;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: UniRoleAccent.institucion.withValues(alpha: 0.11),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.stadium_outlined,
            size: 19,
            color: UniRoleAccent.institucion,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                detail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: UniColors.inkSoft),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              capacity,
              style: AppTheme.scoreboard.copyWith(
                color: UniColors.ink,
                fontSize: 22,
              ),
            ),
            Text(
              'AFORO',
              style: AppTheme.eyebrow.copyWith(
                color: UniColors.inkSoft,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
