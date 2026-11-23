import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:norday_flutter_core/l10n/norday_core_localizations.dart';
import 'package:norday_flutter_core/l10n/norday_core_localizations_en.dart';
import 'package:norday_flutter_core/l10n/norday_core_localizations_es.dart';
import 'package:norday_flutter_core/l10n/norday_core_localizations_pt.dart';
import 'package:norday_flutter_core/screens/tienda_screen.dart';
import 'package:norday_flutter_core/services/analytics_service.dart';
import 'package:norday_flutter_core/theme/app_theme.dart';
import 'package:norday_flutter_core/theme/identidades_paleta.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// La pista de la primera vez en la tienda: una nota junto al saldo que sale
/// una sola vez, con la tienda cargada.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  const pista = 'Aquí gastas tus puntos. La comida le da experiencia a Nori.';
  final identidadInicial = identidadEquipadaNotifier.value;
  final enviarOriginal = AnalyticsCore.enviarEvento;
  final enviados = <(String, Map<String, Object>)>[];
  late bool falla;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    enviados.clear();
    falla = false;
    AnalyticsCore.enviarEvento = (n, p) async => enviados.add((n, p));
    TiendaScreen.obtenerSaldo = (_) async {
      if (falla) throw Exception('sin red');
      return 500;
    };
    TiendaScreen.obtenerCatalogo = () async => [];
    TiendaScreen.obtenerInventario = (_) async => [];
  });

  tearDown(() {
    AnalyticsCore.enviarEvento = enviarOriginal;
    TiendaScreen.reiniciarParaTest();
    aplicarIdentidadEquipada(identidadInicial.codigo);
  });

  /// Sin pumpAndSettle: el fondo anima sin parar.
  Future<void> abrirTienda(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: NordayCoreLocalizations.localizationsDelegates,
        supportedLocales: NordayCoreLocalizations.supportedLocales,
        theme: AppTheme.deTema(temaEquipadoNotifier.value),
        home: const TiendaScreen(usuarioId: 7),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('la primera vez sale, se registra una vez y se cierra tocando', (
    tester,
  ) async {
    await abrirTienda(tester);

    expect(find.text(pista), findsOneWidget);
    expect(enviados, hasLength(1));
    expect(enviados.single.$1, 'pista_vista');
    expect(enviados.single.$2, {'pista': 'tienda'});

    await tester.tap(find.text(pista));
    await tester.pump();
    expect(find.text(pista), findsNothing);
    expect(enviados, hasLength(1));
  });

  testWidgets('la segunda vez no sale ni se registra', (tester) async {
    await abrirTienda(tester);
    expect(find.text(pista), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    enviados.clear();

    await abrirTienda(tester);

    expect(find.text(pista), findsNothing);
    expect(enviados, isEmpty);
  });

  testWidgets('con la marca ya puesta no sale', (tester) async {
    SharedPreferences.setMockInitialValues({
      TiendaScreen.clavePistaVista: true,
    });

    await abrirTienda(tester);

    expect(find.text(pista), findsNothing);
    expect(enviados, isEmpty);
  });

  testWidgets('con la tienda cargando no sale', (tester) async {
    tester.view.physicalSize = const Size(400, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: NordayCoreLocalizations.localizationsDelegates,
        supportedLocales: NordayCoreLocalizations.supportedLocales,
        theme: AppTheme.deTema(temaEquipadoNotifier.value),
        home: const TiendaScreen(usuarioId: 7),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text(pista), findsNothing);
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('con error no sale y no gasta la primera vez', (tester) async {
    falla = true;
    await abrirTienda(tester);
    expect(find.text(pista), findsNothing);
    expect(enviados, isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());

    falla = false;
    await abrirTienda(tester);

    expect(find.text(pista), findsOneWidget);
  });

  test('el texto está en los tres idiomas', () {
    expect(NordayCoreLocalizationsEs().tiendaPista, pista);
    expect(
      NordayCoreLocalizationsEn().tiendaPista,
      'You spend your points here. Food gives Nori experience.',
    );
    expect(
      NordayCoreLocalizationsPt().tiendaPista,
      'Aqui gastas os teus pontos. A comida dá experiência ao Nori.',
    );
  });
}
