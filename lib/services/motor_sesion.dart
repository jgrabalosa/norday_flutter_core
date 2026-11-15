import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'sesion_concentracion.dart';

/// El reloj que usa el motor. Lo implementa cada app; el core no lleva
/// código nativo.
///
/// [monotonicoMs] tiene que contar desde el arranque del móvil, seguir
/// contando con la CPU dormida y no saltar si el usuario cambia la hora. En
/// Android es `SystemClock.elapsedRealtime()`
/// (https://developer.android.com/reference/android/os/SystemClock#elapsedRealtime()):
/// «return the time since the system was booted, and include deep sleep.
/// This clock is guaranteed to be monotonic». Dart no lo expone, así que va
/// por un canal de la app. Un `Stopwatch` de Dart NO sirve: empieza de cero
/// con cada proceso, y una sesión recompuesta tras matar la app se daría por
/// perdida por reinicio.
///
/// [ahoraUtc] es la hora de pared. Solo se usa para el inicio de la sesión
/// (el día) y para reconocer un reinicio al recomponer.
abstract interface class FuenteReloj {
  Future<int> monotonicoMs();
  DateTime ahoraUtc();
}

/// Si la pantalla está encendida y desbloqueada. Lo implementa cada app.
///
/// En Android, `PowerManager.isInteractive()` y no
/// `KeyguardManager.isKeyguardLocked()`:
///
/// - https://developer.android.com/reference/android/os/PowerManager#isInteractive()
///   — falso cuando el móvil «is dozing or asleep» (pantalla apagada).
/// - https://developer.android.com/reference/android/app/KeyguardManager#isKeyguardLocked()
///   — cierto mientras se muestra la pantalla de bloqueo, aunque se quite
///   deslizando, y también si una llamada la tapa. Es lo que se quiere: con
///   el bloqueo delante el usuario no se ha ido a otra app.
///
/// Si la consulta falla, el motor lo trata como `false` (no ha salido): un
/// canal roto no debe hacer perder sesiones a nadie.
abstract interface class FuentePantalla {
  Future<bool> encendidaYDesbloqueada();
}

/// Las notificaciones locales de una sesión. Las implementa cada app (con
/// `flutter_local_notifications` u otro), porque el core no puede añadir esa
/// dependencia sin obligar a todas las apps a activar el desugaring de
/// Android. Sin implementación, [AvisosSesionNulos]: las reglas son las
/// mismas, solo que sin avisos.
///
/// Los textos pueden salir del core sin `BuildContext`:
/// `lookupNordayCoreLocalizations(IdiomaService.localeNotifier.value)` y
/// `sesionAvisoGraciaTitulo`, `sesionAvisoGraciaCuerpo(segundos)`,
/// `sesionAvisoFinTitulo` y `sesionAvisoFinCuerpo`.
///
/// El permiso (`POST_NOTIFICATIONS`, Android 13+,
/// https://developer.android.com/develop/ui/views/notifications/notification-permission)
/// lo pide la app en contexto, con `NotificacionesService`, al empezar la
/// primera sesión. Sin permiso, los avisos no salen y nada más cambia.
///
/// Todas las llamadas deben ser idempotentes (un id fijo por tipo de aviso):
/// al recomponer, el motor vuelve a programar el fin.
abstract interface class AvisosSesion {
  /// Aviso inmediato: el usuario ha salido y le quedan [quedan] de gracia.
  Future<void> avisarGracia(Duration quedan);

  /// Quita el aviso de gracia (ha vuelto, o la sesión ha terminado).
  Future<void> cancelarGracia();

  /// Programa el aviso de fin para [finUtc], sin alarma exacta: la
  /// programación inexacta basta y no pide permisos especiales.
  Future<void> programarFin(DateTime finUtc);

  /// Quita el aviso de fin, programado o ya mostrado.
  Future<void> cancelarFin();
}

/// Sin avisos.
class AvisosSesionNulos implements AvisosSesion {
  const AvisosSesionNulos();

  @override
  Future<void> avisarGracia(Duration quedan) async {}

  @override
  Future<void> cancelarGracia() async {}

  @override
  Future<void> programarFin(DateTime finUtc) async {}

  @override
  Future<void> cancelarFin() async {}
}

/// Lleva una [SesionConcentracion] con bloqueo suave en una app real: escucha
/// el ciclo de vida, consulta la pantalla, guarda cada transición, recompone
/// al reabrir y lanza los avisos.
///
/// Qué cuenta como salir (ver [AppLifecycleState],
/// https://api.flutter.dev/flutter/dart-ui/AppLifecycleState.html):
///
/// - `paused` («not currently visible to the user») con la pantalla
///   encendida y desbloqueada: otra app o el escritorio. Empieza la gracia.
/// - `paused` con la pantalla apagada o bloqueada: no es salir.
/// - `inactive` (cortinilla, diálogos del sistema, selector de apps, una
///   llamada entrante) y `hidden` (Flutter lo sintetiza en Android antes de
///   `paused`): no son salir.
///
/// Al llegar `paused` se consulta la pantalla y se repite la consulta a los
/// [esperaSegundaConsulta] (400 ms): sale solo si las DOS dicen encendida y
/// desbloqueada, para no confundir con una salida un `paused` que llega
/// mientras la pantalla se está apagando. La gracia se mide desde el
/// `paused`. Si mientras tanto cambia el ciclo, la consulta se abandona.
///
/// `resumed` dentro de la gracia vuelve a corriendo; fuera, perdida. El fin
/// por tiempo se detecta con un temporizador (cada segundo con la app
/// delante; con la app detrás, uno solo a la meta o al fin de la gracia) y,
/// si el proceso estaba dormido, al volver.
///
/// Escucha con [AppLifecycleListener]
/// (https://api.flutter.dev/flutter/widgets/AppLifecycleListener-class.html),
/// que es un `WidgetsBindingObserver`
/// (https://api.flutter.dev/flutter/widgets/WidgetsBindingObserver-class.html)
/// con un callback por estado; se suelta en [dispose].
///
/// Una sola sesión a la vez. Una sesión acabada se queda guardada hasta que
/// la app la recoge y llama a [cerrar]: así no se pierde un resultado si el
/// proceso muere antes de enviarlo.
///
/// Uso típico:
///
/// ```dart
/// final motor = MotorSesion(reloj: miReloj, pantalla: miPantalla, avisos: misAvisos);
/// await motor.iniciar();                    // recompone si había una
/// await motor.empezar(duracionObjetivo: const Duration(minutes: 25));
/// motor.sesion.addListener(() { /* si es final: enviarla y motor.cerrar() */ });
/// ```
class MotorSesion {
  MotorSesion({
    required this.reloj,
    required this.pantalla,
    this.avisos = const AvisosSesionNulos(),
    this.esperaSegundaConsulta = const Duration(milliseconds: 400),
    this.clavePreferencias = 'sesion_concentracion_actual',
    this.binding,
  });

  final FuenteReloj reloj;
  final FuentePantalla pantalla;
  final AvisosSesion avisos;

  /// Cuánto se espera para repetir la consulta de pantalla tras `paused`.
  final Duration esperaSegundaConsulta;

  /// Dónde se guarda la sesión en `SharedPreferences`.
  final String clavePreferencias;

  /// El binding cuyo ciclo de vida se escucha. Por defecto,
  /// `WidgetsBinding.instance`.
  final WidgetsBinding? binding;

  final ValueNotifier<SesionConcentracion?> _sesion = ValueNotifier(null);
  final ValueNotifier<Duration> _restante = ValueNotifier(Duration.zero);

  /// La sesión actual: activa, o acabada y aún sin [cerrar]. `null` si no
  /// hay ninguna.
  ValueListenable<SesionConcentracion?> get sesion => _sesion;

  /// Lo que falta para la meta. Se refresca cada segundo con la app delante.
  ValueListenable<Duration> get restante => _restante;

  AppLifecycleListener? _oyente;
  AppLifecycleState? _ciclo;
  int _generacion = 0;
  Future<void> _cola = Future<void>.value();
  Timer? _tic;
  bool _iniciado = false;
  bool _desechado = false;

  bool get _enPrimerPlano =>
      _ciclo == null || _ciclo == AppLifecycleState.resumed;

  /// Engancha el ciclo de vida y recompone la sesión guardada, si la hay.
  /// Hay que llamarlo una vez, antes de [empezar].
  Future<SesionConcentracion?> iniciar() => _enCola(() async {
    if (_iniciado) return _sesion.value;
    _iniciado = true;
    final b = binding ?? WidgetsBinding.instance;
    _ciclo = b.lifecycleState;
    _oyente = AppLifecycleListener(binding: b, onStateChange: alCambiarCiclo);

    final guardada = await _leer();
    if (guardada == null) return null;
    final mono = await reloj.monotonicoMs();
    var s = guardada.recomponer(monoMs: mono, ahoraUtc: reloj.ahoraUtc());
    if (_enPrimerPlano) s = s.volver(mono);
    await _poner(s, anterior: guardada, mono: mono, recompuesta: true);
    return s;
  });

  /// Empieza una sesión. Lanza [StateError] si no se ha llamado a
  /// [iniciar] o si ya hay una (activa, o acabada sin [cerrar]).
  Future<SesionConcentracion> empezar({
    required Duration duracionObjetivo,
    ReglasSesion reglas = const ReglasSesion(),
    Map<String, Object?>? datosApp,
  }) => _enCola(() async {
    if (!_iniciado) {
      throw StateError('MotorSesion.iniciar() antes de empezar');
    }
    if (_sesion.value != null) {
      throw StateError('Ya hay una sesión: ciérrala antes de empezar otra');
    }
    final preparada = SesionConcentracion.preparar(
      duracionObjetivo: duracionObjetivo,
      reglas: reglas,
      datosApp: datosApp,
    );
    final mono = await reloj.monotonicoMs();
    final s = preparada.empezar(monoMs: mono, ahoraUtc: reloj.ahoraUtc());
    await _poner(s, anterior: preparada, mono: mono);
    return s;
  });

  /// Terminar antes: terminada si llega al mínimo, descartada si no.
  Future<SesionConcentracion?> terminar() => _aplicar((s, m) => s.terminar(m));

  /// Rendirse: perdida.
  Future<SesionConcentracion?> rendirse() => _aplicar((s, m) => s.rendirse(m));

  /// Olvida la sesión acabada, cuando la app ya la ha recogido. Lanza
  /// [StateError] si sigue activa: una sesión en curso se termina o se
  /// rinde, no se borra.
  Future<void> cerrar() => _enCola(() async {
    final s = _sesion.value;
    if (s == null || _desechado) return;
    if (s.estado.activa) {
      throw StateError('La sesión sigue activa: termínala o ríndete');
    }
    _sesion.value = null;
    _reprogramar(0);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(clavePreferencias);
    } catch (e) {
      debugPrint('MotorSesion: no se pudo borrar la sesión guardada: $e');
    }
  });

  /// Suelta el ciclo de vida y los temporizadores.
  void dispose() {
    _desechado = true;
    _tic?.cancel();
    _oyente?.dispose();
    _sesion.dispose();
    _restante.dispose();
  }

  /// Lo que hace el motor con cada cambio del ciclo de vida. Lo llama el
  /// [AppLifecycleListener]; público solo para probarlo.
  @visibleForTesting
  Future<void> alCambiarCiclo(AppLifecycleState estado) {
    _ciclo = estado;
    final generacion = ++_generacion;
    switch (estado) {
      case AppLifecycleState.paused:
        return _alPausar(generacion);
      case AppLifecycleState.resumed:
        return _aplicar((s, m) => s.volver(m)).then((_) {});
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        return Future<void>.value();
    }
  }

  Future<void> _alPausar(int generacion) async {
    if (_sesion.value?.estado != EstadoSesion.corriendo) {
      // Nada que vigilar, pero el temporizador pasa al de segundo plano.
      await _enCola(() async => _reprogramar(await reloj.monotonicoMs()));
      return;
    }
    final mono = await reloj.monotonicoMs();
    bool sigue() => generacion == _generacion && !_desechado;

    final primera = await _consultarPantalla();
    if (!sigue()) return;
    if (primera) {
      await Future<void>.delayed(esperaSegundaConsulta);
      if (!sigue()) return;
      final segunda = await _consultarPantalla();
      if (!sigue()) return;
      if (segunda) {
        await _enCola(() async {
          final s = _sesion.value;
          if (s == null || !sigue()) return;
          await _poner(
            s.salir(mono),
            anterior: s,
            mono: await reloj.monotonicoMs(),
          );
        });
        return;
      }
    }
    await _enCola(() async => _reprogramar(await reloj.monotonicoMs()));
  }

  Future<bool> _consultarPantalla() async {
    try {
      return await pantalla.encendidaYDesbloqueada();
    } catch (e) {
      debugPrint('MotorSesion: no se pudo consultar la pantalla: $e');
      return false;
    }
  }

  Future<SesionConcentracion?> _aplicar(
    SesionConcentracion Function(SesionConcentracion s, int monoMs) paso,
  ) => _enCola(() async {
    final s = _sesion.value;
    if (s == null) return null;
    final mono = await reloj.monotonicoMs();
    final nueva = s.estado.activa ? paso(s, mono) : s;
    await _poner(nueva, anterior: s, mono: mono);
    return nueva;
  });

  Future<void> _tictac() => _aplicar((s, m) => s.actualizar(m));

  /// Pone [nueva], la guarda si ha cambiado, lanza los avisos y reprograma
  /// el temporizador.
  Future<void> _poner(
    SesionConcentracion nueva, {
    required SesionConcentracion anterior,
    required int mono,
    bool recompuesta = false,
  }) async {
    if (_desechado) return;
    final cambia = nueva != anterior || recompuesta;
    _sesion.value = nueva;
    if (cambia) {
      await _guardar(nueva);
      await _avisar(anterior, nueva, mono, recompuesta: recompuesta);
    }
    _reprogramar(mono);
  }

  Future<void> _avisar(
    SesionConcentracion anterior,
    SesionConcentracion nueva,
    int mono, {
    required bool recompuesta,
  }) async {
    final a = anterior.estado;
    final n = nueva.estado;
    if (a != EstadoSesion.enGracia && n == EstadoSesion.enGracia) {
      await _seguro(
        () => avisos.avisarGracia(
          Duration(milliseconds: math.max(0, nueva.finGraciaMonoMs! - mono)),
        ),
      );
    }
    if (a == EstadoSesion.enGracia && n != EstadoSesion.enGracia) {
      await _seguro(avisos.cancelarGracia);
    }
    final empieza = a == EstadoSesion.preparada && n == EstadoSesion.corriendo;
    if (empieza || (recompuesta && n.activa)) {
      final fin = reloj.ahoraUtc().add(nueva.restante(mono));
      await _seguro(() => avisos.programarFin(fin));
    }
    if (n.esFinal && !a.esFinal) {
      // Completada con la app detrás (pantalla apagada): el aviso de fin es
      // justo el que tiene que salir. En cualquier otro final, fuera.
      final completadaDetras = n == EstadoSesion.completada && !_enPrimerPlano;
      if (!completadaDetras) await _seguro(avisos.cancelarFin);
    }
  }

  Future<void> _seguro(Future<void> Function() aviso) async {
    try {
      await aviso();
    } catch (e) {
      debugPrint('MotorSesion: aviso fallido: $e');
    }
  }

  void _reprogramar(int mono) {
    _tic?.cancel();
    _tic = null;
    if (_desechado) return;
    final s = _sesion.value;
    _restante.value = s == null ? Duration.zero : s.restante(mono);
    if (s == null || !s.estado.activa) return;
    if (_enPrimerPlano) {
      _tic = Timer(const Duration(seconds: 1), _tictac);
      return;
    }
    // Con la app detrás, un solo despertar: la meta o el fin de la gracia, lo
    // que llegue antes (+1 ms: la gracia vence pasado su borde, no en él).
    var objetivo = s.metaMonoMs!;
    final finGracia = s.finGraciaMonoMs;
    if (finGracia != null && finGracia + 1 < objetivo) objetivo = finGracia + 1;
    _tic = Timer(Duration(milliseconds: math.max(0, objetivo - mono)), _tictac);
  }

  Future<SesionConcentracion?> _leer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final crudo = prefs.getString(clavePreferencias);
      if (crudo == null) return null;
      final s = SesionConcentracion.fromJson(
        (jsonDecode(crudo) as Map).cast<String, Object?>(),
      );
      if (s == null) {
        debugPrint('MotorSesion: sesión guardada ilegible, se descarta');
        await prefs.remove(clavePreferencias);
      }
      return s;
    } catch (e) {
      debugPrint('MotorSesion: no se pudo leer la sesión guardada: $e');
      return null;
    }
  }

  Future<void> _guardar(SesionConcentracion s) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(clavePreferencias, jsonEncode(s.toJson()));
    } catch (e) {
      debugPrint('MotorSesion: no se pudo guardar la sesión: $e');
    }
  }

  Future<T> _enCola<T>(Future<T> Function() op) {
    final r = _cola.then((_) => op());
    _cola = r.then<void>((_) {}, onError: (_) {});
    return r;
  }
}
