import 'dart:math' as math;
import 'dart:ui';

import '../l10n/norday_core_localizations.dart';
import '../theme/app_theme.dart';

part 'letreros_datos.dart';

/// Un letrero de neón del catálogo de Neotokyo+: sus tubos, cada uno una
/// polilínea en coordenadas normalizadas 0..1 dentro del cuadro de la figura.
///
/// Es el «letrero del día» (D-35): con N hábitos, el letrero de N tubos, y
/// cada hábito hecho es un tubo. Durante el día los tubos hechos se ven como
/// cristal apagado; al cerrar el día se encienden uno a uno. Es la figura del
/// día de Neotokyo+, como la constelación en Profundidad y el ramo en Dulce.
///
/// Los dibujos se trazan en `tool/letreros_neotokyo/letreros.py` y de ahí se
/// genera [catalogoLetreros] (`letreros_datos.dart`).
class Letrero {
  /// Los tubos EN ORDEN DE ENCENDIDO: el hábito número N es `tubos[N-1]`.
  final List<List<Offset>> tubos;

  const Letrero({required this.tubos});
}

/// El letrero que toca para [total]. `null` con 0. De 8 en adelante, el de
/// 8 (Nori), como Orión en las constelaciones.
Letrero? letreroPara(int total) {
  if (total <= 0) return null;
  return catalogoLetreros[total.clamp(1, 8)];
}

/// El nombre del letrero que toca para [total], en el idioma activo.
String nombreLetrero(NordayCoreLocalizations l, int total) =>
    switch (total.clamp(1, 8)) {
      1 => l.letreroLuna,
      2 => l.letreroTaza,
      3 => l.letreroGato,
      4 => l.letreroRamen,
      5 => l.letreroTorii,
      6 => l.letreroOla,
      7 => l.letreroKoi,
      _ => l.letreroNori,
    };

/// Lo que espera el encendido antes del primer tubo: lo que tarda el velo de
/// la ceremonia en oscurecer.
const _esperaEncendido = 500;

/// Cada cuánto se enciende el tubo siguiente. Con un solo parpadeo por tubo,
/// salen como mucho dos destellos por segundo: por debajo de los tres de
/// WCAG 2.3.1.
const _pasoEncendido = 450;

/// Lo que dura el parpadeo de arranque de un tubo.
const _parpadeoTubo = 350;

/// El zumbido del letrero entero, al final.
const _zumbido = 600;

/// Lo que tarda en encenderse el letrero de [total] entero, del velo al
/// zumbido. La ceremonia espera esto antes de sacar los textos.
Duration duracionEncendidoLetrero(int total) {
  final n = total.clamp(1, 8);
  return Duration(
    milliseconds: _esperaEncendido + _pasoEncendido * n + _zumbido,
  );
}

/// La luz del tubo [i] cuando el encendido del letrero de [total] va por
/// [t] (de 0 a 1 sobre [duracionEncendidoLetrero]). Un solo parpadeo, como
/// el neón de verdad al arrancar: se enciende, se va un instante y vuelve
/// para quedarse.
double luzTuboEnEncendido(int i, int total, double t) {
  final ms = t * duracionEncendidoLetrero(total).inMilliseconds;
  final v = (ms - _esperaEncendido - _pasoEncendido * i) / _parpadeoTubo;
  if (v <= 0) return 0;
  if (v < 0.25) return v / 0.25;
  if (v < 0.45) return 0.15;
  return 1;
}

/// El zumbido final: un temblor de brillo suave sobre el letrero ya
/// encendido, que se apaga solo. Multiplica la luz; fuera del zumbido, 1.
double zumbidoLetrero(int total, double t) {
  final duracion = duracionEncendidoLetrero(total).inMilliseconds;
  final desde = duracion - _zumbido;
  final ms = t * duracion;
  if (ms <= desde || t >= 1) return 1;
  final v = (ms - desde) / _zumbido;
  return 1 + 0.18 * math.sin(v * math.pi * 3) * (1 - v);
}

/// El color del tubo [i]: la tríada de neón de la identidad, por turnos.
Color colorTubo(TokensContextuales t, int i) =>
    [t.primary, t.streak, t.points][i % 3];

/// Pinta [letrero] en [cuadro]. Quien llama abre antes una capa con
/// `BlendMode.plus`: el neón suma luz a lo que hay debajo, nunca lo tapa.
///
/// [cristal] y [luz] dan, por tubo, de 0 a 1, cuánto se ve el cristal
/// apagado y cuánto brilla. [zumbido] multiplica el brillo.
void pintarLetrero(
  Canvas canvas,
  Rect cuadro,
  Letrero letrero,
  TokensContextuales tokens, {
  required double Function(int) cristal,
  required double Function(int) luz,
  double zumbido = 1,
}) {
  final escala = cuadro.width / 300;
  for (var i = 0; i < letrero.tubos.length; i++) {
    final camino = _camino(letrero.tubos[i], cuadro);
    final c = cristal(i);
    if (c > 0) {
      canvas.drawPath(
        camino,
        _trazo(3.0 * escala)
          ..color = const Color(0xFF3A3358).withValues(alpha: 0.85 * c),
      );
      canvas.drawPath(
        camino,
        _trazo(1.0 * escala)
          ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.10 * c),
      );
    }
    final l = (luz(i) * zumbido).clamp(0.0, 1.2);
    if (l <= 0) continue;
    final color = colorTubo(tokens, i);
    canvas.drawPath(
      camino,
      _trazo(16 * escala)
        ..color = color.withValues(alpha: (0.10 * l).clamp(0.0, 1.0))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12 * escala),
    );
    canvas.drawPath(
      camino,
      _trazo(7 * escala)
        ..color = color.withValues(alpha: (0.30 * l).clamp(0.0, 1.0))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 * escala),
    );
    canvas.drawPath(
      camino,
      _trazo(2.8 * escala)
        ..color = Color.lerp(
          color,
          const Color(0xFFFFFFFF),
          0.55,
        )!.withValues(alpha: l.clamp(0.0, 1.0)),
    );
  }
}

Path _camino(List<Offset> puntos, Rect cuadro) {
  final camino = Path();
  for (var k = 0; k < puntos.length; k++) {
    final p = Offset(
      cuadro.left + puntos[k].dx * cuadro.width,
      cuadro.top + puntos[k].dy * cuadro.height,
    );
    if (k == 0) {
      camino.moveTo(p.dx, p.dy);
    } else {
      camino.lineTo(p.dx, p.dy);
    }
  }
  return camino;
}

Paint _trazo(double ancho) => Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = ancho
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;
