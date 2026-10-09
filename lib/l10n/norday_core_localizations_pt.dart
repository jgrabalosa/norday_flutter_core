// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'norday_core_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class NordayCoreLocalizationsPt extends NordayCoreLocalizations {
  NordayCoreLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitulo => 'Norday Habits';

  @override
  String get idioma => 'Idioma';

  @override
  String get zonaHoraria => 'Fuso horário';

  @override
  String get preferencias => 'Preferências';

  @override
  String get idiomaEs => 'Espanhol';

  @override
  String get idiomaEn => 'Inglês';

  @override
  String get idiomaPt => 'Português';

  @override
  String get guardar => 'Guardar';

  @override
  String get cancelar => 'Cancelar';

  @override
  String get zonaDetectada => 'Detetado do teu dispositivo';

  @override
  String get logroBienvenido => 'Bem-vindo/a';

  @override
  String get logroLoginGoogle => 'Ligado com Google';

  @override
  String get logroPrimerosPasos => 'Primeiros passos';

  @override
  String get logroInteraccionResena => 'A tua opinião conta';

  @override
  String get logroIdentidadProfundidad => 'Sob as estrelas';

  @override
  String get logroIdentidadNeotokyoPlus => 'Luzes de néon';

  @override
  String get logroIdentidadDulce => 'Com carinho';

  @override
  String get logroMascotaCria => 'Saiu da casca';

  @override
  String get logroMascotaAdulto => 'A Nori cresceu';

  @override
  String get prodEscudoRacha => 'Escudo de sequência';

  @override
  String get prodAvatarZorro => 'Raposa';

  @override
  String get prodAvatarGato => 'Gato';

  @override
  String get prodAvatarBuho => 'Coruja';

  @override
  String get prodAvatarPanda => 'Panda';

  @override
  String get prodAvatarTortuga => 'Tartaruga';

  @override
  String get prodComidaBasica => 'Comida';

  @override
  String get preferenciasSubtitulo => 'Idioma e fuso horário';

  @override
  String get sonido => 'Som';

  @override
  String get sonidoOnboardingTitulo => 'Quer som?';

  @override
  String get sonidoOnboardingCuerpo =>
      'Pode ativar ou silenciar a música e os efeitos quando quiser.';

  @override
  String get cambiarZona => 'Alterar fuso horário';

  @override
  String get buscarZona => 'Procurar fuso';

  @override
  String get sinResultados => 'Sem resultados';

  @override
  String get preferenciasGuardadas => 'Preferências atualizadas';

  @override
  String get comunCerrar => 'Fechar';

  @override
  String get comunContinuar => 'Continuar';

  @override
  String get mascotaTitulo => 'Mascote';

  @override
  String get mascotaFaseHuevo => 'Ovo';

  @override
  String get mascotaFaseCria => 'Cria';

  @override
  String get mascotaFaseAdulto => 'Adulto';

  @override
  String get mascotaPonleNombre => 'Dá-lhe um nome';

  @override
  String get mascotaHintNombre => 'Nome do teu bicho';

  @override
  String get mascotaErrorNombre =>
      'Não foi possível guardar o nome. Tenta novamente.';

  @override
  String get mascotaAlimentar => 'Alimentar';

  @override
  String get mascotaErrorAlimentar =>
      'Não foi possível alimentar o teu bicho. Tenta novamente.';

  @override
  String mascotaNivel(int n) {
    return 'Nível $n';
  }

  @override
  String mascotaXp(int actual, int total) {
    return '$actual/$total XP';
  }

  @override
  String mascotaContexto(String fase, int nivel, String animo) {
    return '$fase · Nível $nivel · $animo';
  }

  @override
  String get mascotaAnimoHuevo => 'prestes a sair do ovo';

  @override
  String get mascotaAnimoFeliz => 'à vontade contigo';

  @override
  String get mascotaAnimoAtencion => 'a dormitar';

  @override
  String get mascotaAnimoTriste => 'com saudades tuas';

  @override
  String get mascotaAnimoTranquila => 'sem novidades';

  @override
  String mascotaSubidaNivel(int n) {
    return 'Nível $n!';
  }

  @override
  String get plantillaBeberAgua => 'Beber água';

  @override
  String detLogrosDe(int n, int total) {
    return '$n de $total conquistas';
  }

  @override
  String get perfilTitulo => 'A minha conta';

  @override
  String get perfilActualizado => 'Perfil atualizado ✅';

  @override
  String get perfilErrorGuardar =>
      'Não foi possível guardar o perfil. Tenta novamente.';

  @override
  String get perfilPassActualizada => 'Palavra-passe atualizada ✅';

  @override
  String get perfilErrorPass =>
      'Não foi possível alterar a palavra-passe. Verifica os dados e tenta novamente.';

  @override
  String get perfilErrorEliminar =>
      'Não foi possível eliminar a conta. Tenta novamente.';

  @override
  String get perfilEliminarTitulo => 'Eliminar a tua conta?';

  @override
  String get perfilEliminarCuerpo =>
      'Todos os teus hábitos, registos, sequências, conquistas e pontos serão apagados para sempre.\n\nEsta ação não pode ser anulada.';

  @override
  String get perfilUltimaConfirmacion => 'Última confirmação';

  @override
  String get perfilUltimaConfirmacionCuerpo =>
      'Tens a certeza absoluta? A tua conta e todos os teus dados serão eliminados definitivamente.';

  @override
  String get perfilNoVolver => 'Não, voltar';

  @override
  String get perfilSiEliminar => 'Sim, eliminar a minha conta';

  @override
  String get perfilLabelNombre => 'Nome';

  @override
  String get perfilLabelUsuario => 'Nome de utilizador';

  @override
  String get perfilLabelEmail => 'Email';

  @override
  String get perfilNombreVacio => 'O nome não pode estar vazio';

  @override
  String get perfilUsuarioVacio => 'O nome de utilizador não pode estar vazio';

  @override
  String get perfilEmailVacio => 'O email não pode estar vazio';

  @override
  String get perfilEmailInvalido => 'Introduz um email válido';

  @override
  String get perfilGestionadoGoogle => 'Gerido pela tua conta Google';

  @override
  String get perfilGuardarCambios => 'Guardar alterações';

  @override
  String get perfilPassActual => 'Palavra-passe atual';

  @override
  String get perfilPassNueva => 'Nova palavra-passe';

  @override
  String get perfilPassActualVacia => 'Introduz a tua palavra-passe atual';

  @override
  String get perfilPassNuevaVacia => 'Introduz a nova palavra-passe';

  @override
  String get perfilMinimo6 => 'Mínimo 6 caracteres';

  @override
  String get perfilCambiarPass => 'Alterar palavra-passe';

  @override
  String get perfilZonaPeligro => 'Zona de perigo';

  @override
  String get perfilEliminarCuenta => 'Eliminar a minha conta';

  @override
  String get loginTagline => 'Cria hábitos, transforma a tua vida';

  @override
  String get loginIniciarSesion => 'Entrar';

  @override
  String get loginRegistrarse => 'Criar conta';

  @override
  String get loginCrearCuenta => 'Criar conta';

  @override
  String get loginContinuarGoogle => 'Continuar com o Google';

  @override
  String get loginO => 'ou';

  @override
  String get loginLabelContrasena => 'Palavra-passe';

  @override
  String get loginOlvidasteContrasena => 'Esqueceste-te da palavra-passe?';

  @override
  String get loginError =>
      'Não foi possível concluir. Confirma os teus dados e tenta de novo.';

  @override
  String get loginCancelado =>
      'O início de sessão não foi concluído. Tenta de novo.';

  @override
  String get recTitulo => 'Recuperar palavra-passe';

  @override
  String get recIntro =>
      'Escreve o e-mail da tua conta e enviaremos um código para redefinires a palavra-passe.';

  @override
  String get recCodigoEnviado =>
      'Confirma o teu e-mail. Se o endereço estiver registado, enviamos um código de 6 dígitos (expira em 15 minutos).';

  @override
  String get recLabelCodigo => 'Código de 6 dígitos';

  @override
  String get recEscribeEmail => 'Escreve o teu e-mail';

  @override
  String get recRellenaCampos => 'Preenche o código e a nova palavra-passe';

  @override
  String get recBotonEnviar => 'Enviar código';

  @override
  String get recBotonRestablecer => 'Redefinir palavra-passe';

  @override
  String get recReenviar => 'Reenviar código';

  @override
  String get recRestablecida => 'Palavra-passe redefinida ✅ Já podes entrar';

  @override
  String get recErrorEnviar =>
      'Não foi possível enviar o código. Tenta de novo.';

  @override
  String get recError =>
      'Não foi possível redefinir a palavra-passe. Confirma o código e tenta de novo.';

  @override
  String get navHoy => 'Hoje';

  @override
  String get navColeccion => 'Coleção';

  @override
  String get dashCompletados => 'CONCLUÍDOS';

  @override
  String get puntos => 'pontos';

  @override
  String get tiendaTitulo => 'Loja';

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
  String tiendaPrecioConCantidad(int precio, int n) {
    return '$precio pts · tens $n';
  }

  @override
  String get tiendaError =>
      'Não foi possível concluir a operação. Tenta de novo.';

  @override
  String get tiendaPreviewNavHabitos => 'Hábitos';

  @override
  String get tiendaPreviewNavPerfil => 'Perfil';

  @override
  String get tiendaPreviewHabito2 => 'Meditar 5 min';

  @override
  String get tiendaPreviewQueCrack => 'mandou bem!';

  @override
  String get logrosTitulo => 'Conquistas';

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
  String get colSeccionConsumibles => 'Consumíveis';

  @override
  String get colSeccionTemas => 'Temas';

  @override
  String get colEligeAvatar => 'Escolhe o teu primeiro avatar grátis 👇';

  @override
  String colDescubre(String seccion) {
    return 'Descubra $seccion na loja →';
  }

  @override
  String get colSeleccionActual => 'A tua seleção atual';

  @override
  String colContador(int poseidos, int total) {
    return '$poseidos/$total';
  }

  @override
  String colCantidad(int n) {
    return 'x$n';
  }

  @override
  String get colSeActivaSolo => 'Ativa sozinho';

  @override
  String get colUsar => 'Usar';

  @override
  String get colError => 'Não foi possível concluir a operação. Tenta de novo.';

  @override
  String get obTitulo1 => 'Bem-vindo ao Norday! 🎉';

  @override
  String get obCuerpo1 =>
      'Cada hábito que concluíres dá-te pontos. Usa-os para desbloquear temas e mais na loja.';

  @override
  String get obTitulo2 => 'O teu companheiro cresce contigo 🐣';

  @override
  String get obCuerpo2 =>
      'Chama-se Nori e ganha experiência com cada hábito que concluis. Cuida dela e vê como evolui.';

  @override
  String get obSiguiente => 'Avançar';

  @override
  String get obEmpezar => 'Começar';

  @override
  String get valTitulo => 'Avaliação';

  @override
  String get valEditar => 'Editar avaliação';

  @override
  String get valComoTeSentiste => 'Como te sentiste?';

  @override
  String get valHintNota => 'Adiciona uma nota (opcional)';

  @override
  String get celLogroDesbloqueado => 'Conquista desbloqueada!';

  @override
  String get celGenial => 'Fantástico!';

  @override
  String get selElegirGratis => 'Escolher grátis';

  @override
  String get selError => 'Não foi possível escolher o avatar. Tenta de novo.';

  @override
  String get logroDescPrimerosPasos => 'Conclui o teu primeiro hábito';

  @override
  String get logroDescBienvenido => 'Personaliza o teu perfil de utilizador';

  @override
  String get logroDescLoginGoogle => 'Entra com a tua conta Google';

  @override
  String get logroDescInteraccionResena =>
      'Interage com a avaliação da aplicação no Google Play';

  @override
  String get logroDescIdentidadProfundidad => 'Obtém a identidade Profundidad';

  @override
  String get logroDescIdentidadNeotokyoPlus => 'Obtém a identidade Neotokyo+';

  @override
  String get logroDescIdentidadDulce => 'Obtém a identidade Dulce';

  @override
  String get logroDescMascotaCria => 'A tua mascote passa de ovo a cria';

  @override
  String get logroDescMascotaAdulto => 'A tua mascote passa de cria a adulta';

  @override
  String get prodDescEscudoRacha =>
      'Protege a tua sequência durante 1 dia se te esqueceres de concluir o teu hábito';

  @override
  String get prodDescTemaProfundidad =>
      'Uma viagem espacial entre constelações, estrelas cadentes e foguetões';

  @override
  String get prodDescTemaNeotokyoPlus =>
      'Néon sobre preto, ângulos cortados e letra técnica';

  @override
  String get prodDescTemaDulce =>
      'Rosa suave, formas de pílula e um toque manuscrito';

  @override
  String get prodDescAvatarZorro => 'Avatar ilustrado de raposa';

  @override
  String get prodDescAvatarGato => 'Avatar ilustrado de gato';

  @override
  String get prodDescAvatarBuho => 'Avatar ilustrado de coruja';

  @override
  String get prodDescAvatarPanda => 'Avatar ilustrado de panda';

  @override
  String get prodDescAvatarTortuga => 'Avatar ilustrado de tartaruga';

  @override
  String get prodDescComidaBasica =>
      'Alimenta a tua mascote e ganha experiência';

  @override
  String get logroCatInicio => 'Início';

  @override
  String get logroCatConstancia => 'Constância';

  @override
  String get logroCatVolumen => 'Volume';

  @override
  String get logroCatVariedad => 'Variedade';

  @override
  String get logroCatExploracion => 'Exploração';

  @override
  String get logroCatIdentidad => 'Identidade';

  @override
  String get logroCatMascota => 'Mascote';

  @override
  String get nivelFacil => 'Fácil';

  @override
  String get nivelMedio => 'Médio';

  @override
  String get nivelDificil => 'Difícil';

  @override
  String logrosSubtitulo(String descripcion, String categoria, String nivel) {
    return '$descripcion\n$categoria · $nivel';
  }

  @override
  String get prodAvatarPerro => 'Cachorro';

  @override
  String get prodAvatarConejo => 'Coelho';

  @override
  String get prodAvatarKoala => 'Coala';

  @override
  String get prodAvatarPinguino => 'Pinguim';

  @override
  String get prodAvatarLeon => 'Leão';

  @override
  String get prodDescAvatarPerro => 'Avatar ilustrado de cachorro';

  @override
  String get prodDescAvatarConejo => 'Avatar ilustrado de coelho';

  @override
  String get prodDescAvatarKoala => 'Avatar ilustrado de coala';

  @override
  String get prodDescAvatarPinguino => 'Avatar ilustrado de pinguim';

  @override
  String get prodDescAvatarLeon => 'Avatar ilustrado de leão';

  @override
  String get errorSinConexion =>
      'Sem ligação. Verifica a tua rede e tenta de novo.';

  @override
  String get errorTimeout => 'A ligação demorou demasiado. Tenta de novo.';

  @override
  String get errorServidor =>
      'O servidor não está a responder bem agora. Tenta dentro de alguns minutos.';

  @override
  String get errorSesionCaducada => 'A tua sessão expirou. Entra novamente.';

  @override
  String get errorRespuesta =>
      'O servidor respondeu de forma inesperada. Tenta de novo.';

  @override
  String get errorGenerico =>
      'Não foi possível concluir a operação. Tenta de novo.';

  @override
  String get loginCredenciales => 'E-mail ou palavra-passe incorretos.';

  @override
  String get identidadTitulo => 'Escolhe a tua identidade';

  @override
  String get identidadSubtitulo =>
      'É assim que a tua aplicação vai ficar. Desliza para veres as três; as restantes compram-se depois na loja.';

  @override
  String get identidadElegir => 'Escolher esta';

  @override
  String get identidadErrorGenerico =>
      'Não foi possível guardar a tua escolha.';

  @override
  String get identidadErrorCatalogo =>
      'Não foi possível carregar as identidades.';

  @override
  String get reintentar => 'Tentar novamente';

  @override
  String get tiendaAyudaEtiqueta => 'Ajuda sobre a loja';

  @override
  String get tiendaAyuda =>
      'Gasta aqui os teus pontos: comida para a Nori e temas.';

  @override
  String get constelacionPolar => 'Estrela Polar';

  @override
  String get constelacionPunteros => 'As Guardas';

  @override
  String get constelacionCinturon => 'Cintura de Oríon';

  @override
  String get constelacionCruzSur => 'Cruzeiro do Sul';

  @override
  String get constelacionCasiopea => 'Cassiopeia';

  @override
  String get constelacionLira => 'Lira';

  @override
  String get constelacionOsaMayor => 'Ursa Maior';

  @override
  String get constelacionOrion => 'Oríon';

  @override
  String get colAyudaEtiqueta => 'Ajuda sobre a coleção';

  @override
  String get colAyuda =>
      'O que já tens: equipa um tema ou usa o que compraste.';
}
