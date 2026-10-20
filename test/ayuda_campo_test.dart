import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
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

  Widget ayuda({bool superindice = false}) => AyudaCampo(
    texto: 'Explicación',
    etiquetaSemantica: 'Ayuda',
    superindice: superindice,
  );

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

  testWidgets('desmontarlo con la nota abierta no lanza', (tester) async {
    await tester.pumpWidget(montar(ayuda()));
    await tester.tap(find.byType(InkResponse));
    await tester.pumpAndSettle();
    expect(find.text('Explicación'), findsOneWidget);

    await tester.pumpWidget(montar(const SizedBox.shrink()));
    expect(tester.takeException(), isNull);
  });
}
