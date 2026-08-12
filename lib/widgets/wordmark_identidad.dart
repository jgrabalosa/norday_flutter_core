import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/identidad_paleta.dart';
import '../theme/identidades_paleta.dart';

/// El nombre de la marca escrito con la letra de la identidad equipada.
///
/// La familia ya la pone el tema (`AppTheme` construye el `TextTheme` con
/// `fontDisplay` en los roles de titular), así que aquí se parte de
/// `headlineMedium` y sólo se ajusta el tamaño.
///
/// Lo que se añade es el tratamiento de firma de cada identidad —mayúsculas y
/// tracking en Neotokyo+, itálica en Alba—, que **no** vive en el tema global a
/// propósito: allí Neotokyo+ acabaría poniendo en mayúsculas hasta el cuerpo de
/// un artículo. Un wordmark es titular puro, que es justo donde ese
/// tratamiento sí toca.
class WordmarkIdentidad extends StatelessWidget {
  final String texto;

  /// Tamaño de fuente en dp. Lo manda quien lo pinta: el splash lo quiere
  /// grande y la cabecera del login, pequeño.
  final double tamano;

  final Color color;

  const WordmarkIdentidad({
    super.key,
    required this.texto,
    required this.tamano,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final id = identidad(context);
    final base = Theme.of(context).textTheme.headlineMedium ?? const TextStyle();

    return switch (id.forma) {
      // Profundidad — el wordmark de siempre, sin más.
      FormaIdentidad.glass => Text(
          texto,
          textAlign: TextAlign.center,
          style: base.copyWith(
              fontSize: tamano, color: color, letterSpacing: 0.5),
        ),

      // Neotokyo+ — mayúsculas y tracking generoso, proporcional al cuerpo para
      // que no se cierre al reducirlo.
      FormaIdentidad.chamfer => Text(
          texto.toUpperCase(),
          textAlign: TextAlign.center,
          style: base.copyWith(
              fontSize: tamano, color: color, letterSpacing: tamano * 0.09),
        ),

      // Alba — itálica. Se pide al catálogo y no con un `copyWith` sobre el
      // estilo del tema porque la itálica de verdad es otro fichero: inclinar
      // la redonda daría un falso cursiva.
      FormaIdentidad.hairline => Text(
          texto,
          textAlign: TextAlign.center,
          style: GoogleFonts.getFont(
            id.fontDisplay,
            fontSize: tamano,
            fontWeight: FontWeight.w600,
            fontStyle: FontStyle.italic,
            color: color,
          ),
        ),

      // Dulce — redonda y apretadita, como todo lo suyo.
      FormaIdentidad.pill => Text(
          texto,
          textAlign: TextAlign.center,
          style: base.copyWith(
              fontSize: tamano, color: color, letterSpacing: 0.2),
        ),
    };
  }
}
