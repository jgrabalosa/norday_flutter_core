import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norday_flutter_core/l10n/catalogos_core.dart';
import 'package:norday_flutter_core/l10n/norday_core_localizations.dart';

/// Los textos de Nori vestida (N-12): prendas, colecciones, vestidor y tienda.
void main() {
  // código: [es, en, pt] del nombre y de la descripción.
  const prendas = <String, List<List<String>>>{
    'PRENDA_GORRO_LANA': [
      ['Gorro de lana', 'Wool hat', 'Gorro de lã'],
      [
        'Para las mañanas frías. El brote sigue asomando.',
        'For cold mornings. The sprout still peeks out.',
        'Para as manhãs frias. O rebento continua a espreitar.',
      ],
    ],
    'PRENDA_BUFANDA': [
      ['Bufanda de rayas', 'Striped scarf', 'Cachecol às riscas'],
      [
        'Calentita, a rayas y con flecos.',
        'Warm, striped and fringed.',
        'Quentinho, às riscas e com franjas.',
      ],
    ],
    'PRENDA_GORRO_NOEL': [
      ['Gorro de Papá Noel', 'Santa hat', 'Gorro de Pai Natal'],
      [
        'Con borla. Tapa el brote, solo por unos días.',
        'With a pompom. It hides the sprout, just for a few days.',
        'Com pompom. Tapa o rebento, só por uns dias.',
      ],
    ],
    'PRENDA_TRAJE_NOEL': [
      ['Traje de Papá Noel', 'Santa suit', 'Fato de Pai Natal'],
      [
        'Rojo, con cinturón y hebilla dorada. Se ve desde que Nori es cría.',
        'Red, with a belt and a gold buckle. Shows from the hatchling stage.',
        'Vermelho, com cinto e fivela dourada. Vê-se a partir de cria.',
      ],
    ],
  };
  const colecciones = <String, List<String>>{
    'INVIERNO_2026': ['Invierno', 'Winter', 'Inverno'],
    'NAVIDAD_2026': ['Navidad', 'Christmas', 'Natal'],
  };
  const idiomas = ['es', 'en', 'pt'];

  Future<BuildContext> montar(WidgetTester tester, String idioma) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        locale: Locale(idioma),
        localizationsDelegates: NordayCoreLocalizations.localizationsDelegates,
        supportedLocales: NordayCoreLocalizations.supportedLocales,
        home: Builder(
          builder: (c) {
            ctx = c;
            return const SizedBox();
          },
        ),
      ),
    );
    return ctx;
  }

  for (var i = 0; i < idiomas.length; i++) {
    final idioma = idiomas[i];

    testWidgets('las prendas se traducen por código en $idioma', (
      tester,
    ) async {
      final ctx = await montar(tester, idioma);
      prendas.forEach((codigo, textos) {
        expect(
          CatalogosCore.producto(ctx, codigo, 'backend'),
          textos[0][i],
          reason: codigo,
        );
        expect(
          CatalogosCore.productoDescripcion(ctx, codigo, 'backend'),
          textos[1][i],
          reason: codigo,
        );
      });
    });

    testWidgets('las colecciones se traducen en $idioma', (tester) async {
      final ctx = await montar(tester, idioma);
      colecciones.forEach((codigo, textos) {
        expect(
          CatalogosCore.coleccion(ctx, codigo, 'backend'),
          textos[i],
          reason: codigo,
        );
      });
    });
  }

  testWidgets('una colección desconocida o sin código cae al backend', (
    tester,
  ) async {
    final ctx = await montar(tester, 'es');
    expect(CatalogosCore.coleccion(ctx, 'OTRA', 'Primavera'), 'Primavera');
    expect(CatalogosCore.coleccion(ctx, null, 'Primavera'), 'Primavera');
  });

  test('los textos con valor lo meten en su sitio', () {
    final es = lookupNordayCoreLocalizations(const Locale('es'));
    final en = lookupNordayCoreLocalizations(const Locale('en'));
    final pt = lookupNordayCoreLocalizations(const Locale('pt'));
    expect(es.vestidorSeVeraCuando('cría'), 'Se verá cuando Nori sea cría');
    expect(
      en.vestidorSeVeraCuando('hatchling'),
      'Shows from the hatchling stage',
    );
    expect(pt.vestidorSeVeraCuando('cria'), 'Vê-se a partir de cria');
    expect(es.tiendaHastaEl('6 ene'), 'Hasta el 6 ene');
    expect(en.tiendaHastaEl('Jan 6'), 'Until Jan 6');
    expect(pt.tiendaHastaEl('6 jan'), 'Até 6 jan');
  });

  test('los textos fijos del vestidor y la tienda', () {
    const esperado = {
      'es': [
        'Cabeza',
        'Cuerpo',
        'Vestidor',
        'Nada',
        'Nori',
        'Gratis',
        'Tuyo',
        'Probar',
      ],
      'en': [
        'Head',
        'Body',
        'Wardrobe',
        'Nothing',
        'Nori',
        'Free',
        'Yours',
        'Try on',
      ],
      'pt': [
        'Cabeça',
        'Corpo',
        'Roupeiro',
        'Nada',
        'Nori',
        'Grátis',
        'Teu',
        'Experimentar',
      ],
    };
    esperado.forEach((idioma, textos) {
      final l = lookupNordayCoreLocalizations(Locale(idioma));
      expect(
        [
          l.mascotaSitioCabeza,
          l.mascotaSitioCuerpo,
          l.vestidorTitulo,
          l.vestidorNada,
          l.tiendaSeccionNori,
          l.tiendaGratis,
          l.tiendaTuyo,
          l.tiendaProbar,
        ],
        textos,
        reason: idioma,
      );
    });
  });
}
