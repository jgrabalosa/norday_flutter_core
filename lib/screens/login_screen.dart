import 'package:flutter/material.dart';
import '../l10n/norday_core_localizations.dart';
import '../l10n/mensajes_error.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../theme/identidad_paleta.dart';
import '../theme/identidades_paleta.dart';
import '../theme/tono_error.dart';
import '../services/api_service_core.dart';
import '../services/api_error.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/analytics_service.dart';
import '../services/idioma_service.dart';
import '../services/zona_service.dart';
import '../theme/equipamiento.dart';
import '../widgets/logo_google.dart';
import '../widgets/nori_marca.dart';
import '../widgets/wordmark_identidad.dart';
import 'package:permission_handler/permission_handler.dart';
import 'recuperacion_screen.dart';

class LoginScreen extends StatefulWidget {
  /// Qué pantalla se abre cuando la sesión ya es buena.
  ///
  /// El paquete no puede saberlo: cada app del ecosistema tiene su propia
  /// pantalla principal. [mostrarOnboarding] va a true cuando la cuenta se
  /// acaba de crear en este mismo login.
  final Widget Function(BuildContext context, bool mostrarOnboarding)
      destinoTrasLogin;

  const LoginScreen({super.key, required this.destinoTrasLogin});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _contrasenaController = TextEditingController();
  bool _isLogin = true;
  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  /// Esta es la unica pantalla sin sesion todavia: aqui un 401 no significa
  /// "sesion caducada" sino que el email o la contrasena no son correctos.
  String _textoError(Object e, NordayCoreLocalizations l) {
    if (e is ApiException && e.tipo == TipoErrorApi.noAutorizado) {
      return l.loginCredenciales;
    }
    return MensajesError.de(context, e, generico: l.loginError);
  }

 Future<void> _registrarNotificaciones(int usuarioId) async {
    try {
      final status = await Permission.notification.request();
      if (!status.isGranted) return;

      final messaging = FirebaseMessaging.instance;

      NotificationSettings settings = await messaging.requestPermission();

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        final String? token = await messaging.getToken();
        if (token != null) {
          await ApiServiceCore.actualizarFcmToken(usuarioId, token);
        }
      }
    } catch (_) {
      // No bloqueamos el login si falla el registro de notificaciones
    }
  }

  /// Tras iniciar sesion, el backend manda la ultima palabra sobre las
  /// preferencias (puede haberlas cambiado desde otro dispositivo). En un
  /// alta nueva aun no hay nada guardado, asi que se propone la zona del
  /// dispositivo.
  Future<void> _sincronizarPreferencias(int usuarioId) async {
    try {
      final prefs = await ApiServiceCore.getPreferencias(usuarioId);
      await IdiomaService.sincronizarDesdeBackend(prefs['idioma']);
      await ZonaService.sincronizarDesdeBackend(prefs['zonaHoraria']);
    } catch (_) {
      // Sin conexion se sigue con lo que haya en local
    }
    await ZonaService.inicializarSiHaceFalta(usuarioId: usuarioId);
  }

  // ── Login ──────────────────────────────────────────────
  Future<void> _login() async {
    final l = NordayCoreLocalizations.of(context)!;
    setState(() { _loading = true; _error = null; });
    try {
      final usuario = await ApiServiceCore.login(
        _emailController.text,
        _contrasenaController.text,
      );
      await ApiServiceCore.saveToken(usuario.token);
      await ApiServiceCore.saveUsuario(usuario);
      await AnalyticsCore.login(usuario.usuarioId);
      await _registrarNotificaciones(usuario.usuarioId);
      await _sincronizarPreferencias(usuario.usuarioId);
      await Equipamiento.cargarDeUsuarioSiSePuede(usuario.usuarioId);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (ctx) => widget.destinoTrasLogin(ctx, false)),
        );
      }
    } catch (e) {
      if (mounted) setState(() { _error = _textoError(e, l); });
    } finally {
      // pushReplacement ya ha desmontado esta pantalla en el caso bueno
      if (mounted) setState(() { _loading = false; });
    }
  }

  // ── Registro ───────────────────────────────────────────
  final _nombreController = TextEditingController();
  final _usernameController = TextEditingController();

Future<void> _registro() async {
    final l = NordayCoreLocalizations.of(context)!;
    setState(() { _loading = true; _error = null; });
    try {
      await ApiServiceCore.registro(
        _nombreController.text,
        _usernameController.text,
        _emailController.text,
        _contrasenaController.text,
      );

      // Auto-login tras registrarse, para poder ir directo a crear el primer hábito
      final usuario = await ApiServiceCore.login(
        _emailController.text,
        _contrasenaController.text,
      );
      await ApiServiceCore.saveToken(usuario.token);
      await ApiServiceCore.saveUsuario(usuario);
      await AnalyticsCore.registro(usuario.usuarioId);
      await _registrarNotificaciones(usuario.usuarioId);
      await _sincronizarPreferencias(usuario.usuarioId);
      await Equipamiento.cargarDeUsuarioSiSePuede(usuario.usuarioId);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (ctx) => widget.destinoTrasLogin(ctx, true)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = MensajesError.de(context, e, generico: l.loginError);
        });
      }
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  // ── Login con Google ───────────────────────────────────
  Future<void> _loginConGoogle() async {
    final l = NordayCoreLocalizations.of(context)!;
    setState(() { _loading = true; _error = null; });
    try {
      final esNuevo = await ApiServiceCore.loginConGoogle();
      final usuarioLocal = await ApiServiceCore.getUsuarioLocal();
      if (usuarioLocal != null && usuarioLocal['usuarioId'] != null) {
        await _registrarNotificaciones(usuarioLocal['usuarioId']);
        await _sincronizarPreferencias(usuarioLocal['usuarioId']);
        await Equipamiento.cargarDeUsuarioSiSePuede(usuarioLocal['usuarioId']);
      }
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (ctx) => widget.destinoTrasLogin(ctx, esNuevo)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = MensajesError.de(context, e, generico: l.loginError);
        });
      }
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _contrasenaController.dispose();
    _nombreController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  // ── Pintado ────────────────────────────────────────────
  //
  // Tarjeta, campos, indicador de pestaña y aviso de error despachan por
  // `FormaIdentidad` con un switch exhaustivo, igual que la escena de mascota:
  // una identidad nueva declara su forma y los hereda; una forma nueva rompe la
  // compilación justo en los sitios que hay que decidir. La cabecera no
  // necesita switch propio — el tratamiento de la letra ya lo resuelve
  // `WordmarkIdentidad`.

  /// Lado de la ilustración de la cabecera. Nori aquí acompaña, no manda: la
  /// pantalla va de entrar.
  static const double _ladoNori = 88;

  @override
  Widget build(BuildContext context) {
    final id = identidad(context);
    final t = tokens(context);
    final l = NordayCoreLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              // En tablet el formulario no tiene por qué cruzar la pantalla.
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _cabecera(t, l),
                  const SizedBox(height: 24),
                  _tarjeta(id, t, _formulario(id, t, l)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Nori y el nombre. Sustituye al icono genérico de check que hacía de logo.
  ///
  /// El wordmark va en `text` y no en el verde de antes: aquel se eligió
  /// porque el esmeralda no contrastaba sobre el fondo claro, y con el color
  /// de texto de cada identidad el problema no existe en ninguna de las
  /// cuatro.
  Widget _cabecera(TokensContextuales t, NordayCoreLocalizations l) {
    return Column(
      children: [
        const NoriMarca(tamano: _ladoNori, intensidadHalo: 0.7),
        const SizedBox(height: 8),
        WordmarkIdentidad(texto: l.appTitulo, tamano: 26, color: t.text),
        const SizedBox(height: 6),
        Text(
          l.loginTagline,
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: t.textMuted),
        ),
      ],
    );
  }

  /// La superficie sobre la que se rellena el formulario.
  Widget _tarjeta(IdentidadPaleta id, TokensContextuales t, Widget contenido) {
    const relleno = EdgeInsets.all(24);

    return switch (id.forma) {
      // Profundidad — cristal: degradado entre las dos superficies, filo claro
      // y sombra honda. El mismo tratamiento que la burbuja de contexto.
      FormaIdentidad.glass => Container(
          padding: relleno,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(id.radioHero),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [t.surface, t.surface2],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: contenido,
        ),

      // Neotokyo+ — panel achaflanado con el token de siempre.
      FormaIdentidad.chamfer => Container(
          padding: relleno,
          decoration: ShapeDecoration(
            color: t.surface,
            shape: _BordeChaflan(
              chaflan: id.chaflan,
              side: BorderSide(color: t.primary.withValues(alpha: 0.55)),
            ),
          ),
          child: contenido,
        ),

      // Alba — sin tarjeta. Es la más silenciosa de las cuatro y aquí no
      // encajona nada: el formulario se apoya directamente en el fondo.
      FormaIdentidad.hairline => contenido,

      // Dulce — píldora blanca con sombra rosa.
      FormaIdentidad.pill => Container(
          padding: relleno,
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(id.radioHero),
            boxShadow: [
              BoxShadow(
                color: t.primary.withValues(alpha: 0.22),
                blurRadius: 26,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: contenido,
        ),
    };
  }

  Widget _formulario(
      IdentidadPaleta id, TokensContextuales t, NordayCoreLocalizations l) {
    return Column(
      children: [
        _tabs(id, t, l),
        const SizedBox(height: 24),
        _botonGoogle(id, t, l),
        const SizedBox(height: 16),
        _separador(t, l),
        const SizedBox(height: 16),

        if (!_isLogin) ...[
          _CampoIdentidad(
            controlador: _nombreController,
            etiqueta: l.perfilLabelNombre,
            capitalizacion: TextCapitalization.words,
          ),
          const SizedBox(height: 14),
          _CampoIdentidad(
            controlador: _usernameController,
            etiqueta: l.perfilLabelUsuario,
          ),
          const SizedBox(height: 14),
        ],

        _CampoIdentidad(
          controlador: _emailController,
          etiqueta: l.perfilLabelEmail,
          teclado: TextInputType.emailAddress,
        ),
        const SizedBox(height: 14),

        _CampoIdentidad(
          controlador: _contrasenaController,
          etiqueta: l.loginLabelContrasena,
          oculto: _obscurePassword,
          sufijo: IconButton(
            icon: Icon(
              _obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff,
              size: 18,
              color: t.textMuted,
            ),
            onPressed: () =>
                setState(() { _obscurePassword = !_obscurePassword; }),
          ),
        ),

        if (_isLogin)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _loading
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RecuperacionScreen(),
                        ),
                      );
                    },
              child: Text(
                l.loginOlvidasteContrasena,
                // Subrayado y color de texto en vez del primario: el verde de
                // Profundidad o el salvia de Alba no llegan a 4.5:1 sobre sus
                // propios fondos, y esto es texto que hay que leer.
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: t.text,
                      decoration: TextDecoration.underline,
                      decorationColor: t.textMuted,
                    ),
              ),
            ),
          )
        else
          const SizedBox(height: 16),

        if (_error != null) ...[
          _banderaError(id, _error!),
          const SizedBox(height: 16),
        ],

        _botonPrincipal(id, t, l),
      ],
    );
  }

  /// Iniciar sesión / Registrarse. El mecanismo es el de siempre; lo que cambia
  /// con la identidad es el indicador de la pestaña activa.
  ///
  /// Activa y dormida se distinguen por color, no por peso: cambiar el peso
  /// sobre un estilo ya resuelto no carga la variante negrita de la familia
  /// —google_fonts trae un fichero por variante—, así que se vería un falso
  /// negrita. El indicador ya dice cuál es cuál.
  Widget _tabs(
      IdentidadPaleta id, TokensContextuales t, NordayCoreLocalizations l) {
    return Row(
      children: [
        Expanded(
          child: _tab(id, t, l.loginIniciarSesion, _isLogin,
              () => setState(() { _isLogin = true; _error = null; })),
        ),
        Expanded(
          child: _tab(id, t, l.loginRegistrarse, !_isLogin,
              () => setState(() { _isLogin = false; _error = null; })),
        ),
      ],
    );
  }

  Widget _tab(IdentidadPaleta id, TokensContextuales t, String etiqueta,
      bool activo, VoidCallback alTocar) {
    final base = Theme.of(context).textTheme.titleSmall;
    final color = activo ? t.text : t.textMuted;

    // Neotokyo+ es la única que admite mayúsculas y tracking, y sólo en la
    // familia de titulares — que es la que el tema pone en `title*`.
    final esNeotokyo = id.forma == FormaIdentidad.chamfer;

    return GestureDetector(
      onTap: alTocar,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Text(
            esNeotokyo ? etiqueta.toUpperCase() : etiqueta,
            textAlign: TextAlign.center,
            style: base?.copyWith(
              color: color,
              letterSpacing: esNeotokyo ? 1.2 : null,
            ),
          ),
          const SizedBox(height: 8),
          _indicadorTab(id, t, activo),
        ],
      ),
    );
  }

  /// El subrayado de la pestaña activa, por identidad. Es relleno y no texto,
  /// así que aquí `primary` sí vale.
  Widget _indicadorTab(IdentidadPaleta id, TokensContextuales t, bool activo) {
    final color = activo ? t.primary : Colors.transparent;

    return switch (id.forma) {
      // Profundidad — barra redondeada con algo de luz debajo.
      FormaIdentidad.glass => Container(
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            boxShadow: activo
                ? [
                    BoxShadow(
                      color: t.primary.withValues(alpha: 0.45),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
        ),

      // Neotokyo+ — filo recto, sin radio: el corte es su lenguaje.
      FormaIdentidad.chamfer => Container(height: 2, color: color),

      // Alba — línea fina y nada más.
      FormaIdentidad.hairline => Container(height: 1, color: color),

      // Dulce — píldora.
      FormaIdentidad.pill => Container(
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
    };
  }

  Widget _botonGoogle(
      IdentidadPaleta id, TokensContextuales t, NordayCoreLocalizations l) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _loading ? null : _loginConGoogle,
        icon: const LogoGoogle(lado: 18),
        label: Text(l.loginContinuarGoogle),
        style: OutlinedButton.styleFrom(
          foregroundColor: t.text,
          side: BorderSide(color: t.textMuted.withValues(alpha: 0.45)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: _formaBoton(id),
          textStyle: Theme.of(context).textTheme.labelLarge,
        ),
      ),
    );
  }

  Widget _separador(TokensContextuales t, NordayCoreLocalizations l) {
    final linea = Expanded(
      child: Divider(color: t.textMuted.withValues(alpha: 0.35), height: 1),
    );
    return Row(
      children: [
        linea,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            l.loginO,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: t.textMuted),
          ),
        ),
        linea,
      ],
    );
  }

  /// El aviso de que algo ha ido mal, con el tono de la identidad equipada —
  /// nunca un rojo fijo. Ver `tonoError`.
  Widget _banderaError(IdentidadPaleta id, String mensaje) {
    final tono = tonoError(context);
    final texto = Text(
      mensaje,
      style: Theme.of(context)
          .textTheme
          .bodySmall
          ?.copyWith(color: tono.texto, height: 1.35),
    );
    final icono = Icon(LucideIcons.circleAlert, size: 18, color: tono.borde);
    final fila = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        icono,
        const SizedBox(width: 10),
        Expanded(child: texto),
      ],
    );
    const relleno = EdgeInsets.all(12);

    return switch (id.forma) {
      FormaIdentidad.glass => Container(
          width: double.infinity,
          padding: relleno,
          decoration: BoxDecoration(
            color: tono.fondo,
            borderRadius: BorderRadius.circular(id.radioSecundario),
            border: Border.all(color: tono.borde.withValues(alpha: 0.55)),
          ),
          child: fila,
        ),

      FormaIdentidad.chamfer => Container(
          width: double.infinity,
          padding: relleno,
          decoration: ShapeDecoration(
            color: tono.fondo,
            shape: _BordeChaflan(
              chaflan: id.chaflan,
              side: BorderSide(color: tono.borde),
            ),
          ),
          child: fila,
        ),

      // Alba — ni caja ni relleno: una línea al margen y el texto. Un banner de
      // color sería lo más ruidoso de toda la identidad.
      FormaIdentidad.hairline => Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 4, 0, 4),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: tono.borde, width: 2)),
          ),
          child: fila,
        ),

      FormaIdentidad.pill => Container(
          width: double.infinity,
          padding: relleno,
          decoration: BoxDecoration(
            color: tono.fondo,
            borderRadius: BorderRadius.circular(id.radioSecundario),
          ),
          child: fila,
        ),
    };
  }

  Widget _botonPrincipal(
      IdentidadPaleta id, TokensContextuales t, NordayCoreLocalizations l) {
    final esNeotokyo = id.forma == FormaIdentidad.chamfer;
    final etiqueta = _isLogin ? l.loginIniciarSesion : l.loginCrearCuenta;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _loading ? null : (_isLogin ? _login : _registro),
        style: ElevatedButton.styleFrom(
          backgroundColor: t.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: _formaBoton(id),
        ),
        child: _loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.4, color: Colors.white),
              )
            : Text(
                esNeotokyo ? etiqueta.toUpperCase() : etiqueta,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontSize: 16,
                      color: Colors.white,
                      letterSpacing: esNeotokyo ? 1.2 : null,
                    ),
              ),
      ),
    );
  }

  /// La forma de los botones, del mismo lenguaje que la tarjeta: sería raro
  /// un panel achaflanado con los botones redondeados.
  OutlinedBorder _formaBoton(IdentidadPaleta id) => switch (id.forma) {
        FormaIdentidad.glass =>
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(id.radioSecundario)),
        FormaIdentidad.chamfer => _BordeChaflan(chaflan: id.chaflan),
        FormaIdentidad.hairline =>
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(id.radioSecundario)),
        FormaIdentidad.pill => const StadiumBorder(),
      };
}

/// Un campo de texto resuelto en el lenguaje de la identidad equipada.
///
/// Tiene estado propio porque lo único que necesita saber es si está enfocado:
/// el foco es lo que enciende el glow de Profundidad o la línea magenta de
/// Neotokyo+.
class _CampoIdentidad extends StatefulWidget {
  final TextEditingController controlador;
  final String etiqueta;
  final bool oculto;
  final Widget? sufijo;
  final TextInputType? teclado;
  final TextCapitalization capitalizacion;

  const _CampoIdentidad({
    required this.controlador,
    required this.etiqueta,
    this.oculto = false,
    this.sufijo,
    this.teclado,
    this.capitalizacion = TextCapitalization.none,
  });

  @override
  State<_CampoIdentidad> createState() => _CampoIdentidadState();
}

class _CampoIdentidadState extends State<_CampoIdentidad> {
  final _foco = FocusNode();

  /// Lo que tarda el campo en encenderse al recibir el foco. Corto a propósito:
  /// es respuesta a un gesto del usuario, no el ritmo de firma de la identidad.
  static const _duracionFoco = Duration(milliseconds: 180);

  @override
  void initState() {
    super.initState();
    _foco.addListener(_alCambiarElFoco);
  }

  @override
  void dispose() {
    _foco.removeListener(_alCambiarElFoco);
    _foco.dispose();
    super.dispose();
  }

  void _alCambiarElFoco() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final id = identidad(context);
    final t = tokens(context);
    final enfocado = _foco.hasFocus;

    return switch (id.forma) {
      // Profundidad — caja de cristal que se enciende en verde al enfocar.
      FormaIdentidad.glass => AnimatedContainer(
          duration: _duracionFoco,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(id.radioSecundario),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [t.surface2, t.surface],
            ),
            border: Border.all(
              color: enfocado
                  ? t.primary
                  : Colors.white.withValues(alpha: 0.08),
              width: enfocado ? 1.4 : 1,
            ),
            boxShadow: enfocado
                ? [
                    BoxShadow(
                      color: t.primary.withValues(alpha: 0.30),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: _entrada(t, etiquetaDentro: widget.etiqueta),
        ),

      // Neotokyo+ — sin caja: etiqueta en mayúsculas arriba y una línea abajo
      // que se enciende en magenta. Las mayúsculas y el tracking se aplican
      // aquí, no en el tema, y sobre la familia de titulares.
      FormaIdentidad.chamfer => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.etiqueta.toUpperCase(),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontSize: 11,
                    letterSpacing: 1.4,
                    color: enfocado ? t.primary : t.textMuted,
                  ),
            ),
            _entrada(t),
            AnimatedContainer(
              duration: _duracionFoco,
              height: enfocado ? 2 : 1,
              color: enfocado ? t.primary : t.textMuted.withValues(alpha: 0.5),
            ),
          ],
        ),

      // Alba — la misma idea, pero en voz baja: la línea no engorda, sólo
      // cambia de color.
      FormaIdentidad.hairline => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.etiqueta,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontSize: 12,
                    color: t.textMuted,
                  ),
            ),
            _entrada(t),
            AnimatedContainer(
              duration: _duracionFoco,
              height: 1,
              color: enfocado ? t.primary : t.text.withValues(alpha: 0.22),
            ),
          ],
        ),

      // Dulce — campo redondeado, rosa, con su glow al enfocar.
      FormaIdentidad.pill => AnimatedContainer(
          duration: _duracionFoco,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: t.surface2,
            borderRadius: BorderRadius.circular(id.radioHero),
            border: Border.all(
              color: enfocado ? t.primary : Colors.transparent,
              width: 1.6,
            ),
            boxShadow: enfocado
                ? [
                    BoxShadow(
                      color: t.primary.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: _entrada(t, etiquetaDentro: widget.etiqueta),
        ),
    };
  }

  /// El `TextField` desnudo: la caja (o la línea) la pone la identidad, así que
  /// aquí se desactivan los tres bordes del `inputDecorationTheme` global.
  Widget _entrada(TokensContextuales t, {String? etiquetaDentro}) {
    return TextField(
      controller: widget.controlador,
      focusNode: _foco,
      obscureText: widget.oculto,
      keyboardType: widget.teclado,
      textCapitalization: widget.capitalizacion,
      cursorColor: t.primary,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: t.text),
      decoration: InputDecoration(
        labelText: etiquetaDentro,
        labelStyle: TextStyle(color: t.textMuted),
        floatingLabelStyle: TextStyle(color: t.primary),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        suffixIcon: widget.sufijo,
        suffixIconConstraints:
            const BoxConstraints(minWidth: 40, minHeight: 40),
      ),
    );
  }
}

/// Rectángulo con las cuatro esquinas cortadas en recto, el rasgo de
/// Neotokyo+. Es un [OutlinedBorder] y no un painter para que valga igual de
/// forma de un `Container` que de un botón.
class _BordeChaflan extends OutlinedBorder {
  final double chaflan;

  const _BordeChaflan({required this.chaflan, super.side = BorderSide.none});

  @override
  OutlinedBorder copyWith({BorderSide? side}) =>
      _BordeChaflan(chaflan: chaflan, side: side ?? this.side);

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  ShapeBorder scale(double t) =>
      _BordeChaflan(chaflan: chaflan * t, side: side.scale(t));

  Path _camino(Rect rect) {
    // Con cajas muy bajas el corte se comería el lado entero.
    final c = chaflan.clamp(0.0, rect.shortestSide / 2);
    return Path()
      ..moveTo(rect.left + c, rect.top)
      ..lineTo(rect.right - c, rect.top)
      ..lineTo(rect.right, rect.top + c)
      ..lineTo(rect.right, rect.bottom - c)
      ..lineTo(rect.right - c, rect.bottom)
      ..lineTo(rect.left + c, rect.bottom)
      ..lineTo(rect.left, rect.bottom - c)
      ..lineTo(rect.left, rect.top + c)
      ..close();
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => _camino(rect);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      _camino(rect.deflate(side.width));

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none) return;
    canvas.drawPath(_camino(rect.deflate(side.width / 2)), side.toPaint());
  }

  @override
  bool operator ==(Object other) =>
      other is _BordeChaflan &&
      other.chaflan == chaflan &&
      other.side == side;

  @override
  int get hashCode => Object.hash(chaflan, side);
}
