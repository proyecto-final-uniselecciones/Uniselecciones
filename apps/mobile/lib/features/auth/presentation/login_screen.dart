import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/auth_controller.dart';

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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 850;
          final horizontalPadding = isWide ? 48.0 : 24.0;

          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 32,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isWide ? 1120 : 460),
                  child: isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Expanded(child: _WelcomePanel()),
                            const SizedBox(width: 72),
                            Expanded(child: _loginCard(context)),
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const _WelcomePanel(compact: true),
                            const SizedBox(height: 28),
                            _loginCard(context),
                          ],
                        ),
                ),
              ),
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

    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isRegistering ? 'Crea tu cuenta' : 'Inicia sesión',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                _isRegistering
                    ? 'Regístrate para entrar a UniSelecciones.'
                    : 'Usa tu correo institucional para continuar.',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: const Color(0xFF64748B)),
              ),
              const SizedBox(height: 18),
              _DatabaseStatus(
                isChecking: auth.isCheckingDatabase,
                isConnected: auth.databaseConnected,
              ),
              const SizedBox(height: 28),
              if (_isRegistering) ...[
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
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
                    border: OutlineInputBorder(),
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
                          if (role != null)
                            setState(() => _selectedRole = role);
                        },
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedRole == 'jugador'
                      ? 'Tu cuenta se activa al registrarte.'
                      : 'Puedes entrar con este perfil al terminar el registro.',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: const Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: ValueKey('region-$_selectedRegion'),
                  initialValue: _selectedRegion,
                  decoration: const InputDecoration(
                    labelText: 'Estado',
                    prefixIcon: Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(),
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
                    border: OutlineInputBorder(),
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
                        ?.copyWith(color: const Color(0xFFB42318)),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'El catálogo incluye instituciones afiliadas a ANUIES.',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: const Color(0xFF64748B)),
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
                  border: OutlineInputBorder(),
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
                  border: const OutlineInputBorder(),
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
                    border: OutlineInputBorder(),
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
              const SizedBox(height: 24),
              FilledButton(
                onPressed: auth.isLoading ? null : () => _submit(context),
                child: auth.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isRegistering ? 'Crear cuenta' : 'Entrar'),
              ),
              if (notice != null) ...[
                const SizedBox(height: 16),
                Semantics(
                  liveRegion: true,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: success
                          ? const Color(0xFFECFDF3)
                          : const Color(0xFFFFF4E5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          success
                              ? Icons.check_circle_outline
                              : Icons.info_outline,
                          color: success
                              ? Color(0xFF16803C)
                              : Color(0xFF9A5B00),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            notice,
                            style: TextStyle(
                              color: success
                                  ? Color(0xFF176B36)
                                  : Color(0xFF704300),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
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

class _DatabaseStatus extends StatelessWidget {
  const _DatabaseStatus({required this.isChecking, required this.isConnected});

  final bool isChecking;
  final bool? isConnected;

  @override
  Widget build(BuildContext context) {
    final color = isChecking
        ? const Color(0xFF64748B)
        : isConnected == true
        ? const Color(0xFF16803C)
        : const Color(0xFFB42318);
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
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomePanel extends StatelessWidget {
  const _WelcomePanel({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textAlign = compact ? TextAlign.center : TextAlign.start;
    final crossAxisAlignment = compact
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.sports_basketball,
            color: Colors.white,
            size: 34,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'UniSelecciones',
          textAlign: textAlign,
          style: Theme.of(context).textTheme.headlineMedium
              ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.7),
        ),
        const SizedBox(height: 12),
        Text(
          'La organización del baloncesto universitario, en un solo lugar.',
          textAlign: textAlign,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(color: const Color(0xFF64748B), height: 1.45),
        ),
        if (!compact) ...[
          const SizedBox(height: 28),
          const _FeatureLabel(
            icon: Icons.calendar_month_outlined,
            label: 'Calendario y partidos',
          ),
          const SizedBox(height: 12),
          const _FeatureLabel(
            icon: Icons.groups_2_outlined,
            label: 'Equipos y entrenamientos',
          ),
          const SizedBox(height: 12),
          const _FeatureLabel(
            icon: Icons.query_stats_outlined,
            label: 'Seguimiento del rendimiento',
          ),
        ],
      ],
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
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Text(label, style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }
}
