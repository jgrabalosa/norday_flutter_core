import 'package:flutter/material.dart';

import '../l10n/norday_core_localizations.dart';
import '../theme/app_theme.dart';
import 'nori_vestida.dart';
import 'superficie_identidad.dart';

/// Motor: la tarjeta de «versión recomendada» (T-061). Nori contenta, un
/// título, una frase y dos botones. No obliga a nada: obligar es la versión
/// mínima ([ActualizacionObligatoriaScreen]).
///
/// No sabe qué hacer con los botones: [AvisoActualizacion] la enseña en un
/// diálogo y decide qué pasa con cada uno.
class TarjetaVersionRecomendada extends StatelessWidget {
  final VoidCallback onActualizar;
  final VoidCallback onAhoraNo;

  const TarjetaVersionRecomendada({
    super.key,
    required this.onActualizar,
    required this.onAhoraNo,
  });

  @override
  Widget build(BuildContext context) {
    final t = NordayCoreLocalizations.of(context)!;
    final tema = Theme.of(context);
    return SuperficieIdentidad(
      protagonista: true,
      relleno: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(
            child: NoriVestida(fase: 'CRIA', estado: 'feliz', tamano: 96),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            t.versionRecomendadaTitulo,
            textAlign: TextAlign.center,
            style: tema.textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.ms),
          Text(
            t.versionRecomendadaTexto,
            textAlign: TextAlign.center,
            style: tema.textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: onActualizar,
            child: Text(t.versionRecomendadaActualizar),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: onAhoraNo,
            child: Text(t.versionRecomendadaAhoraNo),
          ),
        ],
      ),
    );
  }
}
