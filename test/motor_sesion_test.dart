import 'dart:convert';
import 'dart:ui' show AppLifecycleState;

import 'package:flutter_test/flutter_test.dart';
import 'package:norday_flutter_core/services/motor_sesion.dart';
import 'package:norday_flutter_core/services/sesion_concentracion.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Reloj a mano: el test lo avanza a la vez que el tiempo falso de
/// `testWidgets`.
class RelojFalso implements FuenteReloj {
  int mono = 5000000;
  DateTime utc = DateTime.utc(2026, 11, 15, 9);

  void avanzar(Duration d) {
    mono += d.inMilliseconds;
    utc = utc.add(d);
  }

  @override
  Future<int> monotonicoMs() async => mono;

  @override
  DateTime ahoraUtc() => utc;
}

/// Contesta lo que diga [respuestas] (en orden) y, agotadas, [valor].
class PantallaFalsa implements FuentePantalla {
  bool valor = true;
  final List<bool> respuestas = [];
  bool falla = false;
  int consultas = 0;

  /// Se llama en cada consulta, antes de contestar, con su número (desde 1).
  void Function(int consulta)? alConsultar;

  @override
  Future<bool> encendidaYDesbloqueada() async {
    consultas++;
    alConsultar?.call(consultas);
    if (falla) throw StateError('canal roto');
    return respuestas.isNotEmpty ? respuestas.removeAt(0) : valor;
  }
}

class AvisosFalsos implements AvisosSesion {
  final List<String> llamadas = [];
  Duration? ultimaGracia;
  DateTime? ultimoFin;

  @override
  Future<void> avisarGracia(Duration quedan) async {
    ultimaGracia = quedan;
    llamadas.add('gracia');
  }

  @override
  Future<void> cancelarGracia() async => llamadas.add('-gracia');

  @override
  Future<void> programarFin(DateTime finUtc) async {
    ultimoFin = finUtc;
    llamadas.add('fin');
  }

  @override
  Future<void> cancelarFin() async => llamadas.add('-fin');
}

void main() {
  const clave = 'sesion_concentracion_actual';
  late RelojFalso reloj;
  late PantallaFalsa pantalla;
  late AvisosFalsos avisos;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    reloj = RelojFalso();
    pantalla = PantallaFalsa();
    avisos = AvisosFalsos();
  });

  /// Cada motor se desecha al acabar el test aunque falle: si no, seguiría
  /// escuchando el binding, que es el mismo para todos los tests.
  MotorSesion nuevoMotor(WidgetTester tester) {
    final motor = MotorSesion(
      reloj: reloj,
      pantalla: pantalla,
      avisos: avisos,
      binding: tester.binding,
    );
    addTearDown(motor.dispose);
    return motor;
  }

  /// Lleva el ciclo de vida por los pasos que da Android, de uno en uno.
  Future<void> ciclo(WidgetTester tester, List<AppLifecycleState> pasos) async {
    for (final p in pasos) {
      tester.binding.handleAppLifecycleStateChanged(p);
      await tester.pump();
    }
  }

  const irse = [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
  ];
  const volver = [
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ];

  /// Deja el binding en primer plano para el test siguiente.
  Future<void> alFrente(WidgetTester tester) async {
    final estado = tester.binding.lifecycleState;
    if (estado == AppLifecycleState.detached) {
      await ciclo(tester, [AppLifecycleState.resumed]);
    } else if (estado == AppLifecycleState.paused) {
      await ciclo(tester, volver);
    } else if (estado == AppLifecycleState.hidden) {
      await ciclo(tester, volver.sublist(1));
    } else if (estado == AppLifecycleState.inactive) {
      await ciclo(tester, [AppLifecycleState.resumed]);
    }
  }

  /// Pasa los 400 ms de la segunda consulta y lo que venga detrás.
  Future<void> segundaConsulta(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
  }

  Future<MotorSesion> empezado(WidgetTester tester) async {
    await alFrente(tester);
    final motor = nuevoMotor(tester);
    await motor.iniciar();
    await motor.empezar(duracionObjetivo: const Duration(minutes: 25));
    return motor;
  }

  Future<Map<String, Object?>?> guardada() async {
    final prefs = await SharedPreferences.getInstance();
    final crudo = prefs.getString(clave);
    return crudo == null ? null : jsonDecode(crudo) as Map<String, Object?>;
  }

  testWidgets('empezar guarda la sesión, programa el fin y cuenta atrás', (
    tester,
  ) async {
    final motor = await empezado(tester);
    final s = motor.sesion.value!;
    expect(s.estado, EstadoSesion.corriendo);
    expect((await guardada())!['estado'], 'corriendo');
    expect(avisos.llamadas, ['fin']);
    expect(avisos.ultimoFin, reloj.utc.add(const Duration(minutes: 25)));
    expect(motor.restante.value, const Duration(minutes: 25));

    reloj.avanzar(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(motor.restante.value, const Duration(minutes: 24, seconds: 59));
    motor.dispose();
  });

  testWidgets('sin iniciar, o con otra sesión en marcha, empezar lanza', (
    tester,
  ) async {
    final suelto = nuevoMotor(tester);
    await expectLater(
      suelto.empezar(duracionObjetivo: const Duration(minutes: 25)),
      throwsStateError,
    );
    suelto.dispose();

    final motor = await empezado(tester);
    await expectLater(
      motor.empezar(duracionObjetivo: const Duration(minutes: 25)),
      throwsStateError,
    );
    motor.dispose();
  });

  testWidgets('salir con la pantalla encendida y volver a tiempo', (
    tester,
  ) async {
    final motor = await empezado(tester);
    await ciclo(tester, irse);
    // Entre la primera consulta y la segunda todavía no ha salido.
    expect(motor.sesion.value!.estado, EstadoSesion.corriendo);
    reloj.avanzar(const Duration(milliseconds: 400));
    await segundaConsulta(tester);
    expect(pantalla.consultas, 2);
    expect(motor.sesion.value!.estado, EstadoSesion.enGracia);
    expect((await guardada())!['estado'], 'enGracia');
    // Al salir: aviso de gracia y fuera el de fin (si no vuelve, no hay fin).
    expect(avisos.llamadas, ['fin', 'gracia', '-fin']);
    // La gracia se mide desde el `paused`: ya se han ido 400 ms.
    expect(avisos.ultimaGracia, const Duration(milliseconds: 9600));

    reloj.avanzar(const Duration(seconds: 5));
    await ciclo(tester, volver);
    expect(motor.sesion.value!.estado, EstadoSesion.corriendo);
    // Al volver: fuera el de gracia y otra vez el de fin, a la hora que toca.
    expect(avisos.llamadas, ['fin', 'gracia', '-fin', '-gracia', 'fin']);
    final restante = motor.sesion.value!.restante(reloj.mono);
    expect(avisos.ultimoFin, reloj.utc.add(restante));
    motor.dispose();
  });

  testWidgets('volver pasada la gracia: perdida, y fuera los avisos', (
    tester,
  ) async {
    final motor = await empezado(tester);
    await ciclo(tester, irse);
    await segundaConsulta(tester);
    expect(motor.sesion.value!.estado, EstadoSesion.enGracia);

    // Con el proceso dormido no salta ningún temporizador: se ve al volver.
    reloj.avanzar(const Duration(seconds: 11));
    await ciclo(tester, volver);
    final s = motor.sesion.value!;
    expect(s.estado, EstadoSesion.perdida);
    expect(s.motivoPerdida, MotivoPerdida.salida);
    expect(avisos.llamadas, containsAllInOrder(['-gracia', '-fin']));
    expect((await guardada())!['estado'], 'perdida');
    motor.dispose();
  });

  testWidgets('la gracia vence con la app detrás y el proceso vivo', (
    tester,
  ) async {
    final motor = await empezado(tester);
    await ciclo(tester, irse);
    await segundaConsulta(tester);
    expect(motor.sesion.value!.estado, EstadoSesion.enGracia);

    reloj.avanzar(const Duration(milliseconds: 10001));
    await tester.pump(const Duration(milliseconds: 10001));
    await tester.pump();
    expect(motor.sesion.value!.estado, EstadoSesion.perdida);
    motor.dispose();
  });

  testWidgets('la meta llega dentro de la gracia con la app detrás: '
      'completada, y sale el aviso de fin', (tester) async {
    final motor = await empezado(tester);
    reloj.avanzar(const Duration(minutes: 24, seconds: 55));
    await tester.pump(const Duration(seconds: 1));
    await ciclo(tester, irse);
    await segundaConsulta(tester);
    expect(motor.sesion.value!.estado, EstadoSesion.enGracia);

    reloj.avanzar(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    final s = motor.sesion.value!;
    expect(s.estado, EstadoSesion.completada);
    expect(s.minutos, 25);
    expect(avisos.llamadas.sublist(1), ['gracia', '-fin', '-gracia', 'fin']);
    motor.dispose();
  });

  testWidgets('paused con la pantalla apagada no es salir', (tester) async {
    pantalla.valor = false;
    final motor = await empezado(tester);
    await ciclo(tester, irse);
    await segundaConsulta(tester);
    expect(motor.sesion.value!.estado, EstadoSesion.corriendo);
    expect(pantalla.consultas, 1);
    expect(avisos.llamadas, ['fin']);
    motor.dispose();
  });

  testWidgets('encendida en la primera consulta y apagada en la segunda: '
      'no es salir', (tester) async {
    pantalla.respuestas.addAll([true, false]);
    final motor = await empezado(tester);
    await ciclo(tester, irse);
    await segundaConsulta(tester);
    expect(pantalla.consultas, 2);
    expect(motor.sesion.value!.estado, EstadoSesion.corriendo);
    motor.dispose();
  });

  testWidgets('inactive (cortinilla, llamada) no consulta ni cuenta', (
    tester,
  ) async {
    final motor = await empezado(tester);
    await ciclo(tester, [AppLifecycleState.inactive]);
    await tester.pump(const Duration(seconds: 1));
    expect(pantalla.consultas, 0);
    expect(motor.sesion.value!.estado, EstadoSesion.corriendo);
    await ciclo(tester, [AppLifecycleState.resumed]);
    expect(motor.sesion.value!.estado, EstadoSesion.corriendo);
    motor.dispose();
  });

  testWidgets('si vuelve antes de la segunda consulta, no sale', (
    tester,
  ) async {
    final motor = await empezado(tester);
    await ciclo(tester, irse);
    expect(pantalla.consultas, 1);
    await ciclo(tester, volver);
    await segundaConsulta(tester);
    expect(pantalla.consultas, 1);
    expect(motor.sesion.value!.estado, EstadoSesion.corriendo);
    expect(avisos.llamadas, ['fin']);
    motor.dispose();
  });

  testWidgets('si la pantalla no responde, no sale', (tester) async {
    pantalla.falla = true;
    final motor = await empezado(tester);
    await ciclo(tester, irse);
    await segundaConsulta(tester);
    expect(motor.sesion.value!.estado, EstadoSesion.corriendo);
    motor.dispose();
  });

  testWidgets('con la app delante, el temporizador la completa en la meta', (
    tester,
  ) async {
    final motor = await empezado(tester);
    reloj.avanzar(const Duration(minutes: 25));
    await tester.pump(const Duration(seconds: 1));
    final s = motor.sesion.value!;
    expect(s.estado, EstadoSesion.completada);
    expect(s.minutos, 25);
    expect(motor.restante.value, Duration.zero);
    // Delante: el aviso de fin sobra.
    expect(avisos.llamadas.last, '-fin');
    motor.dispose();
  });

  testWidgets('completada con la pantalla apagada: el aviso de fin se queda', (
    tester,
  ) async {
    pantalla.valor = false;
    final motor = await empezado(tester);
    await ciclo(tester, irse);
    await segundaConsulta(tester);
    reloj.avanzar(const Duration(minutes: 25));
    await tester.pump(const Duration(minutes: 25));
    await tester.pump();
    expect(motor.sesion.value!.estado, EstadoSesion.completada);
    expect(avisos.llamadas, ['fin']);
    motor.dispose();
  });

  testWidgets('terminar antes del mínimo descarta; cerrar borra lo guardado', (
    tester,
  ) async {
    final motor = await empezado(tester);
    reloj.avanzar(const Duration(minutes: 9, seconds: 59));
    final s = await motor.terminar();
    expect(s!.estado, EstadoSesion.descartada);
    expect(avisos.llamadas.last, '-fin');
    expect(await guardada(), isNotNull);

    await motor.cerrar();
    expect(motor.sesion.value, isNull);
    expect(await guardada(), isNull);
    // Cerrada, se puede empezar otra.
    await motor.empezar(duracionObjetivo: const Duration(minutes: 10));
    expect(motor.sesion.value!.estado, EstadoSesion.corriendo);
    motor.dispose();
  });

  testWidgets('terminar a los 10 min cuenta; rendirse pierde', (tester) async {
    final motor = await empezado(tester);
    reloj.avanzar(const Duration(minutes: 10));
    expect((await motor.terminar())!.minutos, 10);
    await motor.cerrar();

    await motor.empezar(duracionObjetivo: const Duration(minutes: 25));
    reloj.avanzar(const Duration(minutes: 15));
    final s = await motor.rendirse();
    expect(s!.estado, EstadoSesion.perdida);
    expect(s.motivoPerdida, MotivoPerdida.rendicion);
    motor.dispose();
  });

  testWidgets('cerrar una sesión activa lanza', (tester) async {
    final motor = await empezado(tester);
    await expectLater(motor.cerrar(), throwsStateError);
    motor.dispose();
  });

  testWidgets('la primera consulta positiva deja una marca guardada; la '
      'segunda negativa la borra', (tester) async {
    pantalla.respuestas.addAll([true, false]);
    final motor = await empezado(tester);
    await ciclo(tester, irse);
    expect((await guardada())!['salidaPendienteMonoMs'], reloj.mono);
    await segundaConsulta(tester);
    expect(motor.sesion.value!.estado, EstadoSesion.corriendo);
    expect((await guardada())!['salidaPendienteMonoMs'], isNull);
    motor.dispose();
  });

  testWidgets('resumed durante la segunda consulta: el salir encolado no se '
      'aplica', (tester) async {
    final motor = await empezado(tester);
    pantalla.alConsultar = (n) {
      if (n == 2) {
        for (final p in volver) {
          tester.binding.handleAppLifecycleStateChanged(p);
        }
      }
    };
    await ciclo(tester, irse);
    await segundaConsulta(tester);
    await tester.pump();
    expect(pantalla.consultas, 2);
    expect(motor.sesion.value!.estado, EstadoSesion.corriendo);
    expect(avisos.llamadas, isNot(contains('gracia')));
    expect((await guardada())!['salidaPendienteMonoMs'], isNull);
    motor.dispose();
  });

  testWidgets('detached con la pantalla encendida sale sin esperar, desde la '
      'marca', (tester) async {
    final motor = await empezado(tester);
    await ciclo(tester, irse);
    final marca = reloj.mono;
    reloj.avanzar(const Duration(milliseconds: 100));
    await ciclo(tester, [AppLifecycleState.detached]);
    expect(motor.sesion.value!.estado, EstadoSesion.enGracia);
    expect(motor.sesion.value!.salidaMonoMs, marca);
    expect((await guardada())!['estado'], 'enGracia');
    // La consulta de los 400 ms ya no hace nada.
    await segundaConsulta(tester);
    expect(motor.sesion.value!.salidaMonoMs, marca);
    motor.dispose();
    await ciclo(tester, [AppLifecycleState.resumed]);
  });

  testWidgets('detached con la pantalla apagada no es salir y quita la marca', (
    tester,
  ) async {
    pantalla.respuestas.addAll([true, false]);
    final motor = await empezado(tester);
    await ciclo(tester, irse);
    await ciclo(tester, [AppLifecycleState.detached]);
    expect(motor.sesion.value!.estado, EstadoSesion.corriendo);
    expect((await guardada())!['salidaPendienteMonoMs'], isNull);
    await segundaConsulta(tester);
    motor.dispose();
    await ciclo(tester, [AppLifecycleState.resumed]);
  });

  group('bloquear, desbloquear y salir sin pasar por resumed', () {
    testWidgets(
      'avisarDesbloqueo con la app en paused hace la doble consulta',
      (tester) async {
        pantalla.valor = false;
        final motor = await empezado(tester);
        await ciclo(tester, irse);
        await segundaConsulta(tester);
        expect(motor.sesion.value!.estado, EstadoSesion.corriendo);

        // Desbloquea y, sin volver a la app, abre otra.
        pantalla.valor = true;
        reloj.avanzar(const Duration(seconds: 1));
        final desbloqueo = reloj.mono;
        final aviso = motor.avisarDesbloqueo();
        await tester.pump();
        await segundaConsulta(tester);
        await aviso;
        expect(motor.sesion.value!.estado, EstadoSesion.enGracia);
        expect(motor.sesion.value!.salidaMonoMs, desbloqueo);
        motor.dispose();
      },
    );

    testWidgets('avisarDesbloqueo con la app delante no consulta nada', (
      tester,
    ) async {
      final motor = await empezado(tester);
      await motor.avisarDesbloqueo();
      await segundaConsulta(tester);
      expect(pantalla.consultas, 0);
      motor.dispose();
    });

    testWidgets('en paused, la pantalla se vigila cada 2 s', (tester) async {
      pantalla.valor = false;
      final motor = await empezado(tester);
      await ciclo(tester, irse);
      await segundaConsulta(tester);
      expect(pantalla.consultas, 1);

      reloj.avanzar(const Duration(milliseconds: 1600));
      await tester.pump(const Duration(milliseconds: 1600));
      expect(pantalla.consultas, 2);
      reloj.avanzar(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));
      expect(pantalla.consultas, 3);

      pantalla.valor = true;
      reloj.avanzar(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));
      reloj.avanzar(const Duration(milliseconds: 400));
      await segundaConsulta(tester);
      expect(motor.sesion.value!.estado, EstadoSesion.enGracia);

      // En gracia ya no se vigila.
      final antes = pantalla.consultas;
      await tester.pump(const Duration(seconds: 5));
      expect(pantalla.consultas, antes);
      motor.dispose();
    });

    testWidgets('al volver se deja de vigilar', (tester) async {
      pantalla.valor = false;
      final motor = await empezado(tester);
      await ciclo(tester, irse);
      await segundaConsulta(tester);
      await ciclo(tester, volver);
      final antes = pantalla.consultas;
      await tester.pump(const Duration(seconds: 7));
      expect(pantalla.consultas, antes);
      motor.dispose();
    });
  });

  group('recomposición al reabrir', () {
    testWidgets('muerto en la ventana de 400 ms y reabierto tras la meta: '
        'perdida', (tester) async {
      final primero = await empezado(tester);
      await ciclo(tester, irse);
      // El proceso muere antes de la segunda consulta.
      primero.dispose();
      await segundaConsulta(tester);
      await ciclo(tester, volver);

      reloj.avanzar(const Duration(minutes: 30));
      final motor = nuevoMotor(tester);
      final s = await motor.iniciar();
      expect(s!.estado, EstadoSesion.perdida);
      expect(s.motivoPerdida, MotivoPerdida.salida);
      motor.dispose();
    });

    testWidgets('sigue corriendo donde iba y reprograma el fin', (
      tester,
    ) async {
      final primero = await empezado(tester);
      primero.dispose();
      reloj.avanzar(const Duration(minutes: 3));
      avisos.llamadas.clear();

      final motor = nuevoMotor(tester);
      final s = await motor.iniciar();
      expect(s!.estado, EstadoSesion.corriendo);
      expect(motor.restante.value, const Duration(minutes: 22));
      expect(avisos.llamadas, ['fin']);
      motor.dispose();
    });

    testWidgets('el móvil se reinició: perdida por reinicio', (tester) async {
      final primero = await empezado(tester);
      primero.dispose();
      reloj.mono = 20000; // el monótono vuelve a contar desde cero
      reloj.utc = reloj.utc.add(const Duration(minutes: 2));

      final motor = nuevoMotor(tester);
      final s = await motor.iniciar();
      expect(s!.estado, EstadoSesion.perdida);
      expect(s.motivoPerdida, MotivoPerdida.reinicio);
      expect((await guardada())!['motivoPerdida'], 'reinicio');
      motor.dispose();
    });

    testWidgets('muerto en la gracia y reabierto a tiempo: sigue', (
      tester,
    ) async {
      final primero = await empezado(tester);
      await ciclo(tester, irse);
      await segundaConsulta(tester);
      expect(primero.sesion.value!.estado, EstadoSesion.enGracia);
      primero.dispose();
      await ciclo(tester, volver);

      reloj.avanzar(const Duration(seconds: 5));
      final motor = nuevoMotor(tester);
      expect((await motor.iniciar())!.estado, EstadoSesion.corriendo);
      expect(avisos.llamadas, contains('-gracia'));
      motor.dispose();
    });

    testWidgets('muerto en la gracia y reabierto tarde: perdida', (
      tester,
    ) async {
      final primero = await empezado(tester);
      await ciclo(tester, irse);
      await segundaConsulta(tester);
      primero.dispose();
      await ciclo(tester, volver);

      reloj.avanzar(const Duration(seconds: 30));
      final motor = nuevoMotor(tester);
      final s = await motor.iniciar();
      expect(s!.estado, EstadoSesion.perdida);
      expect(s.motivoPerdida, MotivoPerdida.salida);
      motor.dispose();
    });

    testWidgets('una sesión acabada sin cerrar sigue ahí para recogerla', (
      tester,
    ) async {
      final primero = await empezado(tester);
      reloj.avanzar(const Duration(minutes: 12));
      await primero.terminar();
      primero.dispose();

      final motor = nuevoMotor(tester);
      final s = await motor.iniciar();
      expect(s!.estado, EstadoSesion.terminada);
      expect(s.minutos, 12);
      motor.dispose();
    });

    testWidgets('lo guardado ilegible se descarta', (tester) async {
      SharedPreferences.setMockInitialValues({clave: '{"version":1}'});
      await alFrente(tester);
      final motor = nuevoMotor(tester);
      expect(await motor.iniciar(), isNull);
      expect(await guardada(), isNull);
      motor.dispose();
    });
  });
}
