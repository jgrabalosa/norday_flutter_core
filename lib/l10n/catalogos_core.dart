import 'package:flutter/widgets.dart';
import 'norday_core_localizations.dart';

/// Traducción de los catálogos que manda el backend.
///
/// El backend envía `codigo` (RACHA_7, TEMA_OCEANO...) y el nombre en español
/// como caída. Aquí se traduce por código.
///
/// CAÍDA OBLIGATORIA: si el código no está traducido —o viene a null, que es
/// el caso de las categorías que crea el usuario— se muestra el nombre que
/// manda el backend tal cual. Nunca se enseña un código crudo ni una cadena
/// vacía.
///
/// Motor: aquí solo viven los códigos genéricos del ecosistema (productos de
/// la tienda, niveles, categorías de logro y los cuatro logros que no saben
/// de dominio). Los logros propios de cada app se enchufan con
/// [registrarLogrosDeDominio]: el paquete no puede conocerlos, pero es él
/// quien pinta la pantalla de logros y las celebraciones.
class CatalogosCore {
  const CatalogosCore._();

  static Map<String, String> Function(BuildContext)? _logrosDeDominio;
  static Map<String, String> Function(BuildContext)? _logrosDescDeDominio;

  /// La llama la app una vez al arrancar. Los mapas se piden con el
  /// [BuildContext] a mano porque las traducciones dependen del idioma
  /// activo, que cambia sin reiniciar la app.
  static void registrarLogrosDeDominio({
    required Map<String, String> Function(BuildContext) nombres,
    required Map<String, String> Function(BuildContext) descripciones,
  }) {
    _logrosDeDominio = nombres;
    _logrosDescDeDominio = descripciones;
  }

  static String producto(BuildContext context, String? codigo, String nombreBackend) =>
      traducir(_productos(context), codigo, nombreBackend);

  static String productoDescripcion(
          BuildContext context, String? codigo, String descripcionBackend) =>
      traducir(_productosDescripcion(context), codigo, descripcionBackend);

  /// Busca primero en los logros del motor y luego en los que haya registrado
  /// la app. Si el código no está en ninguno de los dos, cae al nombre del
  /// backend.
  static String logro(BuildContext context, String? codigo, String nombreBackend) =>
      traducir(_logros(context), codigo,
          traducir(_logrosDeDominio?.call(context) ?? const {}, codigo, nombreBackend));

  static String logroDescripcion(
          BuildContext context, String? codigo, String descripcionBackend) =>
      traducir(_logrosDescripcion(context), codigo,
          traducir(_logrosDescDeDominio?.call(context) ?? const {}, codigo,
              descripcionBackend));

  /// Categoría y nivel del logro no viajan por código: el backend manda el
  /// literal en español ('Constancia', 'Facil'). Se traducen por ese valor,
  /// que aquí hace de clave.
  static String logroCategoria(BuildContext context, String categoriaBackend) =>
      traducir(_logrosCategoria(context), categoriaBackend, categoriaBackend);

  static String logroNivel(BuildContext context, String nivelBackend) =>
      traducir(_logrosNivel(context), nivelBackend, nivelBackend);

  /// La caída de siempre, expuesta para que los catálogos de dominio de cada
  /// app la reutilicen en vez de repetirla.
  static String traducir(
      Map<String, String> mapa, String? codigo, String nombreBackend) {
    if (codigo == null) return nombreBackend;
    return mapa[codigo] ?? nombreBackend;
  }

  /// Los cuatro logros que no saben de dominio: se ganan por existir, entrar
  /// con Google o valorar la app, no por nada que la app en concreto haga.
  static Map<String, String> _logros(BuildContext context) {
    final l = NordayCoreLocalizations.of(context)!;
    return {
      'BIENVENIDO': l.logroBienvenido,
      'PRIMEROS_PASOS': l.logroPrimerosPasos,
      'LOGIN_GOOGLE': l.logroLoginGoogle,
      'INTERACCION_RESENA': l.logroInteraccionResena,
    };
  }

  static Map<String, String> _logrosDescripcion(BuildContext context) {
    final l = NordayCoreLocalizations.of(context)!;
    return {
      'BIENVENIDO': l.logroDescBienvenido,
      'PRIMEROS_PASOS': l.logroDescPrimerosPasos,
      'LOGIN_GOOGLE': l.logroDescLoginGoogle,
      'INTERACCION_RESENA': l.logroDescInteraccionResena,
    };
  }

  static Map<String, String> _productos(BuildContext context) {
    final l = NordayCoreLocalizations.of(context)!;
    return {
      'ESCUDO_RACHA': l.prodEscudoRacha,
      'TEMA_BASICO_CLARO': l.prodTemaBasicoClaro,
      'TEMA_BASICO_OSCURO': l.prodTemaBasicoOscuro,
      'TEMA_CALIDEZ': l.prodTemaCalidez,
      'TEMA_NEOTOKYO': l.prodTemaNeotokyo,
      'TEMA_OCEANO': l.prodTemaOceano,
      'TEMA_BOSQUE': l.prodTemaBosque,
      'TEMA_COBRE': l.prodTemaCobre,
      'AVATAR_ZORRO': l.prodAvatarZorro,
      'AVATAR_GATO': l.prodAvatarGato,
      'AVATAR_BUHO': l.prodAvatarBuho,
      'AVATAR_PANDA': l.prodAvatarPanda,
      'AVATAR_TORTUGA': l.prodAvatarTortuga,
      'AVATAR_PERRO': l.prodAvatarPerro,
      'AVATAR_CONEJO': l.prodAvatarConejo,
      'AVATAR_KOALA': l.prodAvatarKoala,
      'AVATAR_PINGUINO': l.prodAvatarPinguino,
      'AVATAR_LEON': l.prodAvatarLeon,
      'COMIDA_BASICA': l.prodComidaBasica,
    };
  }

  static Map<String, String> _productosDescripcion(BuildContext context) {
    final l = NordayCoreLocalizations.of(context)!;
    return {
      'ESCUDO_RACHA': l.prodDescEscudoRacha,
      'TEMA_BASICO_CLARO': l.prodDescTemaBasicoClaro,
      'TEMA_BASICO_OSCURO': l.prodDescTemaBasicoOscuro,
      'TEMA_CALIDEZ': l.prodDescTemaCalidez,
      'TEMA_NEOTOKYO': l.prodDescTemaNeotokyo,
      'TEMA_OCEANO': l.prodDescTemaOceano,
      'TEMA_BOSQUE': l.prodDescTemaBosque,
      'TEMA_COBRE': l.prodDescTemaCobre,
      'AVATAR_ZORRO': l.prodDescAvatarZorro,
      'AVATAR_GATO': l.prodDescAvatarGato,
      'AVATAR_BUHO': l.prodDescAvatarBuho,
      'AVATAR_PANDA': l.prodDescAvatarPanda,
      'AVATAR_TORTUGA': l.prodDescAvatarTortuga,
      'AVATAR_PERRO': l.prodDescAvatarPerro,
      'AVATAR_CONEJO': l.prodDescAvatarConejo,
      'AVATAR_KOALA': l.prodDescAvatarKoala,
      'AVATAR_PINGUINO': l.prodDescAvatarPinguino,
      'AVATAR_LEON': l.prodDescAvatarLeon,
      'COMIDA_BASICA': l.prodDescComidaBasica,
    };
  }

  static Map<String, String> _logrosCategoria(BuildContext context) {
    final l = NordayCoreLocalizations.of(context)!;
    return {
      'Inicio': l.logroCatInicio,
      'Constancia': l.logroCatConstancia,
      'Volumen': l.logroCatVolumen,
      'Variedad': l.logroCatVariedad,
      'Exploración': l.logroCatExploracion,
    };
  }

  // Sin tilde en las claves: así es como llegan de los initializers.
  static Map<String, String> _logrosNivel(BuildContext context) {
    final l = NordayCoreLocalizations.of(context)!;
    return {
      'Facil': l.nivelFacil,
      'Medio': l.nivelMedio,
      'Dificil': l.nivelDificil,
    };
  }
}
