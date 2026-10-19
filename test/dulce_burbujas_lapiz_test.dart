import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:norday_flutter_core/theme/app_theme.dart';
import 'package:norday_flutter_core/theme/identidades_paleta.dart';
import 'package:norday_flutter_core/theme/progreso_dia.dart';
import 'package:norday_flutter_core/widgets/fondo_burbujas.dart';
import 'package:norday_flutter_core/widgets/fondo_identidad.dart';
import 'package:norday_flutter_core/widgets/lapiz.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Sin esto, construir un tema en un test intenta bajar las fuentes por HTTP.
  GoogleFonts.config.allowRuntimeFetching = false;

  final identidadInicial = identidadEquipadaNotifier.value;
  tearDown(() {
    aplicarIdentidadEquipada(identidadInicial.codigo);
    limpiarProgresoDia();
    usarCacheLapiz = true;
  });

  testWidgets('en Dulce, las burbujas del fondo van a lápiz', (tester) async {
    usarCacheLapiz = false;
    aplicarIdentidadEquipada('TEMA_DULCE');
    publicarProgresoDia(
      hechos: 3,
      total: 3,
      fecha: DateTime(2026, 10, 19),
      avance: 1,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.deTema(temaEquipadoNotifier.value),
        home: const Scaffold(
          body: Stack(fit: StackFit.expand, children: [FondoIdentidad()]),
        ),
      ),
    );
    await tester.pump();

    final pintado = tester.renderObject(
      find.descendant(
        of: find.byType(FondoBurbujas),
        matching: find.byType(CustomPaint),
      ),
    );
    final t = temaEquipadoNotifier.value;
    expect(pintado, paints..everything((n, a) => n != #drawCircle));
    expect(pintado, paints..something((n, a) => n == #saveLayer));
    expect(
      pintado,
      paints..something(
        (n, a) =>
            n == #drawLine &&
            ((a[2] as Paint).color.toARGB32() & 0xFFFFFF) ==
                (t.primaryTrazo.toARGB32() & 0xFFFFFF),
      ),
    );
  });

  // Misma fórmula que contraste_test.dart.
  double contraste(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    final claro = la > lb ? la : lb;
    final oscuro = la > lb ? lb : la;
    return (claro + 0.05) / (oscuro + 0.05);
  }

  test('con tres burbujas solapadas, textMuted sigue en AA', () {
    final t = catalogoIdentidades['TEMA_DULCE']!.tokens;
    final tinta = t.primaryTrazo.withValues(alpha: tintaMaximaBurbuja);
    var sobre = t.bg;
    for (var i = 0; i < 3; i++) {
      sobre = Color.alphaBlend(tinta, sobre);
    }
    final valor = contraste(t.textMuted, sobre);
    expect(
      valor,
      greaterThanOrEqualTo(4.5),
      reason: 'textMuted sobre tres burbujas = ${valor.toStringAsFixed(2)}',
    );
  });

  test('nunca se solapan más de tres burbujas', () {
    for (final pantalla in [
      const Size(320, 568),
      const Size(360, 640),
      const Size(412, 915),
    ]) {
      final visibles = burbujasDeDulce.take(maximoBurbujasVisibles).toList();
      var maximo = 0;
      for (var y = 0.0; y <= pantalla.height; y += 2) {
        for (var x = 0.0; x <= pantalla.width; x += 2) {
          var cuantas = 0;
          for (final b in visibles) {
            final dx = x - b.x * pantalla.width;
            final dy = y - b.y * pantalla.height;
            if (dx * dx + dy * dy <= b.radio * b.radio) cuantas++;
          }
          if (cuantas > maximo) maximo = cuantas;
        }
      }
      expect(
        maximo,
        lessThanOrEqualTo(3),
        reason:
            'máximo $maximo solapadas en ${pantalla.width}x${pantalla.height}',
      );
    }
  });
}
