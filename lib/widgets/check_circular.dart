import 'package:flutter/material.dart';

import '../theme/identidad_paleta.dart';
import '../theme/identidades_paleta.dart';

/// Checkbox animado — EL gesto de la app.
/// Genérico: recibe el estado [hecho] y un [onTap]; no conoce el dominio.
/// Al pasar de no-hecho a hecho: la forma se rellena con pop elástico
/// y el check se dibuja trazándose.
///
/// "Circular" es el nombre de siempre, pero la forma la pone la identidad
/// equipada: círculo en Profundidad y Dulce, cuadrado achaflanado en
/// Neotokyo+. El gesto —el pop, el trazo, los tiempos— es el mismo en las
/// cuatro: es la marca de la app y no se toca al cambiar de tema.
class CheckCircular extends StatefulWidget {
  final bool hecho;
  final VoidCallback? onTap;
  final Color color;
  final Color colorVacio;
  final double tamano;

  const CheckCircular({
    super.key,
    required this.hecho,
    required this.onTap,
    required this.color,
    required this.colorVacio,
    this.tamano = 44,
  });

  @override
  State<CheckCircular> createState() => _CheckCircularState();
}

class _CheckCircularState extends State<CheckCircular>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _relleno; // 0-1: el círculo se llena
  late final Animation<double> _pop;     // escala con rebote
  late final Animation<double> _trazo;   // 0-1: el check se dibuja

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _relleno = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
    );
    _pop = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.18), weight: 40),
      TweenSequenceItem(
          tween: Tween(begin: 1.18, end: 1.0)
              .chain(CurveTween(curve: Curves.elasticOut)),
          weight: 60),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.15, 0.75),
    ));
    _trazo = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 1.0, curve: Curves.easeOutCubic),
    );

    // Si ya nace hecho (recarga del Dashboard), mostrar el estado final sin animar
    if (widget.hecho) _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(CheckCircular oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hecho && !oldWidget.hecho) {
      _controller.forward(from: 0); // acaba de completarse → animación completa
    } else if (!widget.hecho && oldWidget.hecho) {
      _controller.value = 0; // reset (p. ej. cambio de día)
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.hecho ? null : widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        // Amplía el área táctil sin agrandar el dibujo
        padding: const EdgeInsets.all(6),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Transform.scale(
              scale: _pop.value,
              child: CustomPaint(
                size: Size.square(widget.tamano),
                painter: _CheckPainter(
                  relleno: _relleno.value,
                  trazo: _trazo.value,
                  color: widget.color,
                  colorVacio: widget.colorVacio,
                  forma: identidad(context).forma,
                  chaflan: identidad(context).chaflan,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Grosor del aro y del check en cada forma. El resto de la diferencia —qué
/// figura se dibuja y si el relleno brilla— no cabe en un número y se resuelve
/// al pintar.
class _TrazoCheck {
  final double aro;

  /// Grosor del check, en fracción del lado.
  final double check;

  /// Halo alrededor del relleno. A 0 no lo hay.
  final double glow;

  const _TrazoCheck({
    required this.aro,
    required this.check,
    this.glow = 0,
  });
}

const _checkGlass = _TrazoCheck(aro: 2.5, check: 0.09, glow: 5);
const _checkChamfer = _TrazoCheck(aro: 2.0, check: 0.10);
const _checkHairline = _TrazoCheck(aro: 1.2, check: 0.07);
const _checkPill = _TrazoCheck(aro: 3.0, check: 0.10, glow: 7);

class _CheckPainter extends CustomPainter {
  final double relleno;
  final double trazo;
  final Color color;
  final Color colorVacio;
  final FormaIdentidad forma;
  final double chaflan;

  _CheckPainter({
    required this.relleno,
    required this.trazo,
    required this.color,
    required this.colorVacio,
    required this.forma,
    required this.chaflan,
  });

  _TrazoCheck get _trazoDe => switch (forma) {
        FormaIdentidad.glass => _checkGlass,
        FormaIdentidad.chamfer => _checkChamfer,
        FormaIdentidad.hairline => _checkHairline,
        FormaIdentidad.pill => _checkPill,
      };

  /// La figura del check en esta identidad, inscrita en un cuadrado de lado
  /// `radio * 2` centrado en [centro]. [escala] la encoge desde el centro, que
  /// es como crece el relleno.
  Path _figura(Offset centro, double radio, double escala) {
    final r = radio * escala;
    if (forma != FormaIdentidad.chamfer) {
      return Path()
        ..addOval(Rect.fromCircle(center: centro, radius: r));
    }
    // Cuadrado con las cuatro esquinas cortadas, el mismo chaflán que la
    // identidad usa en tarjetas, chips y burbujas.
    final c = (chaflan * escala).clamp(0.0, r);
    return Path()
      ..moveTo(centro.dx - r + c, centro.dy - r)
      ..lineTo(centro.dx + r - c, centro.dy - r)
      ..lineTo(centro.dx + r, centro.dy - r + c)
      ..lineTo(centro.dx + r, centro.dy + r - c)
      ..lineTo(centro.dx + r - c, centro.dy + r)
      ..lineTo(centro.dx - r + c, centro.dy + r)
      ..lineTo(centro.dx - r, centro.dy + r - c)
      ..lineTo(centro.dx - r, centro.dy - r + c)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = _trazoDe;
    final centro = Offset(size.width / 2, size.height / 2);
    final radio = size.width / 2 - t.aro / 2;

    // Aro exterior (estado vacío)
    canvas.drawPath(
      _figura(centro, radio, 1.0),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = t.aro
        ..color = colorVacio,
    );

    // Relleno que crece desde el centro
    if (relleno > 0) {
      final dentro = _figura(centro, radio, relleno);
      // El glow va debajo del relleno y sólo en las identidades que lo piden.
      // Es estático dentro de cada fotograma del pop, no una sombra animada.
      if (t.glow > 0) {
        canvas.drawPath(
          dentro,
          Paint()
            ..color = color.withValues(alpha: 0.55)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, t.glow * relleno),
        );
      }
      canvas.drawPath(dentro, Paint()..color = color);
    }

    // Check dibujándose (dos segmentos: bajada corta + subida larga)
    if (trazo > 0) {
      final paintCheck = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * t.check
        ..strokeCap =
            forma == FormaIdentidad.chamfer ? StrokeCap.butt : StrokeCap.round
        ..color = Colors.white;

      final p1 = Offset(size.width * 0.28, size.height * 0.53);
      final p2 = Offset(size.width * 0.44, size.height * 0.68);
      final p3 = Offset(size.width * 0.73, size.height * 0.35);

      final path = Path()..moveTo(p1.dx, p1.dy);
      final primerTramo = (trazo * 2).clamp(0.0, 1.0);
      path.lineTo(
        p1.dx + (p2.dx - p1.dx) * primerTramo,
        p1.dy + (p2.dy - p1.dy) * primerTramo,
      );
      if (trazo > 0.5) {
        final segundoTramo = ((trazo - 0.5) * 2).clamp(0.0, 1.0);
        path.lineTo(
          p2.dx + (p3.dx - p2.dx) * segundoTramo,
          p2.dy + (p3.dy - p2.dy) * segundoTramo,
        );
      }
      canvas.drawPath(path, paintCheck);
    }
  }

  @override
  bool shouldRepaint(_CheckPainter old) =>
      old.relleno != relleno ||
      old.trazo != trazo ||
      old.color != color ||
      old.forma != forma;
}