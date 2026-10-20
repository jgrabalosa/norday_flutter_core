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
        style: GoogleFonts.getFont(
          id.fontDisplay,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
      // Neotokyo+ — mayúsculas y tracking generoso.
      FormaIdentidad.chamfer => Text(
        id.nombre.toUpperCase(),
        style: GoogleFonts.getFont(
          id.fontDisplay,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: id.espaciadoEtiquetaPara(12),
          color: color,
        ),
      ),
      // Dulce — normal, tracking mínimo.
      FormaIdentidad.pill => Text(
        id.nombre,
        style: GoogleFonts.getFont(
          id.fontDisplay,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.2,
          color: color,
        ),
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
    final sobrePrimary = p.primary.computeLuminance() > 0.5
        ? Colors.black
        : Colors.white;

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
                      child: Text(
                        l.navHoy,
                        style: GoogleFonts.getFont(
                          id.fontDisplay,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: p.text,
                        ),
                      ),
                    ),
                    _pastilla(
                      id: id,
                      icono: LucideIcons.coins,
                      texto: '120',
                      color: p.points,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _tarjetaHabito(
                  id: id,
                  texto: l.plantillaBeberAgua,
                  hecha: true,
                  sobrePrimary: sobrePrimary,
                ),
                const SizedBox(height: 10),
                _tarjetaHabito(
                  id: id,
                  texto: l.tiendaPreviewHabito2,
                  hecha: false,
                  sobrePrimary: sobrePrimary,
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
      child: Icon(
        LucideIcons.sparkle,
        size: 11,
        color: p.text.withValues(alpha: 0.07),
      ),
    ),
    Positioned(
      top: 64,
      right: 18,
      child: Icon(
        LucideIcons.sparkle,
        size: 8,
        color: p.text.withValues(alpha: 0.05),
      ),
    ),
    Positioned(
      bottom: 90,
      left: 24,
      child: Icon(
        LucideIcons.sparkle,
        size: 9,
        color: p.text.withValues(alpha: 0.06),
      ),
    ),
  ];

  /// Una tarjeta de hábito de mentira, con el lenguaje de [id] —su superficie,
  /// su letra, su color— y nunca con el de la identidad equipada: aquí no se
  /// usa ni `SuperficieIdentidad` ni `CheckCircular`, que leen la equipada.
  Widget _tarjetaHabito({
    required IdentidadPaleta id,
    required String texto,
    required bool hecha,
    required Color sobrePrimary,
  }) {
    final p = id.tokens;
    final Decoration decoracion = switch (id.forma) {
      FormaIdentidad.glass => BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(id.radioSecundario),
      ),
      FormaIdentidad.chamfer => ShapeDecoration(
        color: p.bg,
        shape: formaIdentidad(
          id,
          radio: id.radioSecundario,
          lado: BorderSide(color: p.primary, width: 1.5),
        ),
      ),
      FormaIdentidad.pill => BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(id.radioSecundario),
        border: Border.all(color: p.textMuted, width: 2),
        boxShadow: [
          BoxShadow(
            color: p.textMuted.withValues(alpha: 0.2),
            offset: const Offset(2.3, 2.3),
          ),
        ],
      ),
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: decoracion,
      child: Row(
        children: [
          _casilla(id: id, hecha: hecha, sobrePrimary: sobrePrimary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              texto,
              style: GoogleFonts.getFont(
                id.fontBody,
                fontSize: tamanoLectura(id, 15),
                fontWeight: FontWeight.w600,
                color: p.text,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// La casilla de la tarjeta, con la forma de la identidad. Hecha: relleno y
  /// marca. Pendiente: solo el aro.
  Widget _casilla({
    required IdentidadPaleta id,
    required bool hecha,
    required Color sobrePrimary,
  }) {
    final p = id.tokens;
    const lado = 22.0;
    final Widget? marca = hecha
        ? Icon(
            LucideIcons.check,
            size: 14,
            color: id.forma == FormaIdentidad.pill
                ? Colors.white
                : sobrePrimary,
          )
        : null;
    final Decoration decoracion = switch (id.forma) {
      FormaIdentidad.glass => BoxDecoration(
        shape: BoxShape.circle,
        color: hecha ? p.primary : null,
        border: hecha ? null : Border.all(color: p.aroVacio, width: 2),
      ),
      FormaIdentidad.chamfer => ShapeDecoration(
        color: hecha ? p.primary : null,
        shape: BordeChaflan(
          chaflan: 5,
          side: hecha
              ? BorderSide.none
              : BorderSide(color: p.aroVacio, width: 2),
        ),
      ),
      FormaIdentidad.pill => BoxDecoration(
        shape: BoxShape.circle,
        color: hecha ? p.success : null,
        border: hecha ? null : Border.all(color: p.textMuted, width: 2),
      ),
    };

    return Container(
      width: lado,
      height: lado,
      alignment: Alignment.center,
      decoration: decoracion,
      child: marca,
    );
  }

  Widget _barraNavSimulada(
    IdentidadPaleta id,
    TokensContextuales p,
    NordayCoreLocalizations l,
  ) {
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
          // Cada elemento reparte el ancho a partes iguales y su contenido se
          // encoge si no cabe: con la escala de texto grande, las cuatro
          // etiquetas no caben en 256 px y la fila se salía 129 px.
          for (final (icono, etiqueta) in items)
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icono, size: 18, color: p.textMuted),
                    const SizedBox(height: 2),
                    Text(
                      etiqueta,
                      style: GoogleFonts.getFont(
                        id.fontDisplay,
                        // 11 es el suelo de la escala (labelSmall); a 10 se salía.
                        fontSize: 11,
                        color: p.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
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
  }) => Container(
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
        Text(
          texto,
          style: GoogleFonts.getFont(
            id.fontDisplay,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    ),
  );
}
