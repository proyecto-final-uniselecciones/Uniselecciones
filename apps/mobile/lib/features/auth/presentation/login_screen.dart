import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/auth_controller.dart';
import '../../../app/theme.dart';
import '../../home/presentation/dashboard_components.dart';

/// Pantalla de acceso y registro.
///
/// Son dos modos de la misma pantalla, como estaba: el enlace de abajo
/// alterna entre uno y otro. La lógica del formulario (validaciones,
/// catálogo de universidades, envío y navegación) no cambió; lo que
/// cambió es la presentación.
///
/// En pantalla ancha se parte en dos: a la izquierda un bloque azul
/// marino con la marca, a la derecha el formulario sobre fondo claro. En
/// pantalla estrecha el bloque de marca se convierte en una cabecera.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _passwordVisible = false;
  bool _isRegistering = false;
  String _selectedRole = 'jugador';
  String? _selectedRegion;
  int? _selectedUniversityId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AuthController>().checkDatabaseConnection();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UniColors.canvas,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 980;

          if (isWide) {
            // Dos columnas a sangre: el azul marino llega hasta el borde.
            return Row(
              children: [
                const Expanded(flex: 5, child: _BrandPanel()),
                Expanded(
                  flex: 4,
                  child: SafeArea(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 44,
                          vertical: 36,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 480),
                          child: _loginCard(context),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                const _BrandPanel(compact: true),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 26, 20, 34),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: _loginCard(context),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _loginCard(BuildContext context) {
    final auth = context.watch<AuthController>();
    final notice = auth.notice;
    final success = auth.noticeIsSuccess;
    final universities = auth.universities
        .where((university) => university['region'] == _selectedRegion)
        .toList(growable: false);

    return Container(
      decoration: BoxDecoration(
        color: UniColors.surface,
        borderRadius: UniShape.lg,
        border: Border.all(color: UniColors.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14101828),
            blurRadius: 30,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 26,
                    decoration: BoxDecoration(
                      color: UniColors.red,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isRegistering ? 'CREA TU CUENTA' : 'INICIA SESIÓN',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _isRegistering
                    ? 'Regístrate para entrar a UniSelecciones.'
                    : 'Usa tu correo institucional para continuar.',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: UniColors.inkSoft),
              ),
              const SizedBox(height: 18),
              _DatabaseStatus(
                isChecking: auth.isCheckingDatabase,
                isConnected: auth.databaseConnected,
              ),
              const SizedBox(height: 26),
              if (_isRegistering) ...[
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().length < 3) {
                      return 'Escribe tu nombre completo.';
                    }
                    return null;
                  },
                  onChanged: (_) =>
                      context.read<AuthController>().clearNotice(),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: ValueKey('role-$_selectedRole'),
                  initialValue: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de cuenta',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'jugador', child: Text('Jugador')),
                    DropdownMenuItem(
                      value: 'entrenador',
                      child: Text('Entrenador'),
                    ),
                    DropdownMenuItem(
                      value: 'institucion',
                      child: Text('Institución'),
                    ),
                  ],
                  onChanged: auth.isLoading
                      ? null
                      : (role) {
                          if (role != null) {
                            setState(() => _selectedRole = role);
                          }
                        },
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedRole == 'jugador'
                      ? 'Tu cuenta se activa al registrarte.'
                      : 'Puedes entrar con este perfil al terminar el registro.',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: UniColors.inkSoft),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: ValueKey('region-$_selectedRegion'),
                  initialValue: _selectedRegion,
                  decoration: const InputDecoration(
                    labelText: 'Estado',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'AGS',
                      child: Text('Aguascalientes'),
                    ),
                    DropdownMenuItem(value: 'JAL', child: Text('Jalisco')),
                    DropdownMenuItem(value: 'ZAC', child: Text('Zacatecas')),
                  ],
                  onChanged: auth.isLoading
                      ? null
                      : (region) {
                          setState(() {
                            _selectedRegion = region;
                            _selectedUniversityId = null;
                          });
                        },
                  validator: (value) =>
                      value == null ? 'Selecciona tu estado.' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  key: ValueKey(
                    'university-$_selectedRegion-$_selectedUniversityId',
                  ),
                  initialValue: _selectedUniversityId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Universidad',
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                  hint: Text(
                    auth.isLoadingUniversities
                        ? 'Cargando universidades…'
                        : 'Selecciona primero tu estado',
                  ),
                  items: universities.map((university) {
                    return DropdownMenuItem<int>(
                      value: university['id_univ'] as int,
                      child: Text(
                        university['nombre'] as String,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged:
                      auth.isLoading ||
                          auth.isLoadingUniversities ||
                          _selectedRegion == null
                      ? null
                      : (universityId) {
                          setState(() => _selectedUniversityId = universityId);
                        },
                  validator: (value) =>
                      value == null ? 'Selecciona una universidad.' : null,
                ),
                if (auth.universityError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    auth.universityError!,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: UniColors.redDark),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'El catálogo incluye instituciones afiliadas a ANUIES.',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: UniColors.inkSoft),
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.username],
                decoration: const InputDecoration(
                  labelText: 'Correo institucional',
                  prefixIcon: Icon(Icons.alternate_email),
                ),
                validator: _validateEmail,
                onChanged: (_) => context.read<AuthController>().clearNotice(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: !_passwordVisible,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    tooltip: _passwordVisible
                        ? 'Ocultar contraseña'
                        : 'Mostrar contraseña',
                    onPressed: () {
                      setState(() => _passwordVisible = !_passwordVisible);
                    },
                    icon: Icon(
                      _passwordVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Escribe tu contraseña.';
                  }
                  if (_isRegistering && value.length < 8) {
                    return 'Usa al menos 8 caracteres.';
                  }
                  return null;
                },
                onChanged: (_) => context.read<AuthController>().clearNotice(),
                onFieldSubmitted: (_) => _submit(context),
              ),
              if (_isRegistering) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_passwordVisible,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Confirma tu contraseña',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Confirma tu contraseña.';
                    }
                    if (value != _passwordController.text) {
                      return 'Las contraseñas no coinciden.';
                    }
                    return null;
                  },
                  onChanged: (_) =>
                      context.read<AuthController>().clearNotice(),
                  onFieldSubmitted: (_) => _submit(context),
                ),
              ],
              const SizedBox(height: 26),
              FilledButton(
                onPressed: auth.isLoading ? null : () => _submit(context),
                child: auth.isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : Text(_isRegistering ? 'CREAR CUENTA' : 'ENTRAR'),
              ),
              if (notice != null) ...[
                const SizedBox(height: 18),
                Semantics(
                  liveRegion: true,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: success
                          ? const Color(0xFFECFDF3)
                          : const Color(0xFFFFF4E5),
                      borderRadius: UniShape.sm,
                      border: Border.all(
                        color: success
                            ? const Color(0xFFABEFC6)
                            : const Color(0xFFF5D7A8),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          success
                              ? Icons.check_circle_outline
                              : Icons.info_outline,
                          size: 20,
                          color: success
                              ? const Color(0xFF16803C)
                              : const Color(0xFF9A5B00),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Text(
                            notice,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: success
                                      ? const Color(0xFF176B36)
                                      : const Color(0xFF704300),
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              TextButton(
                onPressed: auth.isLoading
                    ? null
                    : () {
                        setState(() {
                          _isRegistering = !_isRegistering;
                          _selectedRole = 'jugador';
                          _selectedRegion = null;
                          _selectedUniversityId = null;
                        });
                        auth.clearNotice();
                        if (_isRegistering) auth.loadUniversities();
                      },
                child: Text(
                  _isRegistering
                      ? '¿Ya tienes cuenta? Inicia sesión'
                      : '¿No tienes cuenta? Regístrate',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Escribe tu correo institucional.';
    final emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailPattern.hasMatch(email)) {
      return 'Revisa el formato del correo.';
    }
    if (_isRegistering &&
        _selectedUniversityId == 1001 &&
        _selectedRole == 'jugador' &&
        !RegExp(
          r'^al\d{6}@edu\.uaa\.mx$',
          caseSensitive: false,
        ).hasMatch(email)) {
      return 'Para UAA, usa al + seis dígitos + @edu.uaa.mx.';
    }
    return null;
  }

  Future<void> _submit(BuildContext context) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final auth = context.read<AuthController>();
    final authenticated = _isRegistering
        ? await auth.register(
            name: _nameController.text,
            email: _emailController.text,
            password: _passwordController.text,
            universityId: _selectedUniversityId!,
            role: _selectedRole,
          )
        : await auth.login(
            email: _emailController.text,
            password: _passwordController.text,
          );
    if (authenticated && context.mounted) context.go('/home');
  }
}

/// Indicador del estado real de la conexión con PostgreSQL.
class _DatabaseStatus extends StatelessWidget {
  const _DatabaseStatus({required this.isChecking, required this.isConnected});

  final bool isChecking;
  final bool? isConnected;

  @override
  Widget build(BuildContext context) {
    final color = isChecking
        ? UniColors.inkSoft
        : isConnected == true
        ? UniColors.green
        : UniColors.redDark;
    final icon = isChecking
        ? Icons.sync
        : isConnected == true
        ? Icons.cloud_done_outlined
        : Icons.cloud_off_outlined;
    final label = isChecking
        ? 'Comprobando conexión con PostgreSQL…'
        : isConnected == true
        ? 'Base de datos conectada'
        : 'Base de datos desconectada';

    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: UniShape.sm,
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: UniFonts.text,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bloque azul marino con la marca y la propuesta del producto.
class _BrandPanel extends StatelessWidget {
  const _BrandPanel({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: compact ? null : double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [UniColors.navy900, UniColors.navy700, UniColors.navy500],
          stops: [0.0, 0.6, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: compact ? -50 : -70,
            bottom: compact ? -60 : -80,
            child: Icon(
              Icons.sports_basketball,
              size: compact ? 220 : 380,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
          // Franja roja de acento en el borde inferior.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(height: 5, color: UniColors.red),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 22 : 56,
                compact ? 26 : 56,
                compact ? 22 : 56,
                compact ? 34 : 56,
              ),
              child: Column(
                mainAxisAlignment: compact
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const UniBrandMark(),
                  SizedBox(height: compact ? 22 : 42),
                  Text(
                    'EL BALONCESTO\nUNIVERSITARIO,\nCOMO SE DEBE',
                    style:
                        (compact
                                ? Theme.of(context).textTheme.headlineLarge
                                : Theme.of(context).textTheme.displayMedium)
                            ?.copyWith(color: Colors.white),
                  ),
                  SizedBox(height: compact ? 12 : 20),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Text(
                      'Calendario, plantillas, entrenamientos, lesiones y '
                      'estadísticas de las selecciones de Aguascalientes, '
                      'Jalisco y Zacatecas, en un solo lugar.',
                      style: Theme.of(context).textTheme.bodyLarge
                          ?.copyWith(color: UniColors.onNavySoft),
                    ),
                  ),
                  if (!compact) ...[
                    const SizedBox(height: 40),
                    const _FeatureLabel(
                      icon: Icons.calendar_month_outlined,
                      label: 'Calendario y partidos',
                    ),
                    const SizedBox(height: 18),
                    const _FeatureLabel(
                      icon: Icons.groups_2_outlined,
                      label: 'Equipos y entrenamientos',
                    ),
                    const SizedBox(height: 18),
                    const _FeatureLabel(
                      icon: Icons.query_stats_outlined,
                      label: 'Seguimiento del rendimiento',
                    ),
                    const SizedBox(height: 48),
                    const _RegionStrip(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureLabel extends StatelessWidget {
  const _FeatureLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: UniColors.navy600),
          ),
          child: Icon(icon, color: UniColors.red, size: 19),
        ),
        const SizedBox(width: 14),
        Text(
          label,
          style: const TextStyle(
            fontFamily: UniFonts.text,
            fontSize: 15.5,
            fontWeight: FontWeight.w500,
            color: UniColors.onNavy,
          ),
        ),
      ],
    );
  }
}

/// Tira con los tres estados del sistema distribuido, al estilo de la
/// barra de marcadores de una cadena deportiva.
class _RegionStrip extends StatelessWidget {
  const _RegionStrip();

  @override
  Widget build(BuildContext context) {
    const regiones = [
      ('AGS', 'Aguascalientes'),
      ('JAL', 'Jalisco'),
      ('ZAC', 'Zacatecas'),
    ];

    return Row(
      children: [
        for (final (siglas, nombre) in regiones) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: UniColors.navy600),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  siglas,
                  style: const TextStyle(
                    fontFamily: UniFonts.display,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    height: 1.0,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  nombre.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: UniFonts.display,
                    fontWeight: FontWeight.w600,
                    fontSize: 9.5,
                    letterSpacing: 1.1,
                    color: UniColors.onNavySoft,
                  ),
                ),
              ],
            ),
          ),
          if (siglas != 'ZAC') const SizedBox(width: 10),
        ],
      ],
    );
  }
}
