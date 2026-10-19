import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:norday_flutter_core/l10n/norday_core_localizations.dart';
import 'package:norday_flutter_core/theme/app_theme.dart';
import 'package:norday_flutter_core/theme/identidad_paleta.dart';
import 'package:norday_flutter_core/theme/identidades_paleta.dart';
import 'package:norday_flutter_core/widgets/indicador_nivel.dart';
import 'package:norday_flutter_core/widgets/lapiz.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Sin esto, construir un tema en un test intenta bajar las fuentes por HTTP.
  GoogleFonts.config.allowRuntimeFetching = false;

  final identidadInicial = identidadEquipadaNotifier.value;
  tearDown(() {
    aplicarIdentidadEquipada(identidadInicial.codigo);
    usarCacheLapiz = true;
  });

  Widget montar(Widget child) => MaterialApp(
    theme: AppTheme.deTema(temaEquipadoNotifier.value),
    locale: const Locale('es'),
    localizationsDelegates: NordayCoreLocalizations.localizationsDelegates,
    supportedLocales: NordayCoreLocalizations.supportedLocales,
    home: Scaffold(body: Center(child: child)),
  );

  test('cada identidad pinta el objeto de su mundo', () {
    expect(
      IndicadorNivel.dibujoDe(FormaIdentidad.glass),
      DibujoNivel.estrellas,
    );
    expect(
      IndicadorNivel.dibujoDe(FormaIdentidad.chamfer),
      DibujoNivel.ventanas,
    );
    expect(IndicadorNivel.dibujoDe(FormaIdentidad.pill), DibujoNivel.burbujas);
  });

  test('las vacías van en contorno de aroVacio y las llenas en points', () {
    for (final codigo in catalogoIdentidades.keys) {
      aplicarIdentidadEquipada(codigo);
      final t = temaEquipadoNotifier.value;
      expect(IndicadorNivel.colorVacia(t), t.aroVacio, reason: codigo);
      expect(IndicadorNivel.colorLlena(t), t.points, reason: codigo);
    }
  });

  test('van llenas tantas figuras como el nivel', () {
    for (var n = 1; n <= 5; n++) {
      expect(IndicadorNivel.llenas(n), n);
    }
  });

  test('un nivel fuera de rango se recorta', () {
    expect(IndicadorNivel.llenas(0), 0);
    expect(IndicadorNivel.llenas(-2), 0);
    expect(IndicadorNivel.llenas(7), 5);
  });

  test('mide lo de la maqueta', () {
    expect(IndicadorNivel.medida(20), const Size(116, 20));
    expect(IndicadorNivel.medida(11).height, 11);
  });

  testWidgets('construye en las tres identidades y anuncia el nivel', (
    tester,
  ) async {
    for (final codigo in catalogoIdentidades.keys) {
      aplicarIdentidadEquipada(codigo);
      await tester.pumpWidget(
        montar(const IndicadorNivel(nivel: 3, tamano: 20)),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byType(IndicadorNivel)),
        const Size(116, 20),
        reason: codigo,
      );
      expect(
        find.bySemanticsLabel('Nivel 3 de 5'),
        findsOneWidget,
        reason: codigo,
      );
    }
  });

  testWidgets('quien lo usa puede poner su propia etiqueta', (tester) async {
    await tester.pumpWidget(
      montar(
        const IndicadorNivel(
          nivel: 4,
          tamano: 11,
          etiquetaSemantica: 'Cuarto de cinco',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Cuarto de cinco'), findsOneWidget);
  });

  testWidgets(
    'en Dulce, el ritmo va a lápiz: sin círculo liso ni brillo blanco',
    (tester) async {
      usarCacheLapiz = false;
      aplicarIdentidadEquipada('TEMA_DULCE');
      final t = temaEquipadoNotifier.value;
      await tester.pumpWidget(
        montar(const IndicadorNivel(nivel: 3, tamano: 20)),
      );
      await tester.pumpAndSettle();

      final pintado = tester.renderObject(
        find.descendant(
          of: find.byType(IndicadorNivel),
          matching: find.byType(CustomPaint),
        ),
      );
      expect(
        pintado,
        paints..everything((n, a) => n != #drawCircle && n != #drawPath),
      );
      expect(
        pintado,
        paints..something(
          (n, a) =>
              n == #drawLine &&
              ((a[2] as Paint).color.toARGB32() & 0xFFFFFF) ==
                  (t.points.toARGB32() & 0xFFFFFF),
        ),
      );
      expect(
        pintado,
        paints..something(
          (n, a) =>
              n == #drawLine &&
              ((a[2] as Paint).color.toARGB32() & 0xFFFFFF) ==
                  (t.aroVacio.toARGB32() & 0xFFFFFF),
        ),
      );
    },
  );

  testWidgets('en Profundidad y Neotokyo+, el ritmo sigue igual', (
    tester,
  ) async {
    usarCacheLapiz = false;
    for (final codigo in ['TEMA_PROFUNDIDAD', 'TEMA_NEOTOKYO_PLUS']) {
      aplicarIdentidadEquipada(codigo);
      await tester.pumpWidget(
        montar(const IndicadorNivel(nivel: 3, tamano: 20)),
      );
      await tester.pumpAndSettle();

      final pintado = tester.renderObject(
        find.descendant(
          of: find.byType(IndicadorNivel),
          matching: find.byType(CustomPaint),
        ),
      );
      expect(
        pintado,
        paints..something((n, a) => n == #drawPath),
        reason: codigo,
      );
    }
  });
}
