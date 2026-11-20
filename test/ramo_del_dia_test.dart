import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:norday_flutter_core/l10n/norday_core_localizations.dart';
import 'package:norday_flutter_core/theme/app_theme.dart';
import 'package:norday_flutter_core/theme/identidades_paleta.dart';
import 'package:norday_flutter_core/theme/progreso_dia.dart';
import 'package:norday_flutter_core/widgets/cierre_del_dia.dart';
import 'package:norday_flutter_core/widgets/ramo_del_dia.dart';
import 'package:norday_flutter_core/widgets/ramo_dulce.dart';

/// El ramo del día de Dulce en su sitio de la lista de Hoy (D-41): una flor
/// por hábito hecho, a grafito con el día abierto; con el día cerrado, en
/// color y atado. Cómo se ve, en el móvil; aquí, qué se pinta y cuándo.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final identidadInicial = identidadEquipadaNotifier.value;
  tearDown(() {
    aplicarIdentidadEquipada(identidadInicial.codigo);
    limpiarProgresoDia();
  });

  final dia = DateTime(2026, 11, 20);
  const alto = 220.0;

  Future<void> montar(WidgetTester tester, {bool sinMovimiento = false}) async {
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });
    aplicarIdentidadEquipada('TEMA_DULCE');
    await tester.pumpWidget(
      MaterialApp(
        key: ValueKey(sinMovimiento),
        localizationsDelegates: NordayCoreLocalizations.localizationsDelegates,
        supportedLocales: NordayCoreLocalizations.supportedLocales,
        locale: const Locale('es'),
        theme: AppTheme.deTema(temaEquipadoNotifier.value),
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: sinMovimiento),
          child: const Scaffold(
            body: Stack(
              fit: StackFit.expand,
              children: [
                Align(
                  alignment: Alignment.bottomCenter,
                  child: RamoDelDia(alto: alto),
                ),
                CapaCierreDelDia(),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// Los ramos pintados en el sitio de la lista, de abajo arriba del Stack.
  List<RamoDulce> ramos(WidgetTester tester) => tester
      .widgetList<RamoDulce>(
        find.descendant(
          of: find.byType(RamoDelDia),
          matching: find.byType(RamoDulce),
        ),
      )
      .toList();

  (int?, bool, bool) estado(RamoDulce r) => (r.flores, r.atado, r.boceto);

  testWidgets('con el día abierto, una flor por hábito hecho, a grafito', (
    tester,
  ) async {
    publicarProgresoDia(hechos: 2, total: 4, fecha: dia);
    await montar(tester);
    final r = ramos(tester);
    expect(r, hasLength(1));
    expect(estado(r.single), (2, false, true));
    expect(r.single.total, 4);
    expect(tester.getSize(find.byType(RamoDelDia)).height, alto);
  });

  testWidgets('sin ningún hecho, el sitio sigue ocupado (no salta la lista)', (
    tester,
  ) async {
    publicarProgresoDia(hechos: 0, total: 4, fecha: dia);
    await montar(tester);
    expect(estado(ramos(tester).single), (0, false, true));
    expect(tester.getSize(find.byType(RamoDelDia)).height, alto);
  });

  testWidgets('sin hábitos, no pinta ramo pero guarda el sitio', (
    tester,
  ) async {
    await montar(tester);
    expect(ramos(tester), isEmpty);
    expect(tester.getSize(find.byType(RamoDelDia)).height, alto);
  });

  testWidgets(
    'al marcar, la flor nueva entra en 600 ms sobre el ramo de antes',
    (tester) async {
      publicarProgresoDia(hechos: 1, total: 4, fecha: dia);
      await montar(tester);
      publicarProgresoDia(hechos: 2, total: 4, fecha: dia);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      final r = ramos(tester);
      expect([for (final x in r) x.flores], [1, 2]);
      final opacidad = tester
          .widget<Opacity>(
            find.ancestor(
              of: find.byWidget(r.last),
              matching: find.byType(Opacity),
            ),
          )
          .opacity;
      expect(opacidad, inExclusiveRange(0, 1));

      await tester.pump(const Duration(milliseconds: 400));
      expect(estado(ramos(tester).single), (2, false, true));
    },
  );

  testWidgets('al desmarcar, la flor se va en 400 ms', (tester) async {
    publicarProgresoDia(hechos: 3, total: 4, fecha: dia);
    await montar(tester);
    publicarProgresoDia(hechos: 2, total: 4, fecha: dia);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect([for (final x in ramos(tester)) x.flores], [2, 3]);
    await tester.pump(const Duration(milliseconds: 250));
    expect(estado(ramos(tester).single), (2, false, true));
  });

  testWidgets(
    'con el día cerrado sin ceremonia, se colorea y se ata con un fundido',
    (tester) async {
      publicarProgresoDia(hechos: 4, total: 4, fecha: dia);
      await montar(tester);
      marcarDiaCerrado(true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect([for (final r in ramos(tester)) r.boceto], [true, false]);
      await tester.pump(const Duration(milliseconds: 400));
      expect(estado(ramos(tester).single), (4, true, false));
    },
  );

  testWidgets('montado con el día ya cerrado, sale en color y atado', (
    tester,
  ) async {
    publicarProgresoDia(hechos: 3, total: 3, fecha: dia);
    marcarDiaCerrado(true);
    await montar(tester);
    expect(estado(ramos(tester).single), (3, true, false));
  });

  testWidgets(
    'con la ceremonia en curso cambia de golpe: la ceremonia lo pinta en '
    'grande',
    (tester) async {
      publicarProgresoDia(hechos: 3, total: 3, fecha: dia);
      await montar(tester);
      unawaited(mostrarCierreDelDia(titulo: 'T', despedida: 'D'));
      await tester.pump();
      expect(estado(ramos(tester).single), (3, true, false));
    },
  );

  testWidgets('al reabrir el día vuelve a grafito', (tester) async {
    publicarProgresoDia(hechos: 3, total: 3, fecha: dia);
    marcarDiaCerrado(true);
    await montar(tester);
    publicarProgresoDia(hechos: 2, total: 3, fecha: dia);
    marcarDiaCerrado(false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(estado(ramos(tester).single), (2, false, true));
  });

  testWidgets('al cambiar de día o de número de hábitos, quieto', (
    tester,
  ) async {
    publicarProgresoDia(hechos: 1, total: 4, fecha: dia);
    await montar(tester);
    publicarProgresoDia(
      hechos: 3,
      total: 4,
      fecha: dia.subtract(const Duration(days: 1)),
    );
    await tester.pump();
    expect(estado(ramos(tester).single), (3, false, true));
    publicarProgresoDia(
      hechos: 4,
      total: 5,
      fecha: dia.subtract(const Duration(days: 1)),
    );
    await tester.pump();
    expect(estado(ramos(tester).single), (4, false, true));
  });

  testWidgets('con «reducir movimiento», todo de golpe', (tester) async {
    publicarProgresoDia(hechos: 1, total: 3, fecha: dia);
    await montar(tester, sinMovimiento: true);
    publicarProgresoDia(hechos: 3, total: 3, fecha: dia);
    await tester.pump();
    expect(estado(ramos(tester).single), (3, false, true));
    marcarDiaCerrado(true);
    await tester.pump();
    expect(estado(ramos(tester).single), (3, true, false));
  });

  testWidgets('lo hecho a medias no corta la flor que está entrando', (
    tester,
  ) async {
    publicarProgresoDia(hechos: 1, total: 4, fecha: dia);
    await montar(tester);
    publicarProgresoDia(hechos: 2, total: 4, fecha: dia);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    // Un hábito de minutos a medias: cambia el avance, no las flores.
    publicarProgresoDia(hechos: 2, total: 4, fecha: dia, avance: 0.6);
    await tester.pump();
    expect([for (final x in ramos(tester)) x.flores], [1, 2]);
  });
}
