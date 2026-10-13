import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norday_flutter_core/l10n/catalogos_core.dart';
import 'package:norday_flutter_core/l10n/norday_core_localizations.dart';

void main() {
  late BuildContext contexto;

  Future<void> montar(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          NordayCoreLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('es'), Locale('en'), Locale('pt')],
        home: Builder(
          builder: (context) {
            contexto = context;
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    CatalogosCore.registrarProductosDeDominio(
      nombres: (_) => {'PRODUCTO_DE_APP': 'App product'},
      descripciones: (_) => {'PRODUCTO_DE_APP': 'What it does'},
      usos: (_) => {'PRODUCTO_DE_APP': 'Use it from its screen'},
    );
  });

  testWidgets('el nombre de un producto de la app sale traducido', (
    tester,
  ) async {
    await montar(tester);
    expect(
      CatalogosCore.producto(contexto, 'PRODUCTO_DE_APP', 'Producto'),
      'App product',
    );
  });

  testWidgets('su descripción también', (tester) async {
    await montar(tester);
    expect(
      CatalogosCore.productoDescripcion(
        contexto,
        'PRODUCTO_DE_APP',
        'Qué hace',
      ),
      'What it does',
    );
  });

  testWidgets('y su forma de uso', (tester) async {
    await montar(tester);
    expect(
      CatalogosCore.productoUso(contexto, 'PRODUCTO_DE_APP'),
      'Use it from its screen',
    );
  });

  testWidgets('los productos del core siguen con su traducción', (
    tester,
  ) async {
    await montar(tester);
    expect(CatalogosCore.producto(contexto, 'COMIDA_BASICA', 'Comida'), 'Food');
    expect(CatalogosCore.productoUso(contexto, 'COMIDA_BASICA'), isNull);
  });

  testWidgets('un código que nadie conoce cae al texto del backend', (
    tester,
  ) async {
    await montar(tester);
    expect(CatalogosCore.producto(contexto, 'OTRO', 'Otro'), 'Otro');
    expect(CatalogosCore.productoUso(contexto, 'OTRO'), isNull);
    expect(CatalogosCore.productoUso(contexto, null), isNull);
  });
}
