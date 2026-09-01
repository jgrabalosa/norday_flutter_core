import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ── Design Tokens — Identidad oficial Norday ──
class AppColors {
  // Marca
  static const azulNoche = Color(0xFF0A1628);
  static const azulAcero = Color(0xFF23395D);
  static const verdeEsmeralda = Color(0xFF27C76F);
  static const verdeOscuro = Color(0xFF1EA85B);
  static const verdeClaro = Color(0xFF6EE7A8);
  static const grisMuyClaro = Color(0xFFEEF2F6);
  static const grisClaro = Color(0xFFD9E2EC);
  static const grisMedio = Color(0xFF6B7280);
  static const grisOscuro = Color(0xFF374151);

  // Semánticos (sobre la marca)
  static const primary = verdeEsmeralda;
  static const primaryDark = verdeOscuro;
  // Verde de "hecho" para iconos y rellenos, donde WCAG pide 3:1 y no 4.5:1.
  // Como TEXTO sobre los fondos claros no llega (2.59 sobre bgLight, 2.92
  // sobre surfaceLight): para eso está successTextLight.
  static const success = verdeOscuro;
  static const streak = Color(0xFFF97316);
  static const points = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);

  // Básico Claro (crudo frío: fondo un punto más oscuro, tarjetas en blanco roto)
  static const bgLight = Color(0xFFE6ECF2);
  static const surfaceLight = Color(0xFFF7F9FB);
  static const surface2Light = Color(0xFFCFDAE6);
  static const textLight = azulNoche;

  /// Gris secundario del tema claro. Más oscuro que `grisMedio` (#6B7280),
  /// que se quedaba en 4.06 sobre bgLight y 3.41 sobre surface2Light — por
  /// debajo del 4.5:1 de WCAG AA. Este pasa: 5.47 / 6.17 / 4.60.
  static const textMutedLight = Color(0xFF585E6A);

  /// `success` oscurecido para usarlo como TEXTO en el tema claro: 4.65 sobre
  /// bgLight y 5.24 sobre surfaceLight, frente al 2.59/2.92 del verde normal.
  /// Sobre surface2Light se queda en 3.90, así que ahí sólo vale a tamaño
  /// grande — de momento no se usa sobre ese fondo.
  static const successTextLight = Color(0xFF167841);

  /// Lo mismo para `streak`: el naranja normal se queda en 2.66 como texto
  /// sobre surfaceLight. Éste llega a 4.76 ahí, que es donde se usa (las
  /// cifras van dentro de Card). Sobre bgLight se queda en 4.22, así que
  /// directamente sobre el fondo sólo valdría a tamaño grande.
  static const streakTextLight = Color(0xFFB4530A);

  // Básico Oscuro DE MARCA (fondos Azul Noche / Azul Acero, no gris genérico)
  static const primaryDarkMode = verdeEsmeralda;
  static const successDarkMode = verdeClaro;
  static const streakDarkMode = Color(0xFFFF8226);
  static const pointsDarkMode = Color(0xFFFFB020);
  static const bgDark = azulNoche;
  static const surfaceDark = azulAcero;
  static const surface2Dark = Color(0xFF2C4570); // Azul Acero elevado
  static const textDark = grisMuyClaro;
  static const textMutedDark = Color(0xFFA3B3C9); // gris azulado sobre noche
}

/// ── Escala de espaciado oficial (4/8/16/24) ──
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
}

/// ── Radios oficiales (generosos, 16-24) ──
class AppRadius {
  static const double sm = 12; // inputs, botones
  static const double md = 16; // chips, sheets
  static const double lg = 20; // cards
  static const double xl = 24; // overlays, diálogos
}

/// Colores que cambian según el tema equipado — úsalos con tokens(context)
class TokensContextuales {
  final Color primary, success, streak, points, bg, surface, surface2, text, textMuted;

  /// El verde cuando se pinta como TEXTO. Como relleno o icono basta con
  /// `success` (WCAG pide 3:1 ahí, no 4.5:1); es al escribir con él cuando
  /// hace falta la variante oscura. Sólo lo declaran las paletas donde el
  /// verde de relleno no llega a 4.5:1 sobre su propio fondo — en las
  /// oscuras `success` ya contrasta de sobra y es su propio valor.
  final Color successText;

  /// Igual que `successText` pero para `streak`. Mismo criterio: como relleno
  /// o icono vale `streak`; al escribir con él hace falta la variante que
  /// contrasta sobre el fondo de su propia paleta.
  final Color streakText;

  /// La capa por encima de `surface`. La usan las identidades que resuelven
  /// la elevación por luminosidad en vez de por sombra. Quien no la declare
  /// se queda en `surface` y no cambia nada.
  final Color surfaceAlta;

  /// Lo que se dibuja donde no hay nada: la pista de una barra o un anillo de
  /// progreso, la celda de un heatmap sin datos, el día de descanso, el día no
  /// seleccionado, la identidad que aún no se posee, el hueco de un avatar sin
  /// asset y la caja de un esqueleto de carga.
  ///
  /// Las dos primeras familias son «la mitad ausente de un par
  /// presente/ausente» y la última es «contenido que todavía no ha llegado».
  /// Comparten token a propósito: visualmente hacen lo mismo —marcar un hueco
  /// sin llamar la atención— y deben pesar igual, porque a menudo se ven en la
  /// misma pantalla. Lo que NO entra aquí es una superficie: si algo es una
  /// capa del sistema de estratos, su color es `surface2`, no éste.
  ///
  /// Existe porque `surface2` hacía dos trabajos a la vez —la capa hundida del
  /// sistema de estratos y éste—, y eran el mismo color sólo mientras todo iba
  /// encima de una superficie opaca. En cuanto el contenido se apoya en el
  /// fondo de la identidad dejan de serlo: `surface2` sobre el fondo de
  /// Profundidad da 1.13 y desaparece.
  ///
  /// Cada paleta declara el suyo en vez de calcularse con una fórmula común,
  /// porque la misma fórmula NO pesa igual en las cuatro: para llegar al mismo
  /// contraste sobre su propio `bg`, Profundidad necesita `textMuted` al 0.29
  /// y Alba al 0.48. Los cuatro valores están medidos a ~2.0 de contraste
  /// sobre el `bg` de su paleta, que es lo que hace que el estado apagado pese
  /// igual en todas.
  ///
  /// No se rige por WCAG 1.4.11: esto no es el contorno de un control, es la
  /// mitad vacía de una figura, y la información la dan el `Semantics` y la
  /// mitad llena. Un control que además use este color se gana su presencia
  /// con lo suyo —grosor, borde—, no subiendo el token.
  ///
  /// Quien no lo declare se queda en `surface2` y no cambia nada.
  final Color inactivo;

  const TokensContextuales({
    required this.primary, required this.success, required this.streak,
    required this.points, required this.bg, required this.surface,
    required this.surface2, required this.text, required this.textMuted,
    Color? successText,
    Color? streakText,
    Color? surfaceAlta,
    Color? inactivo,
  })  : successText = successText ?? success,
        streakText = streakText ?? streak,
        surfaceAlta = surfaceAlta ?? surface,
        inactivo = inactivo ?? surface2;
}

/// Los colores de la identidad "Profundidad", la de serie.
///
/// Viven aquí y no junto al resto del catálogo (`identidades_paleta.dart`)
/// porque son además el valor de arranque de [temaEquipadoNotifier], y este
/// fichero es la capa de abajo: no puede importar el catálogo sin montar un
/// ciclo. El catálogo los referencia, así que hay una sola definición.
const TokensContextuales tokensProfundidad = TokensContextuales(
  primary: Color(0xFF27C76F),
  success: Color(0xFF27C76F),
  streak: Color(0xFFFFB020),
  points: Color(0xFFFFB020),
  bg: Color(0xFF070D19),
  // Escala de tres capas, de más hundida a más elevada: surface2 (hundida,
  // 101B2F) → surface (base, 1E2E4C) → surfaceAlta (elevada, 2B4068). La
  // jerarquía la lleva la luminosidad, no un degradado entre dos extremos.
  // Contrastes verificados con WebAIM sobre estos fondos:
  // text 12.04 sobre base y 9.17 sobre elevada; textMuted 8.62 y 6.56;
  // primary 6.12 y 4.66; streak 7.41 y 5.64. Todos pasan AA.
  surface: Color(0xFF1E2E4C),
  surface2: Color(0xFF101B2F),
  surfaceAlta: Color(0xFF2B4068),
  text: Color(0xFFEEF2F6),
  textMuted: Color(0xFFC7CFDA), // 12.3 sobre bg (WebAIM), de sobra
  // `textMuted` al 0.29 sobre `bg`, resuelto a opaco. 2.02 de contraste.
  inactivo: Color(0xFF3F4551),
);

/// Las dos familias tipográficas de la identidad equipada.
///
/// Es el mínimo que necesita [AppTheme.deTema] para construir el `TextTheme`:
/// la identidad completa (radios, forma, ritmo) no pinta nada aquí.
class FuentesIdentidad {
  /// Titulares, cifras y etiquetas cortas.
  final String display;

  /// Texto de lectura.
  final String body;

  const FuentesIdentidad({required this.display, required this.body});
}

/// La tipografía de "Profundidad", la de serie: Space Grotesk para los
/// titulares y Manrope para el cuerpo.
///
/// Vive aquí por lo mismo que [tokensProfundidad] —ver la nota de arriba—:
/// este fichero es la capa de abajo y no puede importar el catálogo.
const FuentesIdentidad fuentesProfundidad =
    FuentesIdentidad(display: 'Space Grotesk', body: 'Manrope');

/// La tipografía de la identidad equipada.
///
/// Existe porque [AppTheme.deTema] recibe colores, no identidades, y necesita
/// saber con qué letra escribir sin importar `identidades_paleta.dart`. Lo
/// escribe `aplicarIdentidadEquipada`, igual que [temaEquipadoNotifier], y
/// siempre antes que aquél: los dos describen la misma identidad y el color es
/// el que dispara el repintado.
///
/// **Nadie tiene que escuchar aquí.** Quien redibuja al equipar sigue siendo el
/// `ValueListenableBuilder` sobre [temaEquipadoNotifier] que cada app monta en
/// su `MaterialApp`; para cuando ése salta, este valor ya está puesto.
final ValueNotifier<FuentesIdentidad> fuentesEquipadasNotifier =
    ValueNotifier<FuentesIdentidad>(fuentesProfundidad);

/// Los colores de la identidad equipada. Fallback de arranque: "Profundidad",
/// hasta que `Equipamiento.cargarDeUsuario` resuelva lo que el usuario lleva
/// puesto de verdad.
///
/// Sigue existiendo —y sigue siendo la forma correcta de consumir color—
/// aunque ahora una identidad sea bastante más que sus colores: quien sólo
/// necesita pintar escucha aquí. Quien necesita tipografía, forma o radio
/// escucha `identidadEquipadaNotifier`, que mueve los dos a la vez.
final ValueNotifier<TokensContextuales> temaEquipadoNotifier =
    ValueNotifier<TokensContextuales>(tokensProfundidad);

TokensContextuales tokens(BuildContext context) => temaEquipadoNotifier.value;

/// ── ThemeData ──
class AppTheme {
  /// ThemeData para el tema actualmente equipado — un único look, construido
  /// a partir de sus tokens. Todas las paletas (básicas o premium) pasan por aquí.
  static ThemeData deTema(TokensContextuales t) {
    final scheme = ColorScheme.fromSeed(
      seedColor: t.primary,
      brightness: Brightness.dark,
      surface: t.surface,
    );

    // La letra sale de la identidad equipada, no del parámetro: `deTema`
    // recibe sólo colores y las apps la llaman así desde antes de que una
    // identidad fuera algo más que su paleta.
    final tipografia = _tipografia(fuentesEquipadasNotifier.value);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: t.bg,
      textTheme: tipografia,
      appBarTheme: AppBarTheme(
        backgroundColor: t.surface,
        foregroundColor: t.text,
        elevation: 1,
        // Explícito y no heredado: Material saca el título del AppBar de
        // `titleLarge`, que en esta escala es la cabecera de grupo y vale 16.
        // El título de una pantalla es `headlineSmall`.
        titleTextStyle: tipografia.headlineSmall?.copyWith(color: t.text),
      ),
      cardTheme: CardThemeData(
        color: t.surface,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: t.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: t.primary, width: 2),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: t.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  /// La escala tipográfica de la identidad equipada.
  ///
  /// La escala se declara aquí entera —tamaño y peso— y es la misma para las
  /// cuatro identidades: lo único que cambia con la identidad es la familia.
  /// Una identidad no puede tocar tamaños ni pesos porque no tiene dónde
  /// declararlos, y ese es justo el motivo de que no se le añada el campo.
  /// Los roles de titular, cifra y etiqueta corta (`display*`, `headline*`,
  /// `title*`) van en [FuentesIdentidad.display]; los de texto de lectura
  /// (`body*`, `label*`) en [FuentesIdentidad.body], que es SIEMPRE la más
  /// legible de la identidad.
  ///
  /// `fontAcento` no entra aquí a propósito: es un detalle puntual que se
  /// invoca a mano donde toca, nunca una familia de uso general.
  ///
  /// Tamaño y peso se aplican ANTES de resolver la familia, y no después como
  /// se hacía: google_fonts carga un fichero por variante y elige cuál mirando
  /// el peso del estilo de partida, así que un `copyWith(fontWeight:)`
  /// posterior cambiaba el número pero seguía pintando con el fichero regular.
  ///
  /// Y aquí entra la familia, nada más. Las mayúsculas y el tracking de
  /// Neotokyo+ o la itálica de Alba las aplica cada pantalla donde tienen
  /// sentido —el titular, un chip, una cifra—: metidas en el tema global,
  /// Neotokyo+ pondría en mayúsculas hasta el cuerpo de un artículo.
  static TextTheme _tipografia(FuentesIdentidad fuentes) {
    final base = ThemeData.dark().textTheme;
    final escala = base.copyWith(
      // ── Titulares — familia display ──────────────────────────────────────
      // La cifra. Hoy, el saldo de puntos de Tienda y Logros.
      displaySmall: base.displaySmall
          ?.copyWith(fontSize: 28, fontWeight: FontWeight.w800),
      // Título de pantalla.
      headlineMedium: base.headlineMedium
          ?.copyWith(fontSize: 20, fontWeight: FontWeight.w700),
      // Título de sección, y también el título del AppBar: `deTema` lo apunta
      // explícitamente en `appBarTheme`, porque el de Material es `titleLarge`
      // y aquí `titleLarge` vale otra cosa.
      headlineSmall: base.headlineSmall
          ?.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
      // Cabecera de grupo y título de estado vacío.
      titleLarge: base.titleLarge
          ?.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
      // Nombre de ítem: un hábito, un producto, un logro. Va en la display a
      // propósito — es lo que se nombra, no lo que se lee.
      titleMedium: base.titleMedium
          ?.copyWith(fontSize: 14, fontWeight: FontWeight.w700),
      // Antetítulo: la etiqueta que encabeza un grupo. El tracking es suyo,
      // no de quien lo usa.
      titleSmall: base.titleSmall?.copyWith(
          fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1),
      // `displayLarge`, `displayMedium` y `headlineLarge` se quedan sin uso y
      // sin tamaño declarado, para que quepa algo mayor que un título de
      // pantalla el día que haga falta.
      headlineLarge: base.headlineLarge?.copyWith(fontWeight: FontWeight.w700),

      // ── Cuerpo — familia body ────────────────────────────────────────────
      // Texto largo, y título de `ListTile`, que hereda de aquí.
      bodyLarge:
          base.bodyLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w400),
      // Texto corriente.
      bodyMedium:
          base.bodyMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.w400),
      // Metadato y subtítulo.
      bodySmall:
          base.bodySmall?.copyWith(fontSize: 12, fontWeight: FontWeight.w400),
      // Botones.
      labelLarge:
          base.labelLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
      // Chips y contadores.
      labelMedium:
          base.labelMedium?.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
      // Micro-etiqueta: el pie de una cifra, la leyenda de un heatmap. Es el
      // suelo de la escala y no hay nada por debajo: si algo pide menos de 11,
      // el problema es el sitio, no el tamaño.
      labelSmall:
          base.labelSmall?.copyWith(fontSize: 11, fontWeight: FontWeight.w600),
    );

    // Dos pasadas sobre la misma escala: cada una devuelve los quince roles en
    // su familia, y de cada una se conservan los que le tocan.
    final display = GoogleFonts.getTextTheme(fuentes.display, escala);
    final cuerpo = GoogleFonts.getTextTheme(fuentes.body, escala);

    return TextTheme(
      displayLarge: display.displayLarge,
      displayMedium: display.displayMedium,
      displaySmall: display.displaySmall,
      headlineLarge: display.headlineLarge,
      headlineMedium: display.headlineMedium,
      headlineSmall: display.headlineSmall,
      titleLarge: display.titleLarge,
      titleMedium: display.titleMedium,
      titleSmall: display.titleSmall,
      bodyLarge: cuerpo.bodyLarge,
      bodyMedium: cuerpo.bodyMedium,
      bodySmall: cuerpo.bodySmall,
      labelLarge: cuerpo.labelLarge,
      labelMedium: cuerpo.labelMedium,
      labelSmall: cuerpo.labelSmall,
    );
  }
}