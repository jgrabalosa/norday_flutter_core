/// Motor: traduce el par (fase, estado) que manda el backend a la ilustración
/// que le toca. Único sitio donde vive ese mapeo — MascotaScreen, MiniMascota
/// y el onboarding piden la ruta aquí en vez de repetir el switch.
///
/// Los ficheros se llaman `Nori_{fase}_{estado}.png` con la fase en minúscula
/// y el estado en su forma visual, que no es la del backend:
/// `feliz→sonriente`, `triste→triste`, `dormida→dormido`,
/// `exultante→exultante`.
library;

/// Estado del backend → sufijo del fichero.
const Map<String, String> _sufijoDeEstado = {
  'feliz': 'sonriente',
  'triste': 'triste',
  'dormida': 'dormido',
  'exultante': 'exultante',
};

const Set<String> _fasesConocidas = {'huevo', 'cria', 'adulto'};

/// Con lo que se pinta cuando el backend manda algo que este cliente aún no
/// conoce. Mismo criterio que `Catalogos`: nunca dejar al usuario sin nada,
/// y ante la duda no dar por hecho que la mascota está contenta.
const String _fasePorDefecto = 'huevo';
const String _estadoPorDefecto = 'triste';

/// La fase (en minúscula) y el sufijo visual (`feliz → sonriente`,
/// `dormida → dormido`…) de un par del backend, con la misma caída que
/// [assetMascota]: una fase o un estado desconocidos caen al valor por
/// defecto. Las claves del manifiesto del arte (`<fase>_<estado>`) usan este
/// sufijo visual (`cria_dormido`), no el del backend.
({String fase, String sufijo}) faseYSufijoMascota({
  String? fase,
  String? estado,
}) {
  final f = fase?.toLowerCase();
  return (
    fase: _fasesConocidas.contains(f) ? f! : _fasePorDefecto,
    sufijo: _sufijoDeEstado[estado] ?? _sufijoDeEstado[_estadoPorDefecto]!,
  );
}

/// Ruta del PNG para una fase y un estado. Siempre devuelve un asset que
/// existe: una fase o un estado desconocidos caen al valor por defecto, así
/// que quien la use no necesita respaldo de emoji ni `errorBuilder`.
String assetMascota({String? fase, String? estado}) {
  final f = faseYSufijoMascota(fase: fase, estado: estado);
  return 'assets/mascota/Nori_${f.fase}_${f.sufijo}.png';
}

/// El cuerpo de Nori sin el brote, en el lienzo de 1024 (Nori canónica, N-1):
/// la capa de abajo de `NoriVestida`.
String assetCuerpoMascota({String? fase, String? estado}) {
  final f = faseYSufijoMascota(fase: fase, estado: estado);
  return 'assets/mascota/canonica/Nori_${f.fase}_${f.sufijo}_cuerpo.png';
}

/// El brote de Nori solo, en el mismo lienzo: la capa de arriba de
/// `NoriVestida`, que una prenda puede subir u ocultar.
String assetBroteMascota({String? fase, String? estado}) {
  final f = faseYSufijoMascota(fase: fase, estado: estado);
  return 'assets/mascota/canonica/Nori_${f.fase}_${f.sufijo}_brote.png';
}

/// El ánimo que se pinta, sacado de la respuesta de la mascota. Lo manda
/// `animo`, que trae los cuatro (`triste`, `dormida`, `feliz` y
/// `exultante`); si no viene —un backend anterior a ese campo—, `estado`, que
/// es lo que se leía antes. Sin ninguno de los dos devuelve null, y
/// [assetMascota] y la animación caen a su valor por defecto.
String? animoDeMascota(Map<String, dynamic> data) =>
    (data['animo'] ?? data['estado']) as String?;
