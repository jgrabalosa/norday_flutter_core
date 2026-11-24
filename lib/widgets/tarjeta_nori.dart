import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../l10n/mensajes_mascota.dart';
import '../models/manifiesto_arte.dart';
import '../l10n/norday_core_localizations.dart';
import '../l10n/textos_app.dart';
import '../theme/app_theme.dart';
import 'fondo_identidad.dart';
import 'nori_vestida.dart';
import 'terrario_identidad.dart';

/// Lo que la pantalla de Nori entrega a quien comparte: la fase que está
/// viendo (puede ser otra que la que le toca por nivel), su nombre (vacío si
/// aún no tiene) y su nivel. Es lo único que `TarjetaNori` necesita pintar.
class DatosNori {
  /// Código de fase tal y como lo manda el backend (`HUEVO`, `CRIA`…).
  final String fase;
  final String nombre;
  final int nivel;

  const DatosNori({
    required this.fase,
    required this.nombre,
    required this.nivel,
  });
}

/// La postal de Nori para compartir: una imagen quieta de [ancho] × [alto]
/// lógicos (360 × 450, para capturarla a 1080 × 1350 con `pixelRatio` 3).
///
/// Fondo, terrario y Nori salen de la identidad equipada y de las prendas
/// puestas; Nori va siempre contento, como en el avatar. Sin aro de XP ni
/// halo animado. No llama al backend: recibe todo por parámetros.
///
/// La marca de abajo es [marca]; sin ella, el nombre que la app registró en
/// `TextosApp.nombre` (o «Norday»). El core no conoce ninguna app.
///
/// [prendas], [manifiesto] e [imagen] son para los tests, como en
/// [NoriVestida].
class TarjetaNori extends StatelessWidget {
  static const double ancho = 360;
  static const double alto = 450;

  final String fase;
  final String nombre;
  final int nivel;

  /// Con la fecha del móvil se decide fuera; aquí sólo se pinta.
  final bool nieve;
  final String? marca;

  final ValueListenable<Map<String, String>>? prendas;
  final ValueListenable<ManifiestoArte>? manifiesto;
  final Future<File?> Function(String ruta)? imagen;

  const TarjetaNori({
    super.key,
    required this.fase,
    required this.nombre,
    required this.nivel,
    this.nieve = false,
    this.marca,
    this.prendas,
    this.manifiesto,
    this.imagen,
  });

  /// Atajo desde lo que entrega `MascotaScreen.alCompartir`.
  TarjetaNori.de(DatosNori datos, {Key? key, bool nieve = false, String? marca})
    : this(
        key: key,
        fase: datos.fase,
        nombre: datos.nombre,
        nivel: datos.nivel,
        nieve: nieve,
        marca: marca,
      );

  @override
  Widget build(BuildContext context) {
    final t = tokens(context);
    final l = NordayCoreLocalizations.of(context)!;
    final titulo = nombre.trim().isEmpty
        ? MensajesMascota.fase(l, fase)
        : nombre.trim();
    const lado = 220.0;

    return SizedBox(
      width: ancho,
      height: alto,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // La base opaca: `FondoIdentidad` no la pinta (en la app la pone
            // el Scaffold), y sin ella el PNG sale con agujeros. Como en
            // `TarjetaCierreDia` de Habits.
            ColoredBox(color: t.bg),
            const FondoIdentidad(),
            Column(
              children: [
                const Spacer(flex: 3),
                SizedBox(
                  width: lado * 1.12,
                  height: lado * 1.12,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        bottom: lado * 0.02,
                        child: TerrarioIdentidad(
                          ancho: lado * 0.88,
                          nieve: nieve,
                        ),
                      ),
                      NoriVestida(
                        fase: fase,
                        estado: 'feliz',
                        tamano: lado,
                        prendas: prendas,
                        manifiesto: manifiesto,
                        imagen: imagen,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Text(
                    titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.displaySmall?.copyWith(color: t.text),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l.mascotaNivel(nivel),
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: t.textMuted),
                ),
                const Spacer(flex: 2),
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: Text(
                    marca ?? TextosApp.nombreDe(context),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: t.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
