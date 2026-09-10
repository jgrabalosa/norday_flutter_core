import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:norday_flutter_core/theme/app_theme.dart';
import 'package:norday_flutter_core/theme/identidades_paleta.dart';
import 'package:norday_flutter_core/widgets/burbuja_contexto.dart';
import 'package:norday_flutter_core/widgets/fondo_identidad.dart';
import 'package:norday_flutter_core/widgets/superficie_identidad.dart';

/// Los primeros tests de widget del core.
///
/// `flutter analyze` no ve el layout: un `Stack` al que se le olvidó el
/// `StackFit.expand` colapsó el fondo a cero y pasó el analizador y los tests
/// unitarios sin decir nada. Esto cubre esa clase de fallo — que algo se
/// construya y ocupe sitio — no que sea bonito, que eso se mira en pantalla.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Sin esto, construir un tema en un test intenta bajar las fuentes por HTTP.
  GoogleFonts.config.allowRuntimeFetching = false;

  final identidadInicial = identidadEquipadaNotifier.value;
  tearDown(() => aplicarIdentidadEquipada(identidadInicial.codigo));

  Widget montar(Widget child) => MaterialApp(
        theme: AppTheme.deTema(temaEquipadoNotifier.value),
        home: Scaffold(body: child),
      );

  testWidgets('la superficie construye y ocupa sitio en las cuatro identidades',
      (tester) async {
    for (final codigo in catalogoIdentidades.keys) {
      aplicarIdentidadEquipada(codigo);
      await tester.pumpWidget(montar(
        const SuperficieIdentidad(child: Text('contenido')),
      ));
      await tester.pump();

      expect(find.text('contenido'), findsOneWidget, reason: codigo);
      final tamano = tester.getSize(find.byType(SuperficieIdentidad));
      expect(tamano.width, greaterThan(0), reason: codigo);
      expect(tamano.height, greaterThan(0), reason: codigo);
    }
  });

  testWidgets('la superficie protagonista traslúcida sigue pintando su hijo',
      (tester) async {
    // 0.75 es lo que usan el login, Tienda, Colección y Logros. Sólo tiene
    // efecto en glass, así que las otras tres pasan por el mismo camino sin
    // que cambie nada: eso es justo lo que hay que comprobar.
    for (final codigo in catalogoIdentidades.keys) {
      aplicarIdentidadEquipada(codigo);
      await tester.pumpWidget(montar(
        const SuperficieIdentidad(
          protagonista: true,
          opacidadSuperficie: 0.75,
          child: Text('contenido'),
        ),
      ));
      await tester.pump();
      expect(find.text('contenido'), findsOneWidget, reason: codigo);
    }
  });

  testWidgets('la burbuja pinta texto en las cuatro formas', (tester) async {
    // Se busca el widget Text, no su contenido: Neotokyo+ pasa la frase a
    // mayúsculas y un find.text con el original fallaría sólo ahí.
    for (final codigo in catalogoIdentidades.keys) {
      aplicarIdentidadEquipada(codigo);
      await tester.pumpWidget(montar(
        const BurbujaContexto(texto: 'buen ritmo'),
      ));
      await tester.pump();
      expect(find.byType(Text), findsOneWidget, reason: codigo);
    }
  });

  testWidgets('la burbuja usa el color que le pasan, en las cuatro formas',
      (tester) async {
    // El dashboard lo necesita para marcar el día completado. Sin este test,
    // que una rama se dejara el `color ??` no lo vería nadie.
    const tinta = Color(0xFF123456);

    for (final codigo in catalogoIdentidades.keys) {
      aplicarIdentidadEquipada(codigo);
      await tester.pumpWidget(montar(
        const BurbujaContexto(texto: 'buen ritmo', color: tinta),
      ));
      await tester.pump();

      final texto = tester.widget<Text>(find.byType(Text));
      expect(texto.style?.color, tinta, reason: codigo);
    }
  });

  testWidgets('el fondo llena el Stack cuando el Stack se lo permite',
      (tester) async {
    for (final codigo in catalogoIdentidades.keys) {
      aplicarIdentidadEquipada(codigo);
      await tester.pumpWidget(montar(
        const Stack(
          fit: StackFit.expand,
          children: [FondoIdentidad()],
        ),
      ));
      await tester.pump();

      final tamano = tester.getSize(find.byType(FondoIdentidad));
      expect(tamano.width, greaterThan(0), reason: codigo);
      expect(tamano.height, greaterThan(0), reason: codigo);
    }
  });

  testWidgets('sin StackFit.expand el fondo colapsa a cero', (tester) async {
    // Este test afirma el fallo A PROPÓSITO, y es lo que hace que el de
    // arriba signifique algo: si `CustomPaint` sin hijo dejara de colapsar
    // con restricciones sueltas, el otro test pasaría por casualidad y nadie
    // se enteraría. Aquí está escrito el motivo por el que el `StackFit`
    // no es opcional.
    aplicarIdentidadEquipada('TEMA_PROFUNDIDAD');
    await tester.pumpWidget(montar(
      const Stack(children: [FondoIdentidad()]),
    ));
    await tester.pump();

    expect(tester.getSize(find.byType(FondoIdentidad)), Size.zero);
  });
}
