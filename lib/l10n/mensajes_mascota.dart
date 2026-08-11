import 'norday_core_localizations.dart';

/// Los textos de la mascota que se componen a partir de lo que manda el
/// backend, en un solo sitio: la fase, el estado y la frase de contexto.
///
/// Vive en el motor, así que no puede nombrar ningún concepto de dominio —ni
/// "hábito", ni "registro", ni por qué la mascota está como está—. Sólo sabe
/// que hay una fase, un estado y un nivel.
class MensajesMascota {
  /// Fase traducida. Caída al código crudo si llega una que este cliente aún
  /// no conoce, igual que hace `CatalogosCore`: nunca se deja al usuario sin
  /// texto, pero tampoco se le inventa uno.
  static String fase(NordayCoreLocalizations l, String? codigo) =>
      switch (codigo) {
        'HUEVO' => l.mascotaFaseHuevo,
        'CRIA' => l.mascotaFaseCria,
        'ADULTO' => l.mascotaFaseAdulto,
        _ => codigo ?? '',
      };

  /// Los tres estados que manda el backend, explícitos. La caída sólo cubre
  /// uno futuro que este cliente aún no conozca: mejor "Tranquila" que un
  /// código crudo o una alarma que no toca.
  static String estado(NordayCoreLocalizations l, String? codigo) =>
      switch (codigo) {
        'feliz' => l.mascotaEstadoFeliz,
        'dormida' => l.mascotaEstadoAtencion,
        'triste' => l.mascotaEstadoTriste,
        _ => l.mascotaEstadoTranquila,
      };

  /// La frase corta que acompaña a la mascota: "Cría · Nivel 3 · a gusto
  /// contigo".
  ///
  /// Compone los tres datos que ya existen —fase, estado y nivel— en vez de
  /// enumerarlos separados por puntos, que era lo que había y no decía nada
  /// que no dijeran ya las etiquetas. No cuenta días ni rachas: ese dato no
  /// existe todavía, y cuando exista entra aquí sin tocar la pantalla.
  ///
  /// Dentro del huevo el estado no se menciona: lo único que importa —y lo
  /// único que se ve— es que está a punto de salir.
  static String contexto(
    NordayCoreLocalizations l, {
    required String? codigoFase,
    required String? codigoEstado,
    required int nivel,
  }) {
    final animo = codigoFase == 'HUEVO'
        ? l.mascotaAnimoHuevo
        : switch (codigoEstado) {
            'feliz' => l.mascotaAnimoFeliz,
            'dormida' => l.mascotaAnimoAtencion,
            'triste' => l.mascotaAnimoTriste,
            _ => l.mascotaAnimoTranquila,
          };

    return l.mascotaContexto(fase(l, codigoFase), nivel, animo);
  }
}
