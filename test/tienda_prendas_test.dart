import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:norday_flutter_core/l10n/norday_core_localizations.dart';
import 'package:norday_flutter_core/screens/coleccion_screen.dart';
import 'package:norday_flutter_core/screens/tienda_screen.dart';
import 'package:norday_flutter_core/services/api_error.dart';
import 'package:norday_flutter_core/services/arte_prendas_service.dart';
import 'package:norday_flutter_core/services/manifiesto_compartido.dart';
import 'package:norday_flutter_core/theme/app_theme.dart';
import 'package:norday_flutter_core/theme/equipamiento.dart';
import 'package:norday_flutter_core/theme/identidades_paleta.dart';
import 'package:norday_flutter_core/theme/prendas.dart';
import 'package:norday_flutter_core/widgets/nori_vestida.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> _prenda(
  int id,
  String codigo,
  String sitio, {
  String? coleccion,
  int precio = 300,
  List<Map<String, dynamic>>? ofertas,
}) => {
  'productoId': id,
  'codigo': codigo,
  'nombre': codigo,
  'descripcion': '',
  'tipo': 'EQUIPABLE',
  'categoria': sitio,
  'precio': precio,
  'coleccion': ?coleccion,
  'ofertas': ?ofertas,
};

Map<String, dynamic> _oferta(String desde, String hasta, int precio) => {
  'desde': desde,
  'hasta': hasta,
  'precio': precio,
};

const _temaDulce = {
  'productoId': 21,
  'codigo': 'TEMA_DULCE',
  'nombre': 'Dulce',
  'descripcion': '',
  'tipo': 'EQUIPABLE',
  'categoria': 'Tema',
  'precio': 1000,
};

const _comida = {
  'productoId': 12,
  'codigo': 'COMIDA_BASICA',
  'nombre': 'Comida básica',
  'descripcion': '',
  'tipo': 'CONSUMIBLE',
  'categoria': 'Consumible',
  'precio': 20,
};

Map<String, dynamic> _inv(int productoId, {bool equipado = false}) => {
  'producto': {'productoId': productoId},
  'cantidad': 1,
  'equipado': equipado,
};

/// La tienda con las prendas de Nori (N-10). Todo lo que pide al backend pasa
/// por los seams de `TiendaScreen` y de `Equipamiento`, que cuentan aquí las
/// llamadas; las del servidor del arte van aparte y no cuentan.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final identidadInicial = identidadEquipadaNotifier.value;

  late List<dynamic> catalogo;
  late List<dynamic> inventario;
  late List<String> backend;
  late Object? errorCompra;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    aplicarPrendasEquipadas(const {});
    Equipamiento.reiniciarParaTest();
    reiniciarManifiestoParaTest();
    servicioManifiesto = () => ArtePrendasService(
      cliente: MockClient(
        (_) async => http.Response(
          jsonEncode({'version': 1, 'prendas': <String, dynamic>{}}),
          200,
        ),
      ),
      urlBase: 'https://servidor.test/api',
    );
    catalogo = [];
    inventario = [];
    backend = [];
    errorCompra = null;
    TiendaScreen.ahora = () => DateTime(2026, 12, 10, 23, 30);
    TiendaScreen.obtenerSaldo = (_) async {
      backend.add('saldo');
      return 500;
    };
    TiendaScreen.obtenerCatalogo = () async {
      backend.add('catalogo');
      return catalogo;
    };
    TiendaScreen.obtenerInventario = (_) async {
      backend.add('inventario');
      return inventario;
    };
    TiendaScreen.comprar = (u, p) async {
      backend.add('comprar $p');
      if (errorCompra != null) throw errorCompra!;
      return const [];
    };
    Equipamiento.equiparEnBackend = (u, p) async {
      backend.add('equipar $p');
      return const [];
    };
    Equipamiento.desequiparEnBackend = (u, p) async {
      backend.add('desequipar $p');
    };
  });

  tearDown(() {
    TiendaScreen.reiniciarParaTest();
    ColeccionScreen.reiniciarParaTest();
    Equipamiento.reiniciarParaTest();
    reiniciarManifiestoParaTest();
    aplicarPrendasEquipadas(const {});
    aplicarIdentidadEquipada(identidadInicial.codigo);
  });

  Widget app(Widget home, {Locale locale = const Locale('es')}) => MaterialApp(
    locale: locale,
    localizationsDelegates: NordayCoreLocalizations.localizationsDelegates,
    supportedLocales: NordayCoreLocalizations.supportedLocales,
    theme: AppTheme.deTema(temaEquipadoNotifier.value),
    home: home,
  );

  /// Sin pumpAndSettle: el fondo anima sin parar.
  Future<void> montar(
    WidgetTester tester, {
    Locale locale = const Locale('es'),
  }) async {
    tester.view.physicalSize = const Size(400, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      app(const TiendaScreen(usuarioId: 7), locale: locale),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  Finder tarjeta(int id) => find.byKey(ValueKey('tienda_prenda_$id'));

  Finder en(int id, Finder f) => find.descendant(of: tarjeta(id), matching: f);

  group('la sección Nori', () {
    testWidgets('agrupada por colección, y sin colección al final y sin '
        'título', (tester) async {
      catalogo = [
        _temaDulce,
        _prenda(1, 'PRENDA_GORRO_NOEL', 'Cabeza', coleccion: 'NAVIDAD_2026'),
        _prenda(2, 'PRENDA_GORRO_LANA', 'Cabeza', coleccion: 'INVIERNO_2026'),
        _prenda(3, 'PRENDA_SUELTA', 'Cuerpo'),
        _prenda(4, 'PRENDA_TRAJE_NOEL', 'Cuerpo', coleccion: 'NAVIDAD_2026'),
        _prenda(5, 'PRENDA_RARA', 'Cabeza', coleccion: 'PRIMAVERA_2027'),
      ];
      await montar(tester);

      expect(find.text('Nori'), findsOneWidget);
      expect(find.text('Navidad'), findsOneWidget);
      expect(find.text('Invierno'), findsOneWidget);
      // Una colección sin traducir no enseña su código.
      expect(find.text('PRIMAVERA_2027'), findsNothing);

      double y(Finder f) => tester.getTopLeft(f).dy;
      expect(y(find.text('Navidad')), lessThan(y(tarjeta(1))));
      expect(y(tarjeta(1)), lessThan(y(tarjeta(4))));
      expect(y(tarjeta(4)), lessThan(y(find.text('Invierno'))));
      expect(y(find.text('Invierno')), lessThan(y(tarjeta(2))));
      expect(y(tarjeta(2)), lessThan(y(tarjeta(5))));
      expect(y(tarjeta(5)), lessThan(y(tarjeta(3))));
      // Las prendas no salen en el catálogo de siempre.
      expect(find.text('Gorro de Papá Noel'), findsOneWidget);
    });

    testWidgets('cada prenda lleva una Nori pequeña que la lleva puesta', (
      tester,
    ) async {
      catalogo = [_prenda(2, 'PRENDA_GORRO_LANA', 'Cabeza')];
      await montar(tester);
      final nori = tester.widget<NoriVestida>(en(2, find.byType(NoriVestida)));
      expect(nori.tamano, 64);
      expect(nori.prendas!.value, {'Cabeza': 'PRENDA_GORRO_LANA'});
    });

    testWidgets('sin prendas a la venta, no sale', (tester) async {
      catalogo = [_temaDulce];
      await montar(tester);
      expect(find.text('Nori'), findsNothing);
      expect(find.text('Dulce'), findsWidgets);
    });

    testWidgets('el precio de la oferta de hoy, «Gratis» y «Hasta el…»', (
      tester,
    ) async {
      catalogo = [
        _prenda(
          1,
          'PRENDA_GORRO_NOEL',
          'Cabeza',
          ofertas: [_oferta('2026-12-01', '2027-01-06', 0)],
        ),
        _prenda(
          2,
          'PRENDA_GORRO_LANA',
          'Cabeza',
          ofertas: [
            _oferta('2026-11-01', '2026-11-30', 150),
            _oferta('2026-12-01', '2027-02-28', 200),
          ],
        ),
      ];
      await montar(tester);
      expect(en(1, find.text('Gratis · Hasta el 6 ene')), findsOneWidget);
      expect(en(2, find.text('200 pts · Hasta el 28 feb')), findsOneWidget);
    });

    testWidgets('la fecha, en el idioma activo', (tester) async {
      catalogo = [
        _prenda(
          1,
          'PRENDA_GORRO_NOEL',
          'Cabeza',
          ofertas: [_oferta('2026-12-01', '2027-01-06', 0)],
        ),
      ];
      await montar(tester, locale: const Locale('en'));
      expect(en(1, find.text('Free · Until Jan 6')), findsOneWidget);
    });

    testWidgets('con todas sus ofertas en otros días, no sale', (tester) async {
      catalogo = [
        _prenda(
          1,
          'PRENDA_GORRO_NOEL',
          'Cabeza',
          ofertas: [_oferta('2026-12-24', '2027-01-06', 0)],
        ),
        _prenda(
          2,
          'PRENDA_GORRO_LANA',
          'Cabeza',
          ofertas: [_oferta('2026-11-01', '2026-11-30', 150)],
        ),
      ];
      await montar(tester);
      expect(tarjeta(1), findsNothing);
      expect(tarjeta(2), findsNothing);
      expect(find.text('Nori'), findsNothing);
    });

    testWidgets('sin ofertas, el precio de siempre y sin fecha', (
      tester,
    ) async {
      catalogo = [
        _prenda(2, 'PRENDA_GORRO_LANA', 'Cabeza', precio: 300),
        _prenda(3, 'PRENDA_BUFANDA', 'Cuerpo', precio: 250, ofertas: []),
      ];
      await montar(tester);
      expect(en(2, find.text('300 pts')), findsOneWidget);
      expect(en(3, find.text('250 pts')), findsOneWidget);
      expect(find.textContaining('Hasta el'), findsNothing);
    });

    testWidgets('comprar una prenda', (tester) async {
      catalogo = [_prenda(2, 'PRENDA_GORRO_LANA', 'Cabeza')];
      await montar(tester);
      await tester.tap(en(2, find.text('Comprar')));
      await tester.pump();
      await tester.pump();
      expect(backend, contains('comprar 2'));
    });

    testWidgets('ya es tuya: «Tuyo» y «Equipar», que la pone', (tester) async {
      catalogo = [_prenda(2, 'PRENDA_GORRO_LANA', 'Cabeza')];
      inventario = [_inv(2)];
      await montar(tester);
      expect(en(2, find.text('Tuyo')), findsOneWidget);
      expect(en(2, find.text('Comprar')), findsNothing);

      await tester.tap(en(2, find.text('Equipar')));
      await tester.pump();
      await tester.pump();
      expect(backend, contains('equipar 2'));
      expect(prendasEquipadasNotifier.value, {'Cabeza': 'PRENDA_GORRO_LANA'});
    });

    testWidgets('puesta: «Equipado», sin botón', (tester) async {
      catalogo = [_prenda(2, 'PRENDA_GORRO_LANA', 'Cabeza')];
      inventario = [_inv(2, equipado: true)];
      await montar(tester);
      expect(en(2, find.text('Equipado')), findsOneWidget);
      expect(en(2, find.text('Equipar')), findsNothing);
    });
  });

  group('«Probar»', () {
    testWidgets('Nori en grande con la prenda y lo demás que lleva, sin '
        'llamar al backend', (tester) async {
      aplicarPrendasEquipadas(const {
        'Cabeza': 'PRENDA_GORRO_LANA',
        'Cuerpo': 'PRENDA_BUFANDA',
      });
      catalogo = [_prenda(1, 'PRENDA_GORRO_NOEL', 'Cabeza')];
      await montar(tester);
      final antes = List.of(backend);

      await tester.tap(en(1, find.text('Probar')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final hoja = find.byType(BottomSheet);
      expect(hoja, findsOneWidget);
      final nori = tester.widget<NoriVestida>(
        find.descendant(of: hoja, matching: find.byType(NoriVestida)),
      );
      expect(nori.tamano, greaterThan(64));
      expect(nori.prendas!.value, {
        'Cabeza': 'PRENDA_GORRO_NOEL',
        'Cuerpo': 'PRENDA_BUFANDA',
      });
      // Ni equipa ni compra: lo puesto no cambia.
      expect(prendasEquipadasNotifier.value['Cabeza'], 'PRENDA_GORRO_LANA');

      await tester.tap(
        find.descendant(of: hoja, matching: find.text('Cerrar')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(BottomSheet), findsNothing);
      expect(backend, antes);
    });
  });

  group('un 409 al comprar', () {
    testWidgets('texto propio, recarga y no es un error de red', (
      tester,
    ) async {
      catalogo = [
        _prenda(
          1,
          'PRENDA_GORRO_NOEL',
          'Cabeza',
          ofertas: [_oferta('2026-12-01', '2027-01-06', 0)],
        ),
      ];
      errorCompra = const ApiException(
        TipoErrorApi.peticionInvalida,
        codigoEstado: 409,
        cuerpo: '{"mensaje":"Fuera de temporada"}',
      );
      await montar(tester);
      backend.clear();

      await tester.tap(en(1, find.text('Comprar')));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(
        find.text('No se ha podido comprar. Hemos puesto la tienda al día.'),
        findsOneWidget,
      );
      expect(find.text('Fuera de temporada'), findsNothing);
      expect(backend, ['comprar 1', 'saldo', 'catalogo', 'inventario']);

      // Y nada más: ningún aviso genérico en cola detrás de este. Se miran
      // todos los avisos que salen en los siguientes 15 s.
      final vistos = <String?>{};
      for (var i = 0; i < 15; i++) {
        vistos.addAll(
          find
              .byType(SnackBar)
              .evaluate()
              .map((e) => ((e.widget as SnackBar).content as Text).data),
        );
        await tester.pump(const Duration(seconds: 1));
      }
      expect(vistos, {
        'No se ha podido comprar. Hemos puesto la tienda al día.',
      });
    });

    testWidgets('otro 4xx sigue siendo el error de la tienda, sin recargar', (
      tester,
    ) async {
      catalogo = [_prenda(1, 'PRENDA_GORRO_NOEL', 'Cabeza')];
      errorCompra = const ApiException(
        TipoErrorApi.peticionInvalida,
        codigoEstado: 400,
      );
      await montar(tester);
      backend.clear();

      await tester.tap(en(1, find.text('Comprar')));
      await tester.pump();
      await tester.pump();
      expect(
        find.text('No se pudo completar la operación. Inténtalo de nuevo.'),
        findsOneWidget,
      );
      expect(backend, ['comprar 1']);
    });
  });

  group('lo de siempre, igual', () {
    testWidgets('temas y comida, con su precio, se compran', (tester) async {
      catalogo = [_temaDulce, _comida];
      await montar(tester);
      expect(find.text('1000 pts'), findsOneWidget);
      expect(find.text('20 pts'), findsOneWidget);

      await tester.tap(find.text('Comprar').first);
      await tester.pump();
      await tester.pump();
      expect(backend, contains('comprar 21'));
    });

    testWidgets('un avatar que ya es tuyo se equipa como antes', (
      tester,
    ) async {
      catalogo = [
        {
          'productoId': 30,
          'codigo': 'AVATAR_ZORRO',
          'nombre': 'Zorro',
          'descripcion': '',
          'tipo': 'EQUIPABLE',
          'categoria': 'Avatar',
          'precio': 500,
        },
      ];
      inventario = [_inv(30)];
      await montar(tester);
      await tester.tap(find.text('Equipar'));
      await tester.pump();
      await tester.pump();
      expect(backend, contains('equipar 30'));
      expect(prendasEquipadasNotifier.value, isEmpty);
    });

    testWidgets('un tema que ya es tuyo se equipa como antes', (tester) async {
      catalogo = [_temaDulce];
      inventario = [_inv(21)];
      await montar(tester);
      await tester.tap(find.text('Equipar'));
      await tester.pump();
      await tester.pump();
      expect(backend, contains('equipar 21'));
      expect(prendasEquipadasNotifier.value, isEmpty);
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
    });
  });

  testWidgets('Colección no enseña las prendas', (tester) async {
    ColeccionScreen.obtenerCatalogo = () async => [
      _temaDulce,
      _comida,
      _prenda(1, 'PRENDA_GORRO_NOEL', 'Cabeza'),
      _prenda(2, 'PRENDA_TRAJE_NOEL', 'Cuerpo'),
    ];
    ColeccionScreen.obtenerInventario = (_) async => [_inv(1)];
    tester.view.physicalSize = const Size(400, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(app(const ColeccionScreen(usuarioId: 7)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Dulce'), findsWidgets);
    expect(find.text('Cabeza'), findsNothing);
    expect(find.text('Cuerpo'), findsNothing);
    expect(find.text('Gorro de Papá Noel'), findsNothing);
    expect(find.text('Traje de Papá Noel'), findsNothing);
  });
}
