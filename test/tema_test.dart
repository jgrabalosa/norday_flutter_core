import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:norday_flutter_core/theme/app_theme.dart';
import 'package:norday_flutter_core/theme/identidades_paleta.dart';

/// El tema de Material sale de los tokens de la identidad, y su brillo del
/// fondo: Dulce es clara. Con el brillo fijo a oscuro, todo lo que Material
/// pinta sin color propio salía claro sobre claro en Dulce.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final identidadInicial = identidadEquipadaNotifier.value;
  tearDown(() => aplicarIdentidadEquipada(identidadInicial.codigo));

  ThemeData temaDe(String codigo) {
    aplicarIdentidadEquipada(codigo);
    return AppTheme.deTema(temaEquipadoNotifier.value);
  }

  test('el brillo del tema sale del fondo de la identidad', () {
    expect(temaDe('TEMA_PROFUNDIDAD').brightness, Brightness.dark);
    expect(temaDe('TEMA_NEOTOKYO_PLUS').brightness, Brightness.dark);
    expect(temaDe('TEMA_DULCE').brightness, Brightness.light);
  });

  test('los roles de Material que se ven salen de los tokens', () {
    for (final entrada in catalogoIdentidades.entries) {
      final t = entrada.value.tokens;
      final esquema = temaDe(entrada.key).colorScheme;
      final motivo = entrada.key;
      expect(esquema.primary, t.primary, reason: motivo);
      expect(esquema.onPrimary, t.tinta, reason: motivo);
      expect(esquema.surface, t.surface, reason: motivo);
      expect(esquema.onSurface, t.text, reason: motivo);
      expect(esquema.onSurfaceVariant, t.textMuted, reason: motivo);
      expect(esquema.surfaceContainerHigh, t.surfaceAlta, reason: motivo);
      expect(esquema.surfaceContainerHighest, t.surface2, reason: motivo);
      expect(esquema.outline, t.aroVacio, reason: motivo);
      expect(esquema.inverseSurface, t.text, reason: motivo);
      expect(esquema.onInverseSurface, t.surface, reason: motivo);
      expect(esquema.surfaceTint, Colors.transparent, reason: motivo);
    }
  });

  test('ningún rol de la escala tipográfica sale sin el color del texto', () {
    for (final entrada in catalogoIdentidades.entries) {
      final t = entrada.value.tokens;
      final tt = temaDe(entrada.key).textTheme;
      final roles = {
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
      for (final rol in roles.entries) {
        expect(rol.value?.color, t.text, reason: '${entrada.key} · ${rol.key}');
      }
    }
  });

  test('diálogo, hoja, aviso y barra sin velo de color', () {
    for (final entrada in catalogoIdentidades.entries) {
      final t = entrada.value.tokens;
      final tema = temaDe(entrada.key);
      final motivo = entrada.key;
      expect(tema.dialogTheme.backgroundColor, t.surfaceAlta, reason: motivo);
      expect(
        tema.dialogTheme.surfaceTintColor,
        Colors.transparent,
        reason: motivo,
      );
      expect(tema.dialogTheme.contentTextStyle?.color, t.text, reason: motivo);
      expect(tema.bottomSheetTheme.backgroundColor, t.surface, reason: motivo);
      expect(
        tema.bottomSheetTheme.modalBackgroundColor,
        t.surface,
        reason: motivo,
      );
      expect(tema.snackBarTheme.backgroundColor, t.text, reason: motivo);
      expect(
        tema.snackBarTheme.contentTextStyle?.color,
        t.surface,
        reason: motivo,
      );
      expect(
        tema.appBarTheme.surfaceTintColor,
        Colors.transparent,
        reason: motivo,
      );
    }
  });

  test('botones de texto y de contorno escriben con el acento que se lee', () {
    for (final entrada in catalogoIdentidades.entries) {
      final t = entrada.value.tokens;
      final tema = temaDe(entrada.key);
      final motivo = entrada.key;
      expect(
        tema.textButtonTheme.style?.foregroundColor?.resolve({}),
        t.successText,
        reason: motivo,
      );
      expect(
        tema.outlinedButtonTheme.style?.foregroundColor?.resolve({}),
        t.successText,
        reason: motivo,
      );
      expect(tema.progressIndicatorTheme.color, t.primaryTrazo, reason: motivo);
      expect(
        tema.textSelectionTheme.cursorColor,
        t.primaryTrazo,
        reason: motivo,
      );
    }
  });

  test('el nombre de un ítem (titleMedium) mide 16, como en Material 3', () {
    expect(temaDe('TEMA_PROFUNDIDAD').textTheme.titleMedium?.fontSize, 16);
  });
}
