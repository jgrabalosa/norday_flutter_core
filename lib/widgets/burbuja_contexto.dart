import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import '../theme/identidad_paleta.dart';
import '../theme/identidades_paleta.dart';

/// La frase corta que acompaña a la mascota, resuelta con la superficie de la
/// identidad equipada. No compone el texto: lo recibe hecho (ver
/// `MensajesMascota.contexto`), porque quién está en qué fase es dato de
/// pantalla y esto es sólo cómo se pinta.
///
/// Es el sitio donde más se nota que una identidad no es un repintado: la
/// misma frase sale en tarjeta de cristal, en panel cortado, en itálica
/// desnuda o en un post-it escrito a mano.
///
/// No anima nada — es texto que cambia cuando cambian los datos, no un gesto.
class BurbujaContexto extends StatelessWidget {
  final String texto;

  const BurbujaContexto({super.key, required this.texto});

  @override
  Widget build(BuildContext context) {
    final id = identidad(context);
    final t = tokens(context);

    return switch (id.forma) {
      FormaIdentidad.glass => _cristal(id, t),
      FormaIdentidad.chamfer => _panelCortado(id, t),
      FormaIdentidad.hairline => _soloTexto(id, t),
      FormaIdentidad.pill => _postIt(id, t),
    };
  }

  static const _relleno = EdgeInsets.symmetric(horizontal: 16, vertical: 10);

  /// Profundidad — tarjeta de cristal: degradado entre las dos superficies y
  /// un filo claro arriba, que es lo que hace que parezca un panel con canto
  /// y no un rectángulo de color.
  Widget _cristal(IdentidadPaleta id, TokensContextuales t) {
    return Container(
      padding: _relleno,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(id.radioHero),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [t.surface, t.surface2],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: GoogleFonts.getFont(
          id.fontBody,
          fontSize: 14,
          height: 1.3,
          color: t.textMuted,
        ),
      ),
    );
  }

  /// Neotokyo+ — panel con la esquina cortada, el mismo chaflán que la
  /// identidad usa en todo lo demás. Mayúsculas y tracking: es la única
  /// identidad que los admite, y sólo en [IdentidadPaleta.fontDisplay].
  Widget _panelCortado(IdentidadPaleta id, TokensContextuales t) {
    return CustomPaint(
      painter: _ChaflanPainter(
        relleno: t.surface,
        borde: t.primary.withValues(alpha: 0.70),
        chaflan: id.chaflan,
      ),
      child: Padding(
        padding: _relleno,
        child: Text(
          texto.toUpperCase(),
          textAlign: TextAlign.center,
          style: GoogleFonts.getFont(
            id.fontDisplay,
            fontSize: 12,
            height: 1.3,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w600,
            color: t.textMuted,
          ),
        ),
      ),
    );
  }

  /// Alba — sin burbuja. La identidad no encajona el contenido secundario en
  /// ningún otro sitio, y esto es contenido secundario: una itálica y aire.
  Widget _soloTexto(IdentidadPaleta id, TokensContextuales t) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: GoogleFonts.getFont(
          id.fontDisplay,
          fontSize: 15,
          height: 1.4,
          fontStyle: FontStyle.italic,
          color: t.textMuted,
        ),
      ),
    );
  }

  /// Dulce — post-it: torcido, con sombra de color y escrito a mano. Éste es
  /// el uso único de [IdentidadPaleta.fontAcento] en la pantalla; si aparece
  /// en algún otro sitio, se está usando mal.
  Widget _postIt(IdentidadPaleta id, TokensContextuales t) {
    return Transform.rotate(
      angle: -0.025, // ~1.4°, lo justo para que se note pegado a mano
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: t.surface2,
          borderRadius: BorderRadius.circular(id.radioSecundario),
          boxShadow: [
            BoxShadow(
              color: t.primary.withValues(alpha: 0.28),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Text(
          texto,
          textAlign: TextAlign.center,
          style: GoogleFonts.getFont(
            // La de acento es opcional en el modelo; sin ella, el cuerpo.
            id.fontAcento ?? id.fontBody,
            // Las manuscritas piden más cuerpo que una de palo para leerse
            // igual de bien.
            fontSize: 19,
            height: 1.2,
            color: t.text,
          ),
        ),
      ),
    );
  }
}

/// Rectángulo con las cuatro esquinas cortadas en recto. Se pinta relleno y
/// borde de una vez, en vez de clipar y dibujar el borde aparte: el `ClipPath`
/// recortaría la forma pero dejaría el trazo sin sitio donde caber.
class _ChaflanPainter extends CustomPainter {
  final Color relleno;
  final Color borde;
  final double chaflan;

  _ChaflanPainter({
    required this.relleno,
    required this.borde,
    required this.chaflan,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Con cajas muy bajas el corte se comería el lado entero.
    final c = chaflan.clamp(0.0, size.shortestSide / 2);
    final path = Path()
      ..moveTo(c, 0)
      ..lineTo(size.width - c, 0)
      ..lineTo(size.width, c)
      ..lineTo(size.width, size.height - c)
      ..lineTo(size.width - c, size.height)
      ..lineTo(c, size.height)
      ..lineTo(0, size.height - c)
      ..lineTo(0, c)
      ..close();

    canvas.drawPath(path, Paint()..color = relleno);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = borde,
    );
  }

  @override
  bool shouldRepaint(_ChaflanPainter old) =>
      old.relleno != relleno || old.borde != borde || old.chaflan != chaflan;
}
