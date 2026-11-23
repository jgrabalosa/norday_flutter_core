import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:norday_flutter_core/l10n/norday_core_localizations.dart';
import 'package:norday_flutter_core/l10n/textos_app.dart';
import 'package:norday_flutter_core/theme/app_theme.dart';
import 'package:norday_flutter_core/theme/identidades_paleta.dart';
import 'package:norday_flutter_core/theme/prendas.dart';
import 'package:norday_flutter_core/widgets/tarjeta_nori.dart';

/// T-063a: la postal de Nori. Además, un test que sólo corre a petición
/// exporta la postal en las tres identidades:
/// `NORDAY_NORI_PNG=/ruta/carpeta flutter test test/tarjeta_nori_test.dart`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final identidadInicial = identidadEquipadaNotifier.value;
  tearDown(() {
    aplicarIdentidadEquipada(identidadInicial.codigo);
    aplicarPrendasEquipadas(const {});
  });

  Future<void> montar(
    WidgetTester tester,
    Widget tarjeta, {
    GlobalKey? clave,
  }) async {
    await tester.binding.setSurfaceSize(const Size(400, 500));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: NordayCoreLocalizations.localizationsDelegates,
        supportedLocales: NordayCoreLocalizations.supportedLocales,
        theme: AppTheme.deTema(temaEquipadoNotifier.value),
        home: Center(
          child: RepaintBoundary(key: clave, child: tarjeta),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('pinta el nombre, el nivel y la marca, a 360 × 450', (
    tester,
  ) async {
    await montar(
      tester,
      const TarjetaNori(fase: 'CRIA', nombre: 'Pepa', nivel: 4),
    );
    expect(find.text('Pepa'), findsOneWidget);
    expect(find.text('Nivel 4'), findsOneWidget);
    expect(find.text('Norday'), findsOneWidget);
    expect(tester.getSize(find.byType(TarjetaNori)), const Size(360, 450));
  });

  testWidgets('sin nombre pinta el de la fase', (tester) async {
    await montar(
      tester,
      const TarjetaNori(fase: 'CRIA', nombre: '  ', nivel: 4),
    );
    expect(find.text('Cría'), findsOneWidget);
  });

  testWidgets('la marca es la de TextosApp, o la que se pase', (tester) async {
    TextosApp.registrar(nombre: (_) => 'Norday Habits');
    addTearDown(() => TextosApp.nombre = null);
    await montar(
      tester,
      const TarjetaNori(fase: 'CRIA', nombre: 'Pepa', nivel: 4),
    );
    expect(find.text('Norday Habits'), findsOneWidget);

    await montar(
      tester,
      const TarjetaNori(
        fase: 'CRIA',
        nombre: 'Pepa',
        nivel: 4,
        marca: 'Norday Focus',
      ),
    );
    expect(find.text('Norday Focus'), findsOneWidget);
  });

  final carpeta = Platform.environment['NORDAY_NORI_PNG'];
  testWidgets('exporta la postal en las tres identidades', (tester) async {
    for (final codigo in [
      'TEMA_PROFUNDIDAD',
      'TEMA_NEOTOKYO_PLUS',
      'TEMA_DULCE',
    ]) {
      aplicarIdentidadEquipada(codigo);
      final clave = GlobalKey();
      await montar(
        tester,
        const TarjetaNori(
          fase: 'ADULTO',
          nombre: 'Pepa',
          nivel: 7,
          marca: 'Norday Habits',
        ),
        clave: clave,
      );
      await tester.pump(const Duration(milliseconds: 200));
      await tester.runAsync(() async {
        final frontera =
            clave.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final imagen = await frontera.toImage(pixelRatio: 3);
        final bytes = await imagen.toByteData(format: ui.ImageByteFormat.png);
        File(
          '$carpeta/nori_$codigo.png',
        ).writeAsBytesSync(bytes!.buffer.asUint8List());
      });
    }
  }, skip: carpeta == null);
}
