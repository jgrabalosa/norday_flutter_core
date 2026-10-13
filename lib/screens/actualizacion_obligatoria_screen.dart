import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/norday_core_localizations.dart';

/// La app está por debajo de la versión mínima: solo deja actualizar.
/// No se puede cerrar con «atrás» ni hay nada debajo a lo que volver.
class ActualizacionObligatoriaScreen extends StatelessWidget {
  const ActualizacionObligatoriaScreen({super.key});

  /// Lanza la actualización. Sustituible en tests.
  @visibleForTesting
  static Future<void> Function() actualizar = _actualizarDesdePlay;

  static Future<void> _actualizarDesdePlay() async {
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable &&
          info.immediateUpdateAllowed) {
        final resultado = await InAppUpdate.performImmediateUpdate();
        // Hecha, o el usuario ha cerrado la pantalla de Google: se queda
        // aquí. Solo si la de Google falla se pasa a la ficha de Play.
        if (resultado != AppUpdateResult.inAppUpdateFailed) return;
      }
    } catch (e) {
      debugPrint('Actualización dentro de la app: no se pudo: $e');
    }
    // Plan B, la ficha de Play: cubre lo que la API de Google no puede
    // (Play aún no ofrece la versión a este móvil, o la app no se instaló
    // desde Play).
    try {
      final paquete = (await PackageInfo.fromPlatform()).packageName;
      await launchUrl(
        Uri.parse('https://play.google.com/store/apps/details?id=$paquete'),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('Ficha de Play: no se pudo abrir: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = NordayCoreLocalizations.of(context)!;
    final tema = Theme.of(context);
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  LucideIcons.download,
                  size: 56,
                  color: tema.colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  t.actualizacionTitulo,
                  textAlign: TextAlign.center,
                  style: tema.textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  t.actualizacionTexto,
                  textAlign: TextAlign.center,
                  style: tema.textTheme.bodyLarge,
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: () => actualizar(),
                  child: Text(t.actualizacionBoton),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
