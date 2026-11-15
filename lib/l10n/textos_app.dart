import 'package:flutter/widgets.dart';

import 'norday_core_localizations.dart';

/// Un texto que pone la app, ya traducido al idioma de [context].
typedef TextoDeApp = String Function(BuildContext context);

/// Los textos del core que dependen de qué app es: su nombre, el lema del
/// login, la explicación de la actualización obligatoria y lo que se pierde
/// al borrar la cuenta.
///
/// El core no sabe de qué va cada app, así que estos textos los pone ella en
/// `main()`, antes de `runApp`, igual que fija `ApiServiceCore.appId`:
///
/// ```dart
/// TextosApp.registrar(
///   nombre: (c) => AppLocalizations.of(c)!.appNombre,
///   lemaLogin: (c) => AppLocalizations.of(c)!.loginLema,
///   actualizacionObligatoria: (c) => AppLocalizations.of(c)!.actualizacion,
///   eliminarCuenta: (c) => AppLocalizations.of(c)!.eliminarCuentaCuerpo,
/// );
/// ```
///
/// Lo que la app no registre cae en el texto neutro del core
/// (`appTitulo`, `loginTagline`, `actualizacionTexto` y
/// `perfilEliminarCuerpo` de `core_*.arb`): «Norday» y frases que no hablan
/// de ningún dominio.
abstract final class TextosApp {
  /// El nombre visible de la app (wordmark del login). Caída: «Norday».
  static TextoDeApp? nombre;

  /// La frase bajo el nombre en el login. Caída: un lema genérico.
  static TextoDeApp? lemaLogin;

  /// El cuerpo de `ActualizacionObligatoriaScreen`. Caída: «Para seguir
  /// usando Norday, actualiza la app…» sin nombrar qué se guarda.
  static TextoDeApp? actualizacionObligatoria;

  /// El cuerpo de la primera confirmación de borrado de cuenta en
  /// `PerfilScreen`. Caída: todos los datos de todas las apps de Norday, que
  /// es lo que de verdad se borra: la cuenta es una sola.
  static TextoDeApp? eliminarCuenta;

  /// Fija los cuatro textos de una vez. Lo que se pase a `null` (o no se
  /// pase) vuelve a la caída del core: registrar sustituye, no mezcla.
  static void registrar({
    TextoDeApp? nombre,
    TextoDeApp? lemaLogin,
    TextoDeApp? actualizacionObligatoria,
    TextoDeApp? eliminarCuenta,
  }) {
    TextosApp.nombre = nombre;
    TextosApp.lemaLogin = lemaLogin;
    TextosApp.actualizacionObligatoria = actualizacionObligatoria;
    TextosApp.eliminarCuenta = eliminarCuenta;
  }

  /// Vuelve a las caídas del core. Para tests.
  static void reiniciar() => registrar();

  static NordayCoreLocalizations _l(BuildContext context) =>
      NordayCoreLocalizations.of(context)!;

  /// El nombre de la app, o «Norday».
  static String nombreDe(BuildContext context) =>
      nombre?.call(context) ?? _l(context).appTitulo;

  /// El lema del login de la app, o el genérico.
  static String lemaLoginDe(BuildContext context) =>
      lemaLogin?.call(context) ?? _l(context).loginTagline;

  /// El texto de la actualización obligatoria de la app, o el genérico.
  static String actualizacionObligatoriaDe(BuildContext context) =>
      actualizacionObligatoria?.call(context) ?? _l(context).actualizacionTexto;

  /// Lo que se borra con la cuenta, según la app, o el genérico.
  static String eliminarCuentaDe(BuildContext context) =>
      eliminarCuenta?.call(context) ?? _l(context).perfilEliminarCuerpo;
}
