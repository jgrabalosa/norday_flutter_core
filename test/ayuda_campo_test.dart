import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:norday_flutter_core/l10n/norday_core_localizations.dart';
import 'package:norday_flutter_core/l10n/norday_core_localizations_en.dart';
import 'package:norday_flutter_core/l10n/norday_core_localizations_es.dart';
import 'package:norday_flutter_core/l10n/norday_core_localizations_pt.dart';
import 'package:norday_flutter_core/services/analytics_service.dart';
import 'package:norday_flutter_core/theme/app_theme.dart';
import 'package:norday_flutter_core/theme/identidades_paleta.dart';
import 'package:norday_flutter_core/widgets/ayuda_campo.dart';

/// El interrogante se crea y se desmonta muchas veces en una pantalla. Lo que
/// se comprueba aquí es el ciclo de vida: que desmontarlo no lanza, esté o no
/// abierta la nota, y que la nota abre y cierra al tocar.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Sin esto, construir un tema en un test intenta bajar las fuentes por HTTP.
  GoogleFonts.config.allowRuntimeFetching = false;

  final identidadInicial = identidadEquipadaNotifier.value;
  tearDown(() => aplicarIdentidadEquipada(identidadInicial.codigo));

  Widget montar(Widget child) => MaterialApp(
    theme: AppTheme.deTema(temaEquipadoNotifier.value),
    home: Scaffold(body: Center(child: child)),
  );

  Widget ayuda({bool superindice = false, String? id}) => AyudaCampo(
    texto: 'Explicación',
    etiquetaSemantica: 'Ayuda',
    superindice: superindice,
    id: id,
  );

  final enviados = <(String, Map<String, Object>)>[];
  final enviarOriginal = AnalyticsCore.enviarEvento;
  setUp(() {
    enviados.clear();
    AnalyticsCore.enviarEvento = (n, p) async => enviados.add((n, p));
  });
  tearDown(() => AnalyticsCore.enviarEvento = enviarOriginal);

  testWidgets('abrir con id registra ayuda_abierta una vez; cerrar no', (
    tester,
  ) async {
    await tester.pumpWidget(montar(ayuda(id: 'tienda')));

    await tester.tap(find.byType(InkResponse));
    await tester.pumpAndSettle();
    expect(enviados, hasLength(1));
    expect(enviados.single.$1, 'ayuda_abierta');
    expect(enviados.single.$2, {'ayuda': 'tienda'});

    await tester.tap(find.text('Explicación'));
    await tester.pumpAndSettle();
    expect(enviados, hasLength(1));
  });

  testWidgets('abrir sin id no registra nada', (tester) async {
    await tester.pumpWidget(montar(ayuda()));
    await tester.tap(find.byType(InkResponse));
    await tester.pumpAndSettle();
    expect(find.text('Explicación'), findsOneWidget);
    expect(enviados, isEmpty);
  });

  test('el texto de la tienda menciona la ropa en los tres idiomas', () {
    expect(
      NordayCoreLocalizationsEs().tiendaAyuda,
      'Gasta aquí tus puntos: comida para Nori, temas, ropa y más.',
    );
    expect(
      NordayCoreLocalizationsEn().tiendaAyuda,
      'Spend your points here: food for Nori, themes, clothes and more.',
    );
    expect(
      NordayCoreLocalizationsPt().tiendaAyuda,
      'Gasta aqui os teus pontos: comida para o Nori, temas, roupa e mais.',
    );
  });

  testWidgets('desmontarlo sin haber tocado el interrogante no lanza', (
    tester,
  ) async {
    await tester.pumpWidget(montar(ayuda()));
    await tester.pumpWidget(montar(const SizedBox.shrink()));
    expect(tester.takeException(), isNull);
  });

  testWidgets('lo mismo en superíndice no lanza', (tester) async {
    await tester.pumpWidget(montar(ayuda(superindice: true)));
    await tester.pumpWidget(montar(const SizedBox.shrink()));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'tocar abre la nota, volver a tocar la cierra, y desmontar no lanza',
    (tester) async {
      await tester.pumpWidget(montar(ayuda()));

      await tester.tap(find.byType(InkResponse));
      await tester.pumpAndSettle();
      expect(find.text('Explicación'), findsOneWidget);

      await tester.tap(find.text('Explicación'));
      await tester.pumpAndSettle();
      expect(find.text('Explicación'), findsNothing);

      await tester.pumpWidget(montar(const SizedBox.shrink()));
      expect(tester.takeException(), isNull);
    },
  );

  group('Saber más', () {
    Widget montarConL10n(Widget child) => MaterialApp(
      localizationsDelegates: NordayCoreLocalizations.localizationsDelegates,
      supportedLocales: NordayCoreLocalizations.supportedLocales,
      locale: const Locale('es'),
      theme: AppTheme.deTema(temaEquipadoNotifier.value),
      home: Scaffold(body: Center(child: child)),
    );

    testWidgets('sin alSaberMas la nota no lo lleva', (tester) async {
      await tester.pumpWidget(montarConL10n(ayuda()));
      await tester.tap(find.byType(InkResponse));
      await tester.pumpAndSettle();
      expect(find.text('Explicación'), findsOneWidget);
      expect(find.text('Saber más →'), findsNothing);
    });

    testWidgets('con alSaberMas sale, y tocarlo cierra y lo llama una vez', (
      tester,
    ) async {
      var llamadas = 0;
      await tester.pumpWidget(
        montarConL10n(
          AyudaCampo(
            texto: 'Explicación',
            etiquetaSemantica: 'Ayuda',
            alSaberMas: () => llamadas++,
          ),
        ),
      );
      await tester.tap(find.byType(InkResponse));
      await tester.pumpAndSettle();
      expect(find.text('Saber más →'), findsOneWidget);

      await tester.tap(find.text('Saber más →'));
      await tester.pumpAndSettle();
      expect(llamadas, 1);
      expect(find.text('Explicación'), findsNothing);
    });

    testWidgets('tocar el texto cierra sin llamar a alSaberMas', (
      tester,
    ) async {
      var llamadas = 0;
      await tester.pumpWidget(
        montarConL10n(
          AyudaCampo(
            texto: 'Explicación',
            etiquetaSemantica: 'Ayuda',
            alSaberMas: () => llamadas++,
          ),
        ),
      );
      await tester.tap(find.byType(InkResponse));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Explicación'));
      await tester.pumpAndSettle();
      expect(llamadas, 0);
      expect(find.text('Explicación'), findsNothing);
    });

    test('el texto está en los tres idiomas', () {
      expect(NordayCoreLocalizationsEs().ayudaSaberMas, 'Saber más →');
      expect(NordayCoreLocalizationsEn().ayudaSaberMas, 'Learn more →');
      expect(NordayCoreLocalizationsPt().ayudaSaberMas, 'Saber mais →');
    });
  });

  testWidgets('desmontarlo con la nota abierta no lanza', (tester) async {
    await tester.pumpWidget(montar(ayuda()));
    await tester.tap(find.byType(InkResponse));
    await tester.pumpAndSettle();
    expect(find.text('Explicación'), findsOneWidget);

    await tester.pumpWidget(montar(const SizedBox.shrink()));
    expect(tester.takeException(), isNull);
  });
}
