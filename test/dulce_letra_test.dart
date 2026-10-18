import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:norday_flutter_core/theme/app_theme.dart';
import 'package:norday_flutter_core/theme/identidad_paleta.dart';
import 'package:norday_flutter_core/theme/identidades_paleta.dart';

/// Dulce escribe el texto de lectura en Caveat, agrandada un 25 %, y sus
/// nombres de ítem también. Los titulares siguen en Quicksand. Profundidad y
/// Neotokyo+ no cambian en nada.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final identidadInicial = identidadEquipadaNotifier.value;
  tearDown(() => aplicarIdentidadEquipada(identidadInicial.codigo));

  /// Familia y tamaño de un rol de la escala de la identidad [codigo]. La
  /// familia llega como `Caveat_regular` o `Quicksand_700`: se compara por
  /// prefijo.
  TextStyle rol(String codigo, TextStyle? Function(TextTheme t) elegir) {
    aplicarIdentidadEquipada(codigo);
    final tt = AppTheme.deTema(temaEquipadoNotifier.value).textTheme;
    return elegir(tt)!;
  }

  test('en Dulce, el texto de lectura y los nombres van en Caveat', () {
    final cuerpoGrande = rol('TEMA_DULCE', (t) => t.bodyLarge);
    expect(cuerpoGrande.fontFamily, startsWith('Caveat'));
    expect(cuerpoGrande.fontSize, closeTo(20, 1e-9));

    final cuerpoMediano = rol('TEMA_DULCE', (t) => t.bodyMedium);
    expect(cuerpoMediano.fontFamily, startsWith('Caveat'));
    expect(cuerpoMediano.fontSize, closeTo(17.5, 1e-9));

    final nombre = rol('TEMA_DULCE', (t) => t.titleMedium);
    expect(nombre.fontFamily, startsWith('Caveat'));
    expect(nombre.fontSize, closeTo(20, 1e-9));
  });

  test('en Dulce, los titulares siguen en Quicksand con su tamaño', () {
    final esperados = <String, double>{
      'headlineMedium': 24,
      'headlineSmall': 20,
      'titleLarge': 16,
      'titleSmall': 12,
    };
    for (final entrada in esperados.entries) {
      final estilo = rol(
        'TEMA_DULCE',
        (t) => switch (entrada.key) {
          'headlineMedium' => t.headlineMedium,
          'headlineSmall' => t.headlineSmall,
          'titleLarge' => t.titleLarge,
          _ => t.titleSmall,
        },
      );
      expect(estilo.fontFamily, startsWith('Quicksand'), reason: entrada.key);
      expect(
        estilo.fontSize,
        closeTo(entrada.value, 1e-9),
        reason: entrada.key,
      );
    }
  });

  test(
    'Profundidad y Neotokyo+ no cambian: nombres en titulares, cuerpo sin escalar',
    () {
      final profundidad = rol('TEMA_PROFUNDIDAD', (t) => t.titleMedium);
      expect(profundidad.fontFamily, startsWith('SpaceGrotesk'));
      expect(profundidad.fontSize, closeTo(16, 1e-9));

      final profundidadCuerpo = rol('TEMA_PROFUNDIDAD', (t) => t.bodyLarge);
      expect(profundidadCuerpo.fontFamily, startsWith('Manrope'));
      expect(profundidadCuerpo.fontSize, closeTo(16, 1e-9));

      final neotokyo = rol('TEMA_NEOTOKYO_PLUS', (t) => t.titleMedium);
      expect(neotokyo.fontFamily, startsWith('ChakraPetch'));
      expect(neotokyo.fontSize, closeTo(16, 1e-9));

      final neotokyoCuerpo = rol('TEMA_NEOTOKYO_PLUS', (t) => t.bodyLarge);
      expect(neotokyoCuerpo.fontFamily, startsWith('IBMPlexSans'));
      expect(neotokyoCuerpo.fontSize, closeTo(16, 1e-9));
    },
  );

  test('tamanoLectura multiplica por la escala de la identidad', () {
    expect(
      tamanoLectura(catalogoIdentidades['TEMA_DULCE']!, 16),
      closeTo(20, 1e-9),
    );
    expect(tamanoLectura(catalogoIdentidades['TEMA_PROFUNDIDAD']!, 16), 16);
    expect(tamanoLectura(catalogoIdentidades['TEMA_NEOTOKYO_PLUS']!, 16), 16);
  });

  test('los tokens de Dulce son el rosa de relleno y el rosa de texto', () {
    final dulce = catalogoIdentidades['TEMA_DULCE']!.tokens;
    expect(dulce.streak, const Color(0xFFE53F80));
    expect(dulce.streakText, const Color(0xFFB01E5A));
  });
}
