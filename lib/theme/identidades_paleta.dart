import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'identidad_paleta.dart';

/// Registro de identidades por código de producto — nada de hexadecimales en
/// la BD. El backend manda `codigo` y aquí se resuelve todo lo visual.
///
/// Tres, y muy distintas entre sí a propósito: no son tres repintados del
/// mismo diseño, cada una cambia letra, radio, forma y ritmo. Sustituyen por
/// completo a las siete paletas antiguas, que sólo se diferenciaban en color.
const Map<String, IdentidadPaleta> catalogoIdentidades = {
  'TEMA_PROFUNDIDAD': IdentidadPaleta(
    codigo: 'TEMA_PROFUNDIDAD',
    nombre: 'Profundidad',
    // Definidos en app_theme.dart porque son también el arranque de
    // temaEquipadoNotifier — ver la nota allí.
    tokens: tokensProfundidad,
    fontDisplay: 'Space Grotesk',
    fontBody: 'Manrope', // Space Grotesk sólo titula; el cuerpo nunca
    radioHero: 24,
    radioSecundario: 18,
    forma: FormaIdentidad.glass,
    fondo: FondoIdentidadTipo.cielo,
    duracionAnimacionFirma: Duration(milliseconds: 3200),
    duracionTransicion: Duration(milliseconds: 280),
    curvaTransicion: Curves.easeOutCubic,
  ),

  'TEMA_NEOTOKYO_PLUS': IdentidadPaleta(
    codigo: 'TEMA_NEOTOKYO_PLUS',
    nombre: 'Neotokyo+',
    tokens: TokensContextuales(
      primary: Color(0xFFFF2E88),
      success: Color(0xFFFF2E88),
      // El tercer color: cian. Cierra la tríada del neón (rosa, amarillo,
      // cian) y se separa del rosa también por luminosidad (2.28). 13.03 /
      // 12.48 / 12.05 sobre bg / surface / surface2: vale también como
      // texto corto, así que no declara `streakText`.
      streak: Color(0xFF00E5FF),
      points: Color(0xFFFFE347),
      bg: Color(0xFF090614),
      surface: Color(0xFF110B21),
      surface2: Color(0xFF160F28),
      text: Color(0xFFF5EEFF),
      textMuted: Color(0xFFA08FC2),
      // `textMuted` al 0.41 sobre `bg`, resuelto a opaco. 2.01 de contraste.
      inactivo: Color(0xFF473E5B),
      // `textMuted` al 0.62 sobre `surface`, que es el fondo de sus filas,
      // resuelto a opaco. 3.36 / 3.22 / 3.10 sobre bg / surface / surface2.
      aroVacio: Color(0xFF6A5D85),
      // 5.82 sobre el rosa. El mismo valor que la landing.
      tinta: Color(0xFF12000A),
    ),
    fontDisplay:
        'Chakra Petch', // SÓLO títulos/cifras/chips — mayúsculas+tracking
    fontBody:
        'IBM Plex Sans', // cuerpo de artículo/lista SIEMPRE aquí, nunca en Chakra Petch mayúscula
    // Deliberadamente pequeño: rompe el lenguaje redondeado del resto.
    radioHero: 8,
    radioSecundario: 8,
    chaflan: 10,
    forma: FormaIdentidad.chamfer,
    fondo: FondoIdentidadTipo.ciudad,
    duracionAnimacionFirma: Duration(milliseconds: 2400),
    duracionTransicion: Duration(milliseconds: 200),
    curvaTransicion: Curves.easeOutExpo,
  ),

  'TEMA_DULCE': IdentidadPaleta(
    codigo: 'TEMA_DULCE',
    nombre: 'Dulce',
    tokens: TokensContextuales(
      primary: Color(0xFFFF6FA5),
      // El éxito sigue teniendo color propio, pero vuelve a la familia rosa
      // de la identidad: la salvia rompía con Detalle de hábito, que pinta
      // los días cumplidos con `primary`. El rosa de `primary` (#FF6FA5) no
      // vale como relleno —2.60 / 2.33 / 2.14 sobre surface / bg / surface2,
      // por debajo de los 3.0 de WCAG 1.4.11—, así que éste es el mismo tono
      // asentado: HSL 338, igual que `primary`. Da 3.92 / 3.52 / 3.22.
      success: Color(0xFFE53F80),
      // El tercer color: lavanda. El coral era casi el mismo color que los
      // dos rosas (1.22-1.24 de luminosidad, ΔE 38). La lavanda se separa
      // del rosa también con daltonismo y como relleno da 4.70 / 4.22 / 3.86
      // sobre surface / bg / surface2. Provisional hasta verla en el móvil.
      streak: Color(0xFF7C5CE0),
      points: Color(0xFFE86A58),
      bg: Color(0xFFFAF0F4),
      surface: Color(0xFFFFFFFF),
      surface2: Color(0xFFFFE1EC),
      text: Color(0xFF4A2E3D),
      // El magenta de diseño (#B85E9F) no llegaba a AA como texto normal —4.08
      // sobre surface, 3.66 sobre bg (WebAIM), donde hace falta 4.5—, así que
      // se oscureció conservando el tono. La primera corrección (#A04A83,
      // 5.52 / 4.95 / 4.53) pasaba la métrica pero seguía leyéndose lavada en
      // las etiquetas de formulario, así que se bajó otro escalón de
      // luminosidad manteniendo tono (HSL 320) y saturación: 7.81 / 7.01 /
      // 6.41 sobre surface / bg / surface2. Sigue lejos de `text`
      // (12.00 / 10.77 / 9.85), que es lo que mantiene la jerarquía entre
      // texto principal y secundario.
      textMuted: Color(0xFF7E3A67),
      // `textMuted` al 0.42 sobre `bg`, resuelto a opaco. 2.00 de contraste.
      // Recalculado al oscurecer `textMuted`: se conserva el contraste, no la
      // alfa, para que el estado apagado pese lo mismo que en las otras tres.
      inactivo: Color(0xFFC6A4B9),
      // `textMuted` al 0.70 sobre `surface`, que es el fondo de sus filas,
      // resuelto a opaco. 3.38 / 3.76 / 3.09 sobre bg / surface / surface2.
      aroVacio: Color(0xFFA57595),
      // 4.61 sobre el rosa. El mismo valor que la landing.
      tinta: Color(0xFF4A2E3D),
      // El rosa como trazo (icono, borde, foco): el de relleno no llega a
      // 3.0. Es el mismo tono que `success`: 3.92 / 3.52 / 3.22 sobre
      // surface / bg / surface2.
      primaryTrazo: Color(0xFFE53F80),
      // Sobre fondo claro ningún relleno de esta identidad vale como texto:
      // ni el coral de `streak` ni el rosa de `success` llegan a 4.5, así
      // que hacen falta las variantes oscurecidas. Verificadas con WebAIM
      // sobre los tres fondos de la identidad (surface / bg / surface2).
      streakText: Color(0xFF6145CF), // 6.44 / 5.78 / 5.29
      pointsText: Color(0xFFBB2E1A), // 5.97 / 5.35 / 4.90
      successText: Color(0xFFB01E5A), // 6.61 / 5.92 / 5.42
      // El neutro cálido de Dulce: el papel del post-it. `surface2` es rosa
      // y no separaba la nota del fondo. Sobre este amarillo, `text` da
      // 10.95, `successText` 5.67 y `textMuted` 7.13.
      fondoNota: Color(0xFFFFF4D6),
    ),
    fontDisplay: 'Quicksand',
    fontBody: 'Nunito', // cuerpo SIEMPRE aquí
    // ÚNICO uso: la frase manuscrita del post-it de Hoy (BurbujaContexto).
    fontAcento: 'Caveat',
    radioHero: 26, // casi píldora
    radioSecundario: 20,
    forma: FormaIdentidad.pill,
    fondo: FondoIdentidadTipo.acumulacion,
    duracionAnimacionFirma: Duration(milliseconds: 2600),
    duracionTransicion: Duration(milliseconds: 320),
    curvaTransicion: Curves.easeOutBack,
  ),
};

/// La identidad actualmente equipada — completa, no sólo sus colores.
///
/// Quien únicamente pinta color puede seguir escuchando `temaEquipadoNotifier`
/// sin enterarse de que esto existe: [aplicarIdentidadEquipada] mueve los dos
/// a la vez. Este es para quien necesita tipografía, forma o radio.
final ValueNotifier<IdentidadPaleta> identidadEquipadaNotifier =
    ValueNotifier<IdentidadPaleta>(catalogoIdentidades['TEMA_PROFUNDIDAD']!);

/// Aplica una identidad por su código de producto.
///
/// Sólo pinta: quién está equipado lo decide el backend, y quien lo cambia es
/// `equiparTema` en equipamiento.dart. Antes esto escribía además en
/// `SharedPreferences`, que era una segunda fuente de verdad y se
/// desincronizaba en cuanto el usuario equipaba desde otro dispositivo.
///
/// Sin código —o con uno que este cliente aún no conozca— vale "Profundidad",
/// la de serie. Se fija explícitamente en vez de dejar lo que hubiera puesto,
/// porque los dos notifiers tienen que acabar describiendo la misma identidad.
/// La identidad equipada, en la misma forma en que [tokens] da los colores:
/// se lee el valor, no se suscribe nadie aquí. Quien redibuja al equipar es el
/// `ValueListenableBuilder` sobre `temaEquipadoNotifier` que cada app monta en
/// su `MaterialApp`, y [aplicarIdentidadEquipada] mueve los dos notifiers a la
/// vez, así que este valor nunca se queda atrás del color.
IdentidadPaleta identidad(BuildContext context) =>
    identidadEquipadaNotifier.value;

void aplicarIdentidadEquipada(String? codigo) {
  final identidad = (codigo != null) ? catalogoIdentidades[codigo] : null;
  final resuelta = identidad ?? catalogoIdentidades['TEMA_PROFUNDIDAD']!;
  identidadEquipadaNotifier.value = resuelta;
  // La letra, antes que el color: `AppTheme.deTema` la lee de aquí, y quien lo
  // llama es justo el listener del notifier de abajo. Al revés, el primer
  // repintado saldría con la tipografía de la identidad anterior.
  fuentesEquipadasNotifier.value = FuentesIdentidad(
    display: resuelta.fontDisplay,
    body: resuelta.fontBody,
  );
  // Compatibilidad con los consumidores solo-color existentes: las pantallas
  // aún sin migrar escuchan este y no se tocan.
  temaEquipadoNotifier.value = resuelta.tokens;
}
