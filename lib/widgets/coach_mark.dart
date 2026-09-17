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

  /// Posición del paso dentro del recorrido y cuántos hay, para los puntitos
  /// de progreso. Con [total] menor o igual a 1 no se pintan.
  final int paso;
  final int total;

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
    this.paso = 0,
    this.total = 0,
  });

  @override
  Widget build(BuildContext context) {
    final t = tokens(context);
    final pantalla = MediaQuery.sizeOf(context);
    final focoEnLaMitadDeArriba =
        foco != null && foco!.center.dy < pantalla.height / 2;

    return Material(
      // `transparency`, no un color transparente: son cosas distintas. El
      // render de Material hace `absorbHitTest: type != transparency`, así que
      // con el tipo por defecto se queda TODOS los toques de su superficie,
      // agujero incluido, y ningún paso de acción puede completarse nunca.
      // Con este tipo el `color` sobra y no se admite.
      type: MaterialType.transparency,
      child: Stack(
        children: [
          IgnorePointer(child: _Velo(foco: foco, radio: radio)),
          ..._barreras(pantalla),
          Positioned(
            left: 0,
            right: 0,
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
      // Misma caja que la tarjeta de OnboardingOverlay: para el usuario esto
      // es una sola secuencia, y dos cajas distintas la parten en dos.
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 24,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (total > 1) ...[
            _puntos(t),
            const SizedBox(height: 20),
          ],
          Text(titulo,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(color: t.text)),
          const SizedBox(height: 12),
          Text(cuerpo,
              textAlign: TextAlign.center,
              style: TextStyle(color: t.textMuted)),
          if (textoBoton != null) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onBoton,
                child: Text(textoBoton!),
              ),
            ),
          ],
          if (textoSaltar != null) ...[
            SizedBox(height: textoBoton == null ? 16 : 4),
            TextButton(
              onPressed: onSaltar,
              child: Text(textoSaltar!, style: TextStyle(color: t.textMuted)),
            ),
          ],
        ],
      ),
    );
  }

  /// Los puntitos de progreso, calcados de los de OnboardingOverlay.
  Widget _puntos(TokensContextuales t) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        total,
        (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i == paso ? t.primary : t.inactivo,
          ),
        ),
      ),
    );
  }
}

/// El velo y su pulso.
///
/// Va aparte para que [CoachMark] siga sin estado: lo único que se anima es
/// esto, y así el resto del widget se reconstruye cuando quiera sin arrastrar
/// un AnimationController.
class _Velo extends StatefulWidget {
  final Rect? foco;
  final double radio;

  const _Velo({required this.foco, required this.radio});

  @override
  State<_Velo> createState() => _VeloState();
}

class _VeloState extends State<_Velo> with SingleTickerProviderStateMixin {
  late final AnimationController _pulso = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulso.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulso,
      builder: (context, _) => CustomPaint(
        size: MediaQuery.sizeOf(context),
        painter: _VeloConAgujero(
          foco: widget.foco,
          radio: widget.radio,
          pulso: _pulso.value,
        ),
      ),
    );
  }
}

class _VeloConAgujero extends CustomPainter {
  final Rect? foco;
  final double radio;
  final double pulso;

  const _VeloConAgujero({
    required this.foco,
    required this.radio,
    required this.pulso,
  });

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

    final hueco = RRect.fromRectAndRadius(f, Radius.circular(radio));
    canvas.drawPath(
      Path.combine(PathOperation.difference, velo, Path()..addRRect(hueco)),
      pintura,
    );

    // Un anillo que crece y se desvanece alrededor del hueco. Lo señalado
    // suele estar en un borde de la pantalla —la barra de abajo, un botón
    // flotante— y sin esto cuesta encontrarlo.
    canvas.drawRRect(
      hueco.inflate(4 + 8 * pulso),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: 0.45 * (1 - pulso)),
    );
  }

  @override
  bool shouldRepaint(_VeloConAgujero viejo) =>
      viejo.foco != foco || viejo.radio != radio || viejo.pulso != pulso;
}
