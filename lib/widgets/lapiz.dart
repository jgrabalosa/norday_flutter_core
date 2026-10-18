import 'dart:collection';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// El trazo a lápiz de color: el lenguaje de Dulce, que parece dibujada en un
/// bloc de papel.
///
/// Un trazo de lápiz no es una línea perfecta. El contorno se muestrea y cada
/// punto se desplaza en perpendicular con una onda lenta: tiembla un poco. El
/// trazo se hace en tres pasadas (firme, repaso y una tercera tenue y parcial),
/// con presión —más grueso en el centro del recorrido, fino en las puntas— y
/// grano: de vez en cuando un tramo sale más claro, como el papel que deja
/// huecos. En un contorno cerrado, las dos primeras pasadas se pasan del inicio.
///
/// El sombreado va a rayas desiguales, de bordes deshilachados. Puede tener una
/// intensidad por punto: se desvanece donde la intensidad baja y se cruza solo
/// donde es más oscuro.
///
/// Todo es DETERMINISTA: sale de una semilla, nunca de un `Random()` sin semilla
/// ni de la hora. El mismo dibujo sale igual en cada fotograma y no baila. Cada
/// pieza tiene su propia semilla, que sólo cambia cuando cambia su tamaño
/// ([semillaDe]).
///
/// Lo que es mucho dibujo —el borde, la sombra, el check— se graba una vez en
/// una caché ([pintarConCache]) y después sólo se reproduce.

/// Interruptor de la caché de dibujos. Solo para los tests que miran las
/// llamadas de dibujo: dentro de un `Picture` no se ven.
@visibleForTesting
bool usarCacheLapiz = true;

/// Límite de la caché de imágenes, en píxeles: unos 48 MB en RGBA.
const int _limitePixeles = 12000000;

/// Una imagen grabada, con su tamaño en píxeles.
class _Entrada {
  _Entrada(this.imagen, this.pixeles);

  final ui.Image imagen;
  final int pixeles;
}

final LinkedHashMap<Object, _Entrada> _cache = LinkedHashMap();
int _pixeles = 0;
int _grabaciones = 0;

/// Cuántas imágenes se han grabado desde la última [vaciarCacheLapiz].
@visibleForTesting
int get grabacionesLapiz => _grabaciones;

/// Cuántos píxeles ocupa la caché ahora.
@visibleForTesting
int get pixelesCacheLapiz => _pixeles;

/// Cuántas imágenes hay en la caché ahora.
@visibleForTesting
int get entradasCacheLapiz => _cache.length;

/// El límite de la caché, en píxeles.
@visibleForTesting
int get limitePixelesCacheLapiz => _limitePixeles;

/// Vacía la caché y pone a cero los contadores.
@visibleForTesting
void vaciarCacheLapiz() {
  for (final entrada in _cache.values) {
    entrada.imagen.dispose();
  }
  _cache.clear();
  _pixeles = 0;
  _grabaciones = 0;
}

/// La densidad de píxeles de la pantalla: la imagen se graba a esa resolución.
double _densidad() {
  final vistas = ui.PlatformDispatcher.instance.views;
  return vistas.isEmpty ? 1.0 : vistas.first.devicePixelRatio;
}

/// Graba una vez, como imagen a la densidad de la pantalla, lo que dibuja
/// [dibujo] en una caja de [tamano], y después solo la reproduce.
///
/// [desborde] deja margen por cada lado para lo que se sale de la caja (el
/// filo, la sombra). La caché es LRU por píxeles: al pasar de
/// [_limitePixeles], salen primero las grabaciones más antiguas.
void pintarConCache(
  Canvas canvas,
  Object clave,
  Size tamano,
  void Function(Canvas c) dibujo, {
  double desborde = 0,
}) {
  if (!usarCacheLapiz) {
    dibujo(canvas);
    return;
  }
  final densidad = _densidad();
  final completa = (clave, densidad, tamano.width, tamano.height, desborde);
  var entrada = _cache.remove(completa);
  if (entrada == null) {
    final ancho = ((tamano.width + 2 * desborde) * densidad).ceil();
    final alto = ((tamano.height + 2 * desborde) * densidad).ceil();
    final grabadora = ui.PictureRecorder();
    final lienzo = Canvas(grabadora);
    lienzo.scale(densidad);
    lienzo.translate(desborde, desborde);
    dibujo(lienzo);
    final grabado = grabadora.endRecording();
    final imagen = grabado.toImageSync(ancho, alto);
    grabado.dispose();
    _grabaciones++;
    entrada = _Entrada(imagen, ancho * alto);
    _pixeles += entrada.pixeles;
  }
  _cache[completa] = entrada;
  while (_pixeles > _limitePixeles && _cache.length > 1) {
    final vieja = _cache.remove(_cache.keys.first)!;
    _pixeles -= vieja.pixeles;
    vieja.imagen.dispose();
  }
  canvas.drawImageRect(
    entrada.imagen,
    Rect.fromLTWH(
      0,
      0,
      entrada.imagen.width.toDouble(),
      entrada.imagen.height.toDouble(),
    ),
    Rect.fromLTWH(
      -desborde,
      -desborde,
      tamano.width + 2 * desborde,
      tamano.height + 2 * desborde,
    ),
    Paint()..filterQuality = ui.FilterQuality.medium,
  );
}

/// Un punto del contorno: dónde está, hacia dónde se desplaza el temblor (la
/// normal) y cuánto camino lleva recorrido desde el inicio.
class _Muestra {
  const _Muestra(this.p, this.n, this.s);

  final Offset p;
  final Offset n;
  final double s;
}

/// Muestrea el contorno de [m] cada [paso] px. Un contorno cerrado no repite
/// el punto final; uno abierto sí lo incluye.
List<_Muestra> _muestrear(ui.PathMetric m, double paso) {
  final cuenta = max(2, (m.length / paso).round());
  final total = m.isClosed ? cuenta : cuenta + 1;
  final salto = m.length / cuenta;
  final muestras = <_Muestra>[];
  for (var i = 0; i < total; i++) {
    final d = i * salto;
    final tangente = m.getTangentForOffset(d)!;
    muestras.add(
      _Muestra(
        tangente.position,
        Offset(-tangente.vector.dy, tangente.vector.dx),
        d,
      ),
    );
  }
  return muestras;
}

/// Una pasada del trazo: cuánto tiembla, cuánto pesa, de dónde sale y cuántos
/// tramos recorre.
class _Pasada {
  const _Pasada({
    required this.semilla,
    required this.amplitud,
    required this.grosor,
    required this.alfa,
    required this.desplazo,
    required this.k0,
    required this.cuenta,
    required this.puntas,
  });

  final int semilla;
  final double amplitud;
  final double grosor;
  final double alfa;
  final Offset desplazo;

  /// Índice de la muestra donde empieza la pasada.
  final int k0;

  /// Cuántos tramos recorre.
  final int cuenta;

  /// Si las puntas se afinan (contorno abierto).
  final bool puntas;
}

/// Dibuja una pasada de trazo sobre las muestras [ms] de un contorno de
/// longitud [longitud], como una sucesión de tramos cortos con presión.
void _pasada(
  Canvas canvas,
  List<_Muestra> ms,
  double longitud,
  _Pasada p,
  Color color,
) {
  final n = ms.length;
  final azar = Random(p.semilla);
  final f1 = 0.05 + azar.nextDouble() * 0.05;
  final f2 = 0.11 + azar.nextDouble() * 0.08;
  final fase1 = azar.nextDouble() * 2 * pi;
  final fase2 = azar.nextDouble() * 2 * pi;
  final fasePresion = azar.nextDouble() * 2 * pi;

  // Un contorno cerrado da la vuelta: el índice sigue contando y la distancia
  // recorrida se suma una longitud por vuelta, para que la onda no salte.
  Offset punto(int i) {
    final m = ms[i % n];
    final s = m.s + (i ~/ n) * longitud;
    final onda =
        p.amplitud * (0.6 * sin(s * f1 + fase1) + 0.4 * sin(s * f2 + fase2));
    return m.p + m.n * onda + p.desplazo;
  }

  final cuenta = p.cuenta;
  for (var j = 0; j < cuenta; j++) {
    final t = j / cuenta;
    var presion =
        (0.55 + 0.45 * sin(pi * t)) *
        (0.82 + 0.18 * (0.5 + 0.5 * sin(2 * pi * 1.3 * t + fasePresion)));
    presion = presion.clamp(0.2, 1.0);
    var ancho = p.grosor * presion;
    var alfaTramo = p.alfa * (0.75 + 0.25 * presion);
    if (p.puntas) {
      final f = min(1.0, min(t / 0.08, (1 - t) / 0.08));
      ancho *= 0.3 + 0.7 * f;
    }
    // Grano: de vez en cuando el tramo sale más claro, como un hueco del papel.
    if (azar.nextDouble() < 0.18) {
      alfaTramo *= 0.25 + 0.35 * azar.nextDouble();
    }
    final a = p.k0 + j;
    canvas.drawLine(
      punto(a),
      punto(a + 1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = ancho
        ..color = color.withValues(alpha: alfaTramo.clamp(0.0, 1.0)),
    );
  }
}

/// El contorno [original] con el temblor de un lápiz. Cada [paso] píxeles se
/// toma un punto y se desplaza en perpendicular a la tangente, con una onda de
/// dos senos que nunca se aparta más de [amplitud].
Path caminoTembloroso(
  Path original, {
  required int semilla,
  double amplitud = 0.7,
  double paso = 4,
}) {
  final azar = Random(semilla);
  final f1 = 0.05 + azar.nextDouble() * 0.05;
  final f2 = 0.11 + azar.nextDouble() * 0.08;
  final fase1 = azar.nextDouble() * 2 * pi;
  final fase2 = azar.nextDouble() * 2 * pi;

  final camino = Path();
  var recorrido = 0.0;
  var primero = true;
  for (final metrica in original.computeMetrics()) {
    if (metrica.length == 0) continue;
    for (var d = 0.0; ; d += paso) {
      final distancia = min(d, metrica.length);
      final tangente = metrica.getTangentForOffset(distancia)!;
      final s = recorrido + distancia;
      final normal = Offset(-tangente.vector.dy, tangente.vector.dx);
      final onda =
          amplitud * (0.6 * sin(s * f1 + fase1) + 0.4 * sin(s * f2 + fase2));
      final punto = tangente.position + normal * onda;
      if (primero) {
        camino.moveTo(punto.dx, punto.dy);
        primero = false;
      } else {
        camino.lineTo(punto.dx, punto.dy);
      }
      if (distancia >= metrica.length) break;
    }
    recorrido += metrica.length;
  }
  return camino;
}

/// Un trazo a lápiz de [grosor] y [color] sobre [camino], un solo contorno.
///
/// Tres pasadas: la firme (casi opaca), el repaso (más fino, desplazado) y una
/// tercera tenue que cubre solo un tramo. Un contorno cerrado se pasa del inicio
/// la firme y el repaso; uno abierto afina las puntas.
void pintarTrazoLapiz(
  Canvas canvas,
  Path camino, {
  required Color color,
  required double grosor,
  required int semilla,
}) {
  final metricas = camino.computeMetrics().toList();
  if (metricas.isEmpty || metricas.first.length == 0) return;
  final metrica = metricas.first;
  final cerrado = metrica.isClosed;
  final longitud = metrica.length;
  final ms = _muestrear(metrica, 1.5);
  final n = ms.length;

  final azar = Random(semilla);
  final inicio = cerrado ? azar.nextInt(n) : 0;
  final cuentaFirme = cerrado ? (n * 1.06).round() : n - 1;
  final cuentaTercera = (n * 0.35).round();
  final inicioTercera = cerrado
      ? (inicio + n ~/ 3) % n
      : azar.nextInt(max(1, n - 1 - cuentaTercera));

  _pasada(
    canvas,
    ms,
    longitud,
    _Pasada(
      semilla: semilla,
      amplitud: 0.6,
      grosor: grosor,
      alfa: 0.92,
      desplazo: Offset.zero,
      k0: inicio,
      cuenta: cuentaFirme,
      puntas: !cerrado,
    ),
    color,
  );
  _pasada(
    canvas,
    ms,
    longitud,
    _Pasada(
      semilla: semilla + 1,
      amplitud: 1.3,
      grosor: grosor * 0.55,
      alfa: 0.5,
      desplazo: const Offset(0.6, 0.5),
      k0: inicio,
      cuenta: cuentaFirme,
      puntas: !cerrado,
    ),
    color,
  );
  _pasada(
    canvas,
    ms,
    longitud,
    _Pasada(
      semilla: semilla + 2,
      amplitud: 1.6,
      grosor: grosor * 0.4,
      alfa: 0.35,
      desplazo: const Offset(-0.4, 0.3),
      k0: inicioTercera,
      cuenta: cuentaTercera,
      puntas: !cerrado,
    ),
    color,
  );
}

/// Una capa de rayas paralelas dentro de [zona]. Cada raya tiene su separación,
/// su ángulo y sus extremos al azar; se pinta solo donde [intensidad] pasa de
/// [minimo].
void _capaRayas(
  Canvas canvas,
  Path zona,
  Color color,
  double Function(Offset punto) intensidad, {
  required double angulo,
  required double separacion,
  required double grosor,
  required double alfa,
  required double minimo,
  required int semilla,
  bool Function(Offset punto)? dentro,
}) {
  final azar = Random(semilla);
  final caja = zona.getBounds();
  final centro = caja.center;
  // Media diagonal: así las rayas cubren la caja a cualquier ángulo.
  final radio = sqrt(caja.width * caja.width + caja.height * caja.height) / 2;
  final normalBase = Offset(-sin(angulo), cos(angulo));
  // Quien da [dentro] sabe mejor que la zona dónde cae el sombreado.
  final bool Function(Offset) dentroDe = dentro ?? zona.contains;

  for (
    var s = -radio;
    s <= radio;
    s += separacion * (0.8 + 0.4 * azar.nextDouble())
  ) {
    final desvio = (azar.nextDouble() * 2 - 1) * 3 * pi / 180;
    final a = angulo + desvio;
    final dir = Offset(cos(a), sin(a));
    final normal = Offset(-dir.dy, dir.dx);
    final base = centro + normalBase * s;
    Offset enT(double t) => base + dir * t;

    // Tramos contiguos de la raya que caen dentro de la zona y donde hay tinta.
    final tramos = <(double, double)>[];
    double? inicioTramo;
    for (var t = -radio; t <= radio; t += 1) {
      final dentroAhora = dentroDe(enT(t)) && intensidad(enT(t)) > minimo;
      if (dentroAhora && inicioTramo == null) inicioTramo = t;
      if (!dentroAhora && inicioTramo != null) {
        tramos.add((inicioTramo, t));
        inicioTramo = null;
      }
    }
    if (inicioTramo != null) tramos.add((inicioTramo, radio));

    for (final (t0Bruto, t1Bruto) in tramos) {
      // Los extremos se acortan al azar: bordes deshilachados, no cortados.
      final t0 = t0Bruto + azar.nextDouble() * 2.5;
      final t1 = t1Bruto - azar.nextDouble() * 2.5;
      final curva = (azar.nextDouble() * 2 - 1) * 0.7;
      if (t1 - t0 < 2) continue;

      // La raya se curva ±0,7 px en su centro.
      Offset q(double t) {
        final u = ((t - t0) / (t1 - t0)).clamp(0.0, 1.0);
        return enT(t) + normal * (curva * sin(pi * u));
      }

      for (var tt = t0; tt < t1; tt += 2) {
        final fin = min(tt + 2, t1);
        final mitad = (tt + fin) / 2;
        final u = ((mitad - t0) / (t1 - t0)).clamp(0.0, 1.0);
        final presion = 0.35 + 0.65 * sin(pi * u);
        final tinta = intensidad(q(mitad));
        if (tinta <= minimo) continue;
        canvas.drawLine(
          q(tt),
          q(fin),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = grosor * (0.6 + 0.5 * presion)
            ..color = color.withValues(
              alpha: (alfa * presion * tinta * (0.7 + 0.3 * azar.nextDouble()))
                  .clamp(0.0, 1.0),
            ),
        );
      }
    }
  }
}

/// Sombrea [zona] con rayas desiguales a lápiz. [intensidad] (0 a 1, por
/// defecto 1) dice cuánta tinta lleva cada punto: donde vale 0, no se pinta.
/// Con [cruzado], una segunda capa a 70° se pone solo donde la intensidad pasa
/// de 0,6: lo más oscuro se cruza, el resto no.
void pintarSombreado(
  Canvas canvas,
  Path zona, {
  required Color color,
  double Function(Offset punto)? intensidad,
  double angulo = pi / 4,
  double separacion = 2.4,
  double grosor = 0.9,
  double alfa = 0.6,
  bool cruzado = false,
  required int semilla,
  bool Function(Offset punto)? dentro,
}) {
  final tinta = intensidad ?? (_) => 1.0;
  canvas.save();
  canvas.clipPath(zona);
  _capaRayas(
    canvas,
    zona,
    color,
    tinta,
    angulo: angulo,
    separacion: separacion,
    grosor: grosor,
    alfa: alfa,
    minimo: 0,
    semilla: semilla,
    dentro: dentro,
  );
  if (cruzado) {
    _capaRayas(
      canvas,
      zona,
      color,
      tinta,
      angulo: angulo + 70 * pi / 180,
      separacion: separacion * 1.4,
      grosor: grosor,
      alfa: alfa * 0.55,
      minimo: 0.6,
      semilla: semilla + 11,
      dentro: dentro,
    );
  }
  canvas.restore();
}

/// Rellena [zona] con rayas paralelas en [angulo], cada [separacion] píxeles.
/// Es [pintarSombreado] sin intensidad y sin cruzar.
void pintarRayas(
  Canvas canvas,
  Path zona, {
  required Color color,
  double separacion = 3,
  double angulo = pi / 4,
  double grosor = 0.8,
  double alfa = 0.6,
  required int semilla,
}) {
  pintarSombreado(
    canvas,
    zona,
    color: color,
    angulo: angulo,
    separacion: separacion,
    grosor: grosor,
    alfa: alfa,
    semilla: semilla,
  );
}

/// La semilla de una pieza, a partir de su tamaño. Estable mientras la pieza no
/// cambie de tamaño; cada pieza distinta tiene su temblor.
int semillaDe(Size size) =>
    Object.hash(size.width.round(), size.height.round());

/// El borde de Dulce: el mismo rectángulo redondeado de siempre, pero con el
/// filo dibujado a lápiz. La forma (recortes, `InkWell`, relleno) no tiene
/// temblor: sólo el trazo.
///
/// Si trae [rayas], la figura se rellena antes con rayas de ese color. Las rayas
/// solo valen donde la figura se pinta DETRÁS del contenido (Container o Ink con
/// ShapeDecoration, el indicador de NavigationBar). En los botones y diálogos de
/// Material el borde se pinta delante y las rayas taparían el texto.
class BordeLapiz extends OutlinedBorder {
  final double radio;

  /// El color de las rayas del relleno, o null para no rellenar. Por defecto,
  /// ninguno.
  final Color? rayas;

  const BordeLapiz({
    required this.radio,
    super.side = BorderSide.none,
    this.rayas,
  });

  @override
  BordeLapiz copyWith({BorderSide? side, Color? rayas}) => BordeLapiz(
    radio: radio,
    side: side ?? this.side,
    rayas: rayas ?? this.rayas,
  );

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  ShapeBorder scale(double t) =>
      BordeLapiz(radio: radio * t, side: side.scale(t), rayas: rayas);

  Path _camino(Rect rect) =>
      Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radio)));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => _camino(rect);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      _camino(rect.deflate(side.width));

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    // Sin relleno ni filo no hay nada que pintar: ni siquiera se mueve el canvas.
    if (rayas == null && side.style == BorderStyle.none) return;
    // Se graba en el origen, con el tamaño redondeado (la clave), y se mueve.
    final ancho = rect.width.round().toDouble();
    final alto = rect.height.round().toDouble();
    canvas.save();
    canvas.translate(rect.left, rect.top);
    pintarConCache(
      canvas,
      (ancho, alto, radio, side, rayas),
      Size(ancho, alto),
      (c) => _pintarEnOrigen(c, Size(ancho, alto)),
      desborde: 4,
    );
    canvas.restore();
  }

  void _pintarEnOrigen(Canvas canvas, Size size) {
    final origen = Offset.zero & size;
    final color = rayas;
    if (color != null) {
      pintarRayas(
        canvas,
        _camino(origen),
        color: color,
        separacion: 2.6,
        alfa: 0.7,
        grosor: 1.0,
        semilla: semillaDe(size) + 3,
      );
    }
    if (side.style == BorderStyle.none) return;
    pintarTrazoLapiz(
      canvas,
      _camino(origen.deflate(side.width / 2)),
      color: side.color,
      grosor: side.width,
      semilla: semillaDe(size),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BordeLapiz &&
      other.radio == radio &&
      other.side == side &&
      other.rayas == rayas;

  @override
  int get hashCode => Object.hash(radio, side, rayas);
}
