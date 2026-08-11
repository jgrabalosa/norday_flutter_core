import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'identidad_paleta.dart';

/// Registro de identidades por código de producto — nada de hexadecimales en
/// la BD. El backend manda `codigo` y aquí se resuelve todo lo visual.
///
/// Cuatro, y muy distintas entre sí a propósito: no son cuatro repintados del
/// mismo diseño, cada una cambia letra, radio, forma y ritmo. Sustituyen por
/// completo a las siete paletas antiguas, que sólo se diferenciaban en color.
const Map<String, IdentidadPaleta> catalogoIdentidades = {
  'TEMA_PROFUNDIDAD': IdentidadPaleta(
    codigo: 'TEMA_PROFUNDIDAD',
    nombre: 'Profundidad',
    // Definidos en app_theme.dart porque son también el arranque de
    // temaEquipadoNotifier — ver la nota allí.
    tokens: tokensProfundidad,
    fontDisplay: 'Manrope',
    fontBody: 'Manrope', // única familia en toda la identidad
    radioHero: 24,
    radioSecundario: 18,
    forma: FormaIdentidad.glass,
    duracionAnimacionFirma: Duration(milliseconds: 3200),
  ),

  'TEMA_NEOTOKYO_PLUS': IdentidadPaleta(
    codigo: 'TEMA_NEOTOKYO_PLUS',
    nombre: 'Neotokyo+',
    tokens: TokensContextuales(
      primary: Color(0xFFFF2E88),
      success: Color(0xFFFF2E88),
      streak: Color(0xFFFF4D2E),
      points: Color(0xFFFFE347),
      bg: Color(0xFF090614),
      surface: Color(0xFF110B21),
      surface2: Color(0xFF160F28),
      text: Color(0xFFF5EEFF),
      textMuted: Color(0xFFA08FC2),
    ),
    fontDisplay: 'Chakra Petch', // SÓLO títulos/cifras/chips — mayúsculas+tracking
    fontBody: 'IBM Plex Sans', // cuerpo de artículo/lista SIEMPRE aquí, nunca en Chakra Petch mayúscula
    // Deliberadamente pequeño: rompe el lenguaje redondeado del resto.
    radioHero: 8,
    radioSecundario: 8,
    chaflan: 10,
    forma: FormaIdentidad.chamfer,
    duracionAnimacionFirma: Duration(milliseconds: 2400),
  ),

  'TEMA_ALBA': IdentidadPaleta(
    codigo: 'TEMA_ALBA',
    nombre: 'Alba',
    tokens: TokensContextuales(
      primary: Color(0xFF7A9471),
      success: Color(0xFF7A9471),
      streak: Color(0xFF8C4F35),
      points: Color(0xFF8C4F35),
      bg: Color(0xFFF4F1EB),
      surface: Color(0xFFFCFAF6),
      surface2: Color(0xFFEAE5DB),
      text: Color(0xFF2C2824),
      textMuted: Color(0xFF6B6259),
      // El terracota ya contrasta como texto sobre los tres fondos de Alba
      // —6.13 sobre surface, 5.67 sobre bg, 5.09 sobre surface2 (WebAIM)—,
      // así que la variante de texto es su propio valor: se declara para
      // dejarlo dicho, no porque cambie nada.
      streakText: Color(0xFF8C4F35),
    ),
    fontDisplay: 'Fraunces', // itálica — título/nombre/cifras destacadas
    fontBody: 'Work Sans', // cuerpo SIEMPRE aquí, nunca itálica de corrido
    radioHero: 14,
    // Alba evita encajonar el contenido secundario (listas con hairline en vez
    // de cards), así que este radio se usa poco: cuando se use, este valor.
    radioSecundario: 14,
    forma: FormaIdentidad.hairline,
    duracionAnimacionFirma: Duration(milliseconds: 4000),
  ),

  'TEMA_DULCE': IdentidadPaleta(
    codigo: 'TEMA_DULCE',
    nombre: 'Dulce',
    tokens: TokensContextuales(
      primary: Color(0xFFFF6FA5),
      success: Color(0xFFFF6FA5),
      streak: Color(0xFFE86A58),
      points: Color(0xFFE86A58),
      bg: Color(0xFFFAF0F4),
      surface: Color(0xFFFFFFFF),
      surface2: Color(0xFFFFE1EC),
      text: Color(0xFF4A2E3D),
      // El magenta de diseño (#B85E9F) no llegaba a AA como texto normal —4.08
      // sobre surface, 3.66 sobre bg (WebAIM), donde hace falta 4.5—, así que
      // se oscureció conservando el tono: éste pasa los tres fondos
      // (5.52 / 4.95 / 4.53).
      textMuted: Color(0xFFA04A83),
      // Sobre fondo claro ni el rosa ni el coral de relleno valen como texto:
      // hacen falta las variantes oscurecidas. Verificadas con WebAIM sobre
      // los tres fondos de la identidad (surface / bg / surface2).
      streakText: Color(0xFF9C4E1A), // 5.96 / 5.35 / 4.89
      successText: Color(0xFFB23368), // 5.88 / 5.28 / 4.83
    ),
    fontDisplay: 'Quicksand',
    fontBody: 'Nunito', // cuerpo SIEMPRE aquí
    // ÚNICO uso: el detalle manuscrito "¡qué crack!" junto al badge de racha.
    fontAcento: 'Caveat',
    radioHero: 26, // casi píldora
    radioSecundario: 20,
    forma: FormaIdentidad.pill,
    duracionAnimacionFirma: Duration(milliseconds: 2600),
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
  // Compatibilidad con los consumidores solo-color existentes: las pantallas
  // aún sin migrar escuchan este y no se tocan.
  temaEquipadoNotifier.value = resuelta.tokens;
}
