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
    final martes = ProgresoDia(hechos: 3, total: 7, fecha: DateTime(2026, 8, 25));
    final miercoles = ProgresoDia(hechos: 3, total: 7, fecha: DateTime(2026, 8, 26));

    expect(martes, isNot(miercoles));
  });

  test('publicarProgresoDia guarda la fecha a medianoche aunque llegue con hora', () {
    publicarProgresoDia(hechos: 2, total: 5, fecha: DateTime(2026, 8, 25, 14, 30));

    expect(progresoDiaNotifier.value.fecha, DateTime(2026, 8, 25));
  });

  test('escribir dos veces el mismo valor dispara un solo aviso', () {
    var avisos = 0;
    void listener() => avisos++;

    progresoDiaNotifier.addListener(listener);
    publicarProgresoDia(hechos: 1, total: 4, fecha: DateTime(2026, 8, 25));
    publicarProgresoDia(hechos: 1, total: 4, fecha: DateTime(2026, 8, 25));
    progresoDiaNotifier.removeListener(listener);

    expect(avisos, 1);
  });
}
