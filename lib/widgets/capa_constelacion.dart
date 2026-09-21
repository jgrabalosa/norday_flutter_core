import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/progreso_dia.dart';
import 'constelaciones.dart';

/// La constelación del día de Profundidad, en su propia capa por ENCIMA del
/// contenido.
///
/// NO se exporta en el barrel. La puerta es `CapaProgresoIdentidad`. Pinta con
/// mezcla aditiva (ver [_CapaConstelacionPainter]) y lleva [IgnorePointer]
/// dentro, imprescindible para que la capa no se coma los toques de lo que hay
/// debajo.
///
/// Tiene estado por las animaciones: al marcar un hábito, su estrella entra
/// como fugaz; al desmarcarlo, se desvanece. Sólo se anima un cambio de
/// `hechos` dentro del MISMO día y la MISMA figura. Al montarse, al cambiar de
/// día o al cambiar el número de hábitos, las estrellas aparecen quietas en
/// su sitio: la capa se vuelve a montar cada vez que se pasa por Mascota, y
/// si volaran también entonces dejarían de ser un premio.
class CapaConstelacion extends StatefulWidget {
  /// Los colores de la identidad, que los da el despachador.
  final TokensContextuales tokens;

  /// Si la capa está encima de Hoy. Con el día cerrado ([diaCerradoNotifier])
  /// y en Hoy, lo de debajo se oscurece un poco y la figura brilla más.
  final bool enHoy;

  const CapaConstelacion({
    super.key,
    required this.tokens,
    this.enHoy = false,
  });

  @override
  State<CapaConstelacion> createState() => _CapaConstelacionState();
}

class _CapaConstelacionState extends State<CapaConstelacion>
    with TickerProviderStateMixin {
  static const _duracionVuelo = Duration(milliseconds: 900);
  static const _duracionApagado = Duration(milliseconds: 400);
  static const _duracionRealce = Duration(milliseconds: 600);

  late ProgresoDia _progreso;

  /// «Reducir movimiento»: las estrellas aparecen y desaparecen sin animar.
  bool _sinMovimiento = false;

  /// Estrellas en vuelo, por índice. Un controlador terminado se queda aquí
  /// hasta que se sustituye o se cancela: a 1.0 la estrella ya está posada y
  /// se pinta igual que una encendida.
  final Map<int, AnimationController> _vuelos = {};

  /// Estrellas apagándose, por índice. Igual que [_vuelos]: a 1.0 ya no se
  /// pinta nada.
  final Map<int, AnimationController> _apagados = {};

  /// El realce del día cerrado, de 0 a 1: el velo de debajo y el brillo de
  /// más. Al montarse arranca ya en su sitio, sin fundido, igual que las
  /// estrellas: la capa se vuelve a montar al pasar por Mascota.
  late final AnimationController _realce;

  bool get _realzado => widget.enHoy && diaCerradoNotifier.value;

  @override
  void initState() {
    super.initState();
    _progreso = progresoDiaNotifier.value;
    progresoDiaNotifier.addListener(_alCambiarProgreso);
    _realce = AnimationController(
      vsync: this,
      duration: _duracionRealce,
      value: _realzado ? 1.0 : 0.0,
    );
    diaCerradoNotifier.addListener(_actualizarRealce);
  }

  @override
  void didUpdateWidget(covariant CapaConstelacion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enHoy != widget.enHoy) _actualizarRealce();
  }

  /// Lleva el realce adonde toca: con fundido, o de golpe con «reducir
  /// movimiento».
  void _actualizarRealce() {
    final objetivo = _realzado ? 1.0 : 0.0;
    if (_sinMovimiento) {
      _realce.value = objetivo;
    } else {
      _realce.animateTo(objetivo);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sinMovimiento = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  }

  @override
  void dispose() {
    progresoDiaNotifier.removeListener(_alCambiarProgreso);
    diaCerradoNotifier.removeListener(_actualizarRealce);
    _cancelarTodo();
    _realce.dispose();
    super.dispose();
  }

  void _cancelarTodo() {
    for (final c in _vuelos.values) {
      c.dispose();
    }
    for (final c in _apagados.values) {
      c.dispose();
    }
    _vuelos.clear();
    _apagados.clear();
  }

  void _alCambiarProgreso() {
    final anterior = _progreso;
    final nuevo = progresoDiaNotifier.value;
    final mismaFigura = anterior.fecha != null &&
        anterior.fecha == nuevo.fecha &&
        anterior.total == nuevo.total;

    setState(() {
      _progreso = nuevo;
      if (!mismaFigura || _sinMovimiento) {
        _cancelarTodo();
        return;
      }
      // Suben: las nuevas entran volando.
      for (var i = anterior.hechos; i < nuevo.hechos; i++) {
        _apagados.remove(i)?.dispose();
        _lanzar(_vuelos, i, _duracionVuelo);
      }
      // Bajan: las que sobran se desvanecen donde están.
      for (var i = nuevo.hechos; i < anterior.hechos; i++) {
        _vuelos.remove(i)?.dispose();
        _lanzar(_apagados, i, _duracionApagado);
      }
    });
  }

  void _lanzar(
      Map<int, AnimationController> mapa, int indice, Duration duracion) {
    mapa.remove(indice)?.dispose();
    final controlador = AnimationController(vsync: this, duration: duracion)
      ..addListener(() => setState(() {}));
    mapa[indice] = controlador;
    controlador.forward();
  }

  @override
  Widget build(BuildContext context) {
    // El realce se repinta con su propio AnimatedBuilder, sin setState:
    // puede cambiar desde didUpdateWidget.
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _realce,
        builder: (context, _) => CustomPaint(
          painter: _CapaConstelacionPainter(
            widget.tokens,
            _progreso,
            vuelos: {for (final e in _vuelos.entries) e.key: e.value.value},
            apagados: {
              for (final e in _apagados.entries) e.key: e.value.value
            },
            realce: _realce.value,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _CapaConstelacionPainter extends CustomPainter {
  /// Los tokens de la identidad equipada, pasados por el widget: el painter
  /// no lee ningún notifier global.
  final TokensContextuales tokens;

  /// Cuántos hábitos hay hoy y cuántos están hechos, para dibujar la
  /// constelación del día.
  final ProgresoDia progreso;

  /// Avance de 0 a 1 de las estrellas que están entrando, por índice.
  final Map<int, double> vuelos;

  /// Avance de 0 a 1 de las estrellas que se están apagando, por índice.
  final Map<int, double> apagados;

  /// El realce del día cerrado, de 0 a 1.
  final double realce;

  const _CapaConstelacionPainter(
    this.tokens,
    this.progreso, {
    required this.vuelos,
    required this.apagados,
    required this.realce,
  });

  /// La constelación ocupa la banda central de la pantalla, no la parte
  /// alta: la cabecera de Hoy ("Hoy" y la fecha) es el único texto que NO va
  /// sobre tarjeta opaca, y una figura brillante detrás de ella rompería el
  /// contraste. En la banda central el texto va siempre sobre tarjeta.
  @override
  void paint(Canvas canvas, Size size) {
    final figura = constelacionPara(progreso.total);
    if (figura == null) return;

    final cuadro = cuadroConstelacion(size);
    Offset situar(Offset p) => Offset(
          cuadro.left + p.dx * cuadro.width,
          cuadro.top + p.dy * cuadro.height,
        );

    final encendidas = progreso.hechos.clamp(0, figura.puntos.length);

    // Cuánta luz tiene cada estrella ahora mismo, de 0 a 1. Una estrella en
    // vuelo todavía no ha llegado: cuenta como apagada hasta posarse, así que
    // sus trazos aparecen al llegar. Una que se está apagando conserva la luz
    // que le queda, y sus trazos se desvanecen con ella.
    double luz(int i) {
      if (i < encendidas) {
        final vuelo = vuelos[i];
        return vuelo == null || vuelo >= 1.0 ? 1.0 : 0.0;
      }
      final apagado = apagados[i];
      return apagado == null ? 0.0 : 1.0 - Curves.easeOut.transform(apagado);
    }

    // El día cerrado, en Hoy: un velo que apaga un poco lo de debajo para
    // que la figura terminada destaque. Va fuera de la capa aditiva porque
    // tiene que oscurecer, y la mezcla aditiva sólo sabe sumar luz.
    if (realce > 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = Colors.black.withValues(alpha: 0.25 * realce),
      );
    }

    // Toda la constelación va dentro de una capa aditiva: la capa va
    // DELANTE del contenido, así que no hay superficie que atenúe la luz
    // como pasaba detrás. La luz se suma a lo que hay debajo en vez de
    // sustituirlo — una estrella sobre texto blanco lo vuelve más blanco,
    // nunca lo borra — y es además lo que hace la luz de verdad.
    canvas.saveLayer(Offset.zero & size, Paint()..blendMode = BlendMode.plus);

    for (final (a, b) in figura.segmentos) {
      final pa = situar(figura.puntos[a]);
      final pb = situar(figura.puntos[b]);
      final luzA = luz(a);
      final luzB = luz(b);

      if (luzA > 0 && luzB > 0) {
        canvas.drawLine(
          pa,
          pb,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..color = tokens.streak.withValues(
                alpha: (0.38 + 0.22 * realce) * math.min(luzA, luzB)),
        );
      } else if (luzA > 0 || luzB > 0) {
        // Un trazo con un solo extremo encendido no desaparece: sale de la
        // estrella que ya está y se apaga antes de llegar a la que falta.
        //
        // Sin esto la figura a medias no se lee. El caso peor era la Cruz del
        // Sur con 3 de 4: sus dos segmentos no comparten ningún punto, así
        // que salía la barra vertical y una estrella suelta al lado, que no
        // parece media cruz sino una errata. El cabo le da su medio brazo y
        // la cruz se reconoce. Vale para las ocho figuras, no sólo para ésa.
        //
        // El punto apagado ya se dibuja tenue más abajo, así que el cabo no
        // apunta al vacío: va hacia una estrella que se ve.
        final desde = luzA > 0 ? pa : pb;
        final hacia = luzA > 0 ? pb : pa;
        final luzCabo = math.max(luzA, luzB);
        canvas.drawLine(
          desde,
          hacia,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..strokeCap = StrokeCap.round
            ..shader = ui.Gradient.linear(
              desde,
              hacia,
              [
                tokens.streak.withValues(alpha: 0.22 * luzCabo),
                tokens.streak.withValues(alpha: 0.0),
              ],
              [0.0, 0.55],
            ),
        );
      }
    }

    final apagada = Paint()..color = tokens.text.withValues(alpha: 0.16);

    for (var i = 0; i < figura.puntos.length; i++) {
      final centro = situar(figura.puntos[i]);
      final vuelo = i < encendidas ? vuelos[i] : null;
      if (i < encendidas && (vuelo == null || vuelo >= 1.0)) {
        _pintarEstrella(canvas, centro, 1.0, 1.0);
      } else {
        // El punto apagado. Durante un vuelo marca el sitio adonde va la
        // estrella; durante un apagado, el sitio donde se queda.
        canvas.drawCircle(centro, 1.6, apagada);
        if (vuelo != null) {
          _pintarVuelo(canvas, size, centro, vuelo);
        } else {
          final luzQueQueda = luz(i);
          if (luzQueQueda > 0) {
            _pintarEstrella(canvas, centro, 1.0, luzQueQueda);
          }
        }
      }
    }

    canvas.restore();
  }

  /// Una estrella encendida en [centro], a [escala] de su tamaño y con
  /// [opacidad] de su luz.
  void _pintarEstrella(
      Canvas canvas, Offset centro, double escala, double opacidad) {
    // El resplandor: un degradado radial que cae a cero, no un círculo
    // plano. El disco duro se recorta contra lo que hay debajo; el
    // degradado se funde con él.
    // Con el día cerrado el halo crece un 30 % y gana intensidad.
    final radioHalo = 17.0 * escala * (1 + 0.3 * realce);
    final intensidad = opacidad * (1 + 0.5 * realce);
    final resplandor = Paint()
      ..shader = RadialGradient(
        colors: [
          tokens.streak.withValues(alpha: 0.34 * intensidad),
          tokens.streak.withValues(alpha: 0.12 * intensidad),
          tokens.streak.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.35, 1.0],
      ).createShader(Rect.fromCircle(center: centro, radius: radioHalo));
    canvas.drawCircle(centro, radioHalo, resplandor);

    // Dos puntas diagonales, cortas y tenues, detrás del destello: le dan
    // brillo de estrella sin competir con las cuatro puntas grandes.
    canvas.drawPath(
      _puntasDiagonales(centro, 5.0 * escala, 1.0 * escala),
      Paint()..color = tokens.streak.withValues(alpha: 0.35 * opacidad),
    );

    // El destello de cuatro puntas, con los lados curvados hacia dentro.
    // Primero el borde ámbar, algo mayor, y encima el cuerpo casi blanco.
    // Es lo que separa la constelación del cielo de fondo, cuyas estrellas
    // más grandes miden 1.7.
    canvas.drawPath(
      _destello(centro, 9.5 * escala),
      Paint()..color = tokens.streak.withValues(alpha: 0.55 * opacidad),
    );
    canvas.drawPath(
      _destello(centro, 7.0 * escala),
      Paint()..color = tokens.text.withValues(alpha: 0.95 * opacidad),
    );

    // El núcleo: una estrella real tiene el centro quemado y el color en el
    // halo, no al revés.
    canvas.drawCircle(
      centro,
      2.0 * escala,
      Paint()..color = tokens.text.withValues(alpha: opacidad),
    );
  }

  /// Una estrella que entra como fugaz, con avance [t] de 0 a 1.
  ///
  /// Sale de fuera de la pantalla por la izquierda, más arriba que su sitio,
  /// y baja en un arco que se abomba un poco hacia arriba: una fugaz de
  /// verdad cae, y a su misma altura parecería un disparo. Frena al llegar
  /// (`easeOutCubic`), crece del 80 % a su tamaño y la estela se recoge.
  void _pintarVuelo(Canvas canvas, Size size, Offset llegada, double t) {
    final salida = Offset(-30, llegada.dy - size.height * 0.34);
    final recta = llegada - salida;
    final largo = recta.distance;
    if (largo == 0) return;
    var normal = Offset(recta.dy, -recta.dx) / largo;
    if (normal.dy > 0) normal = -normal;
    final control = (salida + llegada) / 2 + normal * (largo * 0.18);

    Offset punto(double s) {
      final u = 1 - s;
      return salida * (u * u) + control * (2 * u * s) + llegada * (s * s);
    }

    final avance = Curves.easeOutCubic.transform(t);

    // La estela: un trazo ámbar que se afila y se apaga hacia atrás, y se
    // encoge hasta desaparecer cuando la estrella se posa.
    final estela = 0.22 * (1 - t);
    const tramos = 24;
    for (var k = 0; k < tramos; k++) {
      final s0 = math.max(0.0, avance - estela * k / tramos);
      final s1 = math.max(0.0, avance - estela * (k + 1) / tramos);
      final resto = 1 - k / tramos;
      canvas.drawLine(
        punto(s0),
        punto(s1),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 0.3 + 2.1 * resto
          ..color = tokens.streak.withValues(alpha: 0.8 * resto),
      );
    }

    _pintarEstrella(canvas, punto(avance), 0.8 + 0.2 * avance, 1.0);
  }

  /// Una astroide de radio [r] centrada en [c]: x = r·cos³t, y = r·sin³t.
  /// Cuatro puntas con los lados curvados hacia dentro, que es la silueta
  /// que el ojo lee como destello.
  static Path _destello(Offset c, double r) {
    const pasos = 64;
    final path = Path();
    for (var k = 0; k <= pasos; k++) {
      final t = 2 * math.pi * k / pasos;
      final cs = math.cos(t);
      final sn = math.sin(t);
      final x = c.dx + r * cs * cs * cs;
      final y = c.dy + r * sn * sn * sn;
      if (k == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    return path..close();
  }

  /// Cuatro triángulos finos a 45°, de [largo] desde el centro y [ancho] en
  /// la base.
  static Path _puntasDiagonales(Offset c, double largo, double ancho) {
    final path = Path();
    for (var k = 0; k < 4; k++) {
      final a = math.pi / 4 + k * math.pi / 2;
      final dx = math.cos(a);
      final dy = math.sin(a);
      final px = -dy * ancho / 2;
      final py = dx * ancho / 2;
      path
        ..moveTo(c.dx + px, c.dy + py)
        ..lineTo(c.dx + dx * largo, c.dy + dy * largo)
        ..lineTo(c.dx - px, c.dy - py)
        ..close();
    }
    return path;
  }

  // `TokensContextuales` no define `operator ==`, así que comparar el
  // objeto entero compara referencias, no valores: funciona hoy sólo porque
  // las cuatro paletas son `const` y Dart las canoniza. `ProgresoDia` sí
  // define `operator ==`, así que ese campo se compara por valor, y los
  // mapas de animación entrada a entrada.
  @override
  bool shouldRepaint(covariant _CapaConstelacionPainter oldDelegate) =>
      oldDelegate.tokens.primary != tokens.primary ||
      oldDelegate.tokens.streak != tokens.streak ||
      oldDelegate.progreso != progreso ||
      oldDelegate.realce != realce ||
      !_mismosAvances(oldDelegate.vuelos, vuelos) ||
      !_mismosAvances(oldDelegate.apagados, apagados);

  static bool _mismosAvances(Map<int, double> a, Map<int, double> b) {
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      if (b[e.key] != e.value) return false;
    }
    return true;
  }
}

/// El cuadrado donde se dibuja la figura, dentro de una capa de [size].
///
/// Conserva la proporción de la figura: sin esto la Cruz del Sur se estira a
/// lo ancho en una pantalla de móvil y deja de ser una cruz. Es público
/// dentro del core porque la ceremonia del cierre del día coloca sus textos
/// por encima y por debajo de este mismo cuadrado.
Rect cuadroConstelacion(Size size) {
  final destino = Rect.fromLTWH(
    size.width * 0.14,
    size.height * 0.30,
    size.width * 0.72,
    size.height * 0.44,
  );
  final lado = destino.width < destino.height ? destino.width : destino.height;
  return Rect.fromCenter(center: destino.center, width: lado, height: lado);
}
