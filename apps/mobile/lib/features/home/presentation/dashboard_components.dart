import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../app/auth_controller.dart';
import '../../../app/theme.dart';

// =====================================================================
//  Componentes compartidos de los paneles de UniSelecciones
//
//  Los tres roles (jugador, entrenador e institución) usan estas piezas.
//  Lo único que cambia entre ellos es el color de acento, el icono y el
//  contenido; la estructura es la misma para que la aplicación se sienta
//  como un solo producto y no como tres pantallas distintas.
//
//  Regla de honestidad visual: cualquier módulo que muestre contenido
//  inventado lleva la etiqueta MUESTRA bien visible. Lo que todavía no
//  existe se dibuja como estado vacío, no como un dato falso.
// =====================================================================

/// Marca de la aplicación: balón sobre cuadro rojo más el nombre.
class UniBrandMark extends StatelessWidget {
  const UniBrandMark({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 34 : 40,
          height: compact ? 34 : 40,
          decoration: BoxDecoration(
            color: UniColors.red,
            borderRadius: BorderRadius.circular(compact ? 9 : 11),
          ),
          child: Icon(
            Icons.sports_basketball,
            color: Colors.white,
            size: compact ? 20 : 24,
          ),
        ),
        SizedBox(width: compact ? 10 : 12),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'UNISELECCIONES',
              style: TextStyle(
                fontFamily: UniFonts.display,
                fontWeight: FontWeight.w800,
                fontSize: compact ? 17 : 20,
                letterSpacing: 1.4,
                height: 1.0,
                color: UniColors.onNavy,
              ),
            ),
            if (!compact)
              const Text(
                'BALONCESTO UNIVERSITARIO',
                style: TextStyle(
                  fontFamily: UniFonts.display,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                  letterSpacing: 2.0,
                  height: 1.6,
                  color: UniColors.onNavySoft,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Etiqueta corta en mayúsculas. Sirve para estados y categorías.
class UniTag extends StatelessWidget {
  const UniTag(
    this.label, {
    required this.color,
    this.filled = false,
    this.icon,
    super.key,
  });

  /// Estado de lo que aún no se construye.
  const UniTag.proximamente({super.key})
    : label = 'PRÓXIMAMENTE',
      color = UniColors.inkSoft,
      filled = false,
      icon = null;

  /// Aviso de contenido inventado. Se usa en todo módulo cuyo contenido
  /// todavía no viene de la base de datos.
  const UniTag.muestra({super.key})
    : label = 'MUESTRA',
      color = UniColors.gold,
      filled = true,
      icon = Icons.visibility_outlined;

  /// Estado de lo que existe pero aún no tiene datos.
  const UniTag.sinDatos({super.key})
    : label = 'SIN DATOS',
      color = UniColors.inkSoft,
      filled = false,
      icon = null;

  final String label;
  final Color color;
  final bool filled;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: icon == null ? 9 : 8, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
        border: filled ? null : Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: filled ? UniColors.ink : color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: UniFonts.display,
              fontWeight: FontWeight.w700,
              fontSize: 10.5,
              letterSpacing: 1.1,
              height: 1.2,
              color: filled ? UniColors.ink : color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Armazón de los tres paneles: barra, cabecera de rol y contenido.
class RoleDashboardShell extends StatelessWidget {
  const RoleDashboardShell({
    required this.roleTitle,
    required this.roleDescription,
    required this.icon,
    required this.accentColor,
    required this.child,
    super.key,
  });

  final String roleTitle;
  final String roleDescription;
  final IconData icon;
  final Color accentColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return Scaffold(
      backgroundColor: UniColors.canvas,
      appBar: AppBar(
        titleSpacing: 20,
        title: const UniBrandMark(compact: true),
        actions: [
          // El rol se muestra siempre: es el dato que explica por qué la
          // persona ve este panel y no otro.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              roleTitle.toUpperCase(),
              style: const TextStyle(
                fontFamily: UniFonts.display,
                fontWeight: FontWeight.w800,
                fontSize: 12,
                letterSpacing: 1.3,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () {
              context.read<AuthController>().logout();
              context.go('/login');
            },
            icon: const Icon(Icons.logout, size: 20),
            color: UniColors.onNavySoft,
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _RoleHeader(
              roleTitle: roleTitle,
              roleDescription: roleDescription,
              icon: icon,
              accentColor: accentColor,
              firstName: auth.firstName,
              universityName: auth.universityName,
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                  child: child,
                ),
              ),
            ),
            _DashboardFooter(connected: auth.databaseConnected),
          ],
        ),
      ),
    );
  }
}

/// Cabecera oscura con el saludo, el rol y la universidad.
class _RoleHeader extends StatelessWidget {
  const _RoleHeader({
    required this.roleTitle,
    required this.roleDescription,
    required this.icon,
    required this.accentColor,
    required this.firstName,
    required this.universityName,
  });

  final String roleTitle;
  final String roleDescription;
  final IconData icon;
  final Color accentColor;
  final String firstName;
  final String universityName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [UniColors.navy900, UniColors.navy700, UniColors.navy500],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Balón gigante translúcido al fondo: da profundidad sin competir
          // con el texto, igual que las marcas de agua de las cadenas
          // deportivas.
          Positioned(
            right: -40,
            top: -30,
            child: Icon(
              Icons.sports_basketball,
              size: 240,
              color: Colors.white.withValues(alpha: 0.04),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 34),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final narrow = constraints.maxWidth < 620;

                    final identity = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Franja de acento + nombre del panel.
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 18,
                              decoration: BoxDecoration(
                                color: accentColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'PANEL DE ${roleTitle.toUpperCase()}',
                              style: AppTheme.eyebrow.copyWith(
                                color: UniColors.onNavySoft,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Hola, $firstName',
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(color: UniColors.onNavy),
                        ),
                        const SizedBox(height: 10),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 560),
                          child: Text(
                            roleDescription,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: UniColors.onNavySoft),
                          ),
                        ),
                        if (universityName.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: UniColors.navy600),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.account_balance,
                                  color: UniColors.onNavySoft,
                                  size: 16,
                                ),
                                const SizedBox(width: 9),
                                Flexible(
                                  child: Text(
                                    universityName,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: UniFonts.text,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: UniColors.onNavy,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    );

                    final badge = Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.35),
                            blurRadius: 28,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(icon, size: 48, color: Colors.white),
                    );

                    if (narrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [badge, const SizedBox(height: 22), identity],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: identity),
                        const SizedBox(width: 28),
                        badge,
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pie con el estado real de la conexión a la base de datos.
class _DashboardFooter extends StatelessWidget {
  const _DashboardFooter({required this.connected});

  final bool? connected;

  @override
  Widget build(BuildContext context) {
    final ok = connected == true;
    return Container(
      width: double.infinity,
      color: UniColors.navy900,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              ok ? Icons.verified_outlined : Icons.cloud_off_outlined,
              size: 16,
              color: ok ? UniColors.green : UniColors.onNavySoft,
            ),
            const SizedBox(width: 9),
            Flexible(
              child: Text(
                ok
                    ? 'Sesión validada con la base de datos'
                    : 'Conexión de base de datos no confirmada',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: UniFonts.text,
                  fontSize: 13,
                  color: UniColors.onNavySoft,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Encabezado de sección con regla de acento.
class DashboardSectionTitle extends StatelessWidget {
  const DashboardSectionTitle({
    required this.title,
    this.description,
    this.accent = UniColors.red,
    this.trailing,
    super.key,
  });

  final String title;
  final String? description;
  final Color accent;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 4,
          height: description == null ? 24 : 42,
          margin: const EdgeInsets.only(top: 2, right: 12),
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(letterSpacing: 0.6),
              ),
              if (description != null) ...[
                const SizedBox(height: 4),
                Text(
                  description!,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: UniColors.inkSoft),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
    );
  }
}

/// Rejilla adaptable.
///
/// Se usa Wrap con anchos calculados en vez de GridView con proporción
/// fija: así una tarjeta con más texto crece de alto sin desbordarse, que
/// era el riesgo del enfoque anterior.
class DashboardGrid extends StatelessWidget {
  const DashboardGrid({
    required this.children,
    this.minItemWidth = 280,
    this.spacing = 16,
    super.key,
  });

  final List<Widget> children;
  final double minItemWidth;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        var columns = (width / minItemWidth).floor();
        if (columns < 1) columns = 1;
        if (columns > children.length) columns = children.length;
        if (columns < 1) columns = 1;
        final itemWidth = (width - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}

/// Tarjeta de cifra, al estilo de los promedios de temporada.
class DashboardStatCard extends StatelessWidget {
  const DashboardStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
    required this.color,
    this.tag,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final String detail;
  final Color color;
  final Widget? tag;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: UniColors.surface,
        borderRadius: UniShape.md,
        border: Border.all(color: UniColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Franja superior de acento: identifica el rol de un vistazo.
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(UniShape.radiusMd),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(icon, color: color, size: 19),
                    ),
                    const Spacer(),
                    ?tag,
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.scoreboard.copyWith(color: UniColors.ink),
                ),
                const SizedBox(height: 4),
                Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.eyebrow.copyWith(color: color, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Text(
                  detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: UniColors.inkSoft),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de módulo futuro. No navega: lo dice su etiqueta.
class DashboardFeatureCard extends StatelessWidget {
  const DashboardFeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: UniColors.surface,
        borderRadius: UniShape.md,
        border: Border.all(color: UniColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontSize: 19),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: UniColors.inkSoft),
          ),
          const SizedBox(height: 14),
          const UniTag.proximamente(),
        ],
      ),
    );
  }
}

/// Tarjeta de partido, con el aire de un marcador de televisión.
class UniMatchCard extends StatelessWidget {
  const UniMatchCard({
    required this.competition,
    required this.localName,
    required this.visitorName,
    required this.status,
    required this.accent,
    this.localScore,
    this.visitorScore,
    this.schedule,
    this.venue,
    this.isSample = false,
    super.key,
  });

  final String competition;
  final String localName;
  final String visitorName;
  final String status;
  final Color accent;
  final String? localScore;
  final String? visitorScore;
  final String? schedule;
  final String? venue;
  final bool isSample;

  @override
  Widget build(BuildContext context) {
    final played = localScore != null && visitorScore != null;

    return Container(
      decoration: BoxDecoration(
        color: UniColors.navy800,
        borderRadius: UniShape.md,
        border: Border.all(color: UniColors.navy600),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: UniColors.navy900,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(UniShape.radiusMd),
              ),
              border: const Border(
                bottom: BorderSide(color: UniColors.navy600),
              ),
            ),
            child: Row(
              children: [
                Container(width: 3, height: 13, color: accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    competition.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.eyebrow.copyWith(
                      color: UniColors.onNavySoft,
                      fontSize: 11,
                    ),
                  ),
                ),
                if (isSample) const UniTag.muestra(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TeamRow(name: localName, score: localScore, isLocal: true),
                const SizedBox(height: 10),
                _TeamRow(name: visitorName, score: visitorScore, isLocal: false),
                const SizedBox(height: 14),
                const Divider(color: UniColors.navy600),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      played ? Icons.flag_outlined : Icons.schedule,
                      size: 14,
                      color: accent,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        schedule == null ? status : '$status · $schedule',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: UniFonts.text,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: UniColors.onNavy,
                        ),
                      ),
                    ),
                  ],
                ),
                if (venue != null) ...[
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      const Icon(
                        Icons.place_outlined,
                        size: 14,
                        color: UniColors.onNavySoft,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          venue!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: UniFonts.text,
                            fontSize: 12.5,
                            color: UniColors.onNavySoft,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamRow extends StatelessWidget {
  const _TeamRow({required this.name, required this.score, required this.isLocal});

  final String name;
  final String? score;
  final bool isLocal;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: UniColors.navy700,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: UniColors.navy600),
          ),
          child: Center(
            child: Text(
              name.isEmpty ? '?' : name.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                fontFamily: UniFonts.display,
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: UniColors.onNavy,
              ),
            ),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: UniFonts.display,
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  height: 1.1,
                  color: UniColors.onNavy,
                ),
              ),
              Text(
                isLocal ? 'LOCAL' : 'VISITA',
                style: const TextStyle(
                  fontFamily: UniFonts.display,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                  letterSpacing: 1.3,
                  color: UniColors.onNavySoft,
                ),
              ),
            ],
          ),
        ),
        if (score != null)
          Text(
            score!,
            style: AppTheme.scoreboard.copyWith(
              color: UniColors.onNavy,
              fontSize: 28,
            ),
          ),
      ],
    );
  }
}

/// Fila de jugador: dorsal, nombre, posición y disponibilidad.
class UniPlayerRow extends StatelessWidget {
  const UniPlayerRow({
    required this.number,
    required this.name,
    required this.position,
    required this.available,
    this.note,
    super.key,
  });

  final String number;
  final String name;
  final String position;
  final bool available;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final color = available ? UniColors.green : UniColors.red;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          // Dorsal, como en una camiseta.
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: UniColors.navy800,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontFamily: UniFonts.display,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
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
                  note == null ? position : '$position · $note',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: UniColors.inkSoft),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              available ? 'DISPONIBLE' : 'BAJA',
              style: TextStyle(
                fontFamily: UniFonts.display,
                fontWeight: FontWeight.w700,
                fontSize: 10.5,
                letterSpacing: 1.0,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Caja blanca con título, para agrupar contenido dentro de una sección.
class UniPanelCard extends StatelessWidget {
  const UniPanelCard({
    required this.title,
    required this.child,
    this.icon,
    this.accent = UniColors.red,
    this.trailing,
    super.key,
  });

  final String title;
  final Widget child;
  final IconData? icon;
  final Color accent;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: UniColors.surface,
        borderRadius: UniShape.md,
        border: Border.all(color: UniColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 14, 14),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: accent),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.eyebrow.copyWith(color: UniColors.ink),
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
          const Divider(height: 1, color: UniColors.line),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// Estado vacío honesto: dice que no hay dato, en vez de inventarlo.
class UniEmptyState extends StatelessWidget {
  const UniEmptyState({
    required this.icon,
    required this.message,
    this.hint,
    super.key,
  });

  final IconData icon;
  final String message;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: UniColors.canvas,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: UniColors.inkSoft, size: 25),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (hint != null) ...[
            const SizedBox(height: 5),
            Text(
              hint!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: UniColors.inkSoft),
            ),
          ],
        ],
      ),
    );
  }
}

/// Aviso fijo de que lo que se ve abajo es contenido inventado.
class UniSampleNotice extends StatelessWidget {
  const UniSampleNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: UniColors.gold.withValues(alpha: 0.12),
        borderRadius: UniShape.sm,
        border: Border.all(color: UniColors.gold.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: Color(0xFF8A6200)),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              'Los módulos marcados como MUESTRA llevan contenido de ejemplo '
              'para enseñar el diseño. Todavía no se conectan a la base de datos.',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: const Color(0xFF6B4D00)),
            ),
          ),
        ],
      ),
    );
  }
}
