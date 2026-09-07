// material y no widgets: enSnackBar necesita ScaffoldMessenger y SnackBar.
// Este fichero era traducción pura; con el helper pasa a tocar UI.
import 'package:flutter/material.dart';
import '../services/api_error.dart';
import 'norday_core_localizations.dart';

/// Traduce un error de red al idioma activo, igual que [CatalogosCore] hace
/// con los codigos que manda el backend.
///
/// El texto crudo del backend nunca llega al usuario: responde en un solo
/// idioma y la app habla tres.
class MensajesError {
  /// [generico] es el mensaje propio de la pantalla ("No se pudo crear el
  /// habito"). Se usa cuando el fallo no es de red, que es justo cuando el
  /// contexto de la pantalla informa mas que un texto de conexion.
  static String de(BuildContext context, Object error, {String? generico}) {
    final l = NordayCoreLocalizations.of(context)!;
    if (error is! ApiException) return generico ?? l.errorGenerico;

    return switch (error.tipo) {
      TipoErrorApi.sinConexion => l.errorSinConexion,
      TipoErrorApi.timeout => l.errorTimeout,
      TipoErrorApi.servidor => l.errorServidor,
      TipoErrorApi.noAutorizado => l.errorSesionCaducada,
      TipoErrorApi.respuestaInesperada => l.errorRespuesta,
      TipoErrorApi.peticionInvalida => generico ?? l.errorGenerico,
    };
  }

  /// Enseña [error] en un SnackBar, ya traducido por [de].
  ///
  /// Comprobar `mounted` es responsabilidad de quien llama: esto no es un
  /// State y no puede saberlo. Todas las pantallas que lo usan lo hacen
  /// desde un `if (mounted)`.
  static void enSnackBar(BuildContext context, Object error, {String? generico}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(de(context, error, generico: generico))),
    );
  }
}
