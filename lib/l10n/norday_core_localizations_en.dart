// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'norday_core_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class NordayCoreLocalizationsEn extends NordayCoreLocalizations {
  NordayCoreLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitulo => 'Norday Habits';

  @override
  String get idioma => 'Language';

  @override
  String get zonaHoraria => 'Time zone';

  @override
  String get preferencias => 'Preferences';

  @override
  String get idiomaEs => 'Spanish';

  @override
  String get idiomaEn => 'English';

  @override
  String get idiomaPt => 'Portuguese';

  @override
  String get guardar => 'Save';

  @override
  String get cancelar => 'Cancel';

  @override
  String get zonaDetectada => 'Detected from your device';

  @override
  String get zonaAyuda =>
      'It defines when your day starts and ends for streaks and reminders.';

  @override
  String get logroBienvenido => 'Welcome';

  @override
  String get logroLoginGoogle => 'Connected with Google';

  @override
  String get logroPrimerosPasos => 'First steps';

  @override
  String get logroInteraccionResena => 'Your opinion counts';

  @override
  String get prodEscudoRacha => 'Streak shield';

  @override
  String get prodTemaBasicoClaro => 'Basic Light';

  @override
  String get prodTemaBasicoOscuro => 'Basic Dark';

  @override
  String get prodTemaCalidez => 'Warmth';

  @override
  String get prodTemaNeotokyo => 'Neo-Tokyo';

  @override
  String get prodTemaOceano => 'Ocean';

  @override
  String get prodTemaBosque => 'Forest';

  @override
  String get prodTemaCobre => 'Night Copper';

  @override
  String get prodAvatarZorro => 'Fox';

  @override
  String get prodAvatarGato => 'Cat';

  @override
  String get prodAvatarBuho => 'Owl';

  @override
  String get prodAvatarPanda => 'Panda';

  @override
  String get prodAvatarTortuga => 'Turtle';

  @override
  String get prodComidaBasica => 'Food';

  @override
  String get preferenciasSubtitulo => 'Language and time zone';

  @override
  String get cambiarZona => 'Change time zone';

  @override
  String get buscarZona => 'Search zone';

  @override
  String get sinResultados => 'No results';

  @override
  String get preferenciasGuardadas => 'Preferences updated';

  @override
  String get comunCerrar => 'Close';

  @override
  String get comunContinuar => 'Continue';

  @override
  String get mascotaTitulo => 'Pet';

  @override
  String get mascotaFaseHuevo => 'Egg';

  @override
  String get mascotaFaseCria => 'Hatchling';

  @override
  String get mascotaFaseAdulto => 'Adult';

  @override
  String get mascotaEstadoFeliz => 'Happy';

  @override
  String get mascotaEstadoAtencion => 'Needs care';

  @override
  String get mascotaEstadoTranquila => 'Calm';

  @override
  String get mascotaEstadoTriste => 'Sad';

  @override
  String get mascotaPonleNombre => 'Give it a name';

  @override
  String get mascotaHintNombre => 'Your pet\'s name';

  @override
  String get mascotaErrorNombre => 'Couldn\'t save the name. Please try again.';

  @override
  String get mascotaAlimentar => 'Feed';

  @override
  String get mascotaErrorAlimentar =>
      'Couldn\'t feed your pet. Please try again.';

  @override
  String mascotaNivel(int n) {
    return 'Level $n';
  }

  @override
  String mascotaXp(int actual, int total) {
    return '$actual/$total XP';
  }

  @override
  String mascotaContexto(String fase, int nivel, String animo) {
    return '$fase · Level $nivel · $animo';
  }

  @override
  String get mascotaAnimoHuevo => 'about to hatch';

  @override
  String get mascotaAnimoFeliz => 'happy with you';

  @override
  String get mascotaAnimoAtencion => 'taking a nap';

  @override
  String get mascotaAnimoTriste => 'missing you';

  @override
  String get mascotaAnimoTranquila => 'nothing new';

  @override
  String mascotaSubidaNivel(int n) {
    return 'Level $n!';
  }

  @override
  String get plantillaBeberAgua => 'Drink water';

  @override
  String detLogrosDe(int n, int total) {
    return '$n of $total achievements';
  }

  @override
  String get perfilTitulo => 'My account';

  @override
  String get perfilActualizado => 'Profile updated ✅';

  @override
  String get perfilErrorGuardar =>
      'Couldn\'t save your profile. Please try again.';

  @override
  String get perfilPassActualizada => 'Password updated ✅';

  @override
  String get perfilErrorPass =>
      'Couldn\'t change your password. Check the details and try again.';

  @override
  String get perfilErrorEliminar =>
      'Couldn\'t delete your account. Please try again.';

  @override
  String get perfilEliminarTitulo => 'Delete your account?';

  @override
  String get perfilEliminarCuerpo =>
      'All your habits, entries, streaks, achievements and points will be gone for good.\n\nThis can\'t be undone.';

  @override
  String get perfilUltimaConfirmacion => 'Last confirmation';

  @override
  String get perfilUltimaConfirmacionCuerpo =>
      'Are you absolutely sure? Your account and all your data will be permanently deleted.';

  @override
  String get perfilNoVolver => 'No, go back';

  @override
  String get perfilSiEliminar => 'Yes, delete my account';

  @override
  String get perfilLabelNombre => 'Name';

  @override
  String get perfilLabelUsuario => 'Username';

  @override
  String get perfilLabelEmail => 'Email';

  @override
  String get perfilNombreVacio => 'Name can\'t be empty';

  @override
  String get perfilUsuarioVacio => 'Username can\'t be empty';

  @override
  String get perfilEmailVacio => 'Email can\'t be empty';

  @override
  String get perfilEmailInvalido => 'Enter a valid email';

  @override
  String get perfilGestionadoGoogle => 'Managed by your Google account';

  @override
  String get perfilGuardarCambios => 'Save changes';

  @override
  String get perfilPassActual => 'Current password';

  @override
  String get perfilPassNueva => 'New password';

  @override
  String get perfilPassActualVacia => 'Enter your current password';

  @override
  String get perfilPassNuevaVacia => 'Enter the new password';

  @override
  String get perfilMinimo6 => 'At least 6 characters';

  @override
  String get perfilCambiarPass => 'Change password';

  @override
  String get perfilZonaPeligro => 'Danger zone';

  @override
  String get perfilEliminarCuenta => 'Delete my account';

  @override
  String get loginTagline => 'Build habits, transform your life';

  @override
  String get loginIniciarSesion => 'Log in';

  @override
  String get loginRegistrarse => 'Sign up';

  @override
  String get loginCrearCuenta => 'Create account';

  @override
  String get loginContinuarGoogle => 'Continue with Google';

  @override
  String get loginO => 'or';

  @override
  String get loginLabelContrasena => 'Password';

  @override
  String get loginOlvidasteContrasena => 'Forgot your password?';

  @override
  String get loginError =>
      'Something went wrong. Check your details and try again.';

  @override
  String get recTitulo => 'Reset password';

  @override
  String get recIntro =>
      'Enter your account email and we\'ll send you a code to reset your password.';

  @override
  String get recCodigoEnviado =>
      'Check your inbox. If the email is registered, we\'ve sent you a 6-digit code (it expires in 15 minutes).';

  @override
  String get recLabelCodigo => '6-digit code';

  @override
  String get recEscribeEmail => 'Enter your email';

  @override
  String get recRellenaCampos => 'Fill in the code and the new password';

  @override
  String get recBotonEnviar => 'Send code';

  @override
  String get recBotonRestablecer => 'Reset password';

  @override
  String get recReenviar => 'Resend code';

  @override
  String get recRestablecida => 'Password reset ✅ You can log in now';

  @override
  String get recErrorEnviar => 'The code couldn\'t be sent. Please try again.';

  @override
  String get recError =>
      'The password couldn\'t be reset. Check the code and try again.';

  @override
  String get navHoy => 'Today';

  @override
  String get navColeccion => 'Collection';

  @override
  String get dashCompletados => 'COMPLETED';

  @override
  String get puntos => 'points';

  @override
  String get tiendaTitulo => 'Shop';

  @override
  String get tiendaCatalogo => 'Catalogue';

  @override
  String get tiendaComprar => 'Buy';

  @override
  String get tiendaEquipar => 'Equip';

  @override
  String get tiendaEquipado => 'Equipped';

  @override
  String tiendaPrecio(int n) {
    return '$n pts';
  }

  @override
  String tiendaUsar(int n) {
    return 'Use (x$n)';
  }

  @override
  String get tiendaError => 'Something went wrong. Please try again.';

  @override
  String get tiendaPreviewNavHabitos => 'Habits';

  @override
  String get tiendaPreviewNavPerfil => 'Profile';

  @override
  String get tiendaPreviewHabito2 => 'Meditate 5 min';

  @override
  String get tiendaPreviewQueCrack => 'nice one!';

  @override
  String get logrosTitulo => 'My achievements';

  @override
  String get logrosSeccion => 'Achievements';

  @override
  String logrosPorcentaje(int n) {
    return '$n%';
  }

  @override
  String logrosPuntos(int n) {
    return '+$n pts';
  }

  @override
  String get colSeccionAvatares => 'Avatars';

  @override
  String get colSeccionConsumibles => 'Consumables';

  @override
  String get colSeccionTemas => 'Themes';

  @override
  String get colEligeAvatar => 'Pick your first free avatar 👇';

  @override
  String colDescubre(String seccion) {
    return 'Discover $seccion in the shop →';
  }

  @override
  String get colSeleccionActual => 'Your current setup';

  @override
  String colContador(int poseidos, int total) {
    return '$poseidos/$total';
  }

  @override
  String colCantidad(int n) {
    return 'x$n';
  }

  @override
  String get colSeActivaSolo => 'Activates on its own';

  @override
  String get colUsar => 'Use';

  @override
  String get colError => 'Something went wrong. Please try again.';

  @override
  String get obTitulo1 => 'Welcome to Norday! 🎉';

  @override
  String get obCuerpo1 =>
      'Every habit you complete earns you points. Spend them on avatars, themes and more in the shop.';

  @override
  String get obTitulo2 => 'Your companion grows with you 🐣';

  @override
  String get obCuerpo2 =>
      'You have a pet that levels up every time you complete a habit. Take care of it and watch it evolve.';

  @override
  String get obTitulo3 => 'Pick your first avatar — it\'s free! 👇';

  @override
  String get obCuerpo3 => 'You can change it anytime from your Collection.';

  @override
  String get obSiguiente => 'Next';

  @override
  String get valTitulo => 'Rating';

  @override
  String get valEditar => 'Edit rating';

  @override
  String get valComoTeSentiste => 'How did it feel?';

  @override
  String get valHintNota => 'Add a note (optional)';

  @override
  String get celLogroDesbloqueado => 'Achievement unlocked!';

  @override
  String get celGenial => 'Awesome!';

  @override
  String get selElegirGratis => 'Choose for free';

  @override
  String get selError => 'The avatar couldn\'t be selected. Please try again.';

  @override
  String get logroDescPrimerosPasos => 'Complete your first habit';

  @override
  String get logroDescBienvenido => 'Customize your user profile';

  @override
  String get logroDescLoginGoogle => 'Log in with your Google account';

  @override
  String get logroDescInteraccionResena =>
      'Interact with the app\'s rating on Google Play';

  @override
  String get prodDescEscudoRacha =>
      'Protects your streak for 1 day if you forget to complete your habit';

  @override
  String get prodDescTemaBasicoClaro => 'Norday\'s default light theme';

  @override
  String get prodDescTemaBasicoOscuro => 'Norday\'s default dark theme';

  @override
  String get prodDescTemaCalidez =>
      'A premium theme with warm, welcoming tones';

  @override
  String get prodDescTemaNeotokyo =>
      'A premium theme inspired by anime and neon aesthetics';

  @override
  String get prodDescTemaOceano =>
      'A premium theme with cool blue tones from the sea';

  @override
  String get prodDescTemaBosque => 'A premium theme with green, natural tones';

  @override
  String get prodDescTemaCobre =>
      'An elegant premium theme in midnight blue and copper';

  @override
  String get prodDescAvatarZorro => 'Illustrated fox avatar';

  @override
  String get prodDescAvatarGato => 'Illustrated cat avatar';

  @override
  String get prodDescAvatarBuho => 'Illustrated owl avatar';

  @override
  String get prodDescAvatarPanda => 'Illustrated panda avatar';

  @override
  String get prodDescAvatarTortuga => 'Illustrated turtle avatar';

  @override
  String get prodDescComidaBasica => 'Feed your pet and earn experience';

  @override
  String get logroCatInicio => 'Getting started';

  @override
  String get logroCatConstancia => 'Consistency';

  @override
  String get logroCatVolumen => 'Volume';

  @override
  String get logroCatVariedad => 'Variety';

  @override
  String get logroCatExploracion => 'Exploration';

  @override
  String get nivelFacil => 'Easy';

  @override
  String get nivelMedio => 'Medium';

  @override
  String get nivelDificil => 'Hard';

  @override
  String logrosSubtitulo(String descripcion, String categoria, String nivel) {
    return '$descripcion\n$categoria · $nivel';
  }

  @override
  String get prodAvatarPerro => 'Dog';

  @override
  String get prodAvatarConejo => 'Rabbit';

  @override
  String get prodAvatarKoala => 'Koala';

  @override
  String get prodAvatarPinguino => 'Penguin';

  @override
  String get prodAvatarLeon => 'Lion';

  @override
  String get prodDescAvatarPerro => 'Illustrated dog avatar';

  @override
  String get prodDescAvatarConejo => 'Illustrated rabbit avatar';

  @override
  String get prodDescAvatarKoala => 'Illustrated koala avatar';

  @override
  String get prodDescAvatarPinguino => 'Illustrated penguin avatar';

  @override
  String get prodDescAvatarLeon => 'Illustrated lion avatar';

  @override
  String get errorSinConexion =>
      'No connection. Check your network and try again.';

  @override
  String get errorTimeout => 'The connection took too long. Please try again.';

  @override
  String get errorServidor =>
      'The server isn\'t responding properly right now. Try again in a few minutes.';

  @override
  String get errorSesionCaducada =>
      'Your session has expired. Please sign in again.';

  @override
  String get errorRespuesta =>
      'The server returned something unexpected. Please try again.';

  @override
  String get errorGenerico => 'Something went wrong. Please try again.';

  @override
  String get loginCredenciales => 'Incorrect email or password.';

  @override
  String get identidadTitulo => 'Choose your identity';

  @override
  String get identidadSubtitulo =>
      'This is how your app will look. Swipe to see all four.';

  @override
  String get identidadElegir => 'Choose this one';

  @override
  String get identidadErrorGenerico => 'Your choice could not be saved.';

  @override
  String get identidadErrorCatalogo => 'The identities could not be loaded.';

  @override
  String get reintentar => 'Retry';
}
