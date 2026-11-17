import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norday_flutter_core/widgets/burbuja_flotante.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _clave = Key('contenido');
const _size = 72.0;

Future<void> _montar(
  WidgetTester tester,
  Size area, {
  Color? colorZona,
  double minTopFraction = 0.5,
  bool vagabundeo = false,
}) async {
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: area.width,
          height: area.height,
          child: Stack(
            children: [
              BurbujaFlotante(
                storageKey: 'test_burbuja',
                areaSize: area,
                size: _size,
                minTopFraction: minTopFraction,
                vagabundeo: vagabundeo,
                colorZona: colorZona,
                behavior: HitTestBehavior.opaque,
                child: const SizedBox(
                  width: _size,
                  height: _size,
                  child: ColoredBox(key: _clave, color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

Future<void> _arrastrarMucho(WidgetTester tester) async {
  for (final o in const [
    Offset(0, 2000),
    Offset(2000, 0),
    Offset(0, -2000),
    Offset(-2000, 0),
  ]) {
    await tester.drag(find.byKey(_clave), o);
    await tester.pump();
  }
}

void main() {
  testWidgets('área baja: arrastrar no lanza y la burbuja queda dentro', (
    tester,
  ) async {
    const area = Size(360, 120);
    await _montar(tester, area, colorZona: Colors.red);
    await _arrastrarMucho(tester);

    expect(tester.takeException(), isNull);
    final p = tester.getTopLeft(find.byKey(_clave));
    expect(p.dy, 0.5 * 120 + 12); // quieta en minY
    expect(p.dx, greaterThanOrEqualTo(12));
    expect(p.dx + _size, lessThanOrEqualTo(area.width));
  });

  testWidgets('área estrecha: arrastrar no lanza y se queda en el margen', (
    tester,
  ) async {
    const area = Size(60, 600);
    await _montar(tester, area, colorZona: Colors.red);
    await _arrastrarMucho(tester);

    expect(tester.takeException(), isNull);
    final p = tester.getTopLeft(find.byKey(_clave));
    expect(p.dx, 12); // quieta en horizontal
    expect(p.dy, greaterThanOrEqualTo(0.5 * 600 + 12));
    expect(p.dy + _size, lessThanOrEqualTo(area.height));
  });

  testWidgets('área de tamaño cero: construir no lanza', (tester) async {
    // Con el área a cero no hay nada tocable: solo se comprueba la
    // construcción (el arrastre se cubre en las áreas bajas y estrechas).
    await _montar(tester, Size.zero, colorZona: Colors.red);
    expect(tester.takeException(), isNull);
  });

  testWidgets('área baja con vagabundeo: los pasos no lanzan', (tester) async {
    await _montar(
      tester,
      const Size(360, 120),
      colorZona: Colors.red,
      vagabundeo: true,
    );
    await tester.pump(const Duration(seconds: 30));
    expect(tester.takeException(), isNull);
    expect(tester.getTopLeft(find.byKey(_clave)).dy, 0.5 * 120 + 12);
    // Descarta los temporizadores pendientes del vagabundeo.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('área normal: arrastrar hacia abajo y a la derecha llega a los '
      'máximos', (tester) async {
    await _montar(tester, const Size(360, 600));
    await tester.drag(find.byKey(_clave), const Offset(0, 2000));
    await tester.pump();
    await tester.drag(find.byKey(_clave), const Offset(2000, 0));
    await tester.pump();

    expect(tester.takeException(), isNull);
    final p = tester.getTopLeft(find.byKey(_clave));
    expect(p.dy, 600 - _size - 12); // maxY
    expect(p.dx, 360 - _size - 12); // maxX
  });
}
