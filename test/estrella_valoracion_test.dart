import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:norday_flutter_core/l10n/norday_core_localizations.dart';
import 'package:norday_flutter_core/theme/app_theme.dart';
import 'package:norday_flutter_core/theme/identidades_paleta.dart';
import 'package:norday_flutter_core/widgets/estrella_valoracion.dart';
import 'package:norday_flutter_core/widgets/valoracion_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Sin esto, construir un tema en un test intenta bajar las fuentes por HTTP.
  GoogleFonts.config.allowRuntimeFetching = false;

  final identidadInicial = identidadEquipadaNotifier.value;
  tearDown(() => aplicarIdentidadEquipada(identidadInicial.codigo));

  Widget montar(Widget child) => MaterialApp(
    theme: AppTheme.deTema(temaEquipadoNotifier.value),
    locale: const Locale('es'),
    localizationsDelegates: NordayCoreLocalizations.localizationsDelegates,
    supportedLocales: NordayCoreLocalizations.supportedLocales,
    home: Scaffold(body: Center(child: child)),
  );

  Finder pintorDeLaEstrella() => find.descendant(
    of: find.byType(EstrellaValoracion),
    matching: find.byType(CustomPaint),
  );

  Finder iconoEstrella() => find.descendant(
    of: find.byType(EstrellaValoracion),
    matching: find.byWidgetPredicate(
      (w) => w is Icon && w.icon == LucideIcons.star,
    ),
  );

  testWidgets('en Dulce la estrella es a lápiz: un CustomPaint, ningún icono', (
    tester,
  ) async {
    aplicarIdentidadEquipada('TEMA_DULCE');
    await tester.pumpWidget(montar(const EstrellaValoracion(marcada: true)));
    await tester.pumpAndSettle();

    expect(pintorDeLaEstrella(), findsOneWidget);
    expect(iconoEstrella(), findsNothing);
  });

  testWidgets('en Profundidad y Neotokyo+ sigue siendo el icono de siempre', (
    tester,
  ) async {
    for (final codigo in ['TEMA_PROFUNDIDAD', 'TEMA_NEOTOKYO_PLUS']) {
      aplicarIdentidadEquipada(codigo);
      for (final marcada in [true, false]) {
        await tester.pumpWidget(montar(EstrellaValoracion(marcada: marcada)));
        await tester.pumpAndSettle();

        expect(iconoEstrella(), findsOneWidget, reason: codigo);
        final icono = tester.widget<Icon>(iconoEstrella());
        final t = tokens(tester.element(find.byType(EstrellaValoracion)));
        expect(
          icono.color,
          marcada ? t.pointsText : t.aroVacio,
          reason: '$codigo marcada=$marcada',
        );
        expect(pintorDeLaEstrella(), findsNothing, reason: codigo);
      }
    }
  });

  testWidgets('en Dulce marcada y vacía pintan distinto', (tester) async {
    aplicarIdentidadEquipada('TEMA_DULCE');
    await tester.pumpWidget(montar(const EstrellaValoracion(marcada: true)));
    await tester.pumpAndSettle();
    final marcada = tester.widget<CustomPaint>(pintorDeLaEstrella()).painter!;

    await tester.pumpWidget(montar(const EstrellaValoracion(marcada: false)));
    await tester.pumpAndSettle();
    final vacia = tester.widget<CustomPaint>(pintorDeLaEstrella()).painter!;

    expect(vacia.shouldRepaint(marcada), isTrue);
  });

  testWidgets('ocupa tamano x tamano por defecto en las tres identidades', (
    tester,
  ) async {
    for (final codigo in catalogoIdentidades.keys) {
      aplicarIdentidadEquipada(codigo);
      await tester.pumpWidget(montar(const EstrellaValoracion(marcada: true)));
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byType(EstrellaValoracion)),
        const Size(36, 36),
        reason: codigo,
      );
    }
  });

  testWidgets(
    'tocar la tercera estrella marca 3 y volver a tocarla deja null',
    (tester) async {
      aplicarIdentidadEquipada('TEMA_PROFUNDIDAD');
      Map<String, dynamic>? resultado;
      await tester.pumpWidget(
        montar(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                resultado = await ValoracionSheet.mostrar(context);
              },
              child: const Text('abrir'),
            ),
          ),
        ),
      );

      // Primera apertura: tocar la 3.ª y guardar.
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(IconButton).at(2));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(resultado?['valoracion'], 3);

      // Segunda apertura: tocar la 3.ª dos veces y guardar.
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(IconButton).at(2));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(IconButton).at(2));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(resultado?['valoracion'], isNull);
    },
  );

  testWidgets('el diálogo sigue teniendo 5 botones de estrella pulsables', (
    tester,
  ) async {
    aplicarIdentidadEquipada('TEMA_DULCE');
    await tester.pumpWidget(
      montar(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => ValoracionSheet.mostrar(context),
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.byType(IconButton), findsNWidgets(5));
  });
}
