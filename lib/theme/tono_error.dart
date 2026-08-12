import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'identidad_paleta.dart';
import 'identidades_paleta.dart';

/// Con qué colores dice una identidad que algo ha ido mal.
///
/// `TokensContextuales` no tiene tono de error, y un `Colors.red` fijo se sale
/// de las cuatro paletas: en Alba grita, en Dulce se pelea con el rosa y en
/// Neotokyo+ parece un elemento más del neón. Así que cada identidad pone el
/// suyo, y donde ya tenía un color que funciona como alerta se reutiliza en vez
/// de inventar uno.
///
/// El reparto se resuelve por [FormaIdentidad], como el halo, el terrario o la
/// burbuja: una identidad nueva declara su forma y hereda tono; una forma nueva
/// rompe la compilación aquí, que es donde hay que decidirlo.
class TonoError {
  /// El mensaje. Es el único que tiene que llegar a 4.5:1 sobre [fondo]
  /// compuesto encima de la superficie de su identidad.
  final Color texto;

  /// El filo: borde del banner, línea, icono. Como relleno le basta 3:1.
  final Color borde;

  /// Relleno del banner. Transparente en las identidades que no encajonan.
  final Color fondo;

  const TonoError({
    required this.texto,
    required this.borde,
    required this.fondo,
  });
}

/// El tono de error de la identidad equipada. Se lee el valor, como
/// [tokens] o [identidad] — no se suscribe nadie aquí.
TonoError tonoError(BuildContext context) {
  final t = tokens(context);
  return switch (identidad(context).forma) {
    // Profundidad — coral propio. Su `streak` es ámbar (#FFB020) y sobre el
    // azul casi negro se lee como un dato de racha, no como un fallo; y
    // `primary` es el verde de "todo bien". El coral es lo único nuevo de las
    // cuatro identidades, y hace falta. Sobre el banner (coral al 12% encima de
    // `surface`) el texto llega a 5.6:1 y el filo a 4.6:1.
    FormaIdentidad.glass => TonoError(
        texto: const Color(0xFFFF8A8A),
        borde: const Color(0xFFFF6B6B),
        fondo: const Color(0xFFFF6B6B).withValues(alpha: 0.12),
      ),

    // Neotokyo+ — su propio `streak` (#FF4D2E). Es el único rojo de la paleta,
    // ya está a un tono de distancia del magenta primario, y sobre el violeta
    // casi negro se lee como una señal rota, que es exactamente el registro de
    // la identidad. 5.2:1 sobre el banner.
    FormaIdentidad.chamfer => TonoError(
        texto: t.streak,
        borde: t.streak,
        fondo: t.streak.withValues(alpha: 0.12),
      ),

    // Alba — el terracota de `streakText` (#8C4F35), que ya está verificado
    // como texto sobre los tres fondos claros de la identidad (5.1–6.1:1). Y
    // sin relleno: Alba no encajona nada en ninguna otra pantalla, así que su
    // error es una línea fina y el texto. Un banner de color sería lo más
    // ruidoso de toda la identidad.
    FormaIdentidad.hairline => TonoError(
        texto: t.streakText,
        borde: t.streakText,
        fondo: Colors.transparent,
      ),

    // Dulce — rosa-rojo propio para el texto (5.4:1 sobre el blanco de la
    // tarjeta). Aquí no vale derivar: `streak` es el coral (#E86A58), que como
    // relleno funciona de alerta pero como texto no llega, y su `streakText`
    // (#9C4E1A) es un marrón anaranjado que se lee como aviso, no como error.
    // El rosa-rojo es más oscuro y menos saturado que el primario, para que no
    // parezca un elemento activo; el relleno sí lo pone el coral.
    FormaIdentidad.pill => TonoError(
        texto: const Color(0xFFC2325A),
        borde: t.streak,
        fondo: t.streak.withValues(alpha: 0.14),
      ),
  };
}
