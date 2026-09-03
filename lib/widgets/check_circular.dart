import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
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
  final double tamano;

  /// Qué hace un toque cuando ya está [hecho]. Sin esto el check marcado no
  /// es tocable, que es como se ha comportado siempre y como se siguen
  /// comportando los usos de solo lectura.
  final VoidCallback? onDeshacer;

  /// Etiqueta para lectores de pantalla. La pone quien usa el widget: el
  /// core no conoce el dominio y no puede saber si esto completa un hábito,
  /// marca una píldora o cualquier otra cosa.
  final String? etiquetaSemantica;

  /// La etiqueta cuando está [hecho] y hay [onDeshacer]: el botón ya no
  /// promete lo mismo, y un lector de pantalla tiene que anunciar la acción
  /// que de verdad va a ocurrir.
  final String? etiquetaSemanticaDeshacer;

  const CheckCircular({
    super.key,
    required this.hecho,
    required this.onTap,
    required this.color,
    this.tamano = 44,
    this.onDeshacer,
    this.etiquetaSemantica,
    this.etiquetaSemanticaDeshacer,
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

  /// Misma lectura y mismo criterio que el resto del sistema: con "reducir
  /// movimiento" el check no se traza ni rebota, salta a hecho. El estado
  /// final es idéntico —lo que se apaga es el recorrido, no la información—,
  /// y este gesto es de los más aparatosos que tiene la app.
  bool _animacionesDesactivadas = false;

  /// Qué hace un toque ahora mismo: completar si no está hecho, deshacer si
  /// lo está. Sin la acción que toque, el check no es tocable.
  VoidCallback? get _accion => widget.hecho ? widget.onDeshacer : widget.onTap;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
      // Deshacer va más rápido que completar: es una corrección, no un logro,
      // y no merece el mismo recorrido.
      reverseDuration: const Duration(milliseconds: 320),
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    _animacionesDesactivadas =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  }

  @override
  void didUpdateWidget(CheckCircular oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hecho && !oldWidget.hecho) {
      // Acaba de completarse: animación completa, o el estado final de golpe.
      if (_animacionesDesactivadas) {
        _controller.value = 1.0;
      } else {
        _controller.forward(from: 0);
      }
    } else if (!widget.hecho && oldWidget.hecho) {
      // Deja de estar hecho —se deshace, o cambia el día—: el trazo se retira
      // y el relleno se vacía, el mismo gesto al revés. Con "reducir
      // movimiento" se vuelve al estado vacío de golpe, como antes.
      if (_animacionesDesactivadas) {
        _controller.value = 0;
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = tokens(context);
    return Semantics(
      button: true,
      enabled: _accion != null,
      checked: widget.hecho,
      label: widget.hecho
          ? (widget.etiquetaSemanticaDeshacer ?? widget.etiquetaSemantica)
          : widget.etiquetaSemantica,
      child: GestureDetector(
        onTap: _accion,
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
                    colorAro: t.aroVacio,
                    colorBase: t.surface,
                    forma: identidad(context).forma,
                    chaflan: identidad(context).chaflan,
                  ),
                ),
              );
            },
          ),
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

  /// Si esta identidad pinta el control sin tarjeta detrás. Cuando es cierto
  /// el aro se dibuja sobre el fondo de la pantalla, así que necesita base
  /// propia, color claro y el check insinuado.
  final bool sinTarjeta;

  const _TrazoCheck({
    required this.aro,
    required this.check,
    this.glow = 0,
    this.sinTarjeta = false,
  });
}

const _checkGlass =
    _TrazoCheck(aro: 3.4, check: 0.09, glow: 5, sinTarjeta: true);
const _checkChamfer = _TrazoCheck(aro: 2.0, check: 0.10);
const _checkHairline = _TrazoCheck(aro: 1.2, check: 0.07);
const _checkPill = _TrazoCheck(aro: 3.0, check: 0.10, glow: 7);

class _CheckPainter extends CustomPainter {
  final double relleno;
  final double trazo;
  final Color color;

  /// El aro del estado vacío, que viene del token `aroVacio` de la identidad.
  /// Lo usan las cuatro: antes las tres con tarjeta pintaban `surface2` aquí y
  /// no se veía. Ver `TokensContextuales.aroVacio`.
  final Color colorAro;

  /// La base opaca, que impide que una estrella cruce el aro y lo parta. Sólo
  /// la usa la identidad sin tarjeta.
  final Color colorBase;
  final FormaIdentidad forma;
  final double chaflan;

  _CheckPainter({
    required this.relleno,
    required this.trazo,
    required this.color,
    required this.colorAro,
    required this.colorBase,
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

  /// El trazo del check dibujado hasta [progreso] (0 nada, 1 entero): dos
  /// segmentos, bajada corta y subida larga.
  Path _caminoCheck(Size size, double progreso) {
    final p1 = Offset(size.width * 0.28, size.height * 0.53);
    final p2 = Offset(size.width * 0.44, size.height * 0.68);
    final p3 = Offset(size.width * 0.73, size.height * 0.35);

    final path = Path()..moveTo(p1.dx, p1.dy);
    final primerTramo = (progreso * 2).clamp(0.0, 1.0);
    path.lineTo(
      p1.dx + (p2.dx - p1.dx) * primerTramo,
      p1.dy + (p2.dy - p1.dy) * primerTramo,
    );
    if (progreso > 0.5) {
      final segundoTramo = ((progreso - 0.5) * 2).clamp(0.0, 1.0);
      path.lineTo(
        p2.dx + (p3.dx - p2.dx) * segundoTramo,
        p2.dy + (p3.dy - p2.dy) * segundoTramo,
      );
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = _trazoDe;
    final centro = Offset(size.width / 2, size.height / 2);
    final radio = size.width / 2 - t.aro / 2;

    // Sin tarjeta detrás, el control necesita base propia: le da cuerpo para
    // que se lea como pulsable, y tapa el campo estelar, que si no cruza el
    // aro y lo parte.
    if (t.sinTarjeta) {
      canvas.drawPath(_figura(centro, radio, 1.0), Paint()..color = colorBase);
    }

    // Aro exterior (estado vacío)
    canvas.drawPath(
      _figura(centro, radio, 1.0),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = t.aro
        ..color = colorAro,
    );

    // El check insinuado: dice qué va a aparecer al pulsar, y hace que el
    // trazo animado rellene un hueco que ya estaba ahí en vez de salir de la
    // nada. Va debajo del relleno a propósito: cuando el círculo se llena, el
    // verde lo tapa solo, sin necesidad de animar su desaparición.
    if (t.sinTarjeta) {
      canvas.drawPath(
        _caminoCheck(size, 1.0),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * t.check
          ..strokeCap = StrokeCap.round
          ..color = colorAro.withValues(alpha: 0.15),
      );
    }

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

    // Check dibujándose, ahora con el camino compartido.
    if (trazo > 0) {
      canvas.drawPath(
        _caminoCheck(size, trazo),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * t.check
          ..strokeCap =
              forma == FormaIdentidad.chamfer ? StrokeCap.butt : StrokeCap.round
          ..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(_CheckPainter old) =>
      old.relleno != relleno ||
      old.trazo != trazo ||
      old.color != color ||
      old.colorAro != colorAro ||
      old.colorBase != colorBase ||
      old.forma != forma;
}