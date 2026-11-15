import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:norday_flutter_core/l10n/norday_core_localizations.dart';
import 'package:norday_flutter_core/l10n/textos_app.dart';
import 'package:norday_flutter_core/screens/actualizacion_obligatoria_screen.dart';
import 'package:norday_flutter_core/screens/login_screen.dart';
import 'package:norday_flutter_core/screens/perfil_screen.dart';
import 'package:norday_flutter_core/theme/app_theme.dart';
import 'package:norday_flutter_core/widgets/wordmark_identidad.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Los textos que dependen de qué app es: sin registrar, el core habla en
/// neutro; registrados, manda la app.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  tearDown(TextosApp.reiniciar);

  Widget app(Widget home, {Locale locale = const Locale('es')}) => MaterialApp(
    theme: AppTheme.deTema(temaEquipadoNotifier.value),
    locale: locale,
    localizationsDelegates: NordayCoreLocalizations.localizationsDelegates,
    supportedLocales: NordayCoreLocalizations.supportedLocales,
    home: home,
  );

  /// Las cuatro caídas, en el idioma dado.
  List<String> caidas(NordayCoreLocalizations l) => [
    l.appTitulo,
    l.loginTagline,
    l.actualizacionTexto,
    l.perfilEliminarCuerpo,
  ];

  test('las caídas no nombran ningún dominio ni ninguna app concreta', () {
    final dominio = RegExp(
      r'h[áa]bit|registro|racha|entries|streak|registo|sequ[êe]ncia',
      caseSensitive: false,
    );
    for (final idioma in const ['es', 'en', 'pt']) {
      final l = lookupNordayCoreLocalizations(Locale(idioma));
      for (final texto in caidas(l)) {
        expect(texto, isNot(matches(dominio)), reason: '$idioma: $texto');
      }
      expect(l.appTitulo, 'Norday', reason: idioma);
    }
  });

  testWidgets('sin registrar, cada texto cae en el del core', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      app(
        Builder(
          builder: (c) {
            ctx = c;
            return const SizedBox();
          },
        ),
      ),
    );
    final l = NordayCoreLocalizations.of(ctx)!;
    expect(TextosApp.nombreDe(ctx), l.appTitulo);
    expect(TextosApp.lemaLoginDe(ctx), l.loginTagline);
    expect(TextosApp.actualizacionObligatoriaDe(ctx), l.actualizacionTexto);
    expect(TextosApp.eliminarCuentaDe(ctx), l.perfilEliminarCuerpo);
  });

  testWidgets('registrados, mandan los de la app, en su idioma', (
    tester,
  ) async {
    TextosApp.registrar(
      nombre: (c) => 'App ${Localizations.localeOf(c).languageCode}',
      lemaLogin: (_) => 'Lema',
      actualizacionObligatoria: (_) => 'Actualiza',
      eliminarCuenta: (_) => 'Se borra todo',
    );
    late BuildContext ctx;
    await tester.pumpWidget(
      app(
        Builder(
          builder: (c) {
            ctx = c;
            return const SizedBox();
          },
        ),
        locale: const Locale('pt'),
      ),
    );
    expect(TextosApp.nombreDe(ctx), 'App pt');
    expect(TextosApp.lemaLoginDe(ctx), 'Lema');
    expect(TextosApp.actualizacionObligatoriaDe(ctx), 'Actualiza');
    expect(TextosApp.eliminarCuentaDe(ctx), 'Se borra todo');
  });

  test('registrar sustituye: lo que no se pasa vuelve a la caída', () {
    TextosApp.registrar(nombre: (_) => 'A', lemaLogin: (_) => 'B');
    TextosApp.registrar(nombre: (_) => 'C');
    expect(TextosApp.nombre, isNotNull);
    expect(TextosApp.lemaLogin, isNull);
    expect(TextosApp.actualizacionObligatoria, isNull);
    expect(TextosApp.eliminarCuenta, isNull);
  });

  testWidgets('la actualización obligatoria pinta el texto de la app', (
    tester,
  ) async {
    await tester.pumpWidget(app(const ActualizacionObligatoriaScreen()));
    final l = lookupNordayCoreLocalizations(const Locale('es'));
    expect(find.text(l.actualizacionTexto), findsOneWidget);

    TextosApp.registrar(actualizacionObligatoria: (_) => 'Texto de la app');
    await tester.pumpWidget(
      app(const ActualizacionObligatoriaScreen(key: ValueKey(2))),
    );
    expect(find.text('Texto de la app'), findsOneWidget);
    expect(find.text(l.actualizacionTexto), findsNothing);
  });

  testWidgets('el login pinta el nombre y el lema de la app', (tester) async {
    TextosApp.registrar(nombre: (_) => 'Mi App', lemaLogin: (_) => 'Mi lema');
    await tester.pumpWidget(
      app(LoginScreen(destinoTrasLogin: (_, _) => const SizedBox())),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Mi lema'), findsOneWidget);
    final l = lookupNordayCoreLocalizations(const Locale('es'));
    expect(find.text(l.loginTagline), findsNothing);
    expect(
      tester.widget<WordmarkIdentidad>(find.byType(WordmarkIdentidad)).texto,
      'Mi App',
    );
  });

  testWidgets('el borrado de cuenta del perfil pinta el texto de la app', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'usuarioId': 7,
      'nombre': 'Ana',
      'username': 'ana',
      'email': 'ana@example.com',
      'proveedorAuth': 'LOCAL',
    });
    FlutterSecureStorage.setMockInitialValues({'token': 'tok'});
    TextosApp.registrar(eliminarCuenta: (_) => 'Se borra lo de esta app');
    await tester.pumpWidget(
      app(
        PerfilScreen(
          usuarioId: 7,
          destinoTrasLogin: (_, _) => const SizedBox(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    final l = lookupNordayCoreLocalizations(const Locale('es'));
    final boton = find.text(l.perfilEliminarCuenta);
    await tester.ensureVisible(boton);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(boton);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Se borra lo de esta app'), findsOneWidget);
    expect(find.text(l.perfilEliminarCuerpo), findsNothing);
  });
}
