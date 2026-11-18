import 'package:flutter/material.dart';
import 'dart:ui' show Tristate;

import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:norday_flutter_core/l10n/norday_core_localizations.dart';
import 'package:norday_flutter_core/models/manifiesto_arte.dart';
import 'package:norday_flutter_core/services/api_error.dart';
import 'package:norday_flutter_core/theme/equipamiento.dart';
import 'package:norday_flutter_core/theme/prendas.dart';
import 'package:norday_flutter_core/widgets/vestidor_nori.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Una entrada del inventario, como la manda `getInventarioProductos`.
Map<String, dynamic> _inv(
  int productoId,
  String codigo,
  String categoria, {
  String nombre = '',
  bool equipado = false,
}) => {
  'usuarioProductoId': productoId + 100,
  'cantidad': 1,
  'equipado': equipado,
  'producto': {
    'productoId': productoId,
    'codigo': codigo,
    'nombre': nombre,
    'categoria': categoria,
  },
};

/// El vestidor (Nori vestida, N-10), montado solo: la pantalla de Nori llama
/// al backend al montarse y no se puede probar entera.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final manifiesto = ValueNotifier(
    ManifiestoArte.fromJson({
      'version': 1,
      'prendas': {
        'PRENDA_GORRO_LANA': {
          'sitio': 'cabeza',
          'fases': ['huevo', 'cria', 'adulto'],
        },
        'PRENDA_TRAJE_NOEL': {
          'sitio': 'cuerpo',
          'fases': ['cria', 'adulto'],
        },
      },
    }),
  );

  late List<String> llamadas;
  late bool fallar;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    aplicarPrendasEquipadas(const {});
    Equipamiento.reiniciarParaTest();
    llamadas = [];
    fallar = false;
    Equipamiento.equiparEnBackend = (u, p) async {
      llamadas.add('equipar $p');
      if (fallar) throw const ApiException(TipoErrorApi.servidor);
      return const [];
    };
    Equipamiento.desequiparEnBackend = (u, p) async {
      llamadas.add('desequipar $p');
      if (fallar) throw const ApiException(TipoErrorApi.servidor);
    };
  });

  tearDown(() {
    Equipamiento.reiniciarParaTest();
    aplicarPrendasEquipadas(const {});
  });

  final inventarioConPrendas = [
    _inv(1, 'COMIDA_BASICA', 'Consumible'),
    _inv(2, 'TEMA_DULCE', 'Tema', equipado: true),
    _inv(10, 'PRENDA_GORRO_LANA', 'Cabeza'),
    _inv(11, 'PRENDA_GORRO_NOEL', 'Cabeza'),
    _inv(12, 'PRENDA_TRAJE_NOEL', 'Cuerpo'),
  ];

  Future<void> montar(
    WidgetTester tester, {
    required List<dynamic> inventario,
    String fase = 'CRIA',
    Locale locale = const Locale('es'),
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: NordayCoreLocalizations.localizationsDelegates,
        supportedLocales: NordayCoreLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: VestidorNori(
              usuarioId: 7,
              inventario: inventario,
              fase: fase,
              manifiesto: manifiesto,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  bool puesta(WidgetTester tester, String clave) =>
      tester
          .getSemantics(find.byKey(ValueKey(clave)))
          .flagsCollection
          .isSelected ==
      Tristate.isTrue;

  testWidgets('sin prendas en el inventario no pinta nada', (tester) async {
    await montar(tester, inventario: [_inv(1, 'COMIDA_BASICA', 'Consumible')]);
    expect(find.text('Vestidor'), findsNothing);
    expect(tester.getSize(find.byType(VestidorNori)).height, 0);
  });

  testWidgets('una fila por sitio, con «Nada» y sus prendas, traducidas', (
    tester,
  ) async {
    await montar(tester, inventario: inventarioConPrendas);
    expect(find.text('Vestidor'), findsOneWidget);
    expect(find.text('Cabeza'), findsOneWidget);
    expect(find.text('Cuerpo'), findsOneWidget);
    expect(find.text('Nada'), findsNWidgets(2));
    expect(find.text('Gorro de lana'), findsOneWidget);
    expect(find.text('Gorro de Papá Noel'), findsOneWidget);
    expect(find.text('Traje de Papá Noel'), findsOneWidget);
    // Lo que no es prenda no sale.
    expect(find.textContaining('COMIDA'), findsNothing);
    expect(puesta(tester, 'vestidor_Cabeza_nada'), isTrue);
  });

  testWidgets('sin traducción, el nombre del inventario; nunca el código', (
    tester,
  ) async {
    await montar(
      tester,
      inventario: [
        _inv(20, 'PRENDA_NUEVA', 'Cabeza', nombre: 'Diadema de estrellas'),
      ],
    );
    expect(find.text('Diadema de estrellas'), findsOneWidget);
    expect(find.text('PRENDA_NUEVA'), findsNothing);
  });

  testWidgets('poner, cambiar y «Nada»', (tester) async {
    await montar(tester, inventario: inventarioConPrendas);

    await tester.tap(find.text('Gorro de lana'));
    await tester.pump();
    await tester.pump();
    expect(llamadas, ['equipar 10']);
    expect(prendasEquipadasNotifier.value, {'Cabeza': 'PRENDA_GORRO_LANA'});
    expect(puesta(tester, 'vestidor_PRENDA_GORRO_LANA'), isTrue);
    expect(puesta(tester, 'vestidor_Cabeza_nada'), isFalse);

    await tester.tap(find.text('Gorro de Papá Noel'));
    await tester.pump();
    await tester.pump();
    expect(llamadas.last, 'equipar 11');
    expect(prendasEquipadasNotifier.value, {'Cabeza': 'PRENDA_GORRO_NOEL'});

    // Tocar la puesta no hace nada.
    await tester.tap(find.text('Gorro de Papá Noel'));
    await tester.pump();
    expect(llamadas, hasLength(2));

    await tester.tap(find.byKey(const ValueKey('vestidor_Cabeza_nada')));
    await tester.pump();
    await tester.pump();
    expect(llamadas.last, 'desequipar 11');
    expect(prendasEquipadasNotifier.value, isEmpty);
    expect(puesta(tester, 'vestidor_Cabeza_nada'), isTrue);
  });

  testWidgets('si el backend falla, no cambia nada y se avisa', (tester) async {
    aplicarPrendasEquipadas(const {'Cabeza': 'PRENDA_GORRO_LANA'});
    fallar = true;
    await montar(tester, inventario: inventarioConPrendas);

    await tester.tap(find.text('Gorro de Papá Noel'));
    await tester.pump();
    await tester.pump();
    expect(prendasEquipadasNotifier.value, {'Cabeza': 'PRENDA_GORRO_LANA'});
    expect(puesta(tester, 'vestidor_PRENDA_GORRO_LANA'), isTrue);
    expect(find.byType(SnackBar), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('vestidor_Cabeza_nada')));
    await tester.pump();
    await tester.pump();
    expect(llamadas, ['equipar 11', 'desequipar 10']);
    expect(prendasEquipadasNotifier.value, {'Cabeza': 'PRENDA_GORRO_LANA'});
  });

  testWidgets('lo puesto cambia desde fuera: el vestidor lo sigue', (
    tester,
  ) async {
    await montar(tester, inventario: inventarioConPrendas);
    aplicarPrendasEquipadas(const {'Cuerpo': 'PRENDA_TRAJE_NOEL'});
    await tester.pump();
    expect(puesta(tester, 'vestidor_PRENDA_TRAJE_NOEL'), isTrue);
    expect(puesta(tester, 'vestidor_Cuerpo_nada'), isFalse);
  });

  group('«Se verá cuando…»', () {
    testWidgets('el traje en el huevo avisa de la primera fase en que se ve', (
      tester,
    ) async {
      await montar(tester, fase: 'HUEVO', inventario: inventarioConPrendas);
      expect(find.text('Se verá cuando Nori sea cría'), findsOneWidget);
    });

    testWidgets('y se puede poner igual', (tester) async {
      await montar(tester, fase: 'HUEVO', inventario: inventarioConPrendas);
      await tester.tap(find.text('Traje de Papá Noel'));
      await tester.pump();
      await tester.pump();
      expect(llamadas, ['equipar 12']);
      expect(prendasEquipadasNotifier.value, {'Cuerpo': 'PRENDA_TRAJE_NOEL'});
    });

    testWidgets('en una fase en que se ve, ni en una prenda sin arte, no '
        'avisa', (tester) async {
      await montar(
        tester,
        inventario: [
          ...inventarioConPrendas,
          _inv(20, 'PRENDA_NUEVA', 'Cabeza', nombre: 'Diadema'),
        ],
      );
      expect(find.textContaining('Se verá'), findsNothing);
    });

    testWidgets('en inglés y en portugués', (tester) async {
      await montar(
        tester,
        fase: 'HUEVO',
        inventario: inventarioConPrendas,
        locale: const Locale('en'),
      );
      expect(
        find.text(
          lookupNordayCoreLocalizations(
            const Locale('en'),
          ).vestidorSeVeraCuando('hatchling'),
        ),
        findsOneWidget,
      );
      await montar(
        tester,
        fase: 'HUEVO',
        inventario: inventarioConPrendas,
        locale: const Locale('pt'),
      );
      expect(
        find.text(
          lookupNordayCoreLocalizations(
            const Locale('pt'),
          ).vestidorSeVeraCuando('cria'),
        ),
        findsOneWidget,
      );
    });
  });

  testWidgets('una prenda del inventario que ya no se vende sale y se pone', (
    tester,
  ) async {
    // El vestidor no mira el catálogo: basta con que esté en el inventario.
    await montar(tester, inventario: [_inv(30, 'PRENDA_BUFANDA', 'Cuerpo')]);
    await tester.tap(find.text('Bufanda de rayas'));
    await tester.pump();
    await tester.pump();
    expect(llamadas, ['equipar 30']);
    expect(prendasEquipadasNotifier.value, {'Cuerpo': 'PRENDA_BUFANDA'});
  });
}
