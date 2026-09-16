import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Rectángulo en coordenadas globales del elemento al que apunta [ancla],
/// o null si todavía no está pintado.
///
/// Que devuelva null no es un error: un elemento fuera de pantalla o aún sin
/// medir no tiene rectángulo. Quien llame decide qué hacer —esperar al
/// siguiente frame, o saltarse el paso—, pero nunca debe asumir que hay uno.
Rect? rectDeAncla(GlobalKey ancla,
    {EdgeInsets holgura = const EdgeInsets.all(8)}) {
  final render = ancla.currentContext?.findRenderObject();
  if (render is! RenderBox || !render.hasSize) return null;
  return holgura.inflateRect(render.localToGlobal(Offset.zero) & render.size);
}

/// Una marca del recorrido guiado: vela la pantalla, recorta el elemento
/// señalado y lo explica en una tarjeta.
///
/// Hay dos clases de paso y la diferencia no es cosmética:
///
/// - **De acción** ([textoBoton] nulo): sin botón. Se avanza haciendo lo que
///   se señala, y por eso el hueco deja pasar los toques al elemento real de
///   debajo. Un botón aquí ofrecería saltarse la acción, y saltársela vacía
///   el recorrido: lo que se recuerda es lo que se hizo, no lo que se leyó.
/// - **De explicación**: no hay nada que hacer, así que sí hay botón.
///
/// La tarjeta va siempre en la mitad contraria al foco. Regla tonta a
/// propósito: así nunca tapa lo señalado y no salta de sitio de forma
/// impredecible entre pasos.
///
/// El borde en `t.primary` es deliberado: la tarjeta tiene que leerse como
/// una anotación sobre la app, no como una parte más de ella.
class CoachMark extends StatelessWidget {
  /// Qué se recorta. Null vela la pantalla entera, sin agujero.
  final Rect? foco;
  final String titulo;
  final String cuerpo;

  /// Null en los pasos de acción. Ver la nota de clase.
  final String? textoBoton;
  final VoidCallback? onBoton;

  final String? textoSaltar;
  final VoidCallback? onSaltar;

  final double radio;

  const CoachMark({
    super.key,
    required this.foco,
    required this.titulo,
    required this.cuerpo,
    this.textoBoton,
    this.onBoton,
    this.textoSaltar,
    this.onSaltar,
    this.radio = AppRadius.md,
  });

  @override
  Widget build(BuildContext context) {
    final t = tokens(context);
    final pantalla = MediaQuery.sizeOf(context);
    final focoEnLaMitadDeArriba =
        foco != null && foco!.center.dy < pantalla.height / 2;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          IgnorePointer(
            child: CustomPaint(
              size: pantalla,
              painter: _VeloConAgujero(foco: foco, radio: radio),
            ),
          ),
          ..._barreras(pantalla),
          Positioned(
            left: 16,
            right: 16,
            top: focoEnLaMitadDeArriba ? null : 0,
            bottom: focoEnLaMitadDeArriba ? 0 : null,
            child: SafeArea(child: _tarjeta(context, t)),
          ),
        ],
      ),
    );
  }

  /// Cuatro rectángulos opacos alrededor del hueco, y nada encima del hueco.
  ///
  /// Es lo que hace que el elemento señalado siga siendo pulsable: no se
  /// intercepta el toque para reenviarlo, sencillamente no hay nada en medio.
  /// El velo va bajo un IgnorePointer por lo mismo.
  List<Widget> _barreras(Size pantalla) {
    Widget absorber() =>
        GestureDetector(behavior: HitTestBehavior.opaque, onTap: () {});

    final f = foco;
    if (f == null) return [Positioned.fill(child: absorber())];

    final arriba = f.top.clamp(0.0, pantalla.height);
    final abajo = f.bottom.clamp(0.0, pantalla.height);
    return [
      Positioned(left: 0, right: 0, top: 0, height: arriba, child: absorber()),
      Positioned(left: 0, right: 0, top: abajo, bottom: 0, child: absorber()),
      Positioned(
          left: 0,
          top: arriba,
          width: f.left.clamp(0.0, pantalla.width),
          height: abajo - arriba,
          child: absorber()),
      Positioned(
          left: f.right.clamp(0.0, pantalla.width),
          right: 0,
          top: arriba,
          height: abajo - arriba,
          child: absorber()),
    ];
  }

  Widget _tarjeta(BuildContext context, TokensContextuales t) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: t.primary, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: t.text)),
          const SizedBox(height: 6),
          Text(cuerpo, style: TextStyle(color: t.textMuted, height: 1.35)),
          if (textoBoton != null || textoSaltar != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                if (textoSaltar != null)
                  TextButton(
                    onPressed: onSaltar,
                    child: Text(textoSaltar!,
                        style: TextStyle(color: t.textMuted)),
                  ),
                const Spacer(),
                if (textoBoton != null)
                  FilledButton(
                    onPressed: onBoton,
                    style: FilledButton.styleFrom(
                      backgroundColor: t.primary,
                      foregroundColor: t.bg,
                    ),
                    child: Text(textoBoton!),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _VeloConAgujero extends CustomPainter {
  final Rect? foco;
  final double radio;

  const _VeloConAgujero({required this.foco, required this.radio});

  static const double _opacidad = 0.72;

  @override
  void paint(Canvas canvas, Size size) {
    final pintura = Paint()..color = Colors.black.withValues(alpha: _opacidad);
    final velo = Path()..addRect(Offset.zero & size);

    final f = foco;
    if (f == null) {
      canvas.drawPath(velo, pintura);
      return;
    }

    final agujero = Path()
      ..addRRect(RRect.fromRectAndRadius(f, Radius.circular(radio)));
    canvas.drawPath(
        Path.combine(PathOperation.difference, velo, agujero), pintura);
  }

  @override
  bool shouldRepaint(_VeloConAgujero viejo) =>
      viejo.foco != foco || viejo.radio != radio;
}
