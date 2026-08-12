import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'norday_core_localizations_en.dart';
import 'norday_core_localizations_es.dart';
import 'norday_core_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of NordayCoreLocalizations
/// returned by `NordayCoreLocalizations.of(context)`.
///
/// Applications need to include `NordayCoreLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/norday_core_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: NordayCoreLocalizations.localizationsDelegates,
///   supportedLocales: NordayCoreLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the NordayCoreLocalizations.supportedLocales
/// property.
abstract class NordayCoreLocalizations {
  NordayCoreLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static NordayCoreLocalizations? of(BuildContext context) {
    return Localizations.of<NordayCoreLocalizations>(
      context,
      NordayCoreLocalizations,
    );
  }

  static const LocalizationsDelegate<NordayCoreLocalizations> delegate =
      _NordayCoreLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('pt'),
  ];

  /// No description provided for @appTitulo.
  ///
  /// In es, this message translates to:
  /// **'Norday Habits'**
  String get appTitulo;

  /// No description provided for @idioma.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get idioma;

  /// No description provided for @zonaHoraria.
  ///
  /// In es, this message translates to:
  /// **'Zona horaria'**
  String get zonaHoraria;

  /// No description provided for @preferencias.
  ///
  /// In es, this message translates to:
  /// **'Preferencias'**
  String get preferencias;

  /// No description provided for @idiomaEs.
  ///
  /// In es, this message translates to:
  /// **'Español'**
  String get idiomaEs;

  /// No description provided for @idiomaEn.
  ///
  /// In es, this message translates to:
  /// **'Inglés'**
  String get idiomaEn;

  /// No description provided for @idiomaPt.
  ///
  /// In es, this message translates to:
  /// **'Portugués'**
  String get idiomaPt;

  /// No description provided for @guardar.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get guardar;

  /// No description provided for @cancelar.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancelar;

  /// No description provided for @zonaDetectada.
  ///
  /// In es, this message translates to:
  /// **'Detectada de tu dispositivo'**
  String get zonaDetectada;

  /// No description provided for @zonaAyuda.
  ///
  /// In es, this message translates to:
  /// **'Define cuándo empieza y acaba tu día para las rachas y los recordatorios.'**
  String get zonaAyuda;

  /// No description provided for @logroBienvenido.
  ///
  /// In es, this message translates to:
  /// **'Bienvenido/a'**
  String get logroBienvenido;

  /// No description provided for @logroLoginGoogle.
  ///
  /// In es, this message translates to:
  /// **'Conectado con Google'**
  String get logroLoginGoogle;

  /// No description provided for @logroPrimerosPasos.
  ///
  /// In es, this message translates to:
  /// **'Primeros pasos'**
  String get logroPrimerosPasos;

  /// No description provided for @logroInteraccionResena.
  ///
  /// In es, this message translates to:
  /// **'Tu opinión cuenta'**
  String get logroInteraccionResena;

  /// No description provided for @prodEscudoRacha.
  ///
  /// In es, this message translates to:
  /// **'Escudo de racha'**
  String get prodEscudoRacha;

  /// No description provided for @prodTemaBasicoClaro.
  ///
  /// In es, this message translates to:
  /// **'Básico Claro'**
  String get prodTemaBasicoClaro;

  /// No description provided for @prodTemaBasicoOscuro.
  ///
  /// In es, this message translates to:
  /// **'Básico Oscuro'**
  String get prodTemaBasicoOscuro;

  /// No description provided for @prodTemaCalidez.
  ///
  /// In es, this message translates to:
  /// **'Calidez'**
  String get prodTemaCalidez;

  /// No description provided for @prodTemaNeotokyo.
  ///
  /// In es, this message translates to:
  /// **'Neo-Tokyo'**
  String get prodTemaNeotokyo;

  /// No description provided for @prodTemaOceano.
  ///
  /// In es, this message translates to:
  /// **'Océano'**
  String get prodTemaOceano;

  /// No description provided for @prodTemaBosque.
  ///
  /// In es, this message translates to:
  /// **'Bosque'**
  String get prodTemaBosque;

  /// No description provided for @prodTemaCobre.
  ///
  /// In es, this message translates to:
  /// **'Cobre Nocturno'**
  String get prodTemaCobre;

  /// No description provided for @prodAvatarZorro.
  ///
  /// In es, this message translates to:
  /// **'Zorro'**
  String get prodAvatarZorro;

  /// No description provided for @prodAvatarGato.
  ///
  /// In es, this message translates to:
  /// **'Gato'**
  String get prodAvatarGato;

  /// No description provided for @prodAvatarBuho.
  ///
  /// In es, this message translates to:
  /// **'Búho'**
  String get prodAvatarBuho;

  /// No description provided for @prodAvatarPanda.
  ///
  /// In es, this message translates to:
  /// **'Panda'**
  String get prodAvatarPanda;

  /// No description provided for @prodAvatarTortuga.
  ///
  /// In es, this message translates to:
  /// **'Tortuga'**
  String get prodAvatarTortuga;

  /// No description provided for @prodComidaBasica.
  ///
  /// In es, this message translates to:
  /// **'Comida'**
  String get prodComidaBasica;

  /// No description provided for @preferenciasSubtitulo.
  ///
  /// In es, this message translates to:
  /// **'Idioma y zona horaria'**
  String get preferenciasSubtitulo;

  /// No description provided for @cambiarZona.
  ///
  /// In es, this message translates to:
  /// **'Cambiar zona horaria'**
  String get cambiarZona;

  /// No description provided for @buscarZona.
  ///
  /// In es, this message translates to:
  /// **'Buscar zona'**
  String get buscarZona;

  /// No description provided for @sinResultados.
  ///
  /// In es, this message translates to:
  /// **'Sin resultados'**
  String get sinResultados;

  /// No description provided for @preferenciasGuardadas.
  ///
  /// In es, this message translates to:
  /// **'Preferencias actualizadas'**
  String get preferenciasGuardadas;

  /// No description provided for @comunCerrar.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get comunCerrar;

  /// No description provided for @comunContinuar.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get comunContinuar;

  /// No description provided for @mascotaTitulo.
  ///
  /// In es, this message translates to:
  /// **'Mascota'**
  String get mascotaTitulo;

  /// No description provided for @mascotaFaseHuevo.
  ///
  /// In es, this message translates to:
  /// **'Huevo'**
  String get mascotaFaseHuevo;

  /// No description provided for @mascotaFaseCria.
  ///
  /// In es, this message translates to:
  /// **'Cría'**
  String get mascotaFaseCria;

  /// No description provided for @mascotaFaseAdulto.
  ///
  /// In es, this message translates to:
  /// **'Adulto'**
  String get mascotaFaseAdulto;

  /// No description provided for @mascotaEstadoFeliz.
  ///
  /// In es, this message translates to:
  /// **'Feliz'**
  String get mascotaEstadoFeliz;

  /// No description provided for @mascotaEstadoAtencion.
  ///
  /// In es, this message translates to:
  /// **'Necesita atención'**
  String get mascotaEstadoAtencion;

  /// No description provided for @mascotaEstadoTranquila.
  ///
  /// In es, this message translates to:
  /// **'Tranquila'**
  String get mascotaEstadoTranquila;

  /// No description provided for @mascotaEstadoTriste.
  ///
  /// In es, this message translates to:
  /// **'Triste'**
  String get mascotaEstadoTriste;

  /// No description provided for @mascotaPonleNombre.
  ///
  /// In es, this message translates to:
  /// **'Ponle nombre'**
  String get mascotaPonleNombre;

  /// No description provided for @mascotaHintNombre.
  ///
  /// In es, this message translates to:
  /// **'Nombre de tu mascota'**
  String get mascotaHintNombre;

  /// No description provided for @mascotaErrorNombre.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar el nombre. Inténtalo de nuevo.'**
  String get mascotaErrorNombre;

  /// No description provided for @mascotaAlimentar.
  ///
  /// In es, this message translates to:
  /// **'Alimentar'**
  String get mascotaAlimentar;

  /// No description provided for @mascotaErrorAlimentar.
  ///
  /// In es, this message translates to:
  /// **'No se pudo alimentar a tu mascota. Inténtalo de nuevo.'**
  String get mascotaErrorAlimentar;

  /// No description provided for @mascotaNivel.
  ///
  /// In es, this message translates to:
  /// **'Nivel {n}'**
  String mascotaNivel(int n);

  /// No description provided for @mascotaXp.
  ///
  /// In es, this message translates to:
  /// **'{actual}/{total} XP'**
  String mascotaXp(int actual, int total);

  /// Frase de contexto bajo la mascota. Se compone con la fase ya traducida, el nivel y uno de los mascotaAnimo*.
  ///
  /// In es, this message translates to:
  /// **'{fase} · Nivel {nivel} · {animo}'**
  String mascotaContexto(String fase, int nivel, String animo);

  /// No description provided for @mascotaAnimoHuevo.
  ///
  /// In es, this message translates to:
  /// **'a punto de romper el cascarón'**
  String get mascotaAnimoHuevo;

  /// No description provided for @mascotaAnimoFeliz.
  ///
  /// In es, this message translates to:
  /// **'a gusto contigo'**
  String get mascotaAnimoFeliz;

  /// No description provided for @mascotaAnimoAtencion.
  ///
  /// In es, this message translates to:
  /// **'echando una cabezada'**
  String get mascotaAnimoAtencion;

  /// No description provided for @mascotaAnimoTriste.
  ///
  /// In es, this message translates to:
  /// **'te echa de menos'**
  String get mascotaAnimoTriste;

  /// No description provided for @mascotaAnimoTranquila.
  ///
  /// In es, this message translates to:
  /// **'sin novedad'**
  String get mascotaAnimoTranquila;

  /// No description provided for @mascotaSubidaNivel.
  ///
  /// In es, this message translates to:
  /// **'¡Nivel {n}!'**
  String mascotaSubidaNivel(int n);

  /// No description provided for @plantillaBeberAgua.
  ///
  /// In es, this message translates to:
  /// **'Beber agua'**
  String get plantillaBeberAgua;

  /// No description provided for @detLogrosDe.
  ///
  /// In es, this message translates to:
  /// **'{n} de {total} logros'**
  String detLogrosDe(int n, int total);

  /// No description provided for @perfilTitulo.
  ///
  /// In es, this message translates to:
  /// **'Mi cuenta'**
  String get perfilTitulo;

  /// No description provided for @perfilActualizado.
  ///
  /// In es, this message translates to:
  /// **'Perfil actualizado ✅'**
  String get perfilActualizado;

  /// No description provided for @perfilErrorGuardar.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar el perfil. Inténtalo de nuevo.'**
  String get perfilErrorGuardar;

  /// No description provided for @perfilPassActualizada.
  ///
  /// In es, this message translates to:
  /// **'Contraseña actualizada ✅'**
  String get perfilPassActualizada;

  /// No description provided for @perfilErrorPass.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cambiar la contraseña. Revisa los datos e inténtalo de nuevo.'**
  String get perfilErrorPass;

  /// No description provided for @perfilErrorEliminar.
  ///
  /// In es, this message translates to:
  /// **'No se pudo eliminar la cuenta. Inténtalo de nuevo.'**
  String get perfilErrorEliminar;

  /// No description provided for @perfilEliminarTitulo.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar tu cuenta?'**
  String get perfilEliminarTitulo;

  /// No description provided for @perfilEliminarCuerpo.
  ///
  /// In es, this message translates to:
  /// **'Se borrarán para siempre todos tus hábitos, registros, rachas, logros y puntos.\n\nEsta acción no se puede deshacer.'**
  String get perfilEliminarCuerpo;

  /// No description provided for @perfilUltimaConfirmacion.
  ///
  /// In es, this message translates to:
  /// **'Última confirmación'**
  String get perfilUltimaConfirmacion;

  /// No description provided for @perfilUltimaConfirmacionCuerpo.
  ///
  /// In es, this message translates to:
  /// **'¿Estás completamente seguro? Tu cuenta y todos tus datos se eliminarán de forma definitiva.'**
  String get perfilUltimaConfirmacionCuerpo;

  /// No description provided for @perfilNoVolver.
  ///
  /// In es, this message translates to:
  /// **'No, volver'**
  String get perfilNoVolver;

  /// No description provided for @perfilSiEliminar.
  ///
  /// In es, this message translates to:
  /// **'Sí, eliminar mi cuenta'**
  String get perfilSiEliminar;

  /// No description provided for @perfilLabelNombre.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get perfilLabelNombre;

  /// No description provided for @perfilLabelUsuario.
  ///
  /// In es, this message translates to:
  /// **'Nombre de usuario'**
  String get perfilLabelUsuario;

  /// No description provided for @perfilLabelEmail.
  ///
  /// In es, this message translates to:
  /// **'Email'**
  String get perfilLabelEmail;

  /// No description provided for @perfilNombreVacio.
  ///
  /// In es, this message translates to:
  /// **'El nombre no puede estar vacío'**
  String get perfilNombreVacio;

  /// No description provided for @perfilUsuarioVacio.
  ///
  /// In es, this message translates to:
  /// **'El nombre de usuario no puede estar vacío'**
  String get perfilUsuarioVacio;

  /// No description provided for @perfilEmailVacio.
  ///
  /// In es, this message translates to:
  /// **'El email no puede estar vacío'**
  String get perfilEmailVacio;

  /// No description provided for @perfilEmailInvalido.
  ///
  /// In es, this message translates to:
  /// **'Introduce un email válido'**
  String get perfilEmailInvalido;

  /// No description provided for @perfilGestionadoGoogle.
  ///
  /// In es, this message translates to:
  /// **'Gestionado por tu cuenta de Google'**
  String get perfilGestionadoGoogle;

  /// No description provided for @perfilGuardarCambios.
  ///
  /// In es, this message translates to:
  /// **'Guardar cambios'**
  String get perfilGuardarCambios;

  /// No description provided for @perfilPassActual.
  ///
  /// In es, this message translates to:
  /// **'Contraseña actual'**
  String get perfilPassActual;

  /// No description provided for @perfilPassNueva.
  ///
  /// In es, this message translates to:
  /// **'Nueva contraseña'**
  String get perfilPassNueva;

  /// No description provided for @perfilPassActualVacia.
  ///
  /// In es, this message translates to:
  /// **'Introduce tu contraseña actual'**
  String get perfilPassActualVacia;

  /// No description provided for @perfilPassNuevaVacia.
  ///
  /// In es, this message translates to:
  /// **'Introduce la nueva contraseña'**
  String get perfilPassNuevaVacia;

  /// No description provided for @perfilMinimo6.
  ///
  /// In es, this message translates to:
  /// **'Mínimo 6 caracteres'**
  String get perfilMinimo6;

  /// No description provided for @perfilCambiarPass.
  ///
  /// In es, this message translates to:
  /// **'Cambiar contraseña'**
  String get perfilCambiarPass;

  /// No description provided for @perfilZonaPeligro.
  ///
  /// In es, this message translates to:
  /// **'Zona de peligro'**
  String get perfilZonaPeligro;

  /// No description provided for @perfilEliminarCuenta.
  ///
  /// In es, this message translates to:
  /// **'Eliminar mi cuenta'**
  String get perfilEliminarCuenta;

  /// No description provided for @loginTagline.
  ///
  /// In es, this message translates to:
  /// **'Construye hábitos, transforma tu vida'**
  String get loginTagline;

  /// No description provided for @loginIniciarSesion.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get loginIniciarSesion;

  /// No description provided for @loginRegistrarse.
  ///
  /// In es, this message translates to:
  /// **'Registrarse'**
  String get loginRegistrarse;

  /// No description provided for @loginCrearCuenta.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get loginCrearCuenta;

  /// No description provided for @loginContinuarGoogle.
  ///
  /// In es, this message translates to:
  /// **'Continuar con Google'**
  String get loginContinuarGoogle;

  /// No description provided for @loginO.
  ///
  /// In es, this message translates to:
  /// **'o'**
  String get loginO;

  /// No description provided for @loginLabelContrasena.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get loginLabelContrasena;

  /// No description provided for @loginOlvidasteContrasena.
  ///
  /// In es, this message translates to:
  /// **'¿Olvidaste tu contraseña?'**
  String get loginOlvidasteContrasena;

  /// No description provided for @loginError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo completar. Revisa tus datos e inténtalo de nuevo.'**
  String get loginError;

  /// No description provided for @recTitulo.
  ///
  /// In es, this message translates to:
  /// **'Recuperar contraseña'**
  String get recTitulo;

  /// No description provided for @recIntro.
  ///
  /// In es, this message translates to:
  /// **'Escribe el email de tu cuenta y te enviaremos un código para restablecer la contraseña.'**
  String get recIntro;

  /// No description provided for @recCodigoEnviado.
  ///
  /// In es, this message translates to:
  /// **'Revisa tu correo. Si el email está registrado, te hemos enviado un código de 6 dígitos (caduca en 15 minutos).'**
  String get recCodigoEnviado;

  /// No description provided for @recLabelCodigo.
  ///
  /// In es, this message translates to:
  /// **'Código de 6 dígitos'**
  String get recLabelCodigo;

  /// No description provided for @recEscribeEmail.
  ///
  /// In es, this message translates to:
  /// **'Escribe tu email'**
  String get recEscribeEmail;

  /// No description provided for @recRellenaCampos.
  ///
  /// In es, this message translates to:
  /// **'Rellena el código y la nueva contraseña'**
  String get recRellenaCampos;

  /// No description provided for @recBotonEnviar.
  ///
  /// In es, this message translates to:
  /// **'Enviar código'**
  String get recBotonEnviar;

  /// No description provided for @recBotonRestablecer.
  ///
  /// In es, this message translates to:
  /// **'Restablecer contraseña'**
  String get recBotonRestablecer;

  /// No description provided for @recReenviar.
  ///
  /// In es, this message translates to:
  /// **'Reenviar código'**
  String get recReenviar;

  /// No description provided for @recRestablecida.
  ///
  /// In es, this message translates to:
  /// **'Contraseña restablecida ✅ Ya puedes iniciar sesión'**
  String get recRestablecida;

  /// No description provided for @recErrorEnviar.
  ///
  /// In es, this message translates to:
  /// **'No se pudo enviar el código. Inténtalo de nuevo.'**
  String get recErrorEnviar;

  /// No description provided for @recError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo restablecer la contraseña. Revisa el código e inténtalo de nuevo.'**
  String get recError;

  /// No description provided for @navHoy.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get navHoy;

  /// No description provided for @navColeccion.
  ///
  /// In es, this message translates to:
  /// **'Colección'**
  String get navColeccion;

  /// No description provided for @dashCompletados.
  ///
  /// In es, this message translates to:
  /// **'COMPLETADOS'**
  String get dashCompletados;

  /// No description provided for @puntos.
  ///
  /// In es, this message translates to:
  /// **'puntos'**
  String get puntos;

  /// No description provided for @tiendaTitulo.
  ///
  /// In es, this message translates to:
  /// **'Tienda'**
  String get tiendaTitulo;

  /// No description provided for @tiendaCatalogo.
  ///
  /// In es, this message translates to:
  /// **'Catálogo'**
  String get tiendaCatalogo;

  /// No description provided for @tiendaComprar.
  ///
  /// In es, this message translates to:
  /// **'Comprar'**
  String get tiendaComprar;

  /// No description provided for @tiendaEquipar.
  ///
  /// In es, this message translates to:
  /// **'Equipar'**
  String get tiendaEquipar;

  /// No description provided for @tiendaEquipado.
  ///
  /// In es, this message translates to:
  /// **'Equipado'**
  String get tiendaEquipado;

  /// No description provided for @tiendaPrecio.
  ///
  /// In es, this message translates to:
  /// **'{n} pts'**
  String tiendaPrecio(int n);

  /// No description provided for @tiendaUsar.
  ///
  /// In es, this message translates to:
  /// **'Usar (x{n})'**
  String tiendaUsar(int n);

  /// No description provided for @tiendaError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo completar la operación. Inténtalo de nuevo.'**
  String get tiendaError;

  /// No description provided for @tiendaPreviewNavHabitos.
  ///
  /// In es, this message translates to:
  /// **'Hábitos'**
  String get tiendaPreviewNavHabitos;

  /// No description provided for @tiendaPreviewNavPerfil.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get tiendaPreviewNavPerfil;

  /// No description provided for @tiendaPreviewHabito2.
  ///
  /// In es, this message translates to:
  /// **'Meditar 5 min'**
  String get tiendaPreviewHabito2;

  /// No description provided for @tiendaPreviewQueCrack.
  ///
  /// In es, this message translates to:
  /// **'¡qué crack!'**
  String get tiendaPreviewQueCrack;

  /// No description provided for @logrosTitulo.
  ///
  /// In es, this message translates to:
  /// **'Mis logros'**
  String get logrosTitulo;

  /// No description provided for @logrosSeccion.
  ///
  /// In es, this message translates to:
  /// **'Logros'**
  String get logrosSeccion;

  /// No description provided for @logrosPorcentaje.
  ///
  /// In es, this message translates to:
  /// **'{n}%'**
  String logrosPorcentaje(int n);

  /// No description provided for @logrosPuntos.
  ///
  /// In es, this message translates to:
  /// **'+{n} pts'**
  String logrosPuntos(int n);

  /// No description provided for @colSeccionAvatares.
  ///
  /// In es, this message translates to:
  /// **'Avatares'**
  String get colSeccionAvatares;

  /// No description provided for @colSeccionConsumibles.
  ///
  /// In es, this message translates to:
  /// **'Consumibles'**
  String get colSeccionConsumibles;

  /// No description provided for @colSeccionTemas.
  ///
  /// In es, this message translates to:
  /// **'Temas'**
  String get colSeccionTemas;

  /// No description provided for @colEligeAvatar.
  ///
  /// In es, this message translates to:
  /// **'Elige tu primer avatar gratis 👇'**
  String get colEligeAvatar;

  /// No description provided for @colDescubre.
  ///
  /// In es, this message translates to:
  /// **'Descubre {seccion} en la tienda →'**
  String colDescubre(String seccion);

  /// No description provided for @colSeleccionActual.
  ///
  /// In es, this message translates to:
  /// **'Tu selección actual'**
  String get colSeleccionActual;

  /// No description provided for @colContador.
  ///
  /// In es, this message translates to:
  /// **'{poseidos}/{total}'**
  String colContador(int poseidos, int total);

  /// No description provided for @colCantidad.
  ///
  /// In es, this message translates to:
  /// **'x{n}'**
  String colCantidad(int n);

  /// No description provided for @colSeActivaSolo.
  ///
  /// In es, this message translates to:
  /// **'Se activa solo'**
  String get colSeActivaSolo;

  /// No description provided for @colUsar.
  ///
  /// In es, this message translates to:
  /// **'Usar'**
  String get colUsar;

  /// No description provided for @colError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo completar la operación. Inténtalo de nuevo.'**
  String get colError;

  /// No description provided for @obTitulo1.
  ///
  /// In es, this message translates to:
  /// **'¡Bienvenido a Norday! 🎉'**
  String get obTitulo1;

  /// No description provided for @obCuerpo1.
  ///
  /// In es, this message translates to:
  /// **'Cada hábito que completes te da puntos. Úsalos para desbloquear avatares, temas y más en la tienda.'**
  String get obCuerpo1;

  /// No description provided for @obTitulo2.
  ///
  /// In es, this message translates to:
  /// **'Tu compañero crece contigo 🐣'**
  String get obTitulo2;

  /// No description provided for @obCuerpo2.
  ///
  /// In es, this message translates to:
  /// **'Tienes una mascota que sube de nivel cada vez que completas un hábito. Cuídala y mira cómo evoluciona.'**
  String get obCuerpo2;

  /// No description provided for @obTitulo3.
  ///
  /// In es, this message translates to:
  /// **'Elige tu primer avatar, ¡es gratis! 👇'**
  String get obTitulo3;

  /// No description provided for @obCuerpo3.
  ///
  /// In es, this message translates to:
  /// **'Podrás cambiarlo cuando quieras desde la Colección.'**
  String get obCuerpo3;

  /// No description provided for @obSiguiente.
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get obSiguiente;

  /// No description provided for @valTitulo.
  ///
  /// In es, this message translates to:
  /// **'Valoración'**
  String get valTitulo;

  /// No description provided for @valEditar.
  ///
  /// In es, this message translates to:
  /// **'Editar valoración'**
  String get valEditar;

  /// No description provided for @valComoTeSentiste.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo te sentiste?'**
  String get valComoTeSentiste;

  /// No description provided for @valHintNota.
  ///
  /// In es, this message translates to:
  /// **'Añade una nota (opcional)'**
  String get valHintNota;

  /// No description provided for @celLogroDesbloqueado.
  ///
  /// In es, this message translates to:
  /// **'¡Logro desbloqueado!'**
  String get celLogroDesbloqueado;

  /// No description provided for @celGenial.
  ///
  /// In es, this message translates to:
  /// **'¡Genial!'**
  String get celGenial;

  /// No description provided for @selElegirGratis.
  ///
  /// In es, this message translates to:
  /// **'Elegir gratis'**
  String get selElegirGratis;

  /// No description provided for @selError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo elegir el avatar. Inténtalo de nuevo.'**
  String get selError;

  /// No description provided for @logroDescPrimerosPasos.
  ///
  /// In es, this message translates to:
  /// **'Completa tu primer hábito'**
  String get logroDescPrimerosPasos;

  /// No description provided for @logroDescBienvenido.
  ///
  /// In es, this message translates to:
  /// **'Personaliza tu perfil de usuario'**
  String get logroDescBienvenido;

  /// No description provided for @logroDescLoginGoogle.
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión usando tu cuenta de Google'**
  String get logroDescLoginGoogle;

  /// No description provided for @logroDescInteraccionResena.
  ///
  /// In es, this message translates to:
  /// **'Interactúa con la valoración de la app en Google Play'**
  String get logroDescInteraccionResena;

  /// No description provided for @prodDescEscudoRacha.
  ///
  /// In es, this message translates to:
  /// **'Protege tu racha durante 1 día si olvidas completar tu hábito'**
  String get prodDescEscudoRacha;

  /// No description provided for @prodDescTemaBasicoClaro.
  ///
  /// In es, this message translates to:
  /// **'El tema claro de serie de Norday'**
  String get prodDescTemaBasicoClaro;

  /// No description provided for @prodDescTemaBasicoOscuro.
  ///
  /// In es, this message translates to:
  /// **'El tema oscuro de serie de Norday'**
  String get prodDescTemaBasicoOscuro;

  /// No description provided for @prodDescTemaCalidez.
  ///
  /// In es, this message translates to:
  /// **'Un tema premium con tonos cálidos y acogedores'**
  String get prodDescTemaCalidez;

  /// No description provided for @prodDescTemaNeotokyo.
  ///
  /// In es, this message translates to:
  /// **'Un tema premium inspirado en la estética anime y neón'**
  String get prodDescTemaNeotokyo;

  /// No description provided for @prodDescTemaOceano.
  ///
  /// In es, this message translates to:
  /// **'Un tema premium con tonos azules y frescos del mar'**
  String get prodDescTemaOceano;

  /// No description provided for @prodDescTemaBosque.
  ///
  /// In es, this message translates to:
  /// **'Un tema premium con tonos verdes y naturales'**
  String get prodDescTemaBosque;

  /// No description provided for @prodDescTemaCobre.
  ///
  /// In es, this message translates to:
  /// **'Un tema premium elegante en azul noche y cobre'**
  String get prodDescTemaCobre;

  /// No description provided for @prodDescAvatarZorro.
  ///
  /// In es, this message translates to:
  /// **'Avatar ilustrado de zorro'**
  String get prodDescAvatarZorro;

  /// No description provided for @prodDescAvatarGato.
  ///
  /// In es, this message translates to:
  /// **'Avatar ilustrado de gato'**
  String get prodDescAvatarGato;

  /// No description provided for @prodDescAvatarBuho.
  ///
  /// In es, this message translates to:
  /// **'Avatar ilustrado de búho'**
  String get prodDescAvatarBuho;

  /// No description provided for @prodDescAvatarPanda.
  ///
  /// In es, this message translates to:
  /// **'Avatar ilustrado de panda'**
  String get prodDescAvatarPanda;

  /// No description provided for @prodDescAvatarTortuga.
  ///
  /// In es, this message translates to:
  /// **'Avatar ilustrado de tortuga'**
  String get prodDescAvatarTortuga;

  /// No description provided for @prodDescComidaBasica.
  ///
  /// In es, this message translates to:
  /// **'Alimenta a tu mascota y gana experiencia'**
  String get prodDescComidaBasica;

  /// No description provided for @logroCatInicio.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get logroCatInicio;

  /// No description provided for @logroCatConstancia.
  ///
  /// In es, this message translates to:
  /// **'Constancia'**
  String get logroCatConstancia;

  /// No description provided for @logroCatVolumen.
  ///
  /// In es, this message translates to:
  /// **'Volumen'**
  String get logroCatVolumen;

  /// No description provided for @logroCatVariedad.
  ///
  /// In es, this message translates to:
  /// **'Variedad'**
  String get logroCatVariedad;

  /// No description provided for @logroCatExploracion.
  ///
  /// In es, this message translates to:
  /// **'Exploración'**
  String get logroCatExploracion;

  /// No description provided for @nivelFacil.
  ///
  /// In es, this message translates to:
  /// **'Fácil'**
  String get nivelFacil;

  /// No description provided for @nivelMedio.
  ///
  /// In es, this message translates to:
  /// **'Medio'**
  String get nivelMedio;

  /// No description provided for @nivelDificil.
  ///
  /// In es, this message translates to:
  /// **'Difícil'**
  String get nivelDificil;

  /// No description provided for @logrosSubtitulo.
  ///
  /// In es, this message translates to:
  /// **'{descripcion}\n{categoria} · {nivel}'**
  String logrosSubtitulo(String descripcion, String categoria, String nivel);

  /// No description provided for @prodAvatarPerro.
  ///
  /// In es, this message translates to:
  /// **'Perro'**
  String get prodAvatarPerro;

  /// No description provided for @prodAvatarConejo.
  ///
  /// In es, this message translates to:
  /// **'Conejo'**
  String get prodAvatarConejo;

  /// No description provided for @prodAvatarKoala.
  ///
  /// In es, this message translates to:
  /// **'Koala'**
  String get prodAvatarKoala;

  /// No description provided for @prodAvatarPinguino.
  ///
  /// In es, this message translates to:
  /// **'Pingüino'**
  String get prodAvatarPinguino;

  /// No description provided for @prodAvatarLeon.
  ///
  /// In es, this message translates to:
  /// **'León'**
  String get prodAvatarLeon;

  /// No description provided for @prodDescAvatarPerro.
  ///
  /// In es, this message translates to:
  /// **'Avatar ilustrado de perro'**
  String get prodDescAvatarPerro;

  /// No description provided for @prodDescAvatarConejo.
  ///
  /// In es, this message translates to:
  /// **'Avatar ilustrado de conejo'**
  String get prodDescAvatarConejo;

  /// No description provided for @prodDescAvatarKoala.
  ///
  /// In es, this message translates to:
  /// **'Avatar ilustrado de koala'**
  String get prodDescAvatarKoala;

  /// No description provided for @prodDescAvatarPinguino.
  ///
  /// In es, this message translates to:
  /// **'Avatar ilustrado de pingüino'**
  String get prodDescAvatarPinguino;

  /// No description provided for @prodDescAvatarLeon.
  ///
  /// In es, this message translates to:
  /// **'Avatar ilustrado de león'**
  String get prodDescAvatarLeon;

  /// No description provided for @errorSinConexion.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión. Comprueba tu red e inténtalo de nuevo.'**
  String get errorSinConexion;

  /// No description provided for @errorTimeout.
  ///
  /// In es, this message translates to:
  /// **'La conexión ha tardado demasiado. Inténtalo de nuevo.'**
  String get errorTimeout;

  /// No description provided for @errorServidor.
  ///
  /// In es, this message translates to:
  /// **'El servidor no responde bien ahora mismo. Inténtalo en unos minutos.'**
  String get errorServidor;

  /// No description provided for @errorSesionCaducada.
  ///
  /// In es, this message translates to:
  /// **'Tu sesión ha caducado. Vuelve a iniciar sesión.'**
  String get errorSesionCaducada;

  /// No description provided for @errorRespuesta.
  ///
  /// In es, this message translates to:
  /// **'El servidor ha respondido algo que no esperábamos. Inténtalo de nuevo.'**
  String get errorRespuesta;

  /// No description provided for @errorGenerico.
  ///
  /// In es, this message translates to:
  /// **'No se pudo completar la operación. Inténtalo de nuevo.'**
  String get errorGenerico;

  /// No description provided for @loginCredenciales.
  ///
  /// In es, this message translates to:
  /// **'Email o contraseña incorrectos.'**
  String get loginCredenciales;
}

class _NordayCoreLocalizationsDelegate
    extends LocalizationsDelegate<NordayCoreLocalizations> {
  const _NordayCoreLocalizationsDelegate();

  @override
  Future<NordayCoreLocalizations> load(Locale locale) {
    return SynchronousFuture<NordayCoreLocalizations>(
      lookupNordayCoreLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_NordayCoreLocalizationsDelegate old) => false;
}

NordayCoreLocalizations lookupNordayCoreLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return NordayCoreLocalizationsEn();
    case 'es':
      return NordayCoreLocalizationsEs();
    case 'pt':
      return NordayCoreLocalizationsPt();
  }

  throw FlutterError(
    'NordayCoreLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
