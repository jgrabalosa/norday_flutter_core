import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:norday_flutter_core/theme/app_theme.dart';
import 'package:norday_flutter_core/theme/identidades_paleta.dart';
import 'package:norday_flutter_core/widgets/check_circular.dart';

/// CheckCircular es el gesto de la app. Aquí se comprueba lo que promete, no
/// cómo se ve: que se construye en las cuatro formas, a qué acción llama un
/// toque, qué anuncia a un lector de pantalla y cuánto dura cada recorrido.
/// Los píxeles se miran en pantalla.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Sin esto, construir un tema en un test intenta bajar las fuentes por HTTP.
  GoogleFonts.config.allowRuntimeFetching = false;

  final identidadInicial = identidadEquipadaNotifier.value;
  tearDown(() => aplicarIdentidadEquipada(identidadInicial.codigo));

  Widget montar(Widget child, {bool reducirMovimiento = false}) => MaterialApp(
        theme: AppTheme.deTema(temaEquipadoNotifier.value),
        builder: (context, app) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(disableAnimations: reducirMovimiento),
          child: app!,
        ),
        home: Scaffold(body: Center(child: child)),
      );

  testWidgets('construye y ocupa 56x56 en las cuatro identidades, vacío y hecho',
      (tester) async {
    for (final codigo in catalogoIdentidades.keys) {
      aplicarIdentidadEquipada(codigo);
      for (final hecho in [false, true]) {
        await tester.pumpWidget(montar(CheckCircular(
          key: ValueKey('$codigo-$hecho'),
          hecho: hecho,
          onTap: () {},
          color: Colors.green,
        )));
        await tester.pumpAndSettle();
        // 44 del dibujo más 6 de área táctil por cada lado.
        expect(tester.getSize(find.byType(CheckCircular)), const Size(56, 56),
            reason: '$codigo hecho=$hecho');
      }
    }
  });

  testWidgets('sin hacer, un toque completa y no deshace', (tester) async {
    var completar = 0;
    var deshacer = 0;
    await tester.pumpWidget(montar(CheckCircular(
      hecho: false,
      onTap: () => completar++,
      onDeshacer: () => deshacer++,
      color: Colors.green,
    )));
    await tester.tap(find.byType(CheckCircular));
    expect(completar, 1);
    expect(deshacer, 0);
  });

  testWidgets('hecho y sin onDeshacer, un toque no hace nada', (tester) async {
    var completar = 0;
    await tester.pumpWidget(montar(CheckCircular(
      hecho: true,
      onTap: () => completar++,
      color: Colors.green,
    )));
    await tester.tap(find.byType(CheckCircular), warnIfMissed: false);
    expect(completar, 0);
  });

  testWidgets('hecho y con onDeshacer, un toque deshace y no completa',
      (tester) async {
    var completar = 0;
    var deshacer = 0;
    await tester.pumpWidget(montar(CheckCircular(
      hecho: true,
      onTap: () => completar++,
      onDeshacer: () => deshacer++,
      color: Colors.green,
    )));
    await tester.tap(find.byType(CheckCircular));
    expect(deshacer, 1);
    expect(completar, 0);
  });

  testWidgets('la semántica anuncia la acción que va a ocurrir', (tester) async {
    final semantica = tester.ensureSemantics();

    Widget check(String clave,
            {required bool hecho,
            VoidCallback? onDeshacer,
            String? etiquetaDeshacer}) =>
        montar(CheckCircular(
          key: ValueKey(clave),
          hecho: hecho,
          onTap: () {},
          onDeshacer: onDeshacer,
          color: Colors.green,
          etiquetaSemantica: 'Completar',
          etiquetaSemanticaDeshacer: etiquetaDeshacer,
        ));

    // Sin hacer: promete completar.
    await tester.pumpWidget(check('a',
        hecho: false, onDeshacer: () {}, etiquetaDeshacer: 'Deshacer'));
    expect(
      tester.getSemantics(find.bySemanticsLabel('Completar')),
      isSemantics(
          label: 'Completar',
          isButton: true,
          hasCheckedState: true,
          isChecked: false,
          hasEnabledState: true,
          isEnabled: true),
    );

    // Hecho y con deshacer: anuncia deshacer.
    await tester.pumpWidget(check('b',
        hecho: true, onDeshacer: () {}, etiquetaDeshacer: 'Deshacer'));
    expect(
      tester.getSemantics(find.bySemanticsLabel('Deshacer')),
      isSemantics(
          label: 'Deshacer',
          isButton: true,
          hasCheckedState: true,
          isChecked: true,
          hasEnabledState: true,
          isEnabled: true),
    );

    // Hecho, con deshacer pero sin etiqueta propia: cae a la de completar.
    await tester.pumpWidget(check('c', hecho: true, onDeshacer: () {}));
    expect(
      tester.getSemantics(find.bySemanticsLabel('Completar')),
      isSemantics(label: 'Completar', isChecked: true, isEnabled: true),
    );

    // Hecho y sin deshacer: no hay acción, así que deshabilitado.
    await tester.pumpWidget(check('d', hecho: true));
    expect(
      tester.getSemantics(find.bySemanticsLabel('Completar')),
      isSemantics(
          label: 'Completar',
          isChecked: true,
          hasEnabledState: true,
          isEnabled: false),
    );

    semantica.dispose();
  });

  testWidgets('nace hecho sin animar; completar dura 550 ms y deshacer 320 ms',
      (tester) async {
    await tester.pumpWidget(montar(CheckCircular(
      key: const ValueKey('nace-hecho'),
      hecho: true,
      onTap: () {},
      color: Colors.green,
    )));
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse,
        reason: 'nacer hecho no debe animar');

    Widget check(bool hecho) => montar(CheckCircular(
          key: const ValueKey('check'),
          hecho: hecho,
          onTap: () {},
          color: Colors.green,
        ));

    await tester.pumpWidget(check(false));
    await tester.pumpAndSettle();

    // Completar. El ticker toma la hora de inicio en su primer tic, que es
    // el fotograma siguiente: este pump() sin duración lo arranca.
    await tester.pumpWidget(check(true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 549));
    expect(tester.hasRunningAnimations, isTrue, reason: 'completar a 549 ms');
    await tester.pump(const Duration(milliseconds: 2));
    expect(tester.hasRunningAnimations, isFalse, reason: 'completar a 551 ms');

    // Deshacer: más corto, es una corrección y no un logro.
    await tester.pumpWidget(check(false));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 319));
    expect(tester.hasRunningAnimations, isTrue, reason: 'deshacer a 319 ms');
    await tester.pump(const Duration(milliseconds: 2));
    expect(tester.hasRunningAnimations, isFalse, reason: 'deshacer a 321 ms');
  });

  testWidgets('con reducir movimiento, completar y deshacer saltan sin animar',
      (tester) async {
    Widget check(bool hecho) => montar(
          CheckCircular(
            key: const ValueKey('check'),
            hecho: hecho,
            onTap: () {},
            color: Colors.green,
          ),
          reducirMovimiento: true,
        );

    await tester.pumpWidget(check(false));
    await tester.pumpAndSettle();

    await tester.pumpWidget(check(true));
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse, reason: 'completar');

    await tester.pumpWidget(check(false));
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse, reason: 'deshacer');
  });
}
