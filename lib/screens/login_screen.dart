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
import '../widgets/campo_identidad.dart';
import '../widgets/logo_google.dart';
import '../widgets/nori_marca.dart';
import '../widgets/superficie_identidad.dart';
import '../widgets/wordmark_identidad.dart';
import 'package:permission_handler/permission_handler.dart';
import 'eleccion_identidad_screen.dart';
import 'recuperacion_screen.dart';

class LoginScreen extends StatefulWidget {
  /// QuÃ© pantalla se abre cuando la sesiÃ³n ya es buena.
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

  // â”€â”€ Login â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  /// Adónde ir tras una sesión buena: si el usuario no posee identidad se
  /// intercala la elección antes del destino de la app.
  ///
  /// [posee] viene de Equipamiento.cargarDeUsuarioSiSePuede: `null` es "no se
  /// pudo averiguar" y entonces se deja pasar, porque un corte de red no
  /// puede encerrar a nadie en una pantalla sin salida y la red de seguridad
  /// del backend ya cubre el caso persistente.
  void _irADestino(int usuarioId, bool esNuevo, bool? posee) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (ctx) => posee == false
            ? EleccionIdentidadScreen(
                usuarioId: usuarioId,
                alElegir: () => Navigator.pushReplacement(
                  ctx,
                  MaterialPageRoute(
                      builder: (ctx2) => widget.destinoTrasLogin(ctx2, esNuevo)),
                ),
              )
            : widget.destinoTrasLogin(ctx, esNuevo),
      ),
    );
  }

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
      final posee = await Equipamiento.cargarDeUsuarioSiSePuede(usuario.usuarioId);
      _irADestino(usuario.usuarioId, false, posee);
    } catch (e) {
      if (mounted) setState(() { _error = _textoError(e, l); });
    } finally {
      // pushReplacement ya ha desmontado esta pantalla en el caso bueno
      if (mounted) setState(() { _loading = false; });
    }
  }

  // â”€â”€ Registro â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

      // Auto-login tras registrarse, para poder ir directo a crear el primer hÃ¡bito
      final usuario = await ApiServiceCore.login(
        _emailController.text,
        _contrasenaController.text,
      );
      await ApiServiceCore.saveToken(usuario.token);
      await ApiServiceCore.saveUsuario(usuario);
      await AnalyticsCore.registro(usuario.usuarioId);
      await _registrarNotificaciones(usuario.usuarioId);
      await _sincronizarPreferencias(usuario.usuarioId);
      final posee = await Equipamiento.cargarDeUsuarioSiSePuede(usuario.usuarioId);
      _irADestino(usuario.usuarioId, true, posee);
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

  // â”€â”€ Login con Google â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> _loginConGoogle() async {
    final l = NordayCoreLocalizations.of(context)!;
    setState(() { _loading = true; _error = null; });
    try {
      final esNuevo = await ApiServiceCore.loginConGoogle();
      final usuarioLocal = await ApiServiceCore.getUsuarioLocal();
      int? usuarioId;
      bool? posee;
      if (usuarioLocal != null && usuarioLocal['usuarioId'] != null) {
        usuarioId = usuarioLocal['usuarioId'] as int;
        await _registrarNotificaciones(usuarioId);
        await _sincronizarPreferencias(usuarioId);
        posee = await Equipamiento.cargarDeUsuarioSiSePuede(usuarioId);
      }
      // Sin usuarioId no se puede elegir identidad: se deja pasar y ya lo
      // resolverá el siguiente arranque.
      _irADestino(usuarioId ?? 0, esNuevo, usuarioId == null ? null : posee);
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

  // â”€â”€ Pintado â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  //
  // Tarjeta, campos, indicador de pestaÃ±a y aviso de error despachan por
  // `FormaIdentidad` con un switch exhaustivo, igual que la escena de mascota:
  // una identidad nueva declara su forma y los hereda; una forma nueva rompe la
  // compilaciÃ³n justo en los sitios que hay que decidir. La cabecera no
  // necesita switch propio â€” el tratamiento de la letra ya lo resuelve
  // `WordmarkIdentidad`.

  /// Lado de la ilustraciÃ³n de la cabecera. Nori aquÃ­ acompaÃ±a, no manda: la
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
              // En tablet el formulario no tiene por quÃ© cruzar la pantalla.
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _cabecera(t, l),
                  const SizedBox(height: 24),
                  // Alba no encajona: ahÃ­ esto no pinta tarjeta ninguna, y el
                  // formulario se apoya directamente en el fondo.
                  SuperficieIdentidad(
                    protagonista: true,
                    relleno: const EdgeInsets.all(24),
                    child: _formulario(id, t, l),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Nori y el nombre. Sustituye al icono genÃ©rico de check que hacÃ­a de logo.
  ///
  /// El wordmark va en `text` y no en el verde de antes: aquel se eligiÃ³
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
          CampoIdentidad(
            controlador: _nombreController,
            etiqueta: l.perfilLabelNombre,
            capitalizacion: TextCapitalization.words,
          ),
          const SizedBox(height: 14),
          CampoIdentidad(
            controlador: _usernameController,
            etiqueta: l.perfilLabelUsuario,
          ),
          const SizedBox(height: 14),
        ],

        CampoIdentidad(
          controlador: _emailController,
          etiqueta: l.perfilLabelEmail,
          teclado: TextInputType.emailAddress,
        ),
        const SizedBox(height: 14),

        CampoIdentidad(
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

  /// Iniciar sesiÃ³n / Registrarse. El mecanismo es el de siempre; lo que cambia
  /// con la identidad es el indicador de la pestaÃ±a activa.
  ///
  /// Activa y dormida se distinguen por color, no por peso: cambiar el peso
  /// sobre un estilo ya resuelto no carga la variante negrita de la familia
  /// â€”google_fonts trae un fichero por varianteâ€”, asÃ­ que se verÃ­a un falso
  /// negrita. El indicador ya dice cuÃ¡l es cuÃ¡l.
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

    // Neotokyo+ es la Ãºnica que admite mayÃºsculas y tracking, y sÃ³lo en la
    // familia de titulares â€” que es la que el tema pone en `title*`.
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

  /// El subrayado de la pestaÃ±a activa, por identidad. Es relleno y no texto,
  /// asÃ­ que aquÃ­ `primary` sÃ­ vale.
  Widget _indicadorTab(IdentidadPaleta id, TokensContextuales t, bool activo) {
    final color = activo ? t.primary : Colors.transparent;

    return switch (id.forma) {
      // Profundidad â€” barra redondeada con algo de luz debajo.
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

      // Neotokyo+ â€” filo recto, sin radio: el corte es su lenguaje.
      FormaIdentidad.chamfer => Container(height: 2, color: color),

      // Alba â€” lÃ­nea fina y nada mÃ¡s.
      FormaIdentidad.hairline => Container(height: 1, color: color),

      // Dulce â€” pÃ­ldora.
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

  /// El aviso de que algo ha ido mal, con el tono de la identidad equipada â€”
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
            shape: BordeChaflan(
              chaflan: id.chaflan,
              side: BorderSide(color: tono.borde),
            ),
          ),
          child: fila,
        ),

      // Alba â€” ni caja ni relleno: una lÃ­nea al margen y el texto. Un banner de
      // color serÃ­a lo mÃ¡s ruidoso de toda la identidad.
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
          foregroundColor: t.tinta,
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

  /// La forma de los botones, del mismo lenguaje que la tarjeta: serÃ­a raro
  /// un panel achaflanado con los botones redondeados.
  OutlinedBorder _formaBoton(IdentidadPaleta id) => switch (id.forma) {
        FormaIdentidad.glass =>
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(id.radioSecundario)),
        FormaIdentidad.chamfer => BordeChaflan(chaflan: id.chaflan),
        FormaIdentidad.hairline =>
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(id.radioSecundario)),
        FormaIdentidad.pill => const StadiumBorder(),
      };
}
