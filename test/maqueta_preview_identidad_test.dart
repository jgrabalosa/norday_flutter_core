import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:norday_flutter_core/l10n/norday_core_localizations.dart';
import 'package:norday_flutter_core/theme/app_theme.dart';
import 'package:norday_flutter_core/theme/identidad_paleta.dart';
import 'package:norday_flutter_core/theme/identidades_paleta.dart';
import 'package:norday_flutter_core/widgets/preview_identidad_tienda.dart';

/// La maqueta se pinta con la identidad que se LISTA, nunca con la equipada:
/// estos tests fijan la identidad equipada a otra distinta para comprobarlo.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Sin esto, construir un tema intenta bajar las fuentes por HTTP.
  GoogleFonts.config.allowRuntimeFetching = false;

  final identidadInicial = identidadEquipadaNotifier.value;
  tearDown(() => aplicarIdentidadEquipada(identidadInicial.codigo));

  /// Igual que la tienda: la maqueta dentro de un ListView, sin altura acotada.
  Future<void> montarEnLista(
    WidgetTester tester,
    IdentidadPaleta id, {
    double textScale = 1,
    Size tamano = const Size(390, 844),
  }) => _montar(
    tester,
    id,
    textScale: textScale,
    tamano: tamano,
    cuerpo: (maqueta) => ListView(children: [maqueta]),
  );

  /// Igual que la elección de identidad: la maqueta dentro de un Expanded.
  Future<void> montarEnExpanded(
    WidgetTester tester,
    IdentidadPaleta id, {
    double textScale = 1,
    Size tamano = const Size(390, 844),
  }) => _montar(
    tester,
    id,
    textScale: textScale,
    tamano: tamano,
    cuerpo: (maqueta) => Column(
      children: [
        const SizedBox(height: 40),
        Expanded(child: maqueta),
      ],
    ),
  );

  testWidgets(
    'las tres identidades muestran Hoy y las dos tarjetas, sin «Continuar»',
    (tester) async {
      for (final id in catalogoIdentidades.values) {
        await montarEnLista(tester, id);
        expect(find.text('Hoy'), findsWidgets, reason: id.codigo);
        expect(find.text('Beber agua'), findsOneWidget, reason: id.codigo);
        expect(find.text('Meditar 5 min'), findsOneWidget, reason: id.codigo);
        expect(find.text('Continuar'), findsNothing, reason: id.codigo);
      }
    },
  );

  testWidgets(
    'las tarjetas usan la fuente de la identidad listada, no la equipada',
    (tester) async {
      // Equipada: Profundidad. Listada: Dulce (Caveat en el cuerpo).
      aplicarIdentidadEquipada('TEMA_PROFUNDIDAD');
      final dulce = catalogoIdentidades['TEMA_DULCE']!;
      await montarEnLista(tester, dulce);

      final texto = tester.widget<Text>(find.text('Beber agua'));
      expect(
        _familia(texto.style),
        contains(_normalizar(dulce.fontBody)),
        reason: 'el cuerpo debe ir en la letra de Dulce',
      );
      final titulo = tester.widget<Text>(find.text('Hoy').first);
      expect(_familia(titulo.style), contains(_normalizar(dulce.fontDisplay)));
    },
  );

  for (final id in catalogoIdentidades.values) {
    testWidgets(
      '${id.nombre}: sin overflow a 320 px y 1,5 en lista y en Expanded',
      (tester) async {
        await montarEnLista(
          tester,
          id,
          textScale: 1.5,
          tamano: const Size(320, 640),
        );
        expect(tester.takeException(), isNull, reason: 'lista');

        await montarEnExpanded(
          tester,
          id,
          textScale: 1.5,
          tamano: const Size(320, 640),
        );
        expect(tester.takeException(), isNull, reason: 'Expanded');
      },
    );
  }
}

Future<void> _montar(
  WidgetTester tester,
  IdentidadPaleta id, {
  required double textScale,
  required Size tamano,
  required Widget Function(Widget maqueta) cuerpo,
}) async {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: const [
        NordayCoreLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es'), Locale('en'), Locale('pt')],
      theme: AppTheme.deTema(temaEquipadoNotifier.value),
      builder: (context, app) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: app!,
      ),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: cuerpo(MaquetaPreviewIdentidad(identidad: id)),
        ),
      ),
    ),
  );
  await tester.pump();
}

/// La familia de un estilo, en minúsculas y sin espacios: `GoogleFonts`
/// la escribe con su variante (p. ej. `Caveat_regular`).
String _familia(TextStyle? estilo) =>
    (estilo?.fontFamily ?? '').toLowerCase().replaceAll(' ', '');

String _normalizar(String nombre) => nombre.toLowerCase().replaceAll(' ', '');
