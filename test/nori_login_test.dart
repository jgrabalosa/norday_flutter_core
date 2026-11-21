import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:norday_flutter_core/l10n/norday_core_localizations.dart';
import 'package:norday_flutter_core/models/manifiesto_arte.dart';
import 'package:norday_flutter_core/screens/login_screen.dart';
import 'package:norday_flutter_core/services/arte_prendas_service.dart';
import 'package:norday_flutter_core/services/manifiesto_compartido.dart';
import 'package:norday_flutter_core/theme/prendas.dart';
import 'package:norday_flutter_core/widgets/nori_marca.dart';
import 'package:norday_flutter_core/widgets/nori_vestida.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// La Nori del login (T-036): el apartado `login` del manifiesto, `NoriMarca`
/// vestida y que el login no falla sin red.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  ManifiestoArte manifiesto({Object? login, String sitioGorro = 'cabeza'}) =>
      ManifiestoArte.fromJson({
        'version': 1,
        'login': ?login,
        'prendas': {
          'PRENDA_GORRO_NOEL': {
            'sitio': sitioGorro,
            'fases': ['huevo', 'cria', 'adulto'],
            'oculta': ['brote'],
            'imagenes': {'huevo': 'prendas/noel_huevo.webp'},
          },
          'PRENDA_TRAJE_NOEL': {
            'sitio': 'cuerpo',
            'fases': ['cria', 'adulto'],
            'imagenes': {'cria': 'prendas/traje_cria.webp'},
          },
        },
      });

  final navidad = [
    {
      'desde': '2026-11-24',
      'hasta': '2027-01-07',
      'prendas': ['PRENDA_GORRO_NOEL'],
    },
  ];

  group('ManifiestoArte.prendasLogin', () {
    test('dentro del periodo: sitio como en sitiosPrenda', () {
      final m = manifiesto(login: navidad);
      expect(m.prendasLogin(DateTime(2026, 12, 25)), {
        'Cabeza': 'PRENDA_GORRO_NOEL',
      });
      expect(sitiosPrenda, contains('Cabeza'));
    });

    test('bordes: ambos días incluidos, con cualquier hora', () {
      final m = manifiesto(login: navidad);
      expect(m.prendasLogin(DateTime(2026, 11, 23, 23, 59)), isEmpty);
      expect(m.prendasLogin(DateTime(2026, 11, 24)), isNotEmpty);
      expect(m.prendasLogin(DateTime(2027, 1, 7, 23, 59)), isNotEmpty);
      expect(m.prendasLogin(DateTime(2027, 1, 8)), isEmpty);
    });

    test('un código que no está en prendas no cuenta', () {
      final m = manifiesto(
        login: [
          {
            'desde': '2026-11-24',
            'hasta': '2027-01-07',
            'prendas': ['PRENDA_QUE_NO_EXISTE', 'PRENDA_TRAJE_NOEL'],
          },
        ],
      );
      expect(m.prendasLogin(DateTime(2026, 12, 1)), {
        'Cuerpo': 'PRENDA_TRAJE_NOEL',
      });
    });

    test('un sitio que no está en sitiosPrenda no cuenta', () {
      final m = manifiesto(login: navidad, sitioGorro: 'pies');
      expect(m.prendasLogin(DateTime(2026, 12, 25)), isEmpty);
    });

    test('sin el apartado, o con datos raros, vacío', () {
      expect(manifiesto().prendasLogin(DateTime(2026, 12, 25)), isEmpty);
      expect(
        ManifiestoArte.vacio.prendasLogin(DateTime(2026, 12, 25)),
        isEmpty,
      );
      for (final raro in <Object>[
        'no es una lista',
        [1, 'x', null],
        [
          {'desde': 'ayer', 'hasta': '2027-01-07', 'prendas': []},
        ],
        [
          {
            'desde': '2027-01-07',
            'hasta': '2026-11-24',
            'prendas': ['PRENDA_GORRO_NOEL'],
          },
        ],
        [
          {'desde': '2026-11-24', 'hasta': '2027-01-07', 'prendas': 'x'},
        ],
      ]) {
        expect(
          manifiesto(login: raro).prendasLogin(DateTime(2026, 12, 25)),
          isEmpty,
          reason: '$raro',
        );
      }
    });
  });

  group('NoriMarca', () {
    late Directory carpeta;
    late List<String> pedidas;

    setUp(() {
      carpeta = Directory.systemTemp.createTempSync('nori_login_');
      pedidas = [];
      reiniciarManifiestoParaTest();
      servicioManifiesto = () => ArtePrendasService(
        cliente: MockClient((_) async => http.Response('{}', 404)),
      );
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() {
      reiniciarManifiestoParaTest();
      aplicarPrendasEquipadas(const {});
      if (carpeta.existsSync()) carpeta.deleteSync(recursive: true);
    });

    Future<File?> imagen(String ruta) async {
      pedidas.add(ruta);
      final f = File('${carpeta.path}/${ruta.replaceAll('/', '_')}');
      f.writeAsBytesSync(const [0, 1, 2, 3]);
      return f;
    }

    Widget app(Widget hijo) => MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: NordayCoreLocalizations.localizationsDelegates,
      supportedLocales: NordayCoreLocalizations.supportedLocales,
      home: Center(child: hijo),
    );

    Widget marca({
      required bool vestida,
      required ValueNotifier<ManifiestoArte> notifier,
    }) => NoriMarca(
      tamano: 100,
      vestida: vestida,
      ahora: () => DateTime(2026, 12, 25),
      manifiesto: notifier,
      imagen: imagen,
    );

    Future<void> asentar(WidgetTester tester) async {
      await tester.pump();
      await tester.pump();
    }

    testWidgets('vestida: pinta la capa de la prenda de hoy', (tester) async {
      final notifier = ValueNotifier(manifiesto(login: navidad));
      await tester.pumpWidget(app(marca(vestida: true, notifier: notifier)));
      await asentar(tester);

      expect(find.byKey(const ValueKey('prenda_Cabeza')), findsOneWidget);
      expect(pedidas, ['prendas/noel_huevo.webp']);
    });

    testWidgets('vestida: cuando llega el manifiesto, se viste', (
      tester,
    ) async {
      final notifier = ValueNotifier(ManifiestoArte.vacio);
      await tester.pumpWidget(app(marca(vestida: true, notifier: notifier)));
      await asentar(tester);
      expect(find.byKey(const ValueKey('prenda_Cabeza')), findsNothing);

      notifier.value = manifiesto(login: navidad);
      await asentar(tester);
      expect(find.byKey(const ValueKey('prenda_Cabeza')), findsOneWidget);
    });

    testWidgets('vestida: la prenda que no se ve en el huevo no sale', (
      tester,
    ) async {
      final notifier = ValueNotifier(
        manifiesto(
          login: [
            {
              'desde': '2026-11-24',
              'hasta': '2027-01-07',
              'prendas': ['PRENDA_TRAJE_NOEL'],
            },
          ],
        ),
      );
      await tester.pumpWidget(app(marca(vestida: true, notifier: notifier)));
      await asentar(tester);

      expect(find.byKey(const ValueKey('prenda_Cuerpo')), findsNothing);
      expect(pedidas, isEmpty);
    });

    testWidgets('vestida: nunca usa lo equipado de nadie', (tester) async {
      aplicarPrendasEquipadas(const {'Cabeza': 'PRENDA_GORRO_NOEL'});
      final notifier = ValueNotifier(manifiesto());
      await tester.pumpWidget(app(marca(vestida: true, notifier: notifier)));
      await asentar(tester);

      expect(find.byKey(const ValueKey('prenda_Cabeza')), findsNothing);
      expect(pedidas, isEmpty);
    });

    testWidgets('sin vestir, como hoy: ni NoriVestida ni prendas', (
      tester,
    ) async {
      final notifier = ValueNotifier(manifiesto(login: navidad));
      await tester.pumpWidget(app(marca(vestida: false, notifier: notifier)));
      await asentar(tester);

      expect(find.byType(NoriVestida), findsNothing);
      expect(pedidas, isEmpty);
    });
  });

  group('LoginScreen', () {
    setUp(() {
      reiniciarManifiestoParaTest();
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(reiniciarManifiestoParaTest);

    testWidgets('pide el manifiesto al abrirse y, sin red, no falla', (
      tester,
    ) async {
      var pedidos = 0;
      servicioManifiesto = () {
        pedidos++;
        return ArtePrendasService(
          cliente: MockClient((_) async => throw const SocketException('x')),
        );
      };
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          localizationsDelegates:
              NordayCoreLocalizations.localizationsDelegates,
          supportedLocales: NordayCoreLocalizations.supportedLocales,
          home: LoginScreen(destinoTrasLogin: (_, _) => const SizedBox()),
        ),
      );
      await tester.pump();
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();

      expect(pedidos, 1);
      expect(tester.takeException(), isNull);
      final marca = tester.widget<NoriMarca>(find.byType(NoriMarca));
      expect(marca.vestida, isTrue);
      expect(find.byKey(const ValueKey('prenda_Cabeza')), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  });
}
