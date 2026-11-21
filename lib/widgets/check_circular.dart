import 'dart:math' show pi;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/identidad_paleta.dart';
import '../theme/identidades_paleta.dart';
import 'check_vivo.dart';
import 'lapiz.dart';

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
  /// Interruptor de «el check vivo» (T-018, experimento): si está a `true`,
  /// los checks sin hacer y tocables reciben por turnos una vuelta por el aro
  /// (ver `check_vivo.dart`). A `false`, el check se pinta y se comporta
  /// exactamente como antes del experimento. No es un ajuste del usuario: se
  /// cambia aquí o, en los tests, antes de montar.
  static bool vivo = true;

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
    with TickerProviderStateMixin
    implements ParticipanteCheckVivo {
  late final AnimationController _controller;

  /// La vuelta de «el check vivo»: 0-1 en [duracionVueltaCheck]. Parada, no
  /// pinta nada.
  late final AnimationController _vuelta;
  bool _registrado = false;
  late final Animation<double> _relleno; // 0-1: el círculo se llena
  late final Animation<double> _pop; // escala con rebote
  late final Animation<double> _trazo; // 0-1: el check se dibuja

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
    _vuelta = AnimationController(vsync: this, duration: duracionVueltaCheck);
    _relleno = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
    );
    _pop =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.18), weight: 40),
          TweenSequenceItem(
            tween: Tween(
              begin: 1.18,
              end: 1.0,
            ).chain(CurveTween(curve: Curves.elasticOut)),
            weight: 60,
          ),
        ]).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.15, 0.75),
          ),
        );
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
    _sincronizarVivo();
  }

  /// Si este check merece turno: sin hacer, tocable, con el movimiento
  /// permitido y el experimento encendido. Apunta o da de baja en el
  /// coordinador según toque, y corta la vuelta si deja de merecerlo.
  void _sincronizarVivo() {
    final merece =
        CheckCircular.vivo &&
        !widget.hecho &&
        widget.onTap != null &&
        !_animacionesDesactivadas;
    if (merece && !_registrado) {
      _registrado = true;
      CoordinadorCheckVivo.registrar(this);
    } else if (!merece) {
      if (_registrado) {
        _registrado = false;
        CoordinadorCheckVivo.baja(this);
      }
      _cortarVuelta();
    }
  }

  void _cortarVuelta() {
    if (_vuelta.isAnimating || _vuelta.value != 0) _vuelta.value = 0;
  }

  @override
  Offset? get posicionGlobal {
    final caja = context.findRenderObject();
    if (caja is! RenderBox || !caja.attached || !caja.hasSize) return null;
    return caja.localToGlobal(Offset.zero);
  }

  @override
  void darVuelta() {
    if (mounted) _vuelta.forward(from: 0);
  }

  void _alTocar() {
    _cortarVuelta();
    _accion?.call();
  }

  @override
  void didUpdateWidget(CheckCircular oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sincronizarVivo();
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
    if (_registrado) CoordinadorCheckVivo.baja(this);
    _vuelta.dispose();
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
        onTap: _accion == null ? null : _alTocar,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          // Amplía el área táctil sin agrandar el dibujo
          padding: const EdgeInsets.all(6),
          child: AnimatedBuilder(
            animation: Listenable.merge([_controller, _vuelta]),
            builder: (context, _) {
              return Transform.scale(
                scale: _pop.value,
                child: CustomPaint(
                  size: Size.square(widget.tamano),
                  foregroundPainter: _vuelta.isAnimating
                      ? _VueltaPainter(
                          progreso: _vuelta.value,
                          color: t.streak,
                          colorLapiz: t.text,
                          forma: identidad(context).forma,
                          chaflan: identidad(context).chaflan,
                        )
                      : null,
                  painter: _CheckPainter(
                    relleno: _relleno.value,
                    trazo: _trazo.value,
                    color: widget.color,
                    colorAro: t.aroCheck,
                    colorBase: t.surface,
                    // En Dulce el check va en el color del texto, no en blanco.
                    colorCheck: identidad(context).forma == FormaIdentidad.pill
                        ? t.text
                        : Colors.white,
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

  /// Si pinta una base opaca detrás del aro, en `colorBase`. El aro se dibuja
  /// sobre el fondo de la pantalla cuando no hay tarjeta opaca debajo; la base
  /// le da contraste y tapa lo que cruce por detrás (una estrella, una ventana
  /// encendida).
  final bool base;

  /// Si pinta el check insinuado: el check al 0.15 de `colorAro`. Dice qué va a
  /// aparecer al pulsar, y hace que el trazo animado rellene un hueco que ya
  /// estaba ahí en vez de salir de la nada.
  final bool insinuado;

  const _TrazoCheck({
    required this.aro,
    required this.check,
    this.glow = 0,
    this.base = false,
    this.insinuado = false,
  });
}

const _checkGlass = _TrazoCheck(
  aro: 3.4,
  check: 0.09,
  glow: 5,
  base: true,
  insinuado: true,
);
const _checkChamfer = _TrazoCheck(aro: 2.0, check: 0.10, base: true);
const _checkPill = _TrazoCheck(aro: 3.0, check: 0.10);

/// La figura del check en [forma], inscrita en un cuadrado de lado
/// `radio * 2` centrado en [centro]; [escala] la encoge desde el centro. Con
/// [desdeArriba] el contorno empieza en el centro del lado de arriba y va en
/// el sentido de las agujas del reloj (lo que necesita la vuelta).
Path _figuraDe(
  FormaIdentidad forma,
  double chaflan,
  Offset centro,
  double radio,
  double escala, {
  bool desdeArriba = false,
}) {
  final r = radio * escala;
  if (forma != FormaIdentidad.chamfer) {
    final rect = Rect.fromCircle(center: centro, radius: r);
    // `addOval` empieza a las 3; el arco, donde se le diga (arriba = -90°).
    return desdeArriba
        ? (Path()..addArc(rect, -pi / 2, 2 * pi))
        : (Path()..addOval(rect));
  }
  // Cuadrado con las cuatro esquinas cortadas, el mismo chaflán que la
  // identidad usa en tarjetas, chips y burbujas.
  final c = (chaflan * escala).clamp(0.0, r);
  final path = Path();
  if (desdeArriba) {
    path
      ..moveTo(centro.dx, centro.dy - r)
      ..lineTo(centro.dx + r - c, centro.dy - r);
  } else {
    path
      ..moveTo(centro.dx - r + c, centro.dy - r)
      ..lineTo(centro.dx + r - c, centro.dy - r);
  }
  path
    ..lineTo(centro.dx + r, centro.dy - r + c)
    ..lineTo(centro.dx + r, centro.dy + r - c)
    ..lineTo(centro.dx + r - c, centro.dy + r)
    ..lineTo(centro.dx - r + c, centro.dy + r)
    ..lineTo(centro.dx - r, centro.dy + r - c)
    ..lineTo(centro.dx - r, centro.dy - r + c);
  if (desdeArriba) path.lineTo(centro.dx - r + c, centro.dy - r);
  return path..close();
}

/// El pintado de la vuelta de «el check vivo». El dibujo de cada identidad
/// está en el `switch` de [paint]: [color] es el `streak` (Profundidad y
/// Neotokyo+) y [colorLapiz] el `text` (Dulce).
class _VueltaPainter extends CustomPainter {
  final double progreso;
  final Color color;
  final Color colorLapiz;
  final FormaIdentidad forma;
  final double chaflan;

  _VueltaPainter({
    required this.progreso,
    required this.color,
    required this.colorLapiz,
    required this.forma,
    required this.chaflan,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final aro = switch (forma) {
      FormaIdentidad.glass => _checkGlass,
      FormaIdentidad.chamfer => _checkChamfer,
      FormaIdentidad.pill => _checkPill,
    }.aro;
    // El mismo radio que el aro: la vuelta no sale del área del check.
    final figura = _figuraDe(
      forma,
      chaflan,
      Offset(size.width / 2, size.height / 2),
      size.width / 2 - aro / 2,
      1.0,
      desdeArriba: true,
    );
    switch (forma) {
      case FormaIdentidad.glass:
        pintarVueltaProfundidad(
          canvas,
          figura,
          progreso,
          color: color,
          grosor: aro,
        );
      case FormaIdentidad.chamfer:
        pintarVueltaNeotokyo(
          canvas,
          figura,
          progreso,
          color: color,
          grosor: aro,
        );
      case FormaIdentidad.pill:
        pintarVueltaDulce(
          canvas,
          figura,
          progreso,
          color: colorLapiz,
          grosor: aro,
          semilla: semillaDe(size) + 29,
        );
    }
  }

  @override
  bool shouldRepaint(_VueltaPainter old) =>
      old.progreso != progreso ||
      old.color != color ||
      old.colorLapiz != colorLapiz ||
      old.forma != forma ||
      old.chaflan != chaflan;
}

class _CheckPainter extends CustomPainter {
  final double relleno;
  final double trazo;
  final Color color;

  /// El aro del estado vacío, que viene del token `aroCheck` de la identidad
  /// (que sin declarar vale su `aroVacio`). Ver `TokensContextuales.aroCheck`.
  final Color colorAro;

  /// La base opaca, que impide que una estrella cruce el aro y lo parta. La
  /// pintan las identidades con `_TrazoCheck.base`.
  final Color colorBase;

  /// El color del check dibujándose. En Dulce es el del texto, para que se lea
  /// sobre el relleno a rayas; en las demás, blanco.
  final Color colorCheck;
  final FormaIdentidad forma;
  final double chaflan;

  _CheckPainter({
    required this.relleno,
    required this.trazo,
    required this.color,
    required this.colorAro,
    required this.colorBase,
    required this.colorCheck,
    required this.forma,
    required this.chaflan,
  });

  _TrazoCheck get _trazoDe => switch (forma) {
    FormaIdentidad.glass => _checkGlass,
    FormaIdentidad.chamfer => _checkChamfer,
    FormaIdentidad.pill => _checkPill,
  };

  /// La figura del check en esta identidad, inscrita en un cuadrado de lado
  /// `radio * 2` centrado en [centro]. [escala] la encoge desde el centro, que
  /// es como crece el relleno.
  Path _figura(Offset centro, double radio, double escala) =>
      _figuraDe(forma, chaflan, centro, radio, escala);

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
    // Dulce, en reposo (sin animar el relleno ni el trazo), se graba una vez.
    // Durante la animación no: cada fotograma sería una grabación nueva.
    final enReposo =
        (relleno == 0 || relleno == 1) && (trazo == 0 || trazo == 1);
    if (forma == FormaIdentidad.pill && enReposo) {
      final tamano = Size(
        size.width.roundToDouble(),
        size.height.roundToDouble(),
      );
      pintarConCache(
        canvas,
        (relleno, trazo, color, colorAro, colorBase, colorCheck),
        tamano,
        (c) => _pintar(c, tamano),
        desborde: 4,
      );
      return;
    }
    _pintar(canvas, size);
  }

  void _pintar(Canvas canvas, Size size) {
    final t = _trazoDe;
    final centro = Offset(size.width / 2, size.height / 2);
    final radio = size.width / 2 - t.aro / 2;

    // Sin tarjeta opaca detrás, el control necesita base propia: le da cuerpo
    // para que se lea como pulsable, y tapa el campo estelar o la ciudad, que
    // si no cruzan el aro y lo parten.
    if (t.base) {
      canvas.drawPath(_figura(centro, radio, 1.0), Paint()..color = colorBase);
    }

    // Aro exterior (estado vacío). En Dulce, a lápiz y algo más grueso: tiene
    // que pasar 3:1 sobre la tarjeta, y `aroVacio` da 3.76 con él.
    final figura = _figura(centro, radio, 1.0);
    if (forma == FormaIdentidad.pill) {
      pintarTrazoLapiz(
        canvas,
        figura,
        color: colorAro,
        grosor: 2.2,
        semilla: semillaDe(size),
      );
    } else {
      // Solo en Profundidad el aro se funde con el relleno: el trazo asoma
      // medio grosor por fuera del relleno y, en amarillo, quedaría un borde
      // alrededor del verde. Pasa al color del relleno a la vez que éste
      // crece (y vuelve al deshacer), así que hecho acaba en `color`.
      final colorDelAro = forma == FormaIdentidad.glass
          ? Color.lerp(colorAro, color, relleno)!
          : colorAro;
      canvas.drawPath(
        figura,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = t.aro
          ..color = colorDelAro,
      );
    }

    // El check insinuado (sólo Profundidad). Va debajo del relleno a
    // propósito: cuando el círculo se llena, el verde lo tapa solo, sin
    // necesidad de animar su desaparición.
    if (t.insinuado) {
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
      if (forma == FormaIdentidad.pill) {
        // Dulce: el relleno es sombreado a rayas cruzadas, y encima el contorno
        // a lápiz. Sin glow: no hay resplandor en Dulce.
        final semilla = semillaDe(size);
        pintarSombreado(
          canvas,
          dentro,
          color: color,
          separacion: 1.6,
          alfa: 0.95,
          cruzado: true,
          semilla: semilla,
        );
        pintarTrazoLapiz(
          canvas,
          dentro,
          color: color,
          grosor: 1.8,
          semilla: semilla + 13,
        );
      } else {
        // El glow va debajo del relleno y sólo en las identidades que lo piden.
        // Es estático dentro de cada fotograma del pop, no una sombra animada.
        if (t.glow > 0) {
          canvas.drawPath(
            dentro,
            Paint()
              ..color = color.withValues(alpha: 0.55)
              ..maskFilter = MaskFilter.blur(
                BlurStyle.normal,
                t.glow * relleno,
              ),
          );
        }
        canvas.drawPath(dentro, Paint()..color = color);
      }
    }

    // Check dibujándose, ahora con el camino compartido.
    if (trazo > 0) {
      canvas.drawPath(
        _caminoCheck(size, trazo),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * t.check
          ..strokeCap = forma == FormaIdentidad.chamfer
              ? StrokeCap.butt
              : StrokeCap.round
          ..color = colorCheck,
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
      old.colorCheck != colorCheck ||
      old.forma != forma;
}
