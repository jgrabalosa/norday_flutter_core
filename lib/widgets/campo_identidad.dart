import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/identidad_paleta.dart';
import '../theme/identidades_paleta.dart';
import '../theme/tono_error.dart';

/// Un campo de texto resuelto en el lenguaje de la identidad equipada.
///
/// Tiene estado propio porque lo único que necesita saber es si está enfocado:
/// el foco es lo que enciende el glow de Profundidad o la línea magenta de
/// Neotokyo+.
///
/// Es un `TextFormField`, así que sirve igual dentro de un `Form` con
/// validación (Perfil) que suelto (Login). El texto de error va en el tono de
/// error de la identidad — nunca en el rojo de Material.
class CampoIdentidad extends StatefulWidget {
  final TextEditingController controlador;
  final String etiqueta;
  final bool oculto;

  /// Icono o botón al principio del campo. Existe para Perfil, que los tenía
  /// desde antes; Login no pasa ninguno.
  final Widget? prefijo;

  final Widget? sufijo;
  final TextInputType? teclado;
  final TextCapitalization capitalizacion;

  /// Mismo contrato que el de `TextFormField`: null si el valor vale.
  final String? Function(String?)? validador;

  /// En falso el campo se ve pero no se toca — el email de una cuenta de
  /// Google, que lo gestiona Google.
  final bool habilitado;

  /// Aclaración bajo el campo.
  final String? textoAyuda;

  const CampoIdentidad({
    super.key,
    required this.controlador,
    required this.etiqueta,
    this.oculto = false,
    this.prefijo,
    this.sufijo,
    this.teclado,
    this.capitalizacion = TextCapitalization.none,
    this.validador,
    this.habilitado = true,
    this.textoAyuda,
  });

  @override
  State<CampoIdentidad> createState() => _CampoIdentidadState();
}

class _CampoIdentidadState extends State<CampoIdentidad> {
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
    // Un campo deshabilitado no se enciende aunque el foco pase por encima.
    final enfocado = _foco.hasFocus && widget.habilitado;

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
              color:
                  enfocado ? t.primary : Colors.white.withValues(alpha: 0.08),
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
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(fontSize: 12, color: t.textMuted),
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

  /// El `TextFormField` desnudo: la caja (o la línea) la pone la identidad, así
  /// que aquí se desactivan los tres bordes del `inputDecorationTheme` global.
  Widget _entrada(TokensContextuales t, {String? etiquetaDentro}) {
    final tono = tonoError(context);

    return TextFormField(
      controller: widget.controlador,
      focusNode: _foco,
      enabled: widget.habilitado,
      obscureText: widget.oculto,
      keyboardType: widget.teclado,
      textCapitalization: widget.capitalizacion,
      validator: widget.validador,
      cursorColor: t.primary,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: widget.habilitado ? t.text : t.textMuted,
          ),
      decoration: InputDecoration(
        labelText: etiquetaDentro,
        labelStyle: TextStyle(color: t.textMuted),
        floatingLabelStyle: TextStyle(color: t.primary),
        helperText: widget.textoAyuda,
        helperStyle: TextStyle(color: t.textMuted, fontSize: 11),
        errorStyle: TextStyle(color: tono.texto),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        prefixIcon: widget.prefijo,
        prefixIconColor: t.textMuted,
        suffixIcon: widget.sufijo,
        suffixIconConstraints:
            const BoxConstraints(minWidth: 40, minHeight: 40),
      ),
    );
  }
}
