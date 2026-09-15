import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
/// Cuál de las dos pegatinas lleva la nota de Profundidad. PROVISIONAL: está
/// para verlas en el móvil y elegir. Cuando se decida, se borra la constante
/// y se deja sólo la forma elegida.
///
/// `true` → cohete. `false` → constelación de tres puntos.
const bool kPegatinaCohete = true;

class BurbujaContexto extends StatelessWidget {
  final String texto;

  /// Color del texto, cuando la pantalla necesita que diga algo más que la
  /// frase. Sin él, cada forma pinta el suyo, que es lo que hacía siempre.
  final Color? color;

  const BurbujaContexto({super.key, required this.texto, this.color});

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

  /// Profundidad — nota de cristal con una pegatina en la esquina. El
  /// degradado entre las dos superficies y el filo claro de arriba son lo que
  /// hace que parezca un panel con canto y no un rectángulo de color; la
  /// inclinación y la pegatina son lo que la convierten en algo puesto ahí
  /// por alguien, como el post-it de Dulce.
  ///
  /// Se inclina al revés que Dulce (positivo, no negativo) a propósito: las
  /// dos identidades comparten el gesto pero no la mano.
  Widget _cristal(IdentidadPaleta id, TokensContextuales t) {
    final tarjeta = Container(
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
          color: color ?? t.textMuted,
        ),
      ),
    );

    return Transform.rotate(
      angle: 0.018, // ~1°, menos que Dulce: el cristal pesa más que el papel
      child: Stack(
        // La pegatina sobresale del borde de la tarjeta, así que el Stack no
        // puede recortar a sus hijos.
        clipBehavior: Clip.none,
        children: [
          tarjeta,
          Positioned(
            top: -9,
            right: -7,
            child: _pegatina(t),
          ),
        ],
      ),
    );
  }

  /// La pegatina de la esquina de Profundidad. Dos formas mientras se decide
  /// cuál se queda — ver [kPegatinaCohete].
  Widget _pegatina(TokensContextuales t) {
    if (kPegatinaCohete) {
      return Transform.rotate(
        // El cohete de Lucide apunta arriba-izquierda; se endereza un poco
        // para que salga hacia la esquina y no hacia el texto.
        angle: 0.5,
        child: Icon(
          LucideIcons.rocket,
          size: 20,
          color: t.streak,
        ),
      );
    }

    // Constelación: tres puntos y dos trazos, el mismo lenguaje que el fondo
    // de la identidad. Se dibuja a mano en vez de usar un icono porque no hay
    // ninguno que sea esto.
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: _ConstelacionPegatina(color: t.streak)),
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
            color: color ?? t.textMuted,
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
          color: color ?? t.textMuted,
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
          color: t.fondoNota,
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
            color: color ?? t.text,
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

/// Tres estrellas unidas por dos trazos finos. Es la pegatina alternativa al
/// cohete en la nota de Profundidad; el dibujo es deliberadamente mínimo,
/// porque a 22 px cualquier detalle se pierde.
class _ConstelacionPegatina extends CustomPainter {
  final Color color;

  _ConstelacionPegatina({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final a = Offset(size.width * 0.18, size.height * 0.72);
    final b = Offset(size.width * 0.52, size.height * 0.24);
    final c = Offset(size.width * 0.86, size.height * 0.60);

    final trazo = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;

    canvas.drawLine(a, b, trazo);
    canvas.drawLine(b, c, trazo);

    final punto = Paint()..color = color;
    canvas.drawCircle(a, 1.7, punto);
    canvas.drawCircle(b, 2.3, punto);
    canvas.drawCircle(c, 1.7, punto);
  }

  @override
  bool shouldRepaint(_ConstelacionPegatina old) => old.color != color;
}
