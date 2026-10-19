import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norday_flutter_core/l10n/norday_core_localizations.dart';
import 'package:norday_flutter_core/widgets/lapiz.dart';
import 'package:norday_flutter_core/widgets/ramo_dulce.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => usarCacheLapiz = true);

  test('rngRamo da la misma secuencia que la referencia', () {
    final r1 = rngRamo(1);
    expect(r1(), closeTo(0.000015652738518851222, 1e-15));
    expect(r1(), closeTo(0.26307557628633249, 1e-15));
    expect(r1(), closeTo(0.51121064439006647, 1e-15));

    final r2 = rngRamo(165.5);
    expect(r2(), closeTo(0.0013030904816943643, 1e-15));
    expect(r2(), closeTo(0.90104172583717934, 1e-15));
  });

  test('nombreRamo', () async {
    final l = await NordayCoreLocalizations.delegate.load(const Locale('es'));
    expect(nombreRamo(l, 1), 'Una rosa');
    expect(nombreRamo(l, 8), 'Gran ramo');
    expect(nombreRamo(l, 12), 'Gran ramo');
  });

  testWidgets(
    'sin flores ni atado no pinta nada; entero, pinta tallo verde y rosa',
    (tester) async {
      usarCacheLapiz = false;
      Future<void> montar(RamoDulce ramo) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: Center(child: ramo)),
          ),
        );
        await tester.pump();
        return;
      }

      RenderObject pintadoDe() => tester.renderObject(
        find.descendant(
          of: find.byType(RamoDulce),
          matching: find.byType(CustomPaint),
        ),
      );

      await montar(
        const RamoDulce(total: 3, alto: 360, flores: 0, atado: false),
      );
      expect(pintadoDe(), paints..everything((n, a) => n != #drawLine));

      await montar(const RamoDulce(total: 3, alto: 360));
      expect(
        pintadoDe(),
        paints..something(
          (n, a) =>
              n == #drawLine &&
              ((a[2] as Paint).color.toARGB32() & 0xFFFFFF) == 0x56703F,
        ),
      );
      expect(
        pintadoDe(),
        paints..something(
          (n, a) =>
              n == #drawLine &&
              ((a[2] as Paint).color.toARGB32() & 0xFFFFFF) == 0xE53F80,
        ),
      );
    },
  );
}
