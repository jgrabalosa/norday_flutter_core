import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:norday_flutter_core/l10n/norday_core_localizations.dart';
import 'package:norday_flutter_core/models/manifiesto_arte.dart';
import 'package:norday_flutter_core/services/arte_prendas_service.dart';
import 'package:norday_flutter_core/services/manifiesto_compartido.dart';
import 'package:norday_flutter_core/theme/mascota_assets.dart';
import 'package:norday_flutter_core/theme/prendas.dart';
import 'package:norday_flutter_core/widgets/imagen_mascota.dart';
import 'package:norday_flutter_core/widgets/mascota_animada_viva.dart';
import 'package:norday_flutter_core/widgets/nori_marca.dart';
import 'package:norday_flutter_core/widgets/nori_vestida.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Nori vestida por capas (N-9), sin golden: se comprueba la estructura (qué
/// capas hay, en qué orden, cuánto sube el brote), lo que se pide y cuándo, y
/// lo que oye el lector. Lo visual lo mira Quim en el móvil.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  /// Un manifiesto como el de producción: gorro de lana (sube el brote), gorro
  /// de Papá Noel (lo oculta) y traje (solo cría y adulto), con una imagen por
  /// estado para la cría dormida del gorro de lana.
  final manifiestoBueno = ManifiestoArte.fromJson({
    'version': 1,
    'prendas': {
      'PRENDA_GORRO_LANA': {
        'sitio': 'cabeza',
        'fases': ['huevo', 'cria', 'adulto'],
        'subidaBrote': {'huevo': 76, 'cria': 24},
        'imagenes': {
          'huevo': 'prendas/lana_huevo.webp',
          'cria': 'prendas/lana_cria.webp',
          'cria_dormido': 'prendas/lana_cria_dormido.webp',
          'adulto': 'prendas/lana_adulto.webp',
        },
      },
      'PRENDA_GORRO_NOEL': {
        'sitio': 'cabeza',
        'fases': ['huevo', 'cria', 'adulto'],
        'oculta': ['brote'],
        'imagenes': {
          'huevo': 'prendas/noel_huevo.webp',
          'cria': 'prendas/noel_cria.webp',
          'adulto': 'prendas/noel_adulto.webp',
        },
      },
      'PRENDA_TRAJE_NOEL': {
        'sitio': 'cuerpo',
        'fases': ['cria', 'adulto'],
        'imagenes': {
          'cria': 'prendas/traje_cria.webp',
          'adulto': 'prendas/traje_adulto.webp',
        },
      },
    },
  });

  late Directory carpeta;
  late List<String> pedidas;
  late Set<String> sinFichero;
  late ValueNotifier<Map<String, String>> prendas;
  late ValueNotifier<ManifiestoArte> manifiesto;

  setUp(() {
    carpeta = Directory.systemTemp.createTempSync('nori_vestida_');
    pedidas = [];
    sinFichero = {};
    prendas = ValueNotifier(const {});
    manifiesto = ValueNotifier(manifiestoBueno);
    reiniciarManifiestoParaTest();
  });

  tearDown(() {
    reiniciarManifiestoParaTest();
    if (carpeta.existsSync()) carpeta.deleteSync(recursive: true);
  });

  /// Un fichero pequeño por ruta; las de [sinFichero] no llegan (`null`).
  Future<File?> imagen(String ruta) async {
    pedidas.add(ruta);
    if (sinFichero.contains(ruta)) return null;
    final f = File('${carpeta.path}/${ruta.replaceAll('/', '_')}');
    f.writeAsBytesSync(const [0, 1, 2, 3]);
    return f;
  }

  Widget app(Widget hijo, {Locale locale = const Locale('es')}) => MaterialApp(
    locale: locale,
    localizationsDelegates: NordayCoreLocalizations.localizationsDelegates,
    supportedLocales: NordayCoreLocalizations.supportedLocales,
    home: Center(child: hijo),
  );

  Future<void> montar(
    WidgetTester tester, {
    String fase = 'CRIA',
    String estado = 'feliz',
    double tamano = 200,
    Locale locale = const Locale('es'),
  }) async {
    await tester.pumpWidget(
      app(
        NoriVestida(
          fase: fase,
          estado: estado,
          tamano: tamano,
          prendas: prendas,
          manifiesto: manifiesto,
          imagen: imagen,
        ),
        locale: locale,
      ),
    );
    // Los ficheros llegan en microtareas; el `setState` en el frame siguiente.
    await tester.pump();
    await tester.pump();
  }

  /// Las capas, de abajo arriba: `cuerpo`, `prenda_<sitio>` o `brote`; o
  /// `original` si es el dibujo de siempre.
  List<String> capas(WidgetTester tester) {
    final pila = find.descendant(
      of: find.byType(NoriVestida),
      matching: find.byType(Stack),
    );
    if (pila.evaluate().isEmpty) {
      final sola = tester.widget<ImagenMascota>(
        find.descendant(
          of: find.byType(NoriVestida),
          matching: find.byType(ImagenMascota),
        ),
      );
      return ['original:${sola.asset}'];
    }
    return tester.widget<Stack>(pila.first).children.map((w) {
      if (w is ImagenMascota) {
        return w.asset.endsWith('_cuerpo.png') ? 'cuerpo' : w.asset;
      }
      final clave = w.key;
      if (clave is ValueKey<String>) return clave.value;
      return w.runtimeType.toString();
    }).toList();
  }

  double subidaBrote(WidgetTester tester) {
    final brote = tester.widget<Transform>(find.byKey(const ValueKey('brote')));
    return -brote.transform.getTranslation().y;
  }

  group('sin prendas, igual que hoy', () {
    testWidgets('en las 12 combinaciones, el dibujo de siempre y sin pedir '
        'nada', (tester) async {
      var pedidosManifiesto = 0;
      servicioManifiesto = () {
        pedidosManifiesto++;
        return ArtePrendasService(
          cliente: MockClient((_) async => http.Response('{}', 404)),
        );
      };
      for (final fase in ['HUEVO', 'CRIA', 'ADULTO']) {
        for (final estado in ['feliz', 'triste', 'dormida', 'exultante']) {
          await tester.pumpWidget(
            app(
              NoriVestida(
                fase: fase,
                estado: estado,
                tamano: 120,
                prendas: prendas,
                imagen: imagen,
              ),
            ),
          );
          await tester.pump();
          final sola = find.descendant(
            of: find.byType(NoriVestida),
            matching: find.byType(ImagenMascota),
          );
          expect(sola, findsOneWidget, reason: '$fase $estado');
          expect(
            tester.widget<ImagenMascota>(sola).asset,
            assetMascota(fase: fase, estado: estado),
          );
          expect(find.byType(Stack), findsNothing);
        }
      }
      expect(pedidas, isEmpty);
      expect(pedidosManifiesto, 0);
    });
  });

  testWidgets('gorro de lana: cuerpo, gorro y brote, con el brote subido', (
    tester,
  ) async {
    prendas.value = const {'Cabeza': 'PRENDA_GORRO_LANA'};
    await montar(tester, tamano: 200);

    expect(capas(tester), ['cuerpo', 'prenda_Cabeza', 'brote']);
    // 24 px del lienzo de 1024, a 200 de lado.
    expect(subidaBrote(tester), closeTo(24 * 200 / 1024, 0.001));
  });

  testWidgets('gorro de Papá Noel: oculta el brote', (tester) async {
    prendas.value = const {'Cabeza': 'PRENDA_GORRO_NOEL'};
    await montar(tester);

    expect(capas(tester), ['cuerpo', 'prenda_Cabeza']);
  });

  testWidgets('gorro y traje a la vez: el traje debajo del gorro', (
    tester,
  ) async {
    prendas.value = const {
      'Cabeza': 'PRENDA_GORRO_LANA',
      'Cuerpo': 'PRENDA_TRAJE_NOEL',
    };
    await montar(tester);

    expect(capas(tester), [
      'cuerpo',
      'prenda_Cuerpo',
      'prenda_Cabeza',
      'brote',
    ]);
  });

  testWidgets('el traje en el huevo no se pinta; sin otras prendas, el '
      'dibujo de siempre', (tester) async {
    prendas.value = const {'Cuerpo': 'PRENDA_TRAJE_NOEL'};
    await montar(tester, fase: 'HUEVO', estado: 'triste');

    expect(capas(tester), [
      'original:${assetMascota(fase: 'HUEVO', estado: 'triste')}',
    ]);
    expect(pedidas, isEmpty);
  });

  testWidgets('la imagen por estado va antes que la de la fase, y si no hay, '
      'la de la fase', (tester) async {
    prendas.value = const {'Cabeza': 'PRENDA_GORRO_LANA'};
    await montar(tester, estado: 'dormida');
    expect(pedidas, ['prendas/lana_cria_dormido.webp']);

    pedidas.clear();
    await montar(tester, estado: 'triste');
    expect(pedidas, ['prendas/lana_cria.webp']);
  });

  testWidgets('un código que no está en el manifiesto no se pinta', (
    tester,
  ) async {
    prendas.value = const {'Cabeza': 'PRENDA_QUE_NO_EXISTE'};
    await montar(tester);

    expect(capas(tester).single, startsWith('original:'));
  });

  testWidgets('una imagen que no llega no se pinta y su «oculta» no cuenta', (
    tester,
  ) async {
    sinFichero.add('prendas/noel_cria.webp');
    prendas.value = const {
      'Cabeza': 'PRENDA_GORRO_NOEL',
      'Cuerpo': 'PRENDA_TRAJE_NOEL',
    };
    await montar(tester);

    // El gorro (que oculta el brote) no llegó: queda el traje y el brote.
    expect(capas(tester), ['cuerpo', 'prenda_Cuerpo', 'brote']);
  });

  testWidgets('una imagen que no llegó se vuelve a pedir al cambiar el '
      'manifiesto, y se pinta', (tester) async {
    sinFichero.add('prendas/lana_cria.webp');
    prendas.value = const {'Cabeza': 'PRENDA_GORRO_LANA'};
    await montar(tester);
    expect(capas(tester).single, startsWith('original:'));
    expect(pedidas, ['prendas/lana_cria.webp']);

    // Vuelve la red: el servidor ya la da y llega un manifiesto nuevo.
    sinFichero.clear();
    manifiesto.value = ManifiestoArte(
      version: 2,
      prendas: manifiestoBueno.prendas,
    );
    await tester.pump();
    await tester.pump();

    expect(pedidas, ['prendas/lana_cria.webp', 'prendas/lana_cria.webp']);
    expect(capas(tester), ['cuerpo', 'prenda_Cabeza', 'brote']);
  });

  testWidgets('con otro notifier de lo puesto, sin cambiar fase ni estado, '
      'repinta', (tester) async {
    await montar(tester);
    expect(capas(tester).single, startsWith('original:'));

    prendas = ValueNotifier(const {'Cabeza': 'PRENDA_GORRO_LANA'});
    await montar(tester);

    expect(capas(tester), ['cuerpo', 'prenda_Cabeza', 'brote']);
  });

  testWidgets('al cambiar lo puesto o el manifiesto, repinta', (tester) async {
    await montar(tester);
    expect(capas(tester).single, startsWith('original:'));

    prendas.value = const {'Cabeza': 'PRENDA_GORRO_LANA'};
    await tester.pump();
    await tester.pump();
    expect(capas(tester), ['cuerpo', 'prenda_Cabeza', 'brote']);

    manifiesto.value = ManifiestoArte.vacio;
    await tester.pump();
    expect(capas(tester).single, startsWith('original:'));
  });

  testWidgets('los ficheros no se vuelven a pedir al repintar', (tester) async {
    prendas.value = const {'Cabeza': 'PRENDA_GORRO_LANA'};
    await montar(tester);
    expect(pedidas, hasLength(1));

    for (var i = 0; i < 5; i++) {
      await montar(tester);
    }
    await tester.pump(const Duration(seconds: 1));
    expect(pedidas, hasLength(1));
  });

  testWidgets('MascotaAnimadaViva sin «vestida» y NoriMarca no se visten', (
    tester,
  ) async {
    aplicarPrendasEquipadas(const {'Cabeza': 'PRENDA_GORRO_LANA'});
    addTearDown(() => aplicarPrendasEquipadas(const {}));
    await tester.pumpWidget(
      app(
        const Column(
          children: [
            MascotaAnimadaViva(fase: 'CRIA', estado: 'feliz', tamano: 100),
            NoriMarca(tamano: 100),
          ],
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(NoriVestida), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('MascotaAnimadaViva «vestida» lleva NoriVestida dentro', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        const MascotaAnimadaViva(
          fase: 'CRIA',
          estado: 'feliz',
          tamano: 100,
          vestida: true,
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(NoriVestida), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  group('lo que oye el lector', () {
    Future<void> oye(
      WidgetTester tester,
      Locale locale,
      String esperado,
    ) async {
      prendas.value = const {
        'Cabeza': 'PRENDA_GORRO_NOEL',
        'Cuerpo': 'PRENDA_TRAJE_NOEL',
      };
      final semantica = tester.ensureSemantics();
      await montar(tester, locale: locale);
      expect(find.bySemanticsLabel(esperado), findsOneWidget);
      semantica.dispose();
    }

    testWidgets('es', (tester) async {
      await oye(
        tester,
        const Locale('es'),
        'Lleva: Traje de Papá Noel, Gorro de Papá Noel',
      );
    });

    testWidgets('en', (tester) async {
      await oye(tester, const Locale('en'), 'Wearing: Santa suit, Santa hat');
    });

    testWidgets('pt', (tester) async {
      await oye(
        tester,
        const Locale('pt'),
        'Veste: Fato de Pai Natal, Gorro de Pai Natal',
      );
    });

    testWidgets('un código sin traducción no sale, nunca crudo', (
      tester,
    ) async {
      manifiesto.value = ManifiestoArte.fromJson({
        'version': 1,
        'prendas': {
          'PRENDA_NUEVA': {
            'sitio': 'cuerpo',
            'fases': ['cria'],
            'imagenes': {'cria': 'prendas/nueva.webp'},
          },
        },
      });
      prendas.value = const {'Cuerpo': 'PRENDA_NUEVA'};
      final semantica = tester.ensureSemantics();
      await montar(tester);

      expect(capas(tester), ['cuerpo', 'prenda_Cuerpo', 'brote']);
      expect(find.bySemanticsLabel(RegExp('PRENDA_NUEVA')), findsNothing);
      expect(find.bySemanticsLabel(RegExp('^Lleva')), findsNothing);
      semantica.dispose();
    });
  });

  group('el manifiesto compartido', () {
    late int pedidos;
    late Completer<void> respuesta;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      pedidos = 0;
      respuesta = Completer<void>();
      servicioManifiesto = () => ArtePrendasService(
        cliente: MockClient((_) async {
          pedidos++;
          await respuesta.future;
          return http.Response(
            jsonEncode({
              'version': 1,
              'nieve': {'desde': '2026-12-01', 'hasta': '2027-01-06'},
              'prendas': <String, dynamic>{},
            }),
            200,
          );
        }),
        urlBase: 'https://servidor.test/api',
      );
    });

    testWidgets('varias Nori con prendas a la vez: una sola petición', (
      tester,
    ) async {
      prendas.value = const {'Cabeza': 'PRENDA_GORRO_LANA'};
      await tester.pumpWidget(
        app(
          Column(
            children: [
              for (var i = 0; i < 4; i++)
                NoriVestida(
                  fase: 'CRIA',
                  estado: 'feliz',
                  tamano: 40,
                  prendas: prendas,
                  imagen: imagen,
                ),
            ],
          ),
        ),
      );
      await tester.pump();
      expect(pedidos, 1);

      respuesta.complete();
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
      // Ya se pidió en este proceso: montar otra no vuelve a pedir.
      await tester.runAsync(asegurarManifiesto);
      expect(pedidos, 1);
      await tester.pumpWidget(const SizedBox());
    });

    test(
      'recargar vuelve a pedir; dos recargas a la vez, una petición',
      () async {
        respuesta.complete();
        await asegurarManifiesto();
        expect(pedidos, 1);
        expect(manifiestoArteNotifier.value.nieveDesde, DateTime(2026, 12, 1));

        await Future.wait([recargarManifiesto(), recargarManifiesto()]);
        expect(pedidos, 2);

        await asegurarManifiesto();
        expect(pedidos, 2);
      },
    );

    test(
      'si crear el servicio lanza, la siguiente recarga vuelve a pedir',
      () async {
        final bueno = servicioManifiesto;
        servicioManifiesto = () => throw StateError('sin servicio');
        await recargarManifiesto();

        respuesta.complete();
        servicioManifiesto = bueno;
        await recargarManifiesto();
        expect(pedidos, 1);
      },
    );
  });

  group('las rutas', () {
    test('faseYSufijoMascota y assetMascota dan lo de siempre', () {
      expect(faseYSufijoMascota(fase: 'CRIA', estado: 'dormida'), (
        fase: 'cria',
        sufijo: 'dormido',
      ));
      expect(faseYSufijoMascota(fase: 'OTRA', estado: 'nada'), (
        fase: 'huevo',
        sufijo: 'triste',
      ));
      const esperados = {
        'feliz': 'sonriente',
        'triste': 'triste',
        'dormida': 'dormido',
        'exultante': 'exultante',
      };
      for (final fase in ['huevo', 'cria', 'adulto']) {
        for (final e in esperados.entries) {
          expect(
            assetMascota(fase: fase.toUpperCase(), estado: e.key),
            'assets/mascota/Nori_${fase}_${e.value}.png',
          );
        }
      }
      expect(assetMascota(), 'assets/mascota/Nori_huevo_triste.png');
    });

    test('el orden de las capas tiene los mismos sitios que sitiosPrenda', () {
      expect(ordenCapasPrenda.toSet(), sitiosPrenda.toSet());
      expect(ordenCapasPrenda, ['Cuerpo', 'Cabeza']);
    });

    testWidgets('los 24 ficheros declarados se cargan', (tester) async {
      var cargados = 0;
      await tester.runAsync(() async {
        for (final fase in ['HUEVO', 'CRIA', 'ADULTO']) {
          for (final estado in ['feliz', 'triste', 'dormida', 'exultante']) {
            for (final ruta in [
              assetCuerpoMascota(fase: fase, estado: estado),
              assetBroteMascota(fase: fase, estado: estado),
            ]) {
              final datos = await rootBundle.load(
                'packages/norday_flutter_core/$ruta',
              );
              expect(datos.lengthInBytes, greaterThan(0), reason: ruta);
              cargados++;
            }
          }
        }
      });
      expect(cargados, 24);
    });
  });
}
