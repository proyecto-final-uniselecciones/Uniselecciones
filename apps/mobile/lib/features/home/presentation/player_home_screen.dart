import 'package:material_ui/material_ui.dart';

import '../../../app/theme.dart';
import 'dashboard_components.dart';

/// Panel del jugador.
///
/// Lo que el jugador necesita de un vistazo: contra quién juega y cuándo,
/// si está disponible, qué dorsal le toca y cómo va su rendimiento. Los
/// módulos que todavía no tienen datos de la API se muestran como estado
/// vacío o marcados como MUESTRA; ninguno finge ser un dato real.
class PlayerHomeScreen extends StatelessWidget {
  const PlayerHomeScreen({super.key});

  static const _accent = UniRoleAccent.jugador;

  @override
  Widget build(BuildContext context) {
    return RoleDashboardShell(
      roleTitle: 'Jugador',
      roleDescription:
          'Consulta tu actividad deportiva, el calendario y el rendimiento '
          'de tu selección.',
      icon: Icons.sports_basketball,
      accentColor: _accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const UniSampleNotice(),
          const SizedBox(height: 26),

          // --- Resumen de temporada: datos reales o estado vacío ---------
          const DashboardSectionTitle(
            title: 'Mi temporada',
            description: 'Un resumen de tu participación universitaria.',
            accent: _accent,
          ),
          const SizedBox(height: 16),
          const DashboardGrid(
            children: [
              DashboardStatCard(
                icon: Icons.groups,
                label: 'Mi selección',
                value: 'Sin asignar',
                detail: 'Tu equipo aparecerá aquí',
                color: _accent,
                tag: UniTag.sinDatos(),
              ),
              DashboardStatCard(
                icon: Icons.event,
                label: 'Próximo partido',
                value: 'Sin programar',
                detail: 'Revisa el calendario próximamente',
                color: _accent,
                tag: UniTag.sinDatos(),
              ),
              DashboardStatCard(
                icon: Icons.query_stats,
                label: 'Estadísticas',
                value: 'Sin registros',
                detail: 'Tus resultados deportivos',
                color: _accent,
                tag: UniTag.sinDatos(),
              ),
            ],
          ),
          const SizedBox(height: 34),

          // --- Próximo partido y uniforme -------------------------------
          const DashboardSectionTitle(
            title: 'Tu siguiente compromiso',
            description: 'Rival, sede y hora, más lo que debes llevar.',
            accent: _accent,
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 760;
              const match = UniMatchCard(
                competition: 'Liga ABE · Jornada 7',
                localName: 'UAA Gallos',
                visitorName: 'UDG Leones',
                status: 'Programado',
                schedule: 'Sábado 29 nov · 18:00',
                venue: 'Gimnasio Universitario, Aguascalientes',
                accent: _accent,
                isSample: true,
              );
              final uniform = UniPanelCard(
                title: 'Mi uniforme',
                icon: Icons.checkroom,
                accent: _accent,
                trailing: const UniTag.muestra(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    _UniformRow(label: 'Dorsal', value: '23'),
                    Divider(height: 22, color: UniColors.line),
                    _UniformRow(label: 'Posición', value: 'Alero'),
                    Divider(height: 22, color: UniColors.line),
                    _UniformRow(label: 'Equipación', value: 'Local · Blanca'),
                    Divider(height: 22, color: UniColors.line),
                    _UniformRow(label: 'Entrega', value: 'Confirmada'),
                  ],
                ),
              );

              if (narrow) {
                return Column(
                  children: [match, const SizedBox(height: 16), uniform],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(flex: 3, child: match),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: uniform),
                ],
              );
            },
          ),
          const SizedBox(height: 34),

          // --- Promedios ------------------------------------------------
          const DashboardSectionTitle(
            title: 'Mis promedios',
            description: 'Cómo vas en lo que va de la temporada.',
            accent: _accent,
          ),
          const SizedBox(height: 16),
          UniPanelCard(
            title: 'Promedios por partido',
            icon: Icons.insights,
            accent: _accent,
            trailing: const UniTag.muestra(),
            child: LayoutBuilder(
              builder: (context, constraints) {
                const stats = [
                  _AverageStat(label: 'PTS', value: '14.2'),
                  _AverageStat(label: 'REB', value: '5.8'),
                  _AverageStat(label: 'AST', value: '3.1'),
                  _AverageStat(label: 'ROB', value: '1.4'),
                  _AverageStat(label: 'MIN', value: '26.7'),
                ];
                final columns = constraints.maxWidth < 420 ? 3 : 5;
                final itemWidth =
                    (constraints.maxWidth - 12 * (columns - 1)) / columns;
                return Wrap(
                  spacing: 12,
                  runSpacing: 16,
                  children: [
                    for (final stat in stats)
                      SizedBox(width: itemWidth, child: stat),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 34),

          // --- Módulos futuros ------------------------------------------
          const DashboardSectionTitle(
            title: 'Mi espacio deportivo',
            description: 'Lo que vas a poder hacer desde aquí.',
            accent: _accent,
          ),
          const SizedBox(height: 16),
          const DashboardGrid(
            children: [
              DashboardFeatureCard(
                icon: Icons.person,
                title: 'Perfil deportivo',
                description: 'Completa tu información y datos de jugador.',
                color: _accent,
              ),
              DashboardFeatureCard(
                icon: Icons.calendar_month,
                title: 'Calendario',
                description: 'Consulta partidos y próximos entrenamientos.',
                color: _accent,
              ),
              DashboardFeatureCard(
                icon: Icons.leaderboard,
                title: 'Mi rendimiento',
                description: 'Revisa tus estadísticas durante la temporada.',
                color: _accent,
              ),
              DashboardFeatureCard(
                icon: Icons.compare_arrows,
                title: 'Comparativa',
                description:
                    'Compárate con el resto de la plantilla por estadística.',
                color: _accent,
              ),
              DashboardFeatureCard(
                icon: Icons.fitness_center,
                title: 'Mis rutinas',
                description: 'Las rutinas que te asigna el cuerpo técnico.',
                color: _accent,
              ),
              DashboardFeatureCard(
                icon: Icons.how_to_reg,
                title: 'Check-in',
                description: 'Registra tu asistencia a los entrenamientos.',
                color: _accent,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Renglón de dato del uniforme.
class _UniformRow extends StatelessWidget {
  const _UniformRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTheme.eyebrow.copyWith(
            color: UniColors.inkSoft,
            fontSize: 11.5,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ],
    );
  }
}

/// Cifra de promedio, en formato de ficha de jugador.
class _AverageStat extends StatelessWidget {
  const _AverageStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.scoreboard.copyWith(
            color: UniRoleAccent.jugador,
            fontSize: 30,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTheme.eyebrow.copyWith(
            color: UniColors.inkSoft,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
