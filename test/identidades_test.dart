import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:norday_flutter_core/theme/app_theme.dart';
import 'package:norday_flutter_core/theme/identidad_paleta.dart';
import 'package:norday_flutter_core/theme/identidades_paleta.dart';

/// El catalogo se escribe a mano y nada de lo que lleva lo comprueba el
/// analizador: una familia mal escrita no falla hasta que GoogleFonts.getFont
/// la busca en tiempo de ejecucion, y un codigo que no case con su clave rompe
/// el equipado sin decir nada.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Sin esto, construir un tema en un test intenta bajar las fuentes por HTTP.
  GoogleFonts.config.allowRuntimeFetching = false;

  final identidadInicial = identidadEquipadaNotifier.value;

  tearDown(() => aplicarIdentidadEquipada(identidadInicial.codigo));

  test('son cuatro y ninguna de las siete paletas antiguas sigue viva', () {
    expect(catalogoIdentidades.length, 4);

    const viejas = [
      'TEMA_BASICO_CLARO',
      'TEMA_BASICO_OSCURO',
      'TEMA_CALIDEZ',
      'TEMA_NEOTOKYO',
      'TEMA_OCEANO',
      'TEMA_BOSQUE',
      'TEMA_COBRE',
    ];
    for (final codigo in viejas) {
      expect(catalogoIdentidades.containsKey(codigo), isFalse, reason: codigo);
    }
  });

  test('la clave del mapa es el propio codigo de la identidad', () {
    for (final entrada in catalogoIdentidades.entries) {
      expect(entrada.value.codigo, entrada.key);
    }
  });

  test('las familias tipograficas existen en google_fonts', () {
    final disponibles = GoogleFonts.asMap().keys.toSet();

    for (final identidad in catalogoIdentidades.values) {
      for (final familia in [
        identidad.fontDisplay,
        identidad.fontBody,
        if (identidad.fontAcento != null) identidad.fontAcento!,
      ]) {
        expect(disponibles.contains(familia), isTrue,
            reason: '${identidad.codigo} -> $familia');
      }
    }
  });

  test('el chaflan es el mismo token en toda identidad que corta esquina', () {
    final conChaflan = catalogoIdentidades.values
        .where((i) => i.forma == FormaIdentidad.chamfer);

    expect(conChaflan, isNotEmpty);
    for (final identidad in conChaflan) {
      expect(identidad.chaflan, 10.0, reason: identidad.codigo);
    }
  });

  test('aplicar una identidad mueve tambien el notifier de solo color', () {
    aplicarIdentidadEquipada('TEMA_ALBA');

    final alba = catalogoIdentidades['TEMA_ALBA']!;
    expect(identidadEquipadaNotifier.value.codigo, 'TEMA_ALBA');
    expect(temaEquipadoNotifier.value, same(alba.tokens));
  });

  test('sin codigo, o con uno que este cliente no conoce, vale Profundidad', () {
    aplicarIdentidadEquipada('TEMA_ALBA');
    aplicarIdentidadEquipada(null);
    expect(identidadEquipadaNotifier.value.codigo, 'TEMA_PROFUNDIDAD');

    aplicarIdentidadEquipada('TEMA_QUE_LLEGARA_EN_LA_PROXIMA_VERSION');
    expect(identidadEquipadaNotifier.value.codigo, 'TEMA_PROFUNDIDAD');
    expect(temaEquipadoNotifier.value, same(tokensProfundidad));
  });

  /// La escala vive en `AppTheme`, no en la paleta, y esto es lo que impide
  /// que se le escape a una identidad. Profundidad es donde se mide; las otras
  /// tres se la encuentran hecha y sólo aportan dos nombres de familia. El día
  /// que alguien meta un tamaño en una paleta, esto se cae.
  test('la escala tipografica es identica en las cuatro identidades', () {
    Map<String, TextStyle?> rolesDe(TextTheme tt) => {
          'displayLarge': tt.displayLarge,
          'displayMedium': tt.displayMedium,
          'displaySmall': tt.displaySmall,
          'headlineLarge': tt.headlineLarge,
          'headlineMedium': tt.headlineMedium,
          'headlineSmall': tt.headlineSmall,
          'titleLarge': tt.titleLarge,
          'titleMedium': tt.titleMedium,
          'titleSmall': tt.titleSmall,
          'bodyLarge': tt.bodyLarge,
          'bodyMedium': tt.bodyMedium,
          'bodySmall': tt.bodySmall,
          'labelLarge': tt.labelLarge,
          'labelMedium': tt.labelMedium,
          'labelSmall': tt.labelSmall,
        };

    Map<String, TextStyle?>? referencia;
    String? codigoReferencia;

    for (final entrada in catalogoIdentidades.entries) {
      aplicarIdentidadEquipada(entrada.key);
      final roles = rolesDe(AppTheme.deTema(entrada.value.tokens).textTheme);

      if (referencia == null) {
        referencia = roles;
        codigoReferencia = entrada.key;
        continue;
      }

      for (final rol in referencia.keys) {
        final motivo = '$rol — ${entrada.key} frente a $codigoReferencia';
        expect(roles[rol]?.fontSize, referencia[rol]?.fontSize, reason: motivo);
        expect(roles[rol]?.fontWeight, referencia[rol]?.fontWeight,
            reason: motivo);
        expect(roles[rol]?.letterSpacing, referencia[rol]?.letterSpacing,
            reason: motivo);
      }
    }
  });
}
