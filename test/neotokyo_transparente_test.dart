import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:norday_flutter_core/theme/app_theme.dart';
import 'package:norday_flutter_core/widgets/lapiz.dart';
import 'package:norday_flutter_core/theme/identidades_paleta.dart';
import 'package:norday_flutter_core/widgets/check_circular.dart';
import 'package:norday_flutter_core/widgets/superficie_identidad.dart';

/// Neotokyo+ pasa a tener superficies secundarias transparentes, un filo que
/// puede latir o quedarse encendido, y un check con base propia. Lo que se
/// comprueba aquí es lo que promete el cambio: qué pinta cada identidad, no
/// cómo queda en pantalla.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Las llamadas de dibujo no se ven dentro de la caché: aquí se miran.
  usarCacheLapiz = false;
  GoogleFonts.config.allowRuntimeFetching = false;

  final identidadInicial = identidadEquipadaNotifier.value;
  final relojReal = relojFilo;
  tearDown(() {
    relojFilo = relojReal;
    aplicarIdentidadEquipada(identidadInicial.codigo);
  });

  Widget montar(Widget child, {bool reducirMovimiento = false}) => MaterialApp(
    theme: AppTheme.deTema(temaEquipadoNotifier.value),
    builder: (context, app) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(disableAnimations: reducirMovimiento),
      child: app!,
    ),
    home: Scaffold(body: Center(child: child)),
  );

  /// La decoración de la primera superficie que se pinte dentro del árbol.
  ShapeDecoration decoracion(WidgetTester tester) {
    final caja = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(SuperficieIdentidad),
            matching: find.byType(Container),
          )
          .first,
    );
    return caja.decoration! as ShapeDecoration;
  }

  BorderSide ladoDe(ShapeDecoration deco) =>
      (deco.shape as OutlinedBorder).side;

  double alfaDelFilo(WidgetTester tester) => ladoDe(decoracion(tester)).color.a;

  RenderObject pintadoDelCheck(WidgetTester tester) => tester.renderObject(
    find.descendant(
      of: find.byType(CheckCircular),
      matching: find.byType(CustomPaint),
    ),
  );

  group('superficies', () {
    testWidgets(
      'en Neotokyo+ la secundaria no pinta relleno y la protagonista, surface',
      (tester) async {
        aplicarIdentidadEquipada('TEMA_NEOTOKYO_PLUS');
        final t = temaEquipadoNotifier.value;

        await tester.pumpWidget(
          montar(const SuperficieIdentidad(child: Text('x'))),
        );
        expect(decoracion(tester).color, isNull);

        await tester.pumpWidget(
          montar(
            const SuperficieIdentidad(protagonista: true, child: Text('x')),
          ),
        );
        expect(decoracion(tester).color, t.surface);
      },
    );

    testWidgets('Profundidad y Dulce siguen como antes', (tester) async {
      for (final codigo in ['TEMA_PROFUNDIDAD', 'TEMA_DULCE']) {
        aplicarIdentidadEquipada(codigo);
        final t = temaEquipadoNotifier.value;

        await tester.pumpWidget(
          montar(const SuperficieIdentidad(child: Text('x'))),
        );
        final secundaria = decoracion(tester).color;

        await tester.pumpWidget(
          montar(
            const SuperficieIdentidad(protagonista: true, child: Text('x')),
          ),
        );
        final protagonista = decoracion(tester).color;

        if (codigo == 'TEMA_PROFUNDIDAD') {
          expect(secundaria, isNull, reason: codigo);
          expect(protagonista, t.surfaceAlta, reason: codigo);
        } else {
          expect(secundaria, t.surface, reason: codigo);
          expect(protagonista, t.surface, reason: codigo);
        }
      }
    });
  });

  group('filo de Neotokyo+', () {
    testWidgets('fijo va a 0,70 y encendido a 1,0', (tester) async {
      aplicarIdentidadEquipada('TEMA_NEOTOKYO_PLUS');

      await tester.pumpWidget(
        montar(const SuperficieIdentidad(child: Text('x'))),
      );
      expect(alfaDelFilo(tester), closeTo(0.70, 1e-6));

      await tester.pumpWidget(
        montar(
          const SuperficieIdentidad(
            filoNeon: FiloNeon.encendido,
            child: Text('x'),
          ),
        ),
      );
      expect(alfaDelFilo(tester), closeTo(1.0, 1e-6));
    });

    testWidgets(
      'latiendo cambia de alfa a lo largo del ciclo, entre 0,70 y 1,0',
      (tester) async {
        aplicarIdentidadEquipada('TEMA_NEOTOKYO_PLUS');
        relojFilo = () => 0;

        await tester.pumpWidget(
          montar(
            const SuperficieIdentidad(
              filoNeon: FiloNeon.latiendo,
              child: Text('x'),
            ),
          ),
        );
        await tester.pump();

        final muestras = <double>[alfaDelFilo(tester)];
        for (var i = 0; i < 24; i++) {
          await tester.pump(const Duration(milliseconds: 100));
          muestras.add(alfaDelFilo(tester));
        }

        expect(muestras.toSet().length, greaterThan(1));
        expect(muestras.reduce(math.min), closeTo(0.70, 0.01));
        expect(muestras.reduce(math.max), closeTo(1.0, 0.01));
        for (final a in muestras) {
          expect(a, inInclusiveRange(0.70 - 1e-9, 1.0 + 1e-9));
        }
      },
    );

    testWidgets(
      'latiendo con reducir movimiento se queda en 0,70 sin animación',
      (tester) async {
        aplicarIdentidadEquipada('TEMA_NEOTOKYO_PLUS');

        await tester.pumpWidget(
          montar(
            const SuperficieIdentidad(
              filoNeon: FiloNeon.latiendo,
              child: Text('x'),
            ),
            reducirMovimiento: true,
          ),
        );
        await tester.pump(const Duration(milliseconds: 1200));

        expect(alfaDelFilo(tester), closeTo(0.70, 1e-6));
        expect(tester.hasRunningAnimations, isFalse);
      },
    );

    testWidgets('un filo explícito manda sobre filoNeon', (tester) async {
      aplicarIdentidadEquipada('TEMA_NEOTOKYO_PLUS');

      await tester.pumpWidget(
        montar(
          const SuperficieIdentidad(
            filo: BorderSide(color: Colors.red, width: 2),
            filoNeon: FiloNeon.encendido,
            child: Text('x'),
          ),
        ),
      );
      expect(ladoDe(decoracion(tester)).color, Colors.red);
    });

    testWidgets(
      'dos tarjetas latiendo montadas a 700 ms de distancia laten igual',
      (tester) async {
        aplicarIdentidadEquipada('TEMA_NEOTOKYO_PLUS');
        var ahora = 10000;
        relojFilo = () => ahora;
        final kA = UniqueKey();
        final kB = UniqueKey();

        Widget tarjeta(Key key) => SuperficieIdentidad(
          key: key,
          filoNeon: FiloNeon.latiendo,
          child: const Text('x'),
        );

        await tester.pumpWidget(montar(Column(children: [tarjeta(kA)])));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 700));
        ahora += 700;

        await tester.pumpWidget(
          montar(Column(children: [tarjeta(kA), tarjeta(kB)])),
        );
        await tester.pump();

        double alfaDe(Key key) {
          final caja = tester.widget<Container>(
            find
                .descendant(
                  of: find.byKey(key),
                  matching: find.byType(Container),
                )
                .first,
          );
          return ladoDe(caja.decoration! as ShapeDecoration).color.a;
        }

        expect(alfaDe(kA), closeTo(alfaDe(kB), 1e-9));
      },
    );
  });

  group('fase del latido', () {
    testWidgets('volver de Quitar animaciones pone la fase del reloj', (
      tester,
    ) async {
      aplicarIdentidadEquipada('TEMA_NEOTOKYO_PLUS');
      var ahora = 1200;
      relojFilo = () => ahora;
      final k = UniqueKey();
      final kRef = UniqueKey();

      Widget tarjeta(Key key) => SuperficieIdentidad(
        key: key,
        filoNeon: FiloNeon.latiendo,
        child: const Text('x'),
      );

      // Montada con «Quitar animaciones» y luego reactivada, 300 ms después.
      await tester.pumpWidget(montar(tarjeta(k), reducirMovimiento: true));
      await tester.pump();
      ahora += 300;
      await tester.pumpWidget(montar(tarjeta(k)));
      await tester.pump();
      final tras = alfaDelFilo(tester);

      // Referencia: montada de cero en ese mismo instante del reloj.
      await tester.pumpWidget(montar(tarjeta(kRef)));
      await tester.pump();
      final referencia = alfaDelFilo(tester);

      expect(tras, closeTo(referencia, 1e-9));
    });
  });

  group('filo fuera de Neotokyo+', () {
    testWidgets('filoNeon no cambia el borde de Dulce ni de Profundidad', (
      tester,
    ) async {
      for (final codigo in ['TEMA_PROFUNDIDAD', 'TEMA_DULCE']) {
        aplicarIdentidadEquipada(codigo);
        final formas = <ShapeBorder>[];
        for (final filoNeon in FiloNeon.values) {
          await tester.pumpWidget(
            montar(
              SuperficieIdentidad(filoNeon: filoNeon, child: const Text('x')),
            ),
          );
          formas.add(decoracion(tester).shape);
        }
        for (final forma in formas) {
          expect(forma, formas.first, reason: codigo);
        }
      }
    });
  });

  group('check', () {
    testWidgets('en Neotokyo+ pinta la base colorBase', (tester) async {
      aplicarIdentidadEquipada('TEMA_NEOTOKYO_PLUS');
      final t = temaEquipadoNotifier.value;

      await tester.pumpWidget(
        montar(CheckCircular(hecho: false, onTap: () {}, color: Colors.green)),
      );
      await tester.pump();

      // `paints` es secuencial: base antes que aro, en ese orden.
      expect(
        pintadoDelCheck(tester),
        paints
          ..path(color: t.surface)
          ..path(color: t.aroVacio),
      );
    });

    // `paints` es secuencial y en Profundidad la base va antes que el aro y
    // el insinuado va después. En Dulce no se pinta nada más que el aro: un
    // único drawPath lo demuestra sin depender del orden.
    testWidgets('Profundidad pinta base, aro e insinuado en ese orden', (
      tester,
    ) async {
      aplicarIdentidadEquipada('TEMA_PROFUNDIDAD');
      final t = temaEquipadoNotifier.value;

      await tester.pumpWidget(
        montar(CheckCircular(hecho: false, onTap: () {}, color: Colors.green)),
      );
      await tester.pump();

      expect(
        pintadoDelCheck(tester),
        paints
          ..path(color: t.surface)
          ..path(color: t.aroVacio)
          ..path(color: t.aroVacio.withValues(alpha: 0.15)),
      );
    });

    testWidgets('Dulce no pinta base ni insinuado: sólo el aro', (
      tester,
    ) async {
      aplicarIdentidadEquipada('TEMA_DULCE');
      final t = temaEquipadoNotifier.value;

      await tester.pumpWidget(
        montar(CheckCircular(hecho: false, onTap: () {}, color: Colors.green)),
      );
      await tester.pump();

      // El aro a lápiz son tramos de línea (drawLine), no un path: ningún
      // drawPath, ni base ni insinuado. Y el aro va en el color de `aroVacio`.
      expect(pintadoDelCheck(tester), paintsExactlyCountTimes(#drawPath, 0));
      expect(
        pintadoDelCheck(tester),
        paints..something(
          (nombre, args) =>
              nombre == #drawLine &&
              ((args[2] as Paint).color.toARGB32() & 0xFFFFFF) ==
                  (t.aroVacio.toARGB32() & 0xFFFFFF),
        ),
      );
    });
  });
}
