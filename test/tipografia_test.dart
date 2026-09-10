import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:norday_flutter_core/theme/app_theme.dart';
import 'package:norday_flutter_core/theme/identidades_paleta.dart';

/// Cada identidad tiene DOS familias: una para titular y otra para el cuerpo.
/// El tema las reparte —`headline*` y `title*` a la de titulares, `body*` y
/// `label*` a la de cuerpo—, pero un `Text` dentro de un `Scaffold` hereda
/// `bodyMedium` por defecto. Así que escribir el tamaño a mano en un
/// `TextStyle` no elige familia: se queda con la del cuerpo, tenga el tamaño
/// que tenga.
///
/// Esto no lo ve `flutter analyze` y compila perfectamente. Estos dos tests
/// existen para que deje de ser una suposición.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Sin esto, construir un tema en un test intenta bajar las fuentes por HTTP.
  GoogleFonts.config.allowRuntimeFetching = false;

  final identidadInicial = identidadEquipadaNotifier.value;
  tearDown(() => aplicarIdentidadEquipada(identidadInicial.codigo));

  /// El estilo REALMENTE pintado, con lo heredado ya mezclado. El `style` del
  /// widget `Text` solo lleva lo que le escribieron encima.
  TextStyle estiloPintado(WidgetTester tester, String texto) =>
      (tester.renderObject(find.text(texto)) as RenderParagraph).text.style!;

  testWidgets('cada identidad titula con una familia distinta de la del cuerpo',
      (tester) async {
    for (final codigo in catalogoIdentidades.keys) {
      aplicarIdentidadEquipada(codigo);
      final tema = AppTheme.deTema(temaEquipadoNotifier.value);
      expect(
        tema.textTheme.headlineMedium!.fontFamily,
        isNot(tema.textTheme.bodyMedium!.fontFamily),
        reason: codigo,
      );
    }
  });

  testWidgets('un TextStyle crudo de titular se pinta con la letra del cuerpo',
      (tester) async {
    for (final codigo in catalogoIdentidades.keys) {
      aplicarIdentidadEquipada(codigo);
      final tema = AppTheme.deTema(temaEquipadoNotifier.value);

      await tester.pumpWidget(MaterialApp(
        theme: tema,
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                // Lo que hoy hay escrito en onboarding_overlay: 20 y negrita,
                // sin familia.
                const Text('crudo',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                // Lo mismo pedido al tema: headlineMedium es 20 y w700.
                Text('tema', style: Theme.of(context).textTheme.headlineMedium),
              ],
            ),
          ),
        ),
      ));
      // pumpAndSettle y no pump: MaterialApp interpola el tema con
      // AnimatedTheme, y TextStyle.lerp devuelve la familia de ORIGEN hasta
      // media transición. Con un solo fotograma leeríamos la letra de la
      // identidad anterior.
      await tester.pumpAndSettle();

      final crudo = estiloPintado(tester, 'crudo');
      final delTema = estiloPintado(tester, 'tema');

      // Mismo tamaño: la diferencia no está ahí.
      expect(crudo.fontSize, 20, reason: codigo);
      expect(delTema.fontSize, 20, reason: codigo);

      // Y sin embargo, distinta letra.
      expect(crudo.fontFamily, tema.textTheme.bodyMedium!.fontFamily,
          reason: codigo);
      expect(delTema.fontFamily, tema.textTheme.headlineMedium!.fontFamily,
          reason: codigo);
      expect(crudo.fontFamily, isNot(delTema.fontFamily), reason: codigo);
    }
  });
}
