import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:norday_flutter_core/l10n/catalogos_core.dart';
import 'package:norday_flutter_core/l10n/norday_core_localizations.dart';
import 'package:norday_flutter_core/screens/coleccion_screen.dart';
import 'package:norday_flutter_core/theme/app_theme.dart';
import 'package:norday_flutter_core/theme/identidades_paleta.dart';
import 'package:norday_flutter_core/widgets/superficie_identidad.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Productos de la app (no del core): el consumible con uso propio es la Pausa.
// Sus textos se registran como los registraría Norday Habits.
const _pausa = {
  'productoId': 10,
  'codigo': 'PAUSA',
  'nombre': 'Pausa',
  'categoria': 'Consumible',
};
const _comida = {
  'productoId': 12,
  'codigo': 'COMIDA_BASICA',
  'nombre': 'Comida básica',
  'categoria': 'Consumible',
};
const _escudo = {
  'productoId': 11,
  'codigo': 'ESCUDO_RACHA',
  'nombre': 'Escudo de racha',
  'categoria': 'Protección',
};
const _temaNeotokyo = {
  'productoId': 20,
  'codigo': 'TEMA_NEOTOKYO_PLUS',
  'nombre': 'Neotokyo+',
  'categoria': 'Tema',
};
const _temaDulce = {
  'productoId': 21,
  'codigo': 'TEMA_DULCE',
  'nombre': 'Dulce',
  'categoria': 'Tema',
};

const _usoPausaEs =
    'Se usa con «Pausar», en Hábitos o en el detalle de un hábito.';
const _usoPausaPt =
    'Usa-se com «Pausar», em Hábitos ou no detalhe de um hábito.';

Map<String, dynamic> _inv(
  int productoId, {
  int cantidad = 1,
  bool equipado = false,
}) => {
  'producto': {'productoId': productoId},
  'cantidad': cantidad,
  'equipado': equipado,
};

/// Cuenta las aperturas de la Tienda: cada ruta que se apila encima de la
/// raiz (Colección) es una.
class _Aperturas extends NavigatorObserver {
  int total = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null) total++;
  }
}

final _conseguir = find
    .widgetWithText(OutlinedButton, 'Conseguir')
    .hitTestable();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Sin esto, construir un tema en un test intenta bajar las fuentes por HTTP.
  GoogleFonts.config.allowRuntimeFetching = false;

  final identidadInicial = identidadEquipadaNotifier.value;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CatalogosCore.registrarProductosDeDominio(
      nombres: (_) => {'PAUSA': 'Pausa'},
      descripciones: (_) => {'PAUSA': 'Congela la racha un día.'},
      usos: (c) => {
        'PAUSA': Localizations.localeOf(c).languageCode == 'pt'
            ? _usoPausaPt
            : _usoPausaEs,
      },
    );
  });

  tearDown(() {
    ColeccionScreen.reiniciarParaTest();
    aplicarIdentidadEquipada(identidadInicial.codigo);
  });

  /// Monta Colección con un catálogo y un inventario fijos. No usa
  /// pumpAndSettle: el esqueleto y el fondo animan sin parar.
  Future<void> montar(
    WidgetTester tester, {
    required List<dynamic> catalogo,
    required List<dynamic> inventario,
    NavigatorObserver? observador,
    Locale locale = const Locale('es'),
    double textScale = 1,
    Size tamano = const Size(390, 844),
  }) async {
    tester.view.physicalSize = tamano;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    ColeccionScreen.obtenerCatalogo = () async => catalogo;
    ColeccionScreen.obtenerInventario = (_) async => inventario;

    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          NordayCoreLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('es'), Locale('en'), Locale('pt')],
        theme: AppTheme.deTema(temaEquipadoNotifier.value),
        navigatorObservers: [?observador],
        builder: (context, app) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: app!,
        ),
        home: const ColeccionScreen(usuarioId: 1),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  group('Tema', () {
    testWidgets('no poseído: sale «Conseguir» y no «Equipar»', (tester) async {
      await montar(tester, catalogo: [_temaNeotokyo], inventario: []);

      expect(_conseguir, findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Equipar'), findsNothing);
    });

    testWidgets('poseído sin equipar: sale «Equipar» y no «Conseguir»', (
      tester,
    ) async {
      await montar(tester, catalogo: [_temaDulce], inventario: [_inv(21)]);

      expect(find.widgetWithText(OutlinedButton, 'Equipar'), findsOneWidget);
      expect(_conseguir, findsNothing);
    });

    testWidgets('tocar «Conseguir» abre la Tienda una sola vez', (
      tester,
    ) async {
      final observador = _Aperturas();
      await montar(
        tester,
        catalogo: [_temaNeotokyo],
        inventario: [],
        observador: observador,
      );

      await tester.tap(_conseguir);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(observador.total, 1);
    });

    testWidgets('«Conseguir» se anuncia con el nombre del producto', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await montar(tester, catalogo: [_temaNeotokyo], inventario: []);

      expect(
        find.bySemanticsLabel('Conseguir «Neotokyo+» en la tienda'),
        findsOneWidget,
      );
      semantica.dispose();
    });

    testWidgets('al volver de la Tienda, Colección recarga el inventario', (
      tester,
    ) async {
      var cargas = 0;
      await montar(tester, catalogo: [_temaNeotokyo], inventario: []);
      ColeccionScreen.obtenerInventario = (_) async {
        cargas++;
        return [];
      };

      await tester.tap(_conseguir);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      tester.state<NavigatorState>(find.byType(Navigator).first).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(cargas, 1);
    });

    testWidgets('el botón de una tarjeta bloqueada no queda bajo el filtro', (
      tester,
    ) async {
      await montar(tester, catalogo: [_temaNeotokyo], inventario: []);

      // Primero que exista: sin el botón, «no hay filtro encima» se cumple
      // en vacío.
      expect(_conseguir, findsOneWidget);
      expect(
        find.ancestor(of: _conseguir, matching: find.byType(ColorFiltered)),
        findsNothing,
      );
      expect(
        find.ancestor(
          of: _conseguir,
          matching: find.byWidgetPredicate(
            (w) => w is Opacity && w.opacity < 1,
          ),
        ),
        findsNothing,
      );
    });
  });

  group('Consumible', () {
    testWidgets(
      '×0 con uso propio (Pausa): «Conseguir», sin «Usar»; sigue «x0» y el uso',
      (tester) async {
        await montar(
          tester,
          catalogo: [_pausa],
          inventario: [_inv(10, cantidad: 0)],
        );

        expect(_conseguir, findsOneWidget);
        expect(find.text('Usar'), findsNothing);
        expect(find.text('x0'), findsOneWidget);
        expect(find.text(_usoPausaEs), findsOneWidget);
      },
    );

    testWidgets('×0 sin uso propio: «Conseguir» y no «Usar»', (tester) async {
      await montar(
        tester,
        catalogo: [_comida],
        inventario: [_inv(12, cantidad: 0)],
      );

      expect(_conseguir, findsOneWidget);
      expect(find.text('Usar'), findsNothing);
      expect(find.text('x0'), findsOneWidget);
    });

    testWidgets('×3 sin uso propio: «Usar» y no «Conseguir»', (tester) async {
      await montar(
        tester,
        catalogo: [_comida],
        inventario: [_inv(12, cantidad: 3)],
      );

      expect(find.text('Usar'), findsOneWidget);
      expect(_conseguir, findsNothing);
    });

    testWidgets('«se activa solo» con ×0: «Conseguir»', (tester) async {
      await montar(
        tester,
        catalogo: [_escudo],
        inventario: [_inv(11, cantidad: 0)],
      );

      expect(_conseguir, findsOneWidget);
      expect(find.text('Se activa solo'), findsOneWidget);
    });

    testWidgets(
      'no poseído: «Conseguir» fuera del filtro, tocable y abre la Tienda una vez',
      (tester) async {
        final observador = _Aperturas();
        await montar(
          tester,
          catalogo: [_comida],
          inventario: [],
          observador: observador,
        );

        expect(_conseguir, findsOneWidget);
        expect(
          find.ancestor(of: _conseguir, matching: find.byType(ColorFiltered)),
          findsNothing,
        );

        await tester.tap(_conseguir);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(observador.total, 1);
      },
    );
  });

  group('Anchura', () {
    for (final codigo in ['es', 'pt']) {
      for (final escala in [1.0, 1.5]) {
        testWidgets(
          'Dulce, 320 px, texto $escala, tema no poseído en $codigo: sin overflow',
          (tester) async {
            aplicarIdentidadEquipada('TEMA_DULCE');
            await montar(
              tester,
              catalogo: [_temaNeotokyo],
              inventario: [],
              locale: Locale(codigo),
              textScale: escala,
              tamano: const Size(320, 640),
            );

            expect(tester.takeException(), isNull);
            expect(
              find.widgetWithText(OutlinedButton, 'Conseguir'),
              findsWidgets,
            );
          },
        );

        testWidgets(
          'Dulce, 320 px, texto $escala, Pausa ×0 en $codigo: sin overflow',
          (tester) async {
            aplicarIdentidadEquipada('TEMA_DULCE');
            await montar(
              tester,
              catalogo: [_pausa],
              inventario: [_inv(10, cantidad: 0)],
              locale: Locale(codigo),
              textScale: escala,
              tamano: const Size(320, 640),
            );

            expect(tester.takeException(), isNull);
            expect(
              find.widgetWithText(OutlinedButton, 'Conseguir'),
              findsWidgets,
            );
          },
        );
      }
    }
  });

  group('Copia invisible', () {
    // La copia bajo el filtro (la que reserva el hueco) y el boton real
    // tienen que caer en el mismo rectangulo: la tarjeta apagada tiene la
    // altura y el sitio que tendria la real.
    void mismoRectangulo(WidgetTester tester) {
      final botones = find.widgetWithText(OutlinedButton, 'Conseguir');
      expect(botones, findsNWidgets(2), reason: 'copia + real');
      final copia = tester.getRect(botones.at(0));
      final real = tester.getRect(botones.at(1));
      expect(real.size, copia.size);
      expect(real.topLeft.dx, closeTo(copia.left, 0.5));
      expect(real.topLeft.dy, closeTo(copia.top, 0.5));
    }

    testWidgets('tema no poseído: copia y boton real coinciden', (
      tester,
    ) async {
      await montar(tester, catalogo: [_temaNeotokyo], inventario: []);
      mismoRectangulo(tester);
    });

    testWidgets('consumible no poseído: copia y boton real coinciden', (
      tester,
    ) async {
      await montar(tester, catalogo: [_comida], inventario: []);
      mismoRectangulo(tester);
    });

    testWidgets('«Conseguir» del tema no poseído es tocable', (tester) async {
      final observador = _Aperturas();
      await montar(
        tester,
        catalogo: [_temaNeotokyo],
        inventario: [],
        observador: observador,
      );

      await tester.tap(_conseguir);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(observador.total, 1);
    });
  });

  group('Tema en propiedad', () {
    testWidgets(
      'no equipado, 320 px, texto 1,5, Dulce: sin overflow y «Equipar» tocable',
      (tester) async {
        aplicarIdentidadEquipada('TEMA_DULCE');
        await montar(
          tester,
          catalogo: [_temaDulce],
          inventario: [_inv(21)],
          textScale: 1.5,
          tamano: const Size(320, 640),
        );

        expect(tester.takeException(), isNull);
        final equipar = find.widgetWithText(OutlinedButton, 'Equipar');
        await tester.ensureVisible(equipar);
        await tester.pump();
        expect(equipar.hitTestable(), findsOneWidget);
      },
    );

    testWidgets('altura igual a la de no poseído (la copia reserva el hueco)', (
      tester,
    ) async {
      aplicarIdentidadEquipada('TEMA_DULCE');
      final tarjeta = find
          .ancestor(
            of: find.text('Dulce'),
            matching: find.byType(SuperficieIdentidad),
          )
          .first;

      await montar(
        tester,
        catalogo: [_temaDulce],
        inventario: [_inv(21)],
        textScale: 1.5,
        tamano: const Size(320, 640),
      );
      final alturaPoseido = tester.getSize(tarjeta).height;

      await montar(
        tester,
        catalogo: [_temaDulce],
        inventario: [],
        textScale: 1.5,
        tamano: const Size(320, 640),
      );
      final alturaNoPoseido = tester.getSize(tarjeta).height;

      expect(alturaPoseido, closeTo(alturaNoPoseido, 0.5));
    });
  });
}
