import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../l10n/norday_core_localizations.dart';
import '../theme/app_theme.dart';
import '../theme/identidad_paleta.dart';
import 'superficie_identidad.dart';

/// Chip con el nombre de una identidad de paleta, escrito con SU propio
/// tratamiento tipográfico — nunca el de la identidad equipada.
///
/// Existe porque `WordmarkIdentidad` sólo sabe pintar la identidad equipada
/// (lee `identidad(context)`): en la tarjeta de producto de la tienda hace
/// falta lo contrario, la identidad que se está *listando*, que casi nunca es
/// la que el usuario lleva puesta. El criterio de mayúsculas/tracking/itálica
/// por [FormaIdentidad] es el mismo que usa `WordmarkIdentidad`, copiado a
/// propósito en vez de reutilizado.
class ChipIdentidad extends StatelessWidget {
  final IdentidadPaleta identidad;

  const ChipIdentidad({super.key, required this.identidad});

  @override
  Widget build(BuildContext context) {
    final id = identidad;
    final color = id.tokens.primary;

    final Widget nombre = switch (id.forma) {
      // Profundidad — normal.
      FormaIdentidad.glass => Text(
          id.nombre,
          style: GoogleFonts.getFont(id.fontDisplay,
              fontSize: 12, fontWeight: FontWeight.bold, color: color),
        ),
      // Neotokyo+ — mayúsculas y tracking generoso.
      FormaIdentidad.chamfer => Text(
          id.nombre.toUpperCase(),
          style: GoogleFonts.getFont(id.fontDisplay,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              color: color),
        ),
      // Alba — itálica.
      FormaIdentidad.hairline => Text(
          id.nombre,
          style: GoogleFonts.getFont(id.fontDisplay,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
              color: color),
        ),
      // Dulce — normal, tracking mínimo.
      FormaIdentidad.pill => Text(
          id.nombre,
          style: GoogleFonts.getFont(id.fontDisplay,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
              color: color),
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          nombre,
        ],
      ),
    );
  }
}

/// Maqueta de una pantalla de mentira pintada íntegramente con el lenguaje
/// visual de [id]: sus colores, su letra, su radio, su forma de superficie y
/// un detalle mínimo de firma. Ni un trazo sale de la identidad equipada —lo
/// que se ve aquí es el tema que se está mirando, nunca el que se lleva
/// puesto—, así que esta maqueta se usa siempre desde la previsualización de
/// la tienda y nunca desde una pantalla real.
class MaquetaPreviewIdentidad extends StatelessWidget {
  final IdentidadPaleta identidad;

  const MaquetaPreviewIdentidad({super.key, required this.identidad});

  @override
  Widget build(BuildContext context) {
    final l = NordayCoreLocalizations.of(context)!;
    final id = identidad;
    final p = id.tokens;
    // Sobre el primary puede ir texto claro u oscuro según lo vivo que sea:
    // hay paletas con primary casi blanco y otras con primary casi negro.
    final sobrePrimary =
        p.primary.computeLuminance() > 0.5 ? Colors.black : Colors.white;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: p.bg,
        shape: formaIdentidad(id, radio: id.radioHero),
      ),
      child: Stack(
        children: [
          // Profundidad — un par de puntos casi invisibles tipo estrella,
          // quietos: sin certeza de hacer bien el parpadeo respetando
          // `disableAnimations`, mejor sin animación que con una que lo
          // ignore.
          if (id.forma == FormaIdentidad.glass) ..._estrellasDeFondo(p),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(l.navHoy,
                          style: GoogleFonts.getFont(id.fontDisplay,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: p.text)),
                    ),
                    _pastilla(
                        id: id, icono: LucideIcons.coins, texto: '120', color: p.points),
                  ],
                ),
                const SizedBox(height: 12),
                _tarjetaHabitoCompletado(id, p, l),
                const SizedBox(height: 10),
                _tarjetaHabitoConRacha(id, p, l),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: ShapeDecoration(
                    color: p.primary,
                    shape: formaIdentidad(id, radio: id.radioSecundario),
                  ),
                  child: Center(
                    child: Text(l.comunContinuar,
                        style: GoogleFonts.getFont(id.fontDisplay,
                            fontWeight: FontWeight.w700, color: sobrePrimary)),
                  ),
                ),
                const SizedBox(height: 16),
                _barraNavSimulada(id, p, l),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _estrellasDeFondo(TokensContextuales p) => [
        Positioned(
          top: 14,
          right: 54,
          child: Icon(LucideIcons.sparkle, size: 11, color: p.text.withValues(alpha: 0.07)),
        ),
        Positioned(
          top: 64,
          right: 18,
          child: Icon(LucideIcons.sparkle, size: 8, color: p.text.withValues(alpha: 0.05)),
        ),
        Positioned(
          bottom: 90,
          left: 24,
          child: Icon(LucideIcons.sparkle, size: 9, color: p.text.withValues(alpha: 0.06)),
        ),
      ];

  Widget _tarjetaHabitoCompletado(
      IdentidadPaleta id, TokensContextuales p, NordayCoreLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: ShapeDecoration(
        color: p.surface,
        shape: formaIdentidad(id, radio: id.radioSecundario),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.circleCheckBig, size: 20, color: p.success),
              const SizedBox(width: 8),
              Expanded(
                child: Text(l.plantillaBeberAgua,
                    style: GoogleFonts.getFont(id.fontDisplay,
                        fontWeight: FontWeight.w600, color: p.text)),
              ),
              _pastilla(id: id, icono: LucideIcons.flame, texto: '5', color: p.streak),
            ],
          ),
          // Alba — línea fina + rombo pequeño bajo el nombre del hábito
          // destacado: es la única identidad sin superficie propia, así que
          // su firma va en un trazo, no en una forma de tarjeta.
          if (id.forma == FormaIdentidad.hairline) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Transform.rotate(
                  angle: 0.785398, // 45°: rombo
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      border: Border.all(color: p.primary.withValues(alpha: 0.55)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 1,
                    color: p.textMuted.withValues(alpha: 0.25),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Text(l.dashCompletados,
              style: GoogleFonts.getFont(id.fontBody,
                  fontSize: 11, letterSpacing: 0.5, color: p.textMuted)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: 0.7,
              minHeight: 8,
              backgroundColor: p.surface2,
              valueColor: AlwaysStoppedAnimation(p.success),
            ),
          ),
        ],
      ),
    );
  }

  /// Segunda tarjeta: un hábito con racha en vez de check, para que la
  /// maqueta se lea como una lista de verdad y no como una única fila suelta.
  Widget _tarjetaHabitoConRacha(
      IdentidadPaleta id, TokensContextuales p, NordayCoreLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: ShapeDecoration(
        color: p.surface,
        shape: formaIdentidad(id, radio: id.radioSecundario),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.circle, size: 20, color: p.textMuted.withValues(alpha: 0.5)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(l.tiendaPreviewHabito2,
                style: GoogleFonts.getFont(id.fontDisplay,
                    fontWeight: FontWeight.w600, color: p.text)),
          ),
          _pastilla(id: id, icono: LucideIcons.flame, texto: '3', color: p.streak),
          // Dulce — el único detalle manuscrito de la maqueta, y sólo si la
          // identidad declara fuente de acento.
          if (id.forma == FormaIdentidad.pill && id.fontAcento != null) ...[
            const SizedBox(width: 8),
            Text(l.tiendaPreviewQueCrack,
                style: GoogleFonts.getFont(id.fontAcento!,
                    fontSize: 16, color: p.primary)),
          ],
        ],
      ),
    );
  }

  Widget _barraNavSimulada(
      IdentidadPaleta id, TokensContextuales p, NordayCoreLocalizations l) {
    final items = [
      (LucideIcons.house, l.navHoy),
      (LucideIcons.pawPrint, l.mascotaTitulo),
      (LucideIcons.listChecks, l.tiendaPreviewNavHabitos),
      (LucideIcons.userRound, l.tiendaPreviewNavPerfil),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: ShapeDecoration(
        color: p.surface,
        shape: formaIdentidad(id, radio: id.radioSecundario),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (final (icono, etiqueta) in items)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icono, size: 18, color: p.textMuted),
                const SizedBox(height: 2),
                Text(etiqueta,
                    style: GoogleFonts.getFont(id.fontDisplay,
                        fontSize: 10, color: p.textMuted)),
              ],
            ),
        ],
      ),
    );
  }

  /// Pastilla de color de la maqueta (racha, puntos): fondo tenue del mismo
  /// color que el contenido, igual que en la app de verdad.
  Widget _pastilla({
    required IdentidadPaleta id,
    required IconData icono,
    required String texto,
    required Color color,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 13, color: color),
            const SizedBox(width: 4),
            Text(texto,
                style: GoogleFonts.getFont(id.fontDisplay,
                    fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      );
}
