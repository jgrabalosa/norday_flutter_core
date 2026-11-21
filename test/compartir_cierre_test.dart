import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:norday_flutter_core/l10n/norday_core_localizations.dart';
import 'package:norday_flutter_core/theme/app_theme.dart';
import 'package:norday_flutter_core/theme/identidades_paleta.dart';
import 'package:norday_flutter_core/theme/progreso_dia.dart';
import 'package:norday_flutter_core/widgets/cierre_del_dia.dart';
import 'package:norday_flutter_core/widgets/figura_del_dia.dart';

/// Las etiquetas de las acciones propias (la pista de «Cerrar» no tiene).
List<String> _etiquetas(Iterable<int> ids) => [
  for (final i in ids) ?CustomSemanticsAction.getAction(i)?.label,
];

/// T-041: el botón «Compartir» al final de la ceremonia y la figura quieta.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final identidadInicial = identidadEquipadaNotifier.value;
  tearDown(() {
    aplicarIdentidadEquipada(identidadInicial.codigo);
    limpiarProgresoDia();
  });

  Future<void> desmontar(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  }

  Future<void> montar(
    WidgetTester tester, {
    String codigo = 'TEMA_PROFUNDIDAD',
  }) async {
    addTearDown(() => desmontar(tester));
    aplicarIdentidadEquipada(codigo);
    publicarProgresoDia(hechos: 3, total: 3, fecha: DateTime(2026, 10, 18));
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: NordayCoreLocalizations.localizationsDelegates,
        supportedLocales: NordayCoreLocalizations.supportedLocales,
        locale: const Locale('es'),
        theme: AppTheme.deTema(temaEquipadoNotifier.value),
        home: const Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [Text('debajo'), CapaCierreDelDia()],
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// Lanza la ceremonia y guarda su resultado en [resultado].
  void lanzar(List<ResultadoCierreDelDia> resultado, {String? compartir}) {
    unawaited(
      mostrarCierreDelDia(
        titulo: 'T',
        despedida: 'D',
        textoCompartir: compartir,
      ).then(resultado.add),
    );
  }

  Future<void> esperarSalida(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
  }

  double opacidadBoton(WidgetTester tester) {
    final o = tester.widget<Opacity>(
      find
          .ancestor(
            of: find.byType(ElevatedButton),
            matching: find.byType(Opacity),
          )
          .first,
    );
    return o.opacity;
  }

  testWidgets('sin textoCompartir no hay botón y el resultado es cerrado', (
    tester,
  ) async {
    await montar(tester);
    final r = <ResultadoCierreDelDia>[];
    lanzar(r);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 3000));
    expect(find.byType(ElevatedButton), findsNothing);

    await tester.tapAt(const Offset(200, 300));
    await esperarSalida(tester);
    expect(r, [ResultadoCierreDelDia.cerrado]);
  });

  testWidgets('con textoCompartir, el botón sale tras los textos y no '
      'responde antes; pulsarlo devuelve compartir', (tester) async {
    await montar(tester);
    final r = <ResultadoCierreDelDia>[];
    lanzar(r, compartir: 'Compartir');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));

    expect(find.text('Compartir'), findsOneWidget);
    expect(opacidadBoton(tester), 0, reason: 'aún no ha entrado');
    await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
    await esperarSalida(tester);
    expect(r, isEmpty, reason: 'no responde antes de tiempo');

    await tester.pump(const Duration(milliseconds: 2500));
    expect(opacidadBoton(tester), 1);
    // Centrado: el centro del botón cae en el eje de la pantalla.
    expect(tester.getCenter(find.byType(ElevatedButton)).dx, 400);

    await tester.tap(find.byType(ElevatedButton));
    await esperarSalida(tester);
    expect(r, [ResultadoCierreDelDia.compartir]);
  });

  testWidgets('con textoCompartir, tocar fuera del botón devuelve cerrado', (
    tester,
  ) async {
    await montar(tester);
    final r = <ResultadoCierreDelDia>[];
    lanzar(r, compartir: 'Compartir');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 3200));

    await tester.tapAt(const Offset(30, 30));
    await esperarSalida(tester);
    expect(r, [ResultadoCierreDelDia.cerrado]);
  });

  for (final codigo in ['TEMA_DULCE', 'TEMA_NEOTOKYO_PLUS']) {
    testWidgets('$codigo: el botón existe y compartir funciona', (
      tester,
    ) async {
      await montar(tester, codigo: codigo);
      final r = <ResultadoCierreDelDia>[];
      lanzar(r, compartir: 'Compartir');
      await tester.pump();
      // La figura primero y, al acabar, entran los textos.
      await tester.pump(const Duration(seconds: 8));
      await tester.pump(const Duration(seconds: 4));
      await tester.tap(find.byType(ElevatedButton));
      await esperarSalida(tester);
      expect(r, [ResultadoCierreDelDia.compartir]);
    });
  }

  testWidgets('la acción semántica «Compartir» solo está si hay texto, y '
      'cierra con compartir', (tester) async {
    final semantica = tester.ensureSemantics();
    await montar(tester);
    final r = <ResultadoCierreDelDia>[];
    lanzar(r, compartir: 'Compartir');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 3200));

    final buscado = find.semantics.byPredicate(
      (n) => n.label.contains('Orión'),
    );
    final ids = buscado
        .evaluate()
        .single
        .getSemanticsData()
        .customSemanticsActionIds!;
    expect(_etiquetas(ids), ['Compartir']);
    tester.semantics.performAction(
      buscado,
      SemanticsAction.customAction,
      args: ids.firstWhere(
        (i) => CustomSemanticsAction.getAction(i)?.label == 'Compartir',
      ),
    );
    await esperarSalida(tester);
    expect(r, [ResultadoCierreDelDia.compartir]);
    semantica.dispose();
  });

  testWidgets('sin textoCompartir, el nodo no tiene acciones propias', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    await montar(tester);
    final r = <ResultadoCierreDelDia>[];
    lanzar(r);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 3200));
    final nodo = find.semantics
        .byPredicate((n) => n.label.contains('Orión'))
        .evaluate()
        .single;
    expect(
      _etiquetas(nodo.getSemanticsData().customSemanticsActionIds ?? []),
      isEmpty,
    );

    await tester.tapAt(const Offset(30, 30));
    await esperarSalida(tester);
    semantica.dispose();
  });

  group('FiguraDelDia', () {
    for (final codigo in [
      'TEMA_PROFUNDIDAD',
      'TEMA_DULCE',
      'TEMA_NEOTOKYO_PLUS',
    ]) {
      testWidgets('$codigo: pinta algo y no anima', (tester) async {
        aplicarIdentidadEquipada(codigo);
        final clave = GlobalKey();
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.deTema(temaEquipadoNotifier.value),
            home: Center(
              child: RepaintBoundary(
                key: clave,
                child: ColoredBox(
                  color: const Color(0xFF000000),
                  child: const FiguraDelDia(total: 3, tamano: 200),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester.binding.hasScheduledFrame,
          isFalse,
          reason: 'quieta: nada pide otro frame',
        );
        expect(tester.getSize(find.byType(FiguraDelDia)), const Size(200, 200));

        final distintos = await tester.runAsync(() async {
          final frontera =
              clave.currentContext!.findRenderObject() as RenderRepaintBoundary;
          final imagen = await frontera.toImage();
          final datos = (await imagen.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!;
          var n = 0;
          for (var i = 0; i < datos.lengthInBytes; i += 4) {
            if (datos.getUint8(i) != 0 ||
                datos.getUint8(i + 1) != 0 ||
                datos.getUint8(i + 2) != 0) {
              n++;
            }
          }
          return n;
        });
        expect(distintos, greaterThan(100), reason: 'no está vacía');
      });
    }
  });
}
