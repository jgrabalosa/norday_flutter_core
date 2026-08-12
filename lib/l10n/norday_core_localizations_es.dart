// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'norday_core_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class NordayCoreLocalizationsEs extends NordayCoreLocalizations {
  NordayCoreLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitulo => 'Norday Habits';

  @override
  String get idioma => 'Idioma';

  @override
  String get zonaHoraria => 'Zona horaria';

  @override
  String get preferencias => 'Preferencias';

  @override
  String get idiomaEs => 'Español';

  @override
  String get idiomaEn => 'Inglés';

  @override
  String get idiomaPt => 'Portugués';

  @override
  String get guardar => 'Guardar';

  @override
  String get cancelar => 'Cancelar';

  @override
  String get zonaDetectada => 'Detectada de tu dispositivo';

  @override
  String get zonaAyuda =>
      'Define cuándo empieza y acaba tu día para las rachas y los recordatorios.';

  @override
  String get logroBienvenido => 'Bienvenido/a';

  @override
  String get logroLoginGoogle => 'Conectado con Google';

  @override
  String get logroPrimerosPasos => 'Primeros pasos';

  @override
  String get logroInteraccionResena => 'Tu opinión cuenta';

  @override
  String get prodEscudoRacha => 'Escudo de racha';

  @override
  String get prodTemaBasicoClaro => 'Básico Claro';

  @override
  String get prodTemaBasicoOscuro => 'Básico Oscuro';

  @override
  String get prodTemaCalidez => 'Calidez';

  @override
  String get prodTemaNeotokyo => 'Neo-Tokyo';

  @override
  String get prodTemaOceano => 'Océano';

  @override
  String get prodTemaBosque => 'Bosque';

  @override
  String get prodTemaCobre => 'Cobre Nocturno';

  @override
  String get prodAvatarZorro => 'Zorro';

  @override
  String get prodAvatarGato => 'Gato';

  @override
  String get prodAvatarBuho => 'Búho';

  @override
  String get prodAvatarPanda => 'Panda';

  @override
  String get prodAvatarTortuga => 'Tortuga';

  @override
  String get prodComidaBasica => 'Comida';

  @override
  String get preferenciasSubtitulo => 'Idioma y zona horaria';

  @override
  String get cambiarZona => 'Cambiar zona horaria';

  @override
  String get buscarZona => 'Buscar zona';

  @override
  String get sinResultados => 'Sin resultados';

  @override
  String get preferenciasGuardadas => 'Preferencias actualizadas';

  @override
  String get comunCerrar => 'Cerrar';

  @override
  String get comunContinuar => 'Continuar';

  @override
  String get mascotaTitulo => 'Mascota';

  @override
  String get mascotaFaseHuevo => 'Huevo';

  @override
  String get mascotaFaseCria => 'Cría';

  @override
  String get mascotaFaseAdulto => 'Adulto';

  @override
  String get mascotaEstadoFeliz => 'Feliz';

  @override
  String get mascotaEstadoAtencion => 'Necesita atención';

  @override
  String get mascotaEstadoTranquila => 'Tranquila';

  @override
  String get mascotaEstadoTriste => 'Triste';

  @override
  String get mascotaPonleNombre => 'Ponle nombre';

  @override
  String get mascotaHintNombre => 'Nombre de tu mascota';

  @override
  String get mascotaErrorNombre =>
      'No se pudo guardar el nombre. Inténtalo de nuevo.';

  @override
  String get mascotaAlimentar => 'Alimentar';

  @override
  String get mascotaErrorAlimentar =>
      'No se pudo alimentar a tu mascota. Inténtalo de nuevo.';

  @override
  String mascotaNivel(int n) {
    return 'Nivel $n';
  }

  @override
  String mascotaXp(int actual, int total) {
    return '$actual/$total XP';
  }

  @override
  String mascotaContexto(String fase, int nivel, String animo) {
    return '$fase · Nivel $nivel · $animo';
  }

  @override
  String get mascotaAnimoHuevo => 'a punto de romper el cascarón';

  @override
  String get mascotaAnimoFeliz => 'a gusto contigo';

  @override
  String get mascotaAnimoAtencion => 'echando una cabezada';

  @override
  String get mascotaAnimoTriste => 'te echa de menos';

  @override
  String get mascotaAnimoTranquila => 'sin novedad';

  @override
  String mascotaSubidaNivel(int n) {
    return '¡Nivel $n!';
  }

  @override
  String get plantillaBeberAgua => 'Beber agua';

  @override
  String detLogrosDe(int n, int total) {
    return '$n de $total logros';
  }

  @override
  String get perfilTitulo => 'Mi cuenta';

  @override
  String get perfilActualizado => 'Perfil actualizado ✅';

  @override
  String get perfilErrorGuardar =>
      'No se pudo guardar el perfil. Inténtalo de nuevo.';

  @override
  String get perfilPassActualizada => 'Contraseña actualizada ✅';

  @override
  String get perfilErrorPass =>
      'No se pudo cambiar la contraseña. Revisa los datos e inténtalo de nuevo.';

  @override
  String get perfilErrorEliminar =>
      'No se pudo eliminar la cuenta. Inténtalo de nuevo.';

  @override
  String get perfilEliminarTitulo => '¿Eliminar tu cuenta?';

  @override
  String get perfilEliminarCuerpo =>
      'Se borrarán para siempre todos tus hábitos, registros, rachas, logros y puntos.\n\nEsta acción no se puede deshacer.';

  @override
  String get perfilUltimaConfirmacion => 'Última confirmación';

  @override
  String get perfilUltimaConfirmacionCuerpo =>
      '¿Estás completamente seguro? Tu cuenta y todos tus datos se eliminarán de forma definitiva.';

  @override
  String get perfilNoVolver => 'No, volver';

  @override
  String get perfilSiEliminar => 'Sí, eliminar mi cuenta';

  @override
  String get perfilLabelNombre => 'Nombre';

  @override
  String get perfilLabelUsuario => 'Nombre de usuario';

  @override
  String get perfilLabelEmail => 'Email';

  @override
  String get perfilNombreVacio => 'El nombre no puede estar vacío';

  @override
  String get perfilUsuarioVacio => 'El nombre de usuario no puede estar vacío';

  @override
  String get perfilEmailVacio => 'El email no puede estar vacío';

  @override
  String get perfilEmailInvalido => 'Introduce un email válido';

  @override
  String get perfilGestionadoGoogle => 'Gestionado por tu cuenta de Google';

  @override
  String get perfilGuardarCambios => 'Guardar cambios';

  @override
  String get perfilPassActual => 'Contraseña actual';

  @override
  String get perfilPassNueva => 'Nueva contraseña';

  @override
  String get perfilPassActualVacia => 'Introduce tu contraseña actual';

  @override
  String get perfilPassNuevaVacia => 'Introduce la nueva contraseña';

  @override
  String get perfilMinimo6 => 'Mínimo 6 caracteres';

  @override
  String get perfilCambiarPass => 'Cambiar contraseña';

  @override
  String get perfilZonaPeligro => 'Zona de peligro';

  @override
  String get perfilEliminarCuenta => 'Eliminar mi cuenta';

  @override
  String get loginTagline => 'Construye hábitos, transforma tu vida';

  @override
  String get loginIniciarSesion => 'Iniciar sesión';

  @override
  String get loginRegistrarse => 'Registrarse';

  @override
  String get loginCrearCuenta => 'Crear cuenta';

  @override
  String get loginContinuarGoogle => 'Continuar con Google';

  @override
  String get loginO => 'o';

  @override
  String get loginLabelContrasena => 'Contraseña';

  @override
  String get loginOlvidasteContrasena => '¿Olvidaste tu contraseña?';

  @override
  String get loginError =>
      'No se pudo completar. Revisa tus datos e inténtalo de nuevo.';

  @override
  String get recTitulo => 'Recuperar contraseña';

  @override
  String get recIntro =>
      'Escribe el email de tu cuenta y te enviaremos un código para restablecer la contraseña.';

  @override
  String get recCodigoEnviado =>
      'Revisa tu correo. Si el email está registrado, te hemos enviado un código de 6 dígitos (caduca en 15 minutos).';

  @override
  String get recLabelCodigo => 'Código de 6 dígitos';

  @override
  String get recEscribeEmail => 'Escribe tu email';

  @override
  String get recRellenaCampos => 'Rellena el código y la nueva contraseña';

  @override
  String get recBotonEnviar => 'Enviar código';

  @override
  String get recBotonRestablecer => 'Restablecer contraseña';

  @override
  String get recReenviar => 'Reenviar código';

  @override
  String get recRestablecida =>
      'Contraseña restablecida ✅ Ya puedes iniciar sesión';

  @override
  String get recErrorEnviar =>
      'No se pudo enviar el código. Inténtalo de nuevo.';

  @override
  String get recError =>
      'No se pudo restablecer la contraseña. Revisa el código e inténtalo de nuevo.';

  @override
  String get navHoy => 'Hoy';

  @override
  String get navColeccion => 'Colección';

  @override
  String get dashCompletados => 'COMPLETADOS';

  @override
  String get puntos => 'puntos';

  @override
  String get tiendaTitulo => 'Tienda';

  @override
  String get tiendaCatalogo => 'Catálogo';

  @override
  String get tiendaComprar => 'Comprar';

  @override
  String get tiendaEquipar => 'Equipar';

  @override
  String get tiendaEquipado => 'Equipado';

  @override
  String tiendaPrecio(int n) {
    return '$n pts';
  }

  @override
  String tiendaUsar(int n) {
    return 'Usar (x$n)';
  }

  @override
  String get tiendaError =>
      'No se pudo completar la operación. Inténtalo de nuevo.';

  @override
  String get tiendaPreviewNavHabitos => 'Hábitos';

  @override
  String get tiendaPreviewNavPerfil => 'Perfil';

  @override
  String get tiendaPreviewHabito2 => 'Meditar 5 min';

  @override
  String get tiendaPreviewQueCrack => '¡qué crack!';

  @override
  String get logrosTitulo => 'Mis logros';

  @override
  String get logrosSeccion => 'Logros';

  @override
  String logrosPorcentaje(int n) {
    return '$n%';
  }

  @override
  String logrosPuntos(int n) {
    return '+$n pts';
  }

  @override
  String get colSeccionAvatares => 'Avatares';

  @override
  String get colSeccionConsumibles => 'Consumibles';

  @override
  String get colSeccionTemas => 'Temas';

  @override
  String get colEligeAvatar => 'Elige tu primer avatar gratis 👇';

  @override
  String colDescubre(String seccion) {
    return 'Descubre $seccion en la tienda →';
  }

  @override
  String get colSeleccionActual => 'Tu selección actual';

  @override
  String colContador(int poseidos, int total) {
    return '$poseidos/$total';
  }

  @override
  String colCantidad(int n) {
    return 'x$n';
  }

  @override
  String get colSeActivaSolo => 'Se activa solo';

  @override
  String get colUsar => 'Usar';

  @override
  String get colError =>
      'No se pudo completar la operación. Inténtalo de nuevo.';

  @override
  String get obTitulo1 => '¡Bienvenido a Norday! 🎉';

  @override
  String get obCuerpo1 =>
      'Cada hábito que completes te da puntos. Úsalos para desbloquear avatares, temas y más en la tienda.';

  @override
  String get obTitulo2 => 'Tu compañero crece contigo 🐣';

  @override
  String get obCuerpo2 =>
      'Tienes una mascota que sube de nivel cada vez que completas un hábito. Cuídala y mira cómo evoluciona.';

  @override
  String get obTitulo3 => 'Elige tu primer avatar, ¡es gratis! 👇';

  @override
  String get obCuerpo3 => 'Podrás cambiarlo cuando quieras desde la Colección.';

  @override
  String get obSiguiente => 'Siguiente';

  @override
  String get valTitulo => 'Valoración';

  @override
  String get valEditar => 'Editar valoración';

  @override
  String get valComoTeSentiste => '¿Cómo te sentiste?';

  @override
  String get valHintNota => 'Añade una nota (opcional)';

  @override
  String get celLogroDesbloqueado => '¡Logro desbloqueado!';

  @override
  String get celGenial => '¡Genial!';

  @override
  String get selElegirGratis => 'Elegir gratis';

  @override
  String get selError => 'No se pudo elegir el avatar. Inténtalo de nuevo.';

  @override
  String get logroDescPrimerosPasos => 'Completa tu primer hábito';

  @override
  String get logroDescBienvenido => 'Personaliza tu perfil de usuario';

  @override
  String get logroDescLoginGoogle => 'Inicia sesión usando tu cuenta de Google';

  @override
  String get logroDescInteraccionResena =>
      'Interactúa con la valoración de la app en Google Play';

  @override
  String get prodDescEscudoRacha =>
      'Protege tu racha durante 1 día si olvidas completar tu hábito';

  @override
  String get prodDescTemaBasicoClaro => 'El tema claro de serie de Norday';

  @override
  String get prodDescTemaBasicoOscuro => 'El tema oscuro de serie de Norday';

  @override
  String get prodDescTemaCalidez =>
      'Un tema premium con tonos cálidos y acogedores';

  @override
  String get prodDescTemaNeotokyo =>
      'Un tema premium inspirado en la estética anime y neón';

  @override
  String get prodDescTemaOceano =>
      'Un tema premium con tonos azules y frescos del mar';

  @override
  String get prodDescTemaBosque =>
      'Un tema premium con tonos verdes y naturales';

  @override
  String get prodDescTemaCobre =>
      'Un tema premium elegante en azul noche y cobre';

  @override
  String get prodDescAvatarZorro => 'Avatar ilustrado de zorro';

  @override
  String get prodDescAvatarGato => 'Avatar ilustrado de gato';

  @override
  String get prodDescAvatarBuho => 'Avatar ilustrado de búho';

  @override
  String get prodDescAvatarPanda => 'Avatar ilustrado de panda';

  @override
  String get prodDescAvatarTortuga => 'Avatar ilustrado de tortuga';

  @override
  String get prodDescComidaBasica => 'Alimenta a tu mascota y gana experiencia';

  @override
  String get logroCatInicio => 'Inicio';

  @override
  String get logroCatConstancia => 'Constancia';

  @override
  String get logroCatVolumen => 'Volumen';

  @override
  String get logroCatVariedad => 'Variedad';

  @override
  String get logroCatExploracion => 'Exploración';

  @override
  String get nivelFacil => 'Fácil';

  @override
  String get nivelMedio => 'Medio';

  @override
  String get nivelDificil => 'Difícil';

  @override
  String logrosSubtitulo(String descripcion, String categoria, String nivel) {
    return '$descripcion\n$categoria · $nivel';
  }

  @override
  String get prodAvatarPerro => 'Perro';

  @override
  String get prodAvatarConejo => 'Conejo';

  @override
  String get prodAvatarKoala => 'Koala';

  @override
  String get prodAvatarPinguino => 'Pingüino';

  @override
  String get prodAvatarLeon => 'León';

  @override
  String get prodDescAvatarPerro => 'Avatar ilustrado de perro';

  @override
  String get prodDescAvatarConejo => 'Avatar ilustrado de conejo';

  @override
  String get prodDescAvatarKoala => 'Avatar ilustrado de koala';

  @override
  String get prodDescAvatarPinguino => 'Avatar ilustrado de pingüino';

  @override
  String get prodDescAvatarLeon => 'Avatar ilustrado de león';

  @override
  String get errorSinConexion =>
      'Sin conexión. Comprueba tu red e inténtalo de nuevo.';

  @override
  String get errorTimeout =>
      'La conexión ha tardado demasiado. Inténtalo de nuevo.';

  @override
  String get errorServidor =>
      'El servidor no responde bien ahora mismo. Inténtalo en unos minutos.';

  @override
  String get errorSesionCaducada =>
      'Tu sesión ha caducado. Vuelve a iniciar sesión.';

  @override
  String get errorRespuesta =>
      'El servidor ha respondido algo que no esperábamos. Inténtalo de nuevo.';

  @override
  String get errorGenerico =>
      'No se pudo completar la operación. Inténtalo de nuevo.';

  @override
  String get loginCredenciales => 'Email o contraseña incorrectos.';
}
