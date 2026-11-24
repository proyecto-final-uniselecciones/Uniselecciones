import 'package:material_ui/material_ui.dart';

import '../../../app/theme.dart';
import 'dashboard_components.dart';

/// Panel del entrenador.
///
/// El entrenador decide con dos datos: a quién tiene disponible y cuándo
/// es el siguiente partido. Por eso la disponibilidad de la plantilla va
/// arriba y ocupa el espacio grande, y la gestión queda debajo.
class CoachHomeScreen extends StatelessWidget {
  const CoachHomeScreen({super.key});

  static const _accent = UniRoleAccent.entrenador;

  @override
  Widget build(BuildContext context) {
    return RoleDashboardShell(
      roleTitle: 'Entrenador',
      roleDescription:
          'Organiza tu selección, prepara entrenamientos y da seguimiento '
          'a tus jugadores.',
      icon: Icons.sports,
      accentColor: _accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const UniSampleNotice(),
          const SizedBox(height: 26),

          // --- Resumen de la selección ----------------------------------
          const DashboardSectionTitle(
            title: 'Mi selección',
            description: 'Herramientas para organizar a tu equipo.',
            accent: _accent,
          ),
          const SizedBox(height: 16),
          const DashboardGrid(
            children: [
              DashboardStatCard(
                icon: Icons.groups,
                label: 'Jugadores',
                value: '—',
                detail: 'Datos aún no conectados',
                color: _accent,
                tag: UniTag.sinDatos(),
              ),
              DashboardStatCard(
                icon: Icons.fitness_center,
                label: 'Entrenamientos',
                value: '—',
                detail: 'Datos aún no conectados',
                color: _accent,
                tag: UniTag.sinDatos(),
              ),
              DashboardStatCard(
                icon: Icons.emoji_events,
                label: 'Partidos',
                value: '—',
                detail: 'Datos aún no conectados',
                color: _accent,
                tag: UniTag.sinDatos(),
              ),
            ],
          ),
          const SizedBox(height: 34),

          // --- Disponibilidad y siguiente partido -----------------------
          const DashboardSectionTitle(
            title: 'Antes del partido',
            description: 'Con quién cuentas y dónde se juega.',
            accent: _accent,
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 860;

              final roster = UniPanelCard(
                title: 'Disponibilidad de la plantilla',
                icon: Icons.medical_information_outlined,
                accent: _accent,
                trailing: const UniTag.muestra(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    UniPlayerRow(
                      number: '4',
                      name: 'Diego Ramírez',
                      position: 'Base',
                      available: true,
                    ),
                    Divider(height: 1, color: UniColors.line),
                    UniPlayerRow(
                      number: '10',
                      name: 'Emiliano Torres',
                      position: 'Escolta',
                      available: true,
                    ),
                    Divider(height: 1, color: UniColors.line),
                    UniPlayerRow(
                      number: '23',
                      name: 'Santiago Flores',
                      position: 'Alero',
                      available: false,
                      note: 'Esguince de tobillo · 12 días',
                    ),
                    Divider(height: 1, color: UniColors.line),
                    UniPlayerRow(
                      number: '31',
                      name: 'Mateo Gutiérrez',
                      position: 'Ala-pívot',
                      available: true,
                    ),
                    Divider(height: 1, color: UniColors.line),
                    UniPlayerRow(
                      number: '50',
                      name: 'Héctor Mendoza',
                      position: 'Pívot',
                      available: false,
                      note: 'Carga de trabajo',
                    ),
                  ],
                ),
              );

              final sidebar = Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const UniMatchCard(
                    competition: 'Liga ABE · Jornada 7',
                    localName: 'UAA Gallos',
                    visitorName: 'UDG Leones',
                    status: 'Programado',
                    schedule: 'Sáb 29 nov · 18:00',
                    venue: 'Gimnasio Universitario',
                    accent: _accent,
                    isSample: true,
                  ),
                  const SizedBox(height: 16),
                  UniPanelCard(
                    title: 'Logística del partido',
                    icon: Icons.checklist_rtl,
                    accent: _accent,
                    trailing: const UniTag.muestra(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        _LogisticsRow(
                          icon: Icons.wb_sunny_outlined,
                          label: 'Clima previsto',
                          value: '21 °C, despejado',
                        ),
                        SizedBox(height: 14),
                        _LogisticsRow(
                          icon: Icons.checkroom,
                          label: 'Equipación',
                          value: 'Local lista · visitante en lavandería',
                        ),
                        SizedBox(height: 14),
                        _LogisticsRow(
                          icon: Icons.directions_bus_outlined,
                          label: 'Traslado',
                          value: 'No aplica, se juega en casa',
                        ),
                      ],
                    ),
                  ),
                ],
              );

              if (narrow) {
                return Column(
                  children: [roster, const SizedBox(height: 16), sidebar],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: roster),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: sidebar),
                ],
              );
            },
          ),
          const SizedBox(height: 34),

          // --- Módulos futuros ------------------------------------------
          const DashboardSectionTitle(
            title: 'Administración deportiva',
            description: 'Lo que vas a poder gestionar desde aquí.',
            accent: _accent,
          ),
          const SizedBox(height: 16),
          const DashboardGrid(
            children: [
              DashboardFeatureCard(
                icon: Icons.groups,
                title: 'Plantilla',
                description: 'Consulta y organiza a los integrantes.',
                color: _accent,
              ),
              DashboardFeatureCard(
                icon: Icons.event_available,
                title: 'Entrenamientos',
                description: 'Programa sesiones para tu selección.',
                color: _accent,
              ),
              DashboardFeatureCard(
                icon: Icons.fact_check,
                title: 'Asistencia y resultados',
                description: 'Lleva el seguimiento de actividad y partidos.',
                color: _accent,
              ),
              DashboardFeatureCard(
                icon: Icons.schema_outlined,
                title: 'Jugadas',
                description: 'Prepara y comparte el repertorio táctico.',
                color: _accent,
              ),
              DashboardFeatureCard(
                icon: Icons.healing_outlined,
                title: 'Lesiones',
                description: 'Registra bajas y sigue la recuperación.',
                color: _accent,
              ),
              DashboardFeatureCard(
                icon: Icons.inventory_2_outlined,
                title: 'Equipación',
                description: 'Controla dorsales, tallas y material.',
                color: _accent,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Renglón de logística con icono, etiqueta y valor.
class _LogisticsRow extends StatelessWidget {
  const _LogisticsRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: UniColors.canvas,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 17, color: UniColors.inkSoft),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label.toUpperCase(),
                style: AppTheme.eyebrow.copyWith(
                  color: UniColors.inkSoft,
                  fontSize: 10.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(value, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}
