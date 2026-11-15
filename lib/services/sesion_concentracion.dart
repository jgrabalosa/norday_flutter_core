import 'dart:math';

import 'package:flutter/foundation.dart';

/// En qué punto está una [SesionConcentracion].
///
/// ```text
/// preparada ─empezar─▶ corriendo ─salir─▶ enGracia ─volver (≤ gracia)─▶ corriendo
///                         │                  │
///                         │                  └─ gracia vencida ─▶ perdida
///                         ├─ llega la meta ─▶ completada
///                         ├─ terminar (≥ mínimo) ─▶ terminada
///                         ├─ terminar (< mínimo) ─▶ descartada
///                         └─ rendirse ─▶ perdida
/// ```
enum EstadoSesion {
  /// Configurada, sin empezar: aún no hay hora de inicio.
  preparada,

  /// Contando, con la app delante o con la pantalla apagada o bloqueada.
  corriendo,

  /// El usuario ha salido a otra app con la pantalla encendida y
  /// desbloqueada. Si vuelve dentro de la gracia, sigue como si nada.
  enGracia,

  /// Ha llegado a la duración objetivo.
  completada,

  /// Terminada a mano antes de la meta, con al menos el mínimo hecho.
  terminada,

  /// Rendida, fuera de la gracia o rota por un reinicio del móvil. Nunca
  /// suma minutos.
  perdida,

  /// Terminada a mano antes del mínimo: no cuenta, pero tampoco castiga.
  /// La app no la envía.
  descartada;

  /// Contando o en la gracia.
  bool get activa => this == corriendo || this == enGracia;

  /// Ya no cambia.
  bool get esFinal =>
      this == completada ||
      this == terminada ||
      this == perdida ||
      this == descartada;

  /// Suma sus minutos.
  bool get cuenta => this == completada || this == terminada;
}

/// Por qué se perdió una sesión.
enum MotivoPerdida {
  /// El usuario pulsó rendirse.
  rendicion,

  /// Salió a otra app y no volvió dentro de la gracia.
  salida,

  /// El móvil se reinició (o cambió de hora a mano) a mitad de sesión: no
  /// hay forma de saber cuánto tiempo pasó.
  reinicio,
}

/// Las reglas configurables de una sesión. Viajan con ella y se guardan con
/// ella, así que una sesión que se recompone sigue con las reglas con las que
/// empezó.
@immutable
class ReglasSesion {
  /// Cuánto se puede estar fuera de la app sin perder la sesión. El borde
  /// entra: volver justo a los 10 s todavía vale.
  final Duration gracia;

  /// Lo mínimo para que terminar antes cuente. El borde entra: 10:00 cuenta,
  /// 9:59 se descarta.
  final Duration minimoParaContar;

  /// Diferencia máxima entre el arranque del móvil que se calculó al empezar
  /// y el que se calcula al recomponer (hora de pared menos reloj monótono).
  /// Si se pasa, el móvil se ha reiniciado o alguien ha movido la hora.
  final Duration toleranciaArranque;

  const ReglasSesion({
    this.gracia = const Duration(seconds: 10),
    this.minimoParaContar = const Duration(minutes: 10),
    this.toleranciaArranque = const Duration(minutes: 5),
  });

  @override
  bool operator ==(Object other) =>
      other is ReglasSesion &&
      other.gracia == gracia &&
      other.minimoParaContar == minimoParaContar &&
      other.toleranciaArranque == toleranciaArranque;

  @override
  int get hashCode => Object.hash(gracia, minimoParaContar, toleranciaArranque);
}

/// Una sesión de concentración con bloqueo suave: lógica pura, sin reloj, sin
/// plataforma y sin red. Cada transición recibe el reloj monótono en
/// milisegundos y devuelve una sesión nueva; la de partida no cambia.
///
/// Las transiciones que no aplican al estado actual devuelven la misma
/// sesión (salir de una completada, volver a una que no está en gracia…):
/// los eventos del ciclo de vida llegan cuando llegan y no deben romper nada.
/// La única que lanza es [empezar] fuera de [EstadoSesion.preparada].
///
/// El tiempo se mide con un reloj monótono que incluye el sueño profundo
/// (en Android, `SystemClock.elapsedRealtime`,
/// https://developer.android.com/reference/android/os/SystemClock#elapsedRealtime()),
/// que cuenta desde el arranque del móvil y no salta si el usuario cambia la
/// hora. La hora de pared solo se guarda como [inicioUtc], para el día de la
/// sesión, y para detectar un reinicio al recomponer.
///
/// No sabe para qué es la sesión: lo que la app necesite recordar (a qué se
/// dedica, por ejemplo) va en [datosApp], que se guarda y vuelve tal cual.
@immutable
class SesionConcentracion {
  /// Identificador único (UUID v4). Sirve de clave de idempotencia al
  /// enviarla.
  final String clave;

  /// Cuánto debe durar.
  final Duration duracionObjetivo;

  final ReglasSesion reglas;

  /// Lo que la app quiera guardar con la sesión. Tiene que poder pasar por
  /// `jsonEncode`.
  final Map<String, Object?>? datosApp;

  final EstadoSesion estado;

  /// Hora de pared al empezar, en UTC. `null` en [EstadoSesion.preparada].
  final DateTime? inicioUtc;

  /// Reloj monótono al empezar. `null` en [EstadoSesion.preparada].
  final int? inicioMonoMs;

  /// Reloj monótono al salir de la app. Solo en [EstadoSesion.enGracia].
  final int? salidaMonoMs;

  /// Marca provisional de salida: la primera consulta de pantalla dijo
  /// encendida y desbloqueada y falta la segunda. Solo en
  /// [EstadoSesion.corriendo]. Si el proceso muere antes de la segunda (o lo
  /// matan desde Recientes), [recomponer] la trata como una salida desde la
  /// marca.
  final int? salidaPendienteMonoMs;

  /// Reloj monótono en que terminó. Solo en los estados finales.
  final int? finMonoMs;

  /// Solo en [EstadoSesion.perdida].
  final MotivoPerdida? motivoPerdida;

  const SesionConcentracion._({
    required this.clave,
    required this.duracionObjetivo,
    required this.reglas,
    required this.estado,
    this.datosApp,
    this.inicioUtc,
    this.inicioMonoMs,
    this.salidaMonoMs,
    this.salidaPendienteMonoMs,
    this.finMonoMs,
    this.motivoPerdida,
  });

  /// Una sesión nueva, sin empezar. Sin [clave], se genera un UUID v4.
  factory SesionConcentracion.preparar({
    required Duration duracionObjetivo,
    ReglasSesion reglas = const ReglasSesion(),
    Map<String, Object?>? datosApp,
    String? clave,
  }) {
    if (duracionObjetivo <= Duration.zero) {
      throw ArgumentError.value(
        duracionObjetivo,
        'duracionObjetivo',
        'tiene que ser positiva',
      );
    }
    return SesionConcentracion._(
      clave: clave ?? generarClave(),
      duracionObjetivo: duracionObjetivo,
      reglas: reglas,
      estado: EstadoSesion.preparada,
      datosApp: datosApp,
    );
  }

  SesionConcentracion _con({
    required EstadoSesion estado,
    int? salidaMonoMs,
    int? salidaPendienteMonoMs,
    int? finMonoMs,
    MotivoPerdida? motivoPerdida,
  }) => SesionConcentracion._(
    clave: clave,
    duracionObjetivo: duracionObjetivo,
    reglas: reglas,
    datosApp: datosApp,
    inicioUtc: inicioUtc,
    inicioMonoMs: inicioMonoMs,
    estado: estado,
    salidaMonoMs: salidaMonoMs,
    salidaPendienteMonoMs: salidaPendienteMonoMs,
    finMonoMs: finMonoMs,
    motivoPerdida: motivoPerdida,
  );

  int get _objetivoMs => duracionObjetivo.inMilliseconds;

  /// Reloj monótono en que se alcanza la meta.
  int? get metaMonoMs =>
      inicioMonoMs == null ? null : inicioMonoMs! + _objetivoMs;

  /// Reloj monótono en que vence la gracia. Solo en [EstadoSesion.enGracia].
  int? get finGraciaMonoMs => salidaMonoMs == null
      ? null
      : salidaMonoMs! + reglas.gracia.inMilliseconds;

  // ── Transiciones ──────────────────────────────────────

  /// Arranca la cuenta. Solo desde [EstadoSesion.preparada].
  SesionConcentracion empezar({
    required int monoMs,
    required DateTime ahoraUtc,
  }) {
    if (estado != EstadoSesion.preparada) {
      throw StateError('Solo se empieza una sesión preparada ($estado)');
    }
    return SesionConcentracion._(
      clave: clave,
      duracionObjetivo: duracionObjetivo,
      reglas: reglas,
      datosApp: datosApp,
      inicioUtc: ahoraUtc.toUtc(),
      inicioMonoMs: monoMs,
      estado: EstadoSesion.corriendo,
    );
  }

  /// Aplica lo que haya pasado solo con el tiempo:
  ///
  /// - reloj monótono por debajo del inicio → perdida por reinicio;
  /// - corriendo y alcanzada la meta → completada, con el fin en la meta;
  /// - en gracia, si la meta llega antes de que venza la gracia → completada
  ///   (el tiempo de gracia es tiempo de sesión);
  /// - en gracia y vencida → perdida por salida, con el fin en la salida.
  SesionConcentracion actualizar(int monoMs) {
    if (!estado.activa) return this;
    if (monoMs < inicioMonoMs!) {
      return _con(
        estado: EstadoSesion.perdida,
        finMonoMs: salidaMonoMs ?? inicioMonoMs,
        motivoPerdida: MotivoPerdida.reinicio,
      );
    }
    final meta = metaMonoMs!;
    if (estado == EstadoSesion.corriendo) {
      if (monoMs >= meta) {
        return _con(estado: EstadoSesion.completada, finMonoMs: meta);
      }
      return this;
    }
    // En gracia.
    final finGracia = finGraciaMonoMs!;
    if (meta <= finGracia && monoMs >= meta) {
      return _con(estado: EstadoSesion.completada, finMonoMs: meta);
    }
    if (monoMs > finGracia) {
      return _con(
        estado: EstadoSesion.perdida,
        finMonoMs: salidaMonoMs,
        motivoPerdida: MotivoPerdida.salida,
      );
    }
    return this;
  }

  /// Deja la marca provisional de salida en [monoMs] (sustituye a la que
  /// hubiera). Solo en una sesión corriendo; en cualquier otra, nada.
  SesionConcentracion marcarSalidaPendiente(int monoMs) {
    if (estado != EstadoSesion.corriendo) return this;
    return _con(estado: estado, salidaPendienteMonoMs: monoMs);
  }

  /// Quita la marca provisional: la segunda consulta dijo que no era salir.
  SesionConcentracion quitarSalidaPendiente() {
    if (salidaPendienteMonoMs == null) return this;
    return _con(estado: estado);
  }

  /// El usuario se ha ido a otra app con la pantalla encendida y
  /// desbloqueada: empieza la gracia, medida desde [monoMs]. Consume la marca
  /// provisional, si la había.
  SesionConcentracion salir(int monoMs) {
    final s = actualizar(monoMs);
    if (s.estado != EstadoSesion.corriendo) return s;
    return s._con(estado: EstadoSesion.enGracia, salidaMonoMs: monoMs);
  }

  /// La app vuelve a primer plano. Dentro de la gracia, sigue corriendo;
  /// fuera, perdida (eso lo resuelve [actualizar]). Volver quita también la
  /// marca provisional: si está delante, no se ha ido.
  SesionConcentracion volver(int monoMs) {
    final s = actualizar(monoMs);
    if (s.estado == EstadoSesion.enGracia) {
      return s._con(estado: EstadoSesion.corriendo);
    }
    return s.quitarSalidaPendiente();
  }

  /// Terminar antes. Cuenta si lleva al menos [ReglasSesion.minimoParaContar];
  /// si no, se descarta. Si la meta ya había llegado, completada.
  SesionConcentracion terminar(int monoMs) {
    final s = actualizar(monoMs);
    if (!s.estado.activa) return s;
    final hecho = monoMs - inicioMonoMs!;
    return s._con(
      estado: hecho >= reglas.minimoParaContar.inMilliseconds
          ? EstadoSesion.terminada
          : EstadoSesion.descartada,
      finMonoMs: monoMs,
    );
  }

  /// Rendirse: perdida, aunque lleve el mínimo hecho. Si la meta ya había
  /// llegado, sigue completada.
  SesionConcentracion rendirse(int monoMs) {
    final s = actualizar(monoMs);
    if (!s.estado.activa) return s;
    return s._con(
      estado: EstadoSesion.perdida,
      finMonoMs: monoMs,
      motivoPerdida: MotivoPerdida.rendicion,
    );
  }

  /// Al reabrir la app con una sesión guardada: si el móvil se ha reiniciado
  /// desde que empezó, perdida; si no, lo que diga [actualizar]. Una marca
  /// provisional de salida cuenta como salida desde la marca: el proceso
  /// murió entre las dos consultas de pantalla.
  ///
  /// El reinicio se reconoce de dos formas. La obvia: el reloj monótono está
  /// por debajo del inicio, porque empezó a contar de cero. Y la que cubre
  /// un reinicio de hace tiempo, cuando el monótono ya ha vuelto a pasar el
  /// inicio: el instante de arranque del móvil (hora de pared menos
  /// monótono) no es el mismo que al empezar, con un margen de
  /// [ReglasSesion.toleranciaArranque] para los ajustes de hora de la red.
  SesionConcentracion recomponer({
    required int monoMs,
    required DateTime ahoraUtc,
  }) {
    if (!estado.activa) return this;
    final arranqueAlEmpezar = inicioUtc!.millisecondsSinceEpoch - inicioMonoMs!;
    final arranqueAhora = ahoraUtc.toUtc().millisecondsSinceEpoch - monoMs;
    final cambioDeArranque =
        (arranqueAhora - arranqueAlEmpezar).abs() >
        reglas.toleranciaArranque.inMilliseconds;
    if (monoMs < inicioMonoMs! || cambioDeArranque) {
      return _con(
        estado: EstadoSesion.perdida,
        finMonoMs: salidaMonoMs ?? inicioMonoMs,
        motivoPerdida: MotivoPerdida.reinicio,
      );
    }
    final pendiente = salidaPendienteMonoMs;
    if (estado == EstadoSesion.corriendo && pendiente != null) {
      return salir(pendiente).actualizar(monoMs);
    }
    return actualizar(monoMs);
  }

  // ── Lecturas ──────────────────────────────────────────

  /// Lo que lleva en [monoMs] (o lo que duró, si ya terminó), sin pasar de
  /// la meta ni bajar de cero.
  Duration transcurrido(int monoMs) {
    if (inicioMonoMs == null) return Duration.zero;
    final hasta = finMonoMs ?? monoMs;
    final ms = (hasta - inicioMonoMs!).clamp(0, _objetivoMs);
    return Duration(milliseconds: ms);
  }

  /// Lo que le falta en [monoMs] para la meta. Cero en los estados finales.
  Duration restante(int monoMs) {
    if (estado.esFinal) return Duration.zero;
    return duracionObjetivo - transcurrido(monoMs);
  }

  /// Lo que duró. Solo tiene sentido en los estados finales.
  Duration get duracion => finMonoMs == null || inicioMonoMs == null
      ? Duration.zero
      : Duration(
          milliseconds: (finMonoMs! - inicioMonoMs!).clamp(0, _objetivoMs),
        );

  /// Minutos enteros que suma: los de [duracion], redondeados hacia abajo,
  /// solo si [EstadoSesion.cuenta]. Si no, cero.
  int get minutos => estado.cuenta ? duracion.inMinutes : 0;

  // ── Persistencia ──────────────────────────────────────

  static const _version = 1;

  Map<String, Object?> toJson() => {
    'version': _version,
    'clave': clave,
    'objetivoMs': _objetivoMs,
    'graciaMs': reglas.gracia.inMilliseconds,
    'minimoMs': reglas.minimoParaContar.inMilliseconds,
    'toleranciaArranqueMs': reglas.toleranciaArranque.inMilliseconds,
    'estado': estado.name,
    'datosApp': datosApp,
    'inicioUtc': inicioUtc?.toIso8601String(),
    'inicioMonoMs': inicioMonoMs,
    'salidaMonoMs': salidaMonoMs,
    'salidaPendienteMonoMs': salidaPendienteMonoMs,
    'finMonoMs': finMonoMs,
    'motivoPerdida': motivoPerdida?.name,
  };

  /// La sesión de [json], o `null` si no se entiende (otra versión o datos
  /// rotos).
  static SesionConcentracion? fromJson(Map<String, Object?> json) {
    try {
      if (json['version'] != _version) return null;
      final estado = EstadoSesion.values.byName(json['estado']! as String);
      final inicio = json['inicioUtc'] as String?;
      final motivo = json['motivoPerdida'] as String?;
      final datos = json['datosApp'] as Map<String, Object?>?;
      final s = SesionConcentracion._(
        clave: json['clave']! as String,
        duracionObjetivo: Duration(milliseconds: json['objetivoMs']! as int),
        reglas: ReglasSesion(
          gracia: Duration(milliseconds: json['graciaMs']! as int),
          minimoParaContar: Duration(milliseconds: json['minimoMs']! as int),
          toleranciaArranque: Duration(
            milliseconds: json['toleranciaArranqueMs']! as int,
          ),
        ),
        estado: estado,
        datosApp: datos == null ? null : Map.unmodifiable(datos),
        inicioUtc: inicio == null ? null : DateTime.parse(inicio).toUtc(),
        inicioMonoMs: json['inicioMonoMs'] as int?,
        salidaMonoMs: json['salidaMonoMs'] as int?,
        salidaPendienteMonoMs: json['salidaPendienteMonoMs'] as int?,
        finMonoMs: json['finMonoMs'] as int?,
        motivoPerdida: motivo == null
            ? null
            : MotivoPerdida.values.byName(motivo),
      );
      final empezada = s.inicioMonoMs != null && s.inicioUtc != null;
      if (estado != EstadoSesion.preparada && !empezada) return null;
      if (estado == EstadoSesion.enGracia && s.salidaMonoMs == null) {
        return null;
      }
      return s;
    } catch (_) {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is SesionConcentracion &&
      other.clave == clave &&
      other.duracionObjetivo == duracionObjetivo &&
      other.reglas == reglas &&
      mapEquals(other.datosApp, datosApp) &&
      other.estado == estado &&
      other.inicioUtc == inicioUtc &&
      other.inicioMonoMs == inicioMonoMs &&
      other.salidaMonoMs == salidaMonoMs &&
      other.salidaPendienteMonoMs == salidaPendienteMonoMs &&
      other.finMonoMs == finMonoMs &&
      other.motivoPerdida == motivoPerdida;

  @override
  int get hashCode => Object.hash(
    clave,
    duracionObjetivo,
    reglas,
    estado,
    inicioUtc,
    inicioMonoMs,
    salidaMonoMs,
    salidaPendienteMonoMs,
    finMonoMs,
    motivoPerdida,
  );

  @override
  String toString() =>
      'SesionConcentracion($clave, $estado, objetivo: $duracionObjetivo'
      '${motivoPerdida == null ? '' : ', motivo: $motivoPerdida'})';
}

final Random _azar = Random.secure();

/// Un UUID v4 (RFC 9562) en minúsculas, con [Random.secure].
String generarClave() {
  final b = List<int>.generate(16, (_) => _azar.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-'
      '${h.substring(16, 20)}-${h.substring(20)}';
}
