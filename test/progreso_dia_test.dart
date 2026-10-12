import 'package:flutter_test/flutter_test.dart';
import 'package:norday_flutter_core/theme/progreso_dia.dart';

void main() {
  tearDown(limpiarProgresoDia);

  test('mismos hechos, total y fecha son iguales y comparten hashCode', () {
    final a = ProgresoDia(hechos: 3, total: 7, fecha: DateTime(2026, 8, 25));
    final b = ProgresoDia(hechos: 3, total: 7, fecha: DateTime(2026, 8, 25));

    expect(a, b);
    expect(a.hashCode, b.hashCode);
  });

  test('mismos contadores pero fecha distinta no son iguales', () {
    final martes = ProgresoDia(
      hechos: 3,
      total: 7,
      fecha: DateTime(2026, 8, 25),
    );
    final miercoles = ProgresoDia(
      hechos: 3,
      total: 7,
      fecha: DateTime(2026, 8, 26),
    );

    expect(martes, isNot(miercoles));
  });

  test(
    'publicarProgresoDia guarda la fecha a medianoche aunque llegue con hora',
    () {
      publicarProgresoDia(
        hechos: 2,
        total: 5,
        fecha: DateTime(2026, 8, 25, 14, 30),
      );

      expect(progresoDiaNotifier.value.fecha, DateTime(2026, 8, 25));
    },
  );

  test('escribir dos veces el mismo valor dispara un solo aviso', () {
    var avisos = 0;
    void listener() => avisos++;

    progresoDiaNotifier.addListener(listener);
    publicarProgresoDia(hechos: 1, total: 4, fecha: DateTime(2026, 8, 25));
    publicarProgresoDia(hechos: 1, total: 4, fecha: DateTime(2026, 8, 25));
    progresoDiaNotifier.removeListener(listener);

    expect(avisos, 1);
  });

  test('marcarDiaCerrado avisa y limpiarProgresoDia lo apaga', () {
    marcarDiaCerrado(true);
    expect(diaCerradoNotifier.value, isTrue);

    limpiarProgresoDia();
    expect(diaCerradoNotifier.value, isFalse);
  });

  test('sin avance, el avance es hechos entre total', () {
    publicarProgresoDia(hechos: 2, total: 5, fecha: DateTime(2026, 10, 12));
    expect(progresoDiaNotifier.value.avance, closeTo(0.4, 1e-12));
  });

  test('sin nada que hacer, todo a cero', () {
    publicarProgresoDia(hechos: 0, total: 0, fecha: DateTime(2026, 10, 12));
    final p = progresoDiaNotifier.value;
    expect(p.avance, 0.0);
    expect(p.completas, 0);
    expect(p.resto, 0.0);
  });

  test('el avance se recorta entre 0 y 1', () {
    publicarProgresoDia(
      hechos: 3,
      total: 3,
      fecha: DateTime(2026, 10, 12),
      avance: 1.3,
    );
    expect(progresoDiaNotifier.value.avance, 1.0);
    publicarProgresoDia(
      hechos: 0,
      total: 3,
      fecha: DateTime(2026, 10, 12),
      avance: -0.2,
    );
    expect(progresoDiaNotifier.value.avance, 0.0);
  });

  test('mismos contadores con distinto avance no son iguales', () {
    final a = ProgresoDia(
      hechos: 1,
      total: 3,
      avance: 0.5,
      fecha: DateTime(2026, 10, 12),
    );
    final b = ProgresoDia(
      hechos: 1,
      total: 3,
      avance: 0.6,
      fecha: DateTime(2026, 10, 12),
    );
    expect(a, isNot(b));
  });

  test(
    'un avance a medias enciende las enteras y deja el resto en la siguiente',
    () {
      publicarProgresoDia(
        hechos: 0,
        total: 3,
        fecha: DateTime(2026, 10, 12),
        avance: 0.42,
      );
      final p = progresoDiaNotifier.value;
      expect(p.completas, 1);
      expect(p.resto, closeTo(0.26, 1e-9));
    },
  );

  test('un avance exacto no deja resto', () {
    publicarProgresoDia(
      hechos: 1,
      total: 4,
      fecha: DateTime(2026, 10, 12),
      avance: 0.75,
    );
    final p = progresoDiaNotifier.value;
    expect(p.completas, 3);
    expect(p.resto, closeTo(0, 1e-9));
  });

  test('dos tercios de tres son dos enteras, sin error de redondeo', () {
    publicarProgresoDia(
      hechos: 0,
      total: 3,
      fecha: DateTime(2026, 10, 12),
      avance: 2 / 3,
    );
    final p = progresoDiaNotifier.value;
    expect(p.completas, 2);
    expect(p.resto, closeTo(0, 1e-9));
  });

  test('todo hecho: todas enteras y sin resto', () {
    publicarProgresoDia(hechos: 3, total: 3, fecha: DateTime(2026, 10, 12));
    final p = progresoDiaNotifier.value;
    expect(p.completas, 3);
    expect(p.resto, 0.0);
  });
}
