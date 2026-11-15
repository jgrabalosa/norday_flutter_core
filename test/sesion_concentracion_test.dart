import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:norday_flutter_core/services/sesion_concentracion.dart';

/// La máquina de estados pura: sin reloj ni plataforma, cada transición
/// recibe el monótono en milisegundos.
void main() {
  const seg = 1000;
  const min = 60 * seg;
  const inicio = 1000000; // monótono al empezar
  final inicioUtc = DateTime.utc(2026, 11, 15, 9);

  SesionConcentracion corriendo({
    Duration objetivo = const Duration(minutes: 25),
    ReglasSesion reglas = const ReglasSesion(),
  }) => SesionConcentracion.preparar(
    duracionObjetivo: objetivo,
    reglas: reglas,
  ).empezar(monoMs: inicio, ahoraUtc: inicioUtc);

  group('preparar y empezar', () {
    test('preparada no tiene inicio y genera un UUID v4', () {
      final s = SesionConcentracion.preparar(
        duracionObjetivo: const Duration(minutes: 25),
      );
      expect(s.estado, EstadoSesion.preparada);
      expect(s.inicioMonoMs, isNull);
      expect(s.inicioUtc, isNull);
      expect(
        s.clave,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
      final otra = SesionConcentracion.preparar(
        duracionObjetivo: const Duration(minutes: 25),
      );
      expect(otra.clave, isNot(s.clave));
    });

    test('una duración no positiva no se acepta', () {
      expect(
        () => SesionConcentracion.preparar(duracionObjetivo: Duration.zero),
        throwsArgumentError,
      );
    });

    test('datosApp que no pasa por JSON no se acepta', () {
      expect(
        () => SesionConcentracion.preparar(
          duracionObjetivo: const Duration(minutes: 25),
          datosApp: {'x': DateTime(2026)},
        ),
        throwsArgumentError,
      );
    });

    test('empezar fija el inicio y pasa a corriendo; dos veces, lanza', () {
      final s = corriendo();
      expect(s.estado, EstadoSesion.corriendo);
      expect(s.inicioMonoMs, inicio);
      expect(s.inicioUtc, inicioUtc);
      expect(
        () => s.empezar(monoMs: inicio, ahoraUtc: inicioUtc),
        throwsStateError,
      );
    });
  });

  group('fin por tiempo', () {
    test('un milisegundo antes de la meta sigue corriendo', () {
      final s = corriendo().actualizar(inicio + 25 * min - 1);
      expect(s.estado, EstadoSesion.corriendo);
      expect(
        s.restante(inicio + 25 * min - 1),
        const Duration(milliseconds: 1),
      );
    });

    test('en la meta, completada con el fin en la meta y sus minutos', () {
      final s = corriendo().actualizar(inicio + 25 * min);
      expect(s.estado, EstadoSesion.completada);
      expect(s.finMonoMs, inicio + 25 * min);
      expect(s.minutos, 25);
    });

    test('detectada tarde, el fin sigue siendo la meta', () {
      final s = corriendo().actualizar(inicio + 90 * min);
      expect(s.estado, EstadoSesion.completada);
      expect(s.duracion, const Duration(minutes: 25));
      expect(s.minutos, 25);
    });
  });

  group('gracia', () {
    test('salir pasa a enGracia desde ese instante', () {
      final s = corriendo().salir(inicio + 5 * min);
      expect(s.estado, EstadoSesion.enGracia);
      expect(s.salidaMonoMs, inicio + 5 * min);
      expect(s.finGraciaMonoMs, inicio + 5 * min + 10 * seg);
    });

    test('volver justo a los 10 s todavía vale', () {
      final s = corriendo()
          .salir(inicio + 5 * min)
          .volver(inicio + 5 * min + 10 * seg);
      expect(s.estado, EstadoSesion.corriendo);
      expect(s.salidaMonoMs, isNull);
    });

    test('volver un milisegundo después de la gracia: perdida por salida', () {
      final s = corriendo()
          .salir(inicio + 5 * min)
          .volver(inicio + 5 * min + 10 * seg + 1);
      expect(s.estado, EstadoSesion.perdida);
      expect(s.motivoPerdida, MotivoPerdida.salida);
      expect(s.finMonoMs, inicio + 5 * min);
      expect(s.minutos, 0);
    });

    test('la gracia vence sola, sin volver', () {
      final enGracia = corriendo().salir(inicio + 5 * min);
      expect(
        enGracia.actualizar(inicio + 5 * min + 10 * seg).estado,
        EstadoSesion.enGracia,
      );
      expect(
        enGracia.actualizar(inicio + 5 * min + 10 * seg + 1).estado,
        EstadoSesion.perdida,
      );
    });

    test('si la meta llega dentro de la gracia, completada', () {
      final s = corriendo()
          .salir(inicio + 25 * min - 5 * seg)
          .actualizar(inicio + 25 * min + 30 * seg);
      expect(s.estado, EstadoSesion.completada);
      expect(s.finMonoMs, inicio + 25 * min);
      expect(s.minutos, 25);
    });

    test('si la meta llega después de la gracia, perdida', () {
      final s = corriendo()
          .salir(inicio + 25 * min - 11 * seg)
          .actualizar(inicio + 25 * min);
      expect(s.estado, EstadoSesion.perdida);
      expect(s.motivoPerdida, MotivoPerdida.salida);
    });

    test('salir dos veces no mueve el inicio de la gracia', () {
      final s = corriendo()
          .salir(inicio + 5 * min)
          .salir(inicio + 5 * min + 5 * seg);
      expect(s.salidaMonoMs, inicio + 5 * min);
    });

    test('una gracia configurada a 3 s', () {
      final s = corriendo(
        reglas: const ReglasSesion(gracia: Duration(seconds: 3)),
      ).salir(inicio + min);
      expect(s.volver(inicio + min + 3 * seg).estado, EstadoSesion.corriendo);
      expect(s.volver(inicio + min + 3 * seg + 1).estado, EstadoSesion.perdida);
    });
  });

  group('terminar antes', () {
    test('a 9:59 se descarta, sin minutos y sin castigo', () {
      final s = corriendo().terminar(inicio + 10 * min - seg);
      expect(s.estado, EstadoSesion.descartada);
      expect(s.minutos, 0);
      expect(s.motivoPerdida, isNull);
    });

    test('a 9:59.999 también se descarta', () {
      expect(
        corriendo().terminar(inicio + 10 * min - 1).estado,
        EstadoSesion.descartada,
      );
    });

    test('a 10:00 cuenta con 10 minutos', () {
      final s = corriendo().terminar(inicio + 10 * min);
      expect(s.estado, EstadoSesion.terminada);
      expect(s.minutos, 10);
    });

    test('los minutos se redondean hacia abajo', () {
      final s = corriendo().terminar(inicio + 17 * min + 59 * seg);
      expect(s.estado, EstadoSesion.terminada);
      expect(s.minutos, 17);
      expect(s.duracion, const Duration(minutes: 17, seconds: 59));
    });

    test('un mínimo configurado a 1 minuto', () {
      final s = corriendo(
        reglas: const ReglasSesion(minimoParaContar: Duration(minutes: 1)),
      );
      expect(s.terminar(inicio + min).estado, EstadoSesion.terminada);
      expect(s.terminar(inicio + min - 1).estado, EstadoSesion.descartada);
    });

    test('pasada la meta, terminar da completada', () {
      expect(
        corriendo().terminar(inicio + 26 * min).estado,
        EstadoSesion.completada,
      );
    });

    test('terminar desde la gracia (dentro) cuenta igual', () {
      final s = corriendo()
          .salir(inicio + 12 * min)
          .terminar(inicio + 12 * min + 2 * seg);
      expect(s.estado, EstadoSesion.terminada);
      expect(s.minutos, 12);
    });
  });

  group('rendirse', () {
    test('perdida por rendición aunque lleve el mínimo', () {
      final s = corriendo().rendirse(inicio + 20 * min);
      expect(s.estado, EstadoSesion.perdida);
      expect(s.motivoPerdida, MotivoPerdida.rendicion);
      expect(s.minutos, 0);
      expect(s.duracion, const Duration(minutes: 20));
    });

    test('pasada la meta, sigue completada', () {
      expect(
        corriendo().rendirse(inicio + 25 * min).estado,
        EstadoSesion.completada,
      );
    });

    test('desde la gracia, también perdida por rendición', () {
      final s = corriendo().salir(inicio + min).rendirse(inicio + min + seg);
      expect(s.motivoPerdida, MotivoPerdida.rendicion);
    });
  });

  group('los estados finales no cambian', () {
    final finales = {
      'completada': corriendo().actualizar(inicio + 25 * min),
      'terminada': corriendo().terminar(inicio + 15 * min),
      'descartada': corriendo().terminar(inicio + min),
      'perdida': corriendo().rendirse(inicio + min),
    };
    finales.forEach((nombre, s) {
      test(nombre, () {
        final m = inicio + 200 * min;
        expect(s.estado.esFinal, isTrue);
        expect(s.salir(m), same(s));
        expect(s.volver(m), same(s));
        expect(s.actualizar(m), same(s));
        expect(s.terminar(m), same(s));
        expect(s.rendirse(m), same(s));
        expect(s.recomponer(monoMs: 0, ahoraUtc: inicioUtc), same(s));
        expect(s.restante(m), Duration.zero);
      });
    });
  });

  group('reinicio y recomposición', () {
    test('monótono por debajo del inicio: perdida por reinicio', () {
      final s = corriendo().actualizar(5 * seg);
      expect(s.estado, EstadoSesion.perdida);
      expect(s.motivoPerdida, MotivoPerdida.reinicio);
      expect(s.minutos, 0);
    });

    test('recomponer en el mismo arranque sigue donde iba', () {
      final s = corriendo().recomponer(
        monoMs: inicio + 3 * min,
        ahoraUtc: inicioUtc.add(const Duration(minutes: 3)),
      );
      expect(s.estado, EstadoSesion.corriendo);
      expect(s.restante(inicio + 3 * min), const Duration(minutes: 22));
    });

    test('recomponer pasada la meta: completada', () {
      final s = corriendo().recomponer(
        monoMs: inicio + 40 * min,
        ahoraUtc: inicioUtc.add(const Duration(minutes: 40)),
      );
      expect(s.estado, EstadoSesion.completada);
    });

    test('recomponer con el monótono por debajo: reinicio', () {
      final s = corriendo().recomponer(
        monoMs: 30 * seg,
        ahoraUtc: inicioUtc.add(const Duration(minutes: 3)),
      );
      expect(s.motivoPerdida, MotivoPerdida.reinicio);
    });

    test('reinicio antiguo: el monótono ya ha pasado el inicio, pero el '
        'arranque del móvil no es el mismo', () {
      // Se reinició y el monótono volvió a pasar el inicio: sin mirar el
      // arranque, parecería que lleva 2 minutos.
      final s = corriendo().recomponer(
        monoMs: inicio + 2 * min,
        ahoraUtc: inicioUtc.add(const Duration(hours: 3)),
      );
      expect(s.estado, EstadoSesion.perdida);
      expect(s.motivoPerdida, MotivoPerdida.reinicio);
    });

    test('un ajuste de hora dentro de la tolerancia no es un reinicio', () {
      final s = corriendo().recomponer(
        monoMs: inicio + 3 * min,
        ahoraUtc: inicioUtc.add(const Duration(minutes: 3, seconds: 290)),
      );
      expect(s.estado, EstadoSesion.corriendo);
    });

    test('recomponer en gracia vencida: perdida por salida', () {
      final s = corriendo()
          .salir(inicio + min)
          .recomponer(
            monoMs: inicio + min + 30 * seg,
            ahoraUtc: inicioUtc.add(const Duration(minutes: 1, seconds: 30)),
          );
      expect(s.motivoPerdida, MotivoPerdida.salida);
    });

    test('recomponer en gracia viva la deja en gracia', () {
      final s = corriendo()
          .salir(inicio + min)
          .recomponer(
            monoMs: inicio + min + 4 * seg,
            ahoraUtc: inicioUtc.add(const Duration(minutes: 1, seconds: 4)),
          );
      expect(s.estado, EstadoSesion.enGracia);
    });
  });

  group('salida pendiente (entre las dos consultas de pantalla)', () {
    test('marcar no cambia el estado y salir la consume', () {
      final marcada = corriendo().marcarSalidaPendiente(inicio + min);
      expect(marcada.estado, EstadoSesion.corriendo);
      expect(marcada.salidaPendienteMonoMs, inicio + min);
      final fuera = marcada.salir(inicio + min);
      expect(fuera.estado, EstadoSesion.enGracia);
      expect(fuera.salidaPendienteMonoMs, isNull);
    });

    test('quitar la marca la borra; volver también', () {
      final marcada = corriendo().marcarSalidaPendiente(inicio + min);
      expect(marcada.quitarSalidaPendiente().salidaPendienteMonoMs, isNull);
      expect(marcada.volver(inicio + min + seg).salidaPendienteMonoMs, isNull);
    });

    test('solo se marca una sesión corriendo', () {
      final enGracia = corriendo().salir(inicio + min);
      expect(enGracia.marcarSalidaPendiente(inicio + 2 * min), same(enGracia));
    });

    test('recomponer con marca y la gracia vencida: perdida por salida', () {
      final s = corriendo()
          .marcarSalidaPendiente(inicio + min)
          .recomponer(
            monoMs: inicio + 30 * min,
            ahoraUtc: inicioUtc.add(const Duration(minutes: 30)),
          );
      expect(s.estado, EstadoSesion.perdida);
      expect(s.motivoPerdida, MotivoPerdida.salida);
      expect(s.finMonoMs, inicio + min);
    });

    test(
      'recomponer con marca dentro de la gracia: en gracia desde la marca',
      () {
        final s = corriendo()
            .marcarSalidaPendiente(inicio + min)
            .recomponer(
              monoMs: inicio + min + 3 * seg,
              ahoraUtc: inicioUtc.add(const Duration(minutes: 1, seconds: 3)),
            );
        expect(s.estado, EstadoSesion.enGracia);
        expect(s.salidaMonoMs, inicio + min);
      },
    );
  });

  group('JSON', () {
    final datos = <String, Object?>{'tipo': 'x', 'id': 7};
    final base = SesionConcentracion.preparar(
      duracionObjetivo: const Duration(minutes: 45),
      reglas: const ReglasSesion(
        gracia: Duration(seconds: 8),
        minimoParaContar: Duration(minutes: 5),
      ),
      datosApp: datos,
    );
    final enCurso = base.empezar(monoMs: inicio, ahoraUtc: inicioUtc);
    final casos = {
      'preparada': base,
      'corriendo': enCurso,
      'enGracia': enCurso.salir(inicio + min),
      'corriendo con marca': enCurso.marcarSalidaPendiente(inicio + min),
      'completada': enCurso.actualizar(inicio + 45 * min),
      'terminada': enCurso.terminar(inicio + 6 * min),
      'descartada': enCurso.terminar(inicio + min),
      'perdida': enCurso.rendirse(inicio + min),
    };
    casos.forEach((nombre, s) {
      test('ida y vuelta: $nombre', () {
        final texto = jsonEncode(s.toJson());
        final vuelta = SesionConcentracion.fromJson(
          (jsonDecode(texto) as Map).cast<String, Object?>(),
        );
        expect(vuelta, s);
        expect(vuelta!.datosApp, datos);
        expect(vuelta.reglas, s.reglas);
      });
    });

    test('lo que está fuera de rango o no cuadra con el estado da null', () {
      Map<String, Object?> con(
        SesionConcentracion base,
        Map<String, Object?> cambios,
      ) => {...base.toJson(), ...cambios};
      final completada = enCurso.actualizar(inicio + 45 * min);
      final perdida = enCurso.rendirse(inicio + min);
      final enGracia = enCurso.salir(inicio + min);
      final rotos = <String, Map<String, Object?>>{
        'objetivo cero': con(enCurso, {'objetivoMs': 0}),
        'gracia negativa': con(enCurso, {'graciaMs': -1}),
        'mínimo negativo': con(enCurso, {'minimoMs': -1}),
        'tolerancia negativa': con(enCurso, {'toleranciaArranqueMs': -1}),
        'clave vacía': con(enCurso, {'clave': ''}),
        'final sin fin': con(completada, {'finMonoMs': null}),
        'fin antes del inicio': con(completada, {'finMonoMs': inicio - 1}),
        'perdida sin motivo': con(perdida, {'motivoPerdida': null}),
        'completada con motivo': con(completada, {'motivoPerdida': 'salida'}),
        'gracia con salida antes del inicio': con(enGracia, {
          'salidaMonoMs': inicio - 1,
        }),
        'corriendo con salida': con(enCurso, {'salidaMonoMs': inicio + 1}),
        'corriendo con fin': con(enCurso, {'finMonoMs': inicio + 1}),
        'preparada con inicio': con(base, {'inicioMonoMs': inicio}),
        'monótono negativo': con(enCurso, {'inicioMonoMs': -5}),
      };
      rotos.forEach((nombre, json) {
        expect(SesionConcentracion.fromJson(json), isNull, reason: nombre);
      });
    });

    test('la versión del formato es la 1', () {
      expect(SesionConcentracion.versionFormato, 1);
      expect(enCurso.toJson()['version'], 1);
      final sinVersion = {...enCurso.toJson()}..remove('version');
      expect(SesionConcentracion.fromJson(sinVersion), isNull);
    });

    test('lo que no se entiende da null', () {
      expect(SesionConcentracion.fromJson({}), isNull);
      expect(
        SesionConcentracion.fromJson({...enCurso.toJson(), 'version': 99}),
        isNull,
      );
      expect(
        SesionConcentracion.fromJson({...enCurso.toJson(), 'estado': 'otro'}),
        isNull,
      );
      expect(
        SesionConcentracion.fromJson({
          ...enCurso.toJson(),
          'inicioMonoMs': null,
        }),
        isNull,
      );
    });
  });

  test('transcurrido no baja de cero ni pasa de la meta', () {
    final s = corriendo();
    expect(s.transcurrido(inicio + 30 * min), const Duration(minutes: 25));
    expect(s.transcurrido(inicio - 1), Duration.zero);
  });
}
