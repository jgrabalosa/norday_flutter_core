import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:norday_flutter_core/l10n/norday_core_localizations.dart';
import 'package:norday_flutter_core/screens/perfil_screen.dart';
import 'package:norday_flutter_core/services/api_service_core.dart';
import 'package:norday_flutter_core/theme/app_theme.dart';
import 'package:norday_flutter_core/widgets/selector_preferencias.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// El interruptor «Avisos de Norday»: lee y escribe `avisosApp`, solo sale si
/// la app lo pide y si el backend trae el campo.
///
/// `ApiServiceCore.cliente` es un `static final`: este test vive en su propio
/// fichero y lo crea dentro de `http.runWithClient` (ver `fcm_token_app_test`).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final peticiones = <http.Request>[];
  late Future<http.Response> Function(http.Request) responder;
  final falso = MockClient((peticion) {
    peticiones.add(peticion);
    return responder(peticion);
  });
  http.runWithClient(() => ApiServiceCore.cliente, () => falso);

  http.Response preferencias(Map<String, Object> extra) => http.Response(
    jsonEncode({'idioma': 'es', 'zonaHoraria': 'Europe/Madrid', ...extra}),
    200,
  );

  setUp(() {
    peticiones.clear();
    responder = (p) async => p.method == 'GET'
        ? preferencias({'avisosApp': true})
        : http.Response('', 200);
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({'token': 'tok'});
  });

  Widget app(Widget home) => MaterialApp(
    theme: AppTheme.deTema(temaEquipadoNotifier.value),
    locale: const Locale('es'),
    localizationsDelegates: NordayCoreLocalizations.localizationsDelegates,
    supportedLocales: NordayCoreLocalizations.supportedLocales,
    home: home is PerfilScreen
        ? home
        : Scaffold(body: SingleChildScrollView(child: home)),
  );

  Widget selector({bool mostrar = true}) =>
      SelectorPreferencias(usuarioId: 7, mostrarAvisosApp: mostrar);

  Widget perfil({bool? mostrar}) => PerfilScreen(
    usuarioId: 7,
    destinoTrasLogin: (_, _) => const SizedBox(),
    mostrarAvisosApp: mostrar ?? false,
  );

  final interruptor = find.widgetWithText(Row, 'Avisos de Norday');

  Future<void> montar(WidgetTester tester, Widget w) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(w));
    await tester.pumpAndSettle();
  }

  Finder switchDeAvisos() =>
      find.descendant(of: interruptor, matching: find.byType(Switch));

  List<http.Request> puts() =>
      peticiones.where((p) => p.method == 'PUT').toList();

  group('SelectorPreferencias', () {
    testWidgets('con avisosApp en la respuesta, lo enseña con su ayuda', (
      tester,
    ) async {
      await montar(tester, selector());

      expect(interruptor, findsOneWidget);
      expect(find.textContaining('Como mucho dos a la semana'), findsOneWidget);
      expect(tester.widget<Switch>(switchDeAvisos()).value, isTrue);
      expect(peticiones.first.url.path, endsWith('/usuarios/7/preferencias'));
    });

    testWidgets('apagarlo manda avisosApp: false y encenderlo, true', (
      tester,
    ) async {
      await montar(tester, selector());

      await tester.tap(switchDeAvisos());
      await tester.pumpAndSettle();
      expect(puts(), hasLength(1));
      expect(puts().last.url.path, endsWith('/usuarios/7/preferencias'));
      expect(jsonDecode(puts().last.body), {'avisosApp': false});
      expect(tester.widget<Switch>(switchDeAvisos()).value, isFalse);

      await tester.tap(switchDeAvisos());
      await tester.pumpAndSettle();
      expect(puts(), hasLength(2));
      expect(jsonDecode(puts().last.body), {'avisosApp': true});
      expect(tester.widget<Switch>(switchDeAvisos()).value, isTrue);
    });

    testWidgets('si el PUT falla, el interruptor vuelve y se avisa', (
      tester,
    ) async {
      await montar(tester, selector());
      responder = (p) async => http.Response('', 500);

      await tester.tap(switchDeAvisos());
      await tester.pumpAndSettle();

      expect(puts(), hasLength(1));
      expect(tester.widget<Switch>(switchDeAvisos()).value, isTrue);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Preferencias actualizadas'), findsNothing);
    });

    testWidgets('sin avisosApp en la respuesta (backend anterior), no sale', (
      tester,
    ) async {
      responder = (_) async => preferencias({});
      await montar(tester, selector());

      expect(peticiones, isNotEmpty);
      expect(interruptor, findsNothing);
      expect(find.textContaining('Como mucho dos a la semana'), findsNothing);
    });

    testWidgets('sin mostrarAvisosApp no sale ni se pregunta al backend', (
      tester,
    ) async {
      await montar(tester, selector(mostrar: false));

      expect(interruptor, findsNothing);
      expect(peticiones, isEmpty);
    });
  });

  group('PerfilScreen', () {
    testWidgets('con mostrarAvisosApp se lo pasa al selector y sale', (
      tester,
    ) async {
      await montar(tester, perfil(mostrar: true));

      expect(
        tester
            .widget<SelectorPreferencias>(find.byType(SelectorPreferencias))
            .mostrarAvisosApp,
        isTrue,
      );
      expect(interruptor, findsOneWidget);
    });

    testWidgets('por defecto (Focus) no lo enseña', (tester) async {
      await montar(tester, perfil());

      expect(
        tester
            .widget<SelectorPreferencias>(find.byType(SelectorPreferencias))
            .mostrarAvisosApp,
        isFalse,
      );
      expect(interruptor, findsNothing);
    });
  });
}
