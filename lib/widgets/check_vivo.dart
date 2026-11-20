import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/widgets.dart';

/// «El check vivo» (T-018, experimento): de vez en cuando algo da una vuelta
/// al aro de un [CheckCircular] sin hacer. Aquí vive la mecánica que no
/// depende de la identidad: el coordinador de turnos y el dibujo de la vuelta
/// de cada una. El interruptor es `CheckCircular.vivo`.
///
/// Para quitar el experimento: borrar este fichero y los ganchos de
/// `check_circular.dart` (todos llevan «vivo» en el nombre).

/// Lo que el coordinador necesita de un check para darle el turno.
abstract class ParticipanteCheckVivo {
  /// Dónde está en pantalla (esquina superior izquierda), o `null` si ahora
  /// no se puede saber. Sirve para ordenar «de arriba abajo».
  Offset? get posicionGlobal;

  /// Empieza su vuelta. El coordinador no espera: la vuelta dura menos que el
  /// turno, así que no se solapan.
  void darVuelta();
}

/// Reparte los turnos: **uno cada vez**, cada [cadaTurno], de arriba abajo y
/// vuelta a empezar.
///
/// Estático, como los notifiers del core (`refrescoMascotaNotifier`…): hay un
/// solo coordinador y los checks se apuntan solos. «De arriba abajo» se decide
/// **al dar cada turno**, por la posición en pantalla (primero la `dy`, y a
/// igualdad la `dx`), no por orden de registro: así sigue valiendo si la lista
/// se desplaza o se reordena, y un check que aparece arriba entra en su sitio.
/// Cada turno va al primero que queda por debajo del último servido; al
/// llegar al final, vuelve al primero.
///
/// Sin registrados no hay temporizador: se crea con el primero y se cancela
/// con el último.
class CoordinadorCheckVivo {
  CoordinadorCheckVivo._();

  /// Cada cuánto se da un turno.
  static const cadaTurno = Duration(seconds: 8);

  static final List<ParticipanteCheckVivo> _registrados = [];
  static ParticipanteCheckVivo? _ultimo;
  static Timer? _temporizador;

  /// Cuántos hay apuntados.
  static int get registrados => _registrados.length;

  /// Si hay un temporizador en marcha. Solo mientras haya registrados.
  static bool get activo => _temporizador != null;

  /// Apunta un check. Apuntar dos veces el mismo no hace nada.
  static void registrar(ParticipanteCheckVivo p) {
    if (_registrados.contains(p)) return;
    _registrados.add(p);
    _temporizador ??= Timer.periodic(cadaTurno, (_) => _darTurno());
  }

  /// Da de baja un check. Con el último, se cancela el temporizador.
  static void baja(ParticipanteCheckVivo p) {
    _registrados.remove(p);
    if (identical(_ultimo, p)) _ultimo = null;
    if (_registrados.isEmpty) {
      _temporizador?.cancel();
      _temporizador = null;
    }
  }

  /// Lo deja todo como al principio. Para los tests.
  @visibleForTesting
  static void reiniciar() {
    _registrados.clear();
    _ultimo = null;
    _temporizador?.cancel();
    _temporizador = null;
  }

  static void _darTurno() {
    final candidatos = <(ParticipanteCheckVivo, Offset)>[
      for (final p in _registrados)
        if (p.posicionGlobal case final pos?) (p, pos),
    ];
    if (candidatos.isEmpty) return;
    candidatos.sort((a, b) {
      final porY = a.$2.dy.compareTo(b.$2.dy);
      return porY != 0 ? porY : a.$2.dx.compareTo(b.$2.dx);
    });
    final i = candidatos.indexWhere((c) => identical(c.$1, _ultimo));
    // Tras el último servido; si ya no está o era el de abajo, el de arriba.
    final siguiente = candidatos[(i + 1) % candidatos.length].$1;
    _ultimo = siguiente;
    siguiente.darVuelta();
  }
}

/// Cuánto dura una vuelta.
const duracionVueltaCheck = Duration(milliseconds: 1600);

/// El recorrido de la vuelta: la figura del check, empezando **arriba** (la
/// figura ya llega así) y en el sentido de las agujas del reloj.
PathMetric? _recorrido(Path figura) {
  final metricas = figura.computeMetrics().iterator;
  return metricas.moveNext() ? metricas.current : null;
}

/// Aparición y desaparición suave en los extremos de la vuelta.
double _alfaDeVuelta(double progreso) =>
    math.min(1.0, math.min(progreso, 1 - progreso) / 0.08);

/// Profundidad: un cohete amarillo del tamaño del grosor del aro, orientado
/// hacia donde avanza, con una estela que se desvanece y un brillo suave.
///
/// [figura] es el aro (empieza arriba, sentido horario), [progreso] va de 0
/// a 1, [grosor] es el del aro y [color] el `streak` de la identidad.
void pintarVueltaProfundidad(
  Canvas canvas,
  Path figura,
  double progreso, {
  required Color color,
  required double grosor,
}) {
  final metrica = _recorrido(figura);
  if (metrica == null) return;
  final alfa = _alfaDeVuelta(progreso.clamp(0.0, 1.0));
  final d = metrica.length * progreso.clamp(0.0, 1.0);
  final cabeza = metrica.getTangentForOffset(d);
  if (cabeza == null) return;

  // Estela: cinco tramos hacia atrás, cada uno más fino y más claro.
  final largoEstela = grosor * 7;
  const tramos = 5;
  for (var i = 0; i < tramos; i++) {
    final hasta = d - largoEstela * i / tramos;
    final desde = d - largoEstela * (i + 1) / tramos;
    if (hasta <= 0) break;
    final f = 1 - i / tramos;
    canvas.drawPath(
      metrica.extractPath(math.max(0.0, desde), hasta),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = grosor * (0.25 + 0.6 * f)
        ..color = color.withValues(alpha: 0.7 * f * f * alfa),
    );
  }

  canvas.save();
  canvas.translate(cabeza.position.dx, cabeza.position.dy);
  canvas.rotate(math.atan2(cabeza.vector.dy, cabeza.vector.dx));
  // Brillo suave, como el resto de Profundidad.
  canvas.drawCircle(
    Offset.zero,
    grosor * 0.9,
    Paint()
      ..color = color.withValues(alpha: 0.55 * alfa)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, grosor * 0.8),
  );
  // El cohete: morro en punta, cuerpo y dos aletas que salen hacia atrás.
  final l = grosor * 2.2;
  final a = grosor * 0.9;
  final cuerpo = Path()
    ..moveTo(l / 2, 0)
    ..quadraticBezierTo(l / 6, -a / 2, -l / 2, -a)
    ..lineTo(-l / 3, 0)
    ..lineTo(-l / 2, a)
    ..quadraticBezierTo(l / 6, a / 2, l / 2, 0)
    ..close();
  canvas.drawPath(cuerpo, Paint()..color = color.withValues(alpha: alfa));
  canvas.restore();
}

/// Marcador provisional para Neotokyo+ y Dulce, hasta T-018b: un punto en
/// `streak` (sin brillo) que recorre la figura.
void pintarVueltaProvisional(
  Canvas canvas,
  Path figura,
  double progreso, {
  required Color color,
  required double grosor,
}) {
  final metrica = _recorrido(figura);
  if (metrica == null) return;
  final p = progreso.clamp(0.0, 1.0);
  final punto = metrica.getTangentForOffset(metrica.length * p);
  if (punto == null) return;
  canvas.drawCircle(
    punto.position,
    grosor * 0.7,
    Paint()..color = color.withValues(alpha: _alfaDeVuelta(p)),
  );
}
