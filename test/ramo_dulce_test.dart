import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
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

  // Los nombres de Dulce, de Quim (23-nov-2026): más dulces y sin cinco
  // «Ramo de…» seguidos. Uno por número de hábitos; de 8 en adelante, el 8.
  test('nombreRamo, en los tres idiomas', () async {
    const esperados = {
      'es': [
        'Una rosa',
        'Un mimo',
        'Un ramillete',
        'Flores para ti',
        'Un ramo que sonríe',
        'Jardín en flor',
        'Ramo de ensueño',
        'El ramo más bonito',
      ],
      'en': [
        'A rose',
        'A little treat',
        'A posy',
        'Flowers for you',
        'A smiling bouquet',
        'Garden in bloom',
        'Dreamy bouquet',
        'The loveliest bouquet',
      ],
      'pt': [
        'Uma rosa',
        'Um mimo',
        'Um raminho',
        'Flores para ti',
        'Um ramo sorridente',
        'Jardim em flor',
        'Ramo de sonho',
        'O ramo mais bonito',
      ],
    };
    for (final MapEntry(key: idioma, value: nombres) in esperados.entries) {
      final l = await NordayCoreLocalizations.delegate.load(Locale(idioma));
      for (var total = 1; total <= 8; total++) {
        expect(nombreRamo(l, total), nombres[total - 1], reason: idioma);
      }
      expect(nombreRamo(l, 12), nombres[7], reason: idioma);
    }
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

  testWidgets(
    'a grafito (D-41): el mismo dibujo, dentro de una capa que lo pasa a gris',
    (tester) async {
      usarCacheLapiz = false;
      addTearDown(() => usarCacheLapiz = true);
      Future<RenderObject> pintado(RamoDulce ramo) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: Center(child: ramo)),
          ),
        );
        await tester.pump();
        return tester.renderObject(
          find.descendant(
            of: find.byType(RamoDulce),
            matching: find.byType(CustomPaint),
          ),
        );
      }

      bool capaGris(Symbol n, List<dynamic> a) =>
          n == #saveLayer && (a[1] as Paint).colorFilter != null;

      expect(
        await pintado(const RamoDulce(total: 3, alto: 360, boceto: true)),
        paints
          ..something(capaGris)
          ..something((n, a) => n == #drawLine)
          ..restore(),
      );
      expect(
        await pintado(const RamoDulce(total: 3, alto: 360)),
        paints..everything((n, a) => !capaGris(n, a)),
      );
    },
  );

  testWidgets(
    'a grafito, la caché no sirve el de color (y al revés), y el blanco '
    'sigue blanco',
    (tester) async {
      usarCacheLapiz = true;
      Future<ui.Image> captura(RamoDulce ramo) async {
        final clave = GlobalKey();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              backgroundColor: Colors.white,
              body: Center(
                child: RepaintBoundary(key: clave, child: ramo),
              ),
            ),
          ),
        );
        await tester.pump();
        final rb =
            tester.renderObject(find.byKey(clave)) as RenderRepaintBoundary;
        return (await tester.runAsync(() => rb.toImage()))!;
      }

      Future<Set<int>> colores(RamoDulce ramo) async {
        final img = await captura(ramo);
        final datos = (await tester.runAsync(
          () => img.toByteData(format: ui.ImageByteFormat.rawRgba),
        ))!;
        final r = <int>{};
        for (var i = 0; i < datos.lengthInBytes; i += 4) {
          r.add(datos.getUint32(i));
        }
        return r;
      }

      final color = await colores(const RamoDulce(total: 3, alto: 180));
      final boceto = await colores(
        const RamoDulce(total: 3, alto: 180, boceto: true),
      );
      bool esGris(int rgba) {
        final r = rgba >> 24 & 0xFF,
            g = rgba >> 16 & 0xFF,
            b = rgba >> 8 & 0xFF;
        // El grafito tira a violeta: el azul nunca por debajo del rojo, y
        // todos cerca entre sí.
        return b >= r - 1 && (r - g).abs() <= 12 && (b - g).abs() <= 16;
      }

      expect(color.any((c) => !esGris(c)), isTrue, reason: 'en color');
      expect(
        boceto.where((c) => !esGris(c)),
        isEmpty,
        reason: 'si la caché sirviera el de color, aquí habría color',
      );
      // El papel del ramo (casi blanco) sigue casi blanco: sin los
      // desplazamientos de la matriz se iría a gris medio.
      final claro = boceto
          .where((c) => (c & 0xFF) == 0xFF)
          .map((c) => [c >> 24 & 0xFF, c >> 16 & 0xFF, c >> 8 & 0xFF])
          .reduce(
            (a, b) =>
                a.reduce((x, y) => x + y) >= b.reduce((x, y) => x + y) ? a : b,
          );
      expect(claro, everyElement(greaterThanOrEqualTo(245)), reason: '$claro');
    },
  );
}
