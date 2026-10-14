import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'identidad_paleta.dart';
import 'identidades_paleta.dart';

/// Con qué colores dice una identidad que algo ha ido mal.
///
/// `TokensContextuales` no tiene tono de error, y un `Colors.red` fijo se sale
/// de las paletas: en Dulce se pelea con el rosa y en Neotokyo+ parece un
/// elemento más del neón. Así que cada identidad pone el
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

  /// La tinta que va ENCIMA de [borde] cuando éste hace de fondo sólido —
  /// el botón de un diálogo destructivo, por ejemplo. Tiene que llegar a
  /// 4.5:1 sobre [borde]. No se puede fijar a blanco ni a negro para todas:
  /// las identidades de borde claro piden tinta oscura.
  final Color tinta;

  const TonoError({
    required this.texto,
    required this.borde,
    required this.fondo,
    required this.tinta,
  });
}

/// El tono de error de la identidad equipada. Se lee el valor, como
/// [tokens] o [identidad] — no se suscribe nadie aquí.
TonoError tonoError(BuildContext context) {
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
      tinta: const Color(0xFF1A1A1A), // 6.27:1 sobre #FF6B6B
    ),

    // Neotokyo+ — el rojo que antes era su `streak` (#FF4D2E), ahora literal:
    // su tercer color pasó a ser el cian. Está a un tono del magenta
    // primario y sobre el violeta casi negro se lee como una señal rota, que
    // es el registro de la identidad. 5.2:1 sobre el banner.
    FormaIdentidad.chamfer => TonoError(
      texto: const Color(0xFFFF4D2E),
      borde: const Color(0xFFFF4D2E),
      fondo: const Color(0xFFFF4D2E).withValues(alpha: 0.12),
      tinta: const Color(0xFF1A1A1A), // 5.27:1 sobre #FF4D2E
    ),

    // Dulce — rosa-rojo propio para el texto (5.4:1 sobre el blanco de la
    // tarjeta). Aquí no vale derivar: el coral (#E86A58), que fue su `streak`
    // hasta que el tercer color pasó a lavanda, como relleno funciona de
    // alerta pero como texto no llega. El rosa-rojo es más oscuro y menos
    // saturado que el primario, para que no parezca un elemento activo; el
    // relleno sí lo pone el coral.
    FormaIdentidad.pill => TonoError(
      texto: const Color(0xFFC2325A),
      borde: const Color(0xFFE86A58),
      fondo: const Color(0xFFE86A58).withValues(alpha: 0.14),
      tinta: const Color(0xFF1A1A1A), // 5.50:1 sobre #E86A58
    ),
  };
}
