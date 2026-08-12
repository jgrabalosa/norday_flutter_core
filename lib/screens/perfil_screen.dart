import 'package:flutter/material.dart';
import '../l10n/norday_core_localizations.dart';
import '../l10n/mensajes_error.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/api_service_core.dart';
import '../theme/app_theme.dart';
import '../theme/identidad_paleta.dart';
import '../theme/identidades_paleta.dart';
import '../theme/tono_error.dart';
import '../widgets/campo_identidad.dart';
import '../widgets/selector_preferencias.dart';
import '../widgets/superficie_identidad.dart';
import 'login_screen.dart';

class PerfilScreen extends StatefulWidget {
  final int usuarioId;

  /// Se reenvía al [LoginScreen] al que se vuelve tras eliminar la cuenta:
  /// el paquete no sabe cuál es la pantalla principal de esta app.
  final Widget Function(BuildContext context, bool mostrarOnboarding)
      destinoTrasLogin;

  const PerfilScreen({
    super.key,
    required this.usuarioId,
    required this.destinoTrasLogin,
  });

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _contrasenaActualController = TextEditingController();
  final _contrasenaNuevaController = TextEditingController();
  final _formContrasenaKey = GlobalKey<FormState>();

  bool _cargando = true;
  bool _esGoogle = false;
  bool _guardando = false;
  bool _cambiandoContrasena = false;
  bool _verContrasenas = false;
  bool _eliminando = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final datos = await ApiServiceCore.getUsuarioLocal();
    if (datos != null && mounted) {
      _nombreController.text = datos['nombre'] ?? '';
      _usernameController.text = datos['username'] ?? '';
      _emailController.text = datos['email'] ?? '';
      _esGoogle = datos['proveedorAuth'] == 'GOOGLE';
    }
    if (mounted) setState(() => _cargando = false);
  }

  Future<void> _guardar() async {
    final l = NordayCoreLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);
    try {
      await ApiServiceCore.actualizarUsuario(
        widget.usuarioId,
        _nombreController.text.trim(),
        _usernameController.text.trim(),
        _emailController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.perfilActualizado)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(MensajesError.de(context, e,
                  generico: l.perfilErrorGuardar))),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _cambiarContrasena() async {
    final l = NordayCoreLocalizations.of(context)!;
    if (!_formContrasenaKey.currentState!.validate()) return;

    setState(() => _cambiandoContrasena = true);
    try {
      await ApiServiceCore.cambiarContrasena(
        widget.usuarioId,
        _contrasenaActualController.text,
        _contrasenaNuevaController.text,
      );
      if (mounted) {
        _contrasenaActualController.clear();
        _contrasenaNuevaController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.perfilPassActualizada)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(MensajesError.de(context, e,
                  generico: l.perfilErrorPass))),
        );
      }
    } finally {
      if (mounted) setState(() => _cambiandoContrasena = false);
    }
  }

  Future<void> _confirmarEliminarCuenta() async {
    final l = NordayCoreLocalizations.of(context)!;
    // ── Primera confirmación ──
    final primera = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.perfilEliminarTitulo),
        content: Text(l.perfilEliminarCuerpo),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancelar),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            // El tono de error de la identidad equipada, no un rojo fijo:
            // ver `tonoError`.
            child: Text(l.comunContinuar,
                style: TextStyle(color: tonoError(context).texto)),
          ),
        ],
      ),
    );
    if (primera != true || !mounted) return;

    // ── Segunda confirmación ──
    final segunda = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.perfilUltimaConfirmacion),
        content: Text(l.perfilUltimaConfirmacionCuerpo),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.perfilNoVolver),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: tonoError(context).borde,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.perfilSiEliminar),
          ),
        ],
      ),
    );
    if (segunda != true || !mounted) return;

    setState(() => _eliminando = true);
    try {
      await ApiServiceCore.eliminarUsuario(widget.usuarioId);
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  LoginScreen(destinoTrasLogin: widget.destinoTrasLogin)),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _eliminando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(MensajesError.de(context, e,
                  generico: l.perfilErrorEliminar))),
        );
      }
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _contrasenaActualController.dispose();
    _contrasenaNuevaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = NordayCoreLocalizations.of(context)!;
    final t = tokens(context);
    final id = identidad(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.perfilTitulo,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SelectorPreferencias(usuarioId: widget.usuarioId),
                    const SizedBox(height: 12),
                    _tarjetaDatos(l, t, id),
                    if (!_esGoogle) ...[
                      const SizedBox(height: 12),
                      _tarjetaContrasena(l, t, id),
                    ],
                    const SizedBox(height: 12),
                    _tarjetaZonaPeligro(l, id),
                  ],
                ),
              ),
            ),
    );
  }

  /// Los datos de la cuenta. El `Form` se queda aquí dentro, con su misma
  /// clave y sus mismos validadores: lo que cambia es el vestido.
  Widget _tarjetaDatos(
      NordayCoreLocalizations l, TokensContextuales t, IdentidadPaleta id) {
    return SuperficieIdentidad(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CampoIdentidad(
              controlador: _nombreController,
              etiqueta: l.perfilLabelNombre,
              capitalizacion: TextCapitalization.words,
              prefijo: const Icon(LucideIcons.userRound, size: 18),
              validador: (v) => (v == null || v.trim().isEmpty)
                  ? l.perfilNombreVacio
                  : null,
            ),
            const SizedBox(height: 14),
            CampoIdentidad(
              controlador: _usernameController,
              etiqueta: l.perfilLabelUsuario,
              prefijo: const Icon(LucideIcons.atSign, size: 18),
              validador: (v) => (v == null || v.trim().isEmpty)
                  ? l.perfilUsuarioVacio
                  : null,
            ),
            const SizedBox(height: 14),
            CampoIdentidad(
              controlador: _emailController,
              etiqueta: l.perfilLabelEmail,
              habilitado: !_esGoogle,
              prefijo: const Icon(LucideIcons.mail, size: 18),
              textoAyuda: _esGoogle ? l.perfilGestionadoGoogle : null,
              validador: (v) {
                if (v == null || v.trim().isEmpty) {
                  return l.perfilEmailVacio;
                }
                if (!v.contains('@') || !v.contains('.')) {
                  return l.perfilEmailInvalido;
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _guardando ? null : _guardar,
              style: FilledButton.styleFrom(
                backgroundColor: t.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: _formaBoton(id),
              ),
              child: _guardando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(l.perfilGuardarCambios),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tarjetaContrasena(
      NordayCoreLocalizations l, TokensContextuales t, IdentidadPaleta id) {
    return SuperficieIdentidad(
      child: Form(
        key: _formContrasenaKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.perfilCambiarPass,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: t.text,
              ),
            ),
            const SizedBox(height: 16),
            CampoIdentidad(
              controlador: _contrasenaActualController,
              etiqueta: l.perfilPassActual,
              oculto: !_verContrasenas,
              prefijo: const Icon(LucideIcons.lock, size: 18),
              validador: (v) =>
                  (v == null || v.isEmpty) ? l.perfilPassActualVacia : null,
            ),
            const SizedBox(height: 14),
            CampoIdentidad(
              controlador: _contrasenaNuevaController,
              etiqueta: l.perfilPassNueva,
              oculto: !_verContrasenas,
              prefijo: const Icon(LucideIcons.keyRound, size: 18),
              sufijo: IconButton(
                icon: Icon(
                    _verContrasenas ? LucideIcons.eyeOff : LucideIcons.eye,
                    size: 18,
                    color: t.textMuted),
                onPressed: () =>
                    setState(() => _verContrasenas = !_verContrasenas),
              ),
              validador: (v) {
                if (v == null || v.isEmpty) {
                  return l.perfilPassNuevaVacia;
                }
                if (v.length < 6) {
                  return l.perfilMinimo6;
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: _cambiandoContrasena ? null : _cambiarContrasena,
              style: OutlinedButton.styleFrom(
                foregroundColor: t.text,
                side: BorderSide(color: t.textMuted.withValues(alpha: 0.45)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: _formaBoton(id),
              ),
              child: _cambiandoContrasena
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l.perfilCambiarPass),
            ),
          ],
        ),
      ),
    );
  }

  /// Eliminar la cuenta. Va en el tono de error de la identidad equipada —
  /// antes era `Colors.red` fijo, que en Alba grita y en Dulce se pelea con el
  /// rosa. Ver `tonoError`.
  Widget _tarjetaZonaPeligro(NordayCoreLocalizations l, IdentidadPaleta id) {
    final tono = tonoError(context);

    return SuperficieIdentidad(
      filo: BorderSide(color: tono.borde.withValues(alpha: 0.55)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.perfilZonaPeligro,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: tono.texto,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: tono.texto,
              side: BorderSide(color: tono.borde),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: _formaBoton(id),
            ),
            onPressed: _eliminando ? null : _confirmarEliminarCuenta,
            icon: _eliminando
                ? SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: tono.borde),
                  )
                : const Icon(LucideIcons.trash2, size: 18),
            label: Text(l.perfilEliminarCuenta),
          ),
        ],
      ),
    );
  }

  /// La forma de los botones, del mismo lenguaje que la tarjeta que los lleva.
  /// Mismo criterio que en Login.
  OutlinedBorder _formaBoton(IdentidadPaleta id) => switch (id.forma) {
        FormaIdentidad.chamfer => BordeChaflan(chaflan: id.chaflan),
        FormaIdentidad.pill => const StadiumBorder(),
        _ => RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(id.radioSecundario)),
      };
}