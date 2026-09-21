import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_theme.dart';
import 'burbuja_contexto.dart';

/// Un interrogante junto a un campo que, al pulsarlo, despliega la
/// explicación en una nota: la misma [BurbujaContexto] que acompaña a la
/// mascota, así que cada identidad la pinta a su manera sin código propio.
///
/// Recibe el texto y la etiqueta de accesibilidad ya traducidos, igual que
/// `CheckCircular`: qué explica cada campo es cosa de cada pantalla.
///
/// Sólo texto dentro, a propósito. Las explicaciones animadas son otro
/// proyecto.
///
/// La nota crece desde el propio icono —no desde el centro— y se encoge de
/// vuelta hacia él al cerrarse. Se cierra tocando en cualquier sitio: fuera,
/// en el icono o en la propia nota.
class AyudaCampo extends StatefulWidget {
  final String texto;

  /// Lo que lee el lector de pantalla en el icono, p. ej. «Ayuda sobre la
  /// meta». El icono solo no dice de qué es la ayuda.
  final String etiquetaSemantica;

  /// En vez de un botón aparte, un exponente: el interrogante, más pequeño,
  /// pegado a la palabra y subido, como el `²` de una potencia.
  ///
  /// La zona de toque baja de 48 a 28, por debajo del mínimo recomendado.
  /// Es el precio de que ocupe el sitio de un signo y no el de un botón; la
  /// nota que abre es la misma.
  final bool superindice;

  const AyudaCampo({
    super.key,
    required this.texto,
    required this.etiquetaSemantica,
    this.superindice = false,
  });

  @override
  State<AyudaCampo> createState() => _AyudaCampoState();
}

class _AyudaCampoState extends State<AyudaCampo>
    with SingleTickerProviderStateMixin {
  /// Ancho de la nota. Fijo y no ajustado al texto: así se sabe dónde cae
  /// antes de pintarla y se centra bajo el icono sin medir nada.
  static const _anchoNota = 260.0;

  /// Lo mínimo que la nota se separa de los bordes de la pantalla.
  static const _margenPantalla = 16.0;

  final _portal = OverlayPortalController();
  final _claveIcono = GlobalKey();

  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    reverseDuration: const Duration(milliseconds: 150),
  );

  /// Para la escala, con un pequeño rebote al abrir. La opacidad usa el
  /// controlador sin curva: `easeOutBack` se pasa de 1, y una opacidad por
  /// encima de 1 es un error, no un efecto.
  late final CurvedAnimation _escala = CurvedAnimation(
    parent: _anim,
    curve: Curves.easeOutBack,
    reverseCurve: Curves.easeIn,
  );

  /// Dónde está el icono y cuánto mide el overlay, tomados al abrir.
  Rect? _icono;
  Size? _areaOverlay;

  @override
  void dispose() {
    _escala.dispose();
    _anim.dispose();
    super.dispose();
  }

  void _abrir() {
    final caja = _claveIcono.currentContext?.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (caja == null || overlay == null) return;
    final origen = caja.localToGlobal(Offset.zero, ancestor: overlay);
    setState(() {
      _icono = origen & caja.size;
      _areaOverlay = overlay.size;
    });
    _portal.show();
    _anim.forward();
  }

  Future<void> _cerrar() async {
    await _anim.reverse();
    // Si se vuelve a abrir a mitad del cierre, `reverse` no llega a
    // completarse y esto no se ejecuta; la comprobación es por si acaso.
    if (mounted && _anim.isDismissed) _portal.hide();
  }

  void _alternar() {
    HapticFeedback.selectionClick();
    final abierta = _anim.status == AnimationStatus.forward ||
        _anim.status == AnimationStatus.completed;
    if (abierta) {
      _cerrar();
    } else {
      _abrir();
    }
  }

  Widget _nota(BuildContext context) {
    final icono = _icono;
    final area = _areaOverlay;
    if (icono == null || area == null) return const SizedBox.shrink();

    final ancho = min(_anchoNota, area.width - _margenPantalla * 2);
    final izquierda = (icono.center.dx - ancho / 2)
        .clamp(_margenPantalla, area.width - _margenPantalla - ancho)
        .toDouble();
    // El origen de la escala es el centro del icono, en coordenadas de la
    // nota: -1 es su borde izquierdo y 1 el derecho. En vertical, su borde
    // de arriba, que es el que queda pegado al icono.
    final origen = Alignment(
      ((icono.center.dx - izquierda) / ancho * 2 - 1).clamp(-1.0, 1.0).toDouble(),
      -1,
    );

    return Stack(
      children: [
        // Cualquier toque fuera de la nota la cierra. Es transparente: la
        // pantalla no se oscurece, porque esto es una aclaración y no un
        // diálogo que exija respuesta.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _cerrar,
          ),
        ),
        Positioned(
          left: izquierda,
          // `_icono` es el rectángulo del dibujo, no el de la caja de toque:
          // la nota nace justo debajo del interrogante que se ve, en los dos
          // modos.
          top: icono.bottom + 4,
          width: ancho,
          child: GestureDetector(
            onTap: _cerrar,
            child: FadeTransition(
              opacity: _anim,
              child: ScaleTransition(
                scale: _escala,
                alignment: origen,
                child: BurbujaContexto(texto: widget.texto),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = tokens(context);
    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: _nota,
      child: Semantics(
        button: true,
        label: widget.etiquetaSemantica,
        excludeSemantics: true,
        child: InkResponse(
          onTap: _alternar,
          radius: widget.superindice ? 14 : 20,
          // Normal: zona de toque de 48, el mínimo de accesibilidad, y el
          // dibujo en 18 para no pesar más que la etiqueta del campo.
          // Superíndice: 28 y 14, con el dibujo arriba a la izquierda de su
          // caja, que es lo que lo pega a la palabra y lo sube.
          child: SizedBox(
            width: widget.superindice ? 28 : 48,
            height: widget.superindice ? 28 : 48,
            child: Align(
              alignment:
                  widget.superindice ? Alignment.topLeft : Alignment.center,
              child: Icon(
                LucideIcons.circleQuestionMark,
                // La clave va en el dibujo y no en la caja: la nota nace del
                // interrogante que se ve, esté donde esté dentro de ella.
                key: _claveIcono,
                size: widget.superindice ? 14 : 18,
                color: t.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
