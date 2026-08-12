import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/identidad_paleta.dart';
import '../theme/identidades_paleta.dart';

/// Cómo se resuelve una superficie en cada identidad, en un solo sitio.
///
/// Nació dentro de `login_screen.dart` y salió de ahí en cuanto Perfil,
/// Colección y Logros necesitaron lo mismo: una tarjeta de Material en medio de
/// una pantalla achaflanada canta, y cuatro copias del mismo `switch` acaban
/// divergiendo. Es el equivalente en el motor a `identidad_ui.dart` de la app
/// de hábitos, que hace esto mismo para la tarjeta de hábito y el chip.
///
/// Se despacha por [FormaIdentidad] con un `switch` exhaustivo y los radios
/// salen de [IdentidadPaleta], nunca de un número suelto.

/// Rectángulo con las cuatro esquinas cortadas en recto, el rasgo de
/// Neotokyo+. Es un [OutlinedBorder] y no un painter para que valga igual de
/// forma de un `Container`, de un botón o de un recorte.
class BordeChaflan extends OutlinedBorder {
  final double chaflan;

  const BordeChaflan({required this.chaflan, super.side = BorderSide.none});

  @override
  OutlinedBorder copyWith({BorderSide? side}) =>
      BordeChaflan(chaflan: chaflan, side: side ?? this.side);

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  ShapeBorder scale(double t) =>
      BordeChaflan(chaflan: chaflan * t, side: side.scale(t));

  Path _camino(Rect rect) {
    // Con cajas muy bajas el corte se comería el lado entero.
    final c = chaflan.clamp(0.0, rect.shortestSide / 2);
    return Path()
      ..moveTo(rect.left + c, rect.top)
      ..lineTo(rect.right - c, rect.top)
      ..lineTo(rect.right, rect.top + c)
      ..lineTo(rect.right, rect.bottom - c)
      ..lineTo(rect.right - c, rect.bottom)
      ..lineTo(rect.left + c, rect.bottom)
      ..lineTo(rect.left, rect.bottom - c)
      ..lineTo(rect.left, rect.top + c)
      ..close();
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => _camino(rect);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      _camino(rect.deflate(side.width));

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none) return;
    canvas.drawPath(_camino(rect.deflate(side.width / 2)), side.toPaint());
  }

  @override
  bool operator ==(Object other) =>
      other is BordeChaflan && other.chaflan == chaflan && other.side == side;

  @override
  int get hashCode => Object.hash(chaflan, side);
}

/// La figura de una superficie de esta identidad al radio que se le pida.
/// Sale de aquí para que la tarjeta, el botón y el recorte de una tira de
/// color no puedan acabar cortando la esquina de formas distintas.
ShapeBorder formaIdentidad(
  IdentidadPaleta id, {
  required double radio,
  BorderSide lado = BorderSide.none,
}) =>
    switch (id.forma) {
      FormaIdentidad.chamfer => BordeChaflan(chaflan: id.chaflan, side: lado),
      _ => RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radio),
          side: lado,
        ),
    };

/// Una superficie —tarjeta, panel, fila de lista— en el lenguaje de la
/// identidad equipada.
///
/// Alba no tiene superficie propia: como panel no pinta nada en absoluto, y
/// como fila de lista se marca con una línea fina debajo. Es la misma decisión
/// que ya tomaron la burbuja de contexto y la tarjeta de hábito.
class SuperficieIdentidad extends StatelessWidget {
  final Widget child;

  final VoidCallback? onTap;

  final EdgeInsets margen;

  final EdgeInsets relleno;

  /// El elemento protagonista de la pantalla usa [IdentidadPaleta.radioHero];
  /// el contenido de una lista, [IdentidadPaleta.radioSecundario].
  final bool protagonista;

  /// Qué hace Alba: una fila de lista lleva su línea fina debajo, un panel de
  /// formulario no lleva nada. En las otras tres identidades no cambia nada.
  final bool esFila;

  /// Filo propio, cuando esta superficie tiene que destacar sobre las de su
  /// alrededor. Sin él manda el de la identidad.
  final BorderSide? filo;

  const SuperficieIdentidad({
    super.key,
    required this.child,
    this.onTap,
    this.margen = EdgeInsets.zero,
    this.relleno = const EdgeInsets.all(16),
    this.protagonista = false,
    this.esFila = false,
    this.filo,
  });

  @override
  Widget build(BuildContext context) {
    final id = identidad(context);
    final t = tokens(context);

    if (id.forma == FormaIdentidad.hairline) {
      // Como panel, Alba no pinta nada — y tampoco reserva relleno: sangraría
      // el contenido sin que se vea de qué. Como fila sí, que es lo que separa
      // una fila de la siguiente.
      final contenido = esFila ? Padding(padding: relleno, child: child) : child;
      return Container(
        margin: margen,
        decoration: esFila
            ? BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                      color: filo?.color ?? t.textMuted.withValues(alpha: 0.20)),
                ),
              )
            : null,
        child: onTap == null
            ? contenido
            : Material(
                type: MaterialType.transparency,
                child: InkWell(onTap: onTap, child: contenido),
              ),
      );
    }

    final forma = formaIdentidad(
      id,
      radio: protagonista ? id.radioHero : id.radioSecundario,
      lado: filo ??
          switch (id.forma) {
            // El filo claro es lo que hace que el cristal tenga canto.
            FormaIdentidad.glass =>
              BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            FormaIdentidad.chamfer =>
              BorderSide(color: t.primary.withValues(alpha: 0.55), width: 1.2),
            _ => BorderSide.none,
          },
    );

    return Container(
      margin: margen,
      decoration: ShapeDecoration(
        shape: forma,
        // Profundidad es un degradado entre sus dos superficies; las otras dos
        // son superficie plana. Un degradado y un color sólido no caben en el
        // mismo campo, de ahí el reparto.
        gradient: id.forma == FormaIdentidad.glass
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [t.surface, t.surface2],
              )
            : null,
        color: id.forma == FormaIdentidad.glass ? null : t.surface,
        shadows: switch (id.forma) {
          FormaIdentidad.glass => [
              BoxShadow(
                color: Colors.black.withValues(alpha: protagonista ? 0.35 : 0.28),
                blurRadius: protagonista ? 24 : 14,
                offset: Offset(0, protagonista ? 10 : 5),
              ),
            ],
          // Dulce: la sombra es del color de la identidad, no negra. Es lo que
          // convierte una sombra en un resplandor.
          FormaIdentidad.pill => [
              BoxShadow(
                color: t.primary.withValues(alpha: protagonista ? 0.22 : 0.18),
                blurRadius: protagonista ? 26 : 16,
                offset: Offset(0, protagonista ? 12 : 6),
              ),
            ],
          // Neotokyo+ no proyecta sombra: su relieve es el corte y el borde.
          _ => const [],
        },
      ),
      child: onTap == null
          ? Padding(padding: relleno, child: child)
          : Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: onTap,
                customBorder: forma,
                child: Padding(padding: relleno, child: child),
              ),
            ),
    );
  }
}
