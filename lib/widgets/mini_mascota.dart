import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service_core.dart';
import '../theme/app_theme.dart';
import '../theme/mascota_assets.dart';
import '../theme/mascota_refresh.dart';
import 'burbuja_flotante.dart';
import 'halo_identidad.dart';
import 'mascota_animada_viva.dart';

/// Versión flotante y pequeña de la mascota. La ilustración y su animación
/// de reposo salen de `MascotaAnimadaViva`, el mismo widget que usa la
/// pantalla grande: aquí no se decide nada sobre fases ni estados.
class MiniMascota extends StatefulWidget {
  final int usuarioId;
  final Size areaSize;

  /// Franja derecha prohibida, para no taparle el toque a la columna de
  /// acciones de la lista que haya debajo.
  ///
  /// El valor por defecto sale de la lista de Hoy, medida desde el borde
  /// derecho del área: 16 del relleno de la lista, 16 del relleno de la fila,
  /// y el `CheckCircular` con sus 44 más 6 de aire por lado (56 de caja
  /// táctil). La caja del check empieza, pues, a 88 del borde (82 el aro
  /// visible). Nori arrastrada del todo a la derecha deja su caja a
  /// `12 + margenDerecho` del borde (12 es el margen de `BurbujaFlotante`);
  /// con 86, son 98: 10 px a la izquierda de la caja táctil del check y 16 del
  /// aro, dentro de los 8–16 pedidos. Una pantalla con otra maquetación pasa
  /// el suyo.
  ///
  /// Sin esto, Nori acaba encima de un aro y, como su caja es opaca al hit
  /// test, se come el toque: el hábito no se marca y no hay forma de saber por
  /// qué.
  final double margenDerecho;

  const MiniMascota({
    super.key,
    required this.usuarioId,
    required this.areaSize,
    this.margenDerecho = margenDerechoHoy,
  });

  /// Ver [margenDerecho]. Antes era 132.
  static const double margenDerechoHoy = 86;

  /// Marca de que la posición guardada ya está en el formato de toda la
  /// altura y la franja estrecha (T-071).
  static const String claveFormatoNuevo = 'mini_mascota_formato_altura';

  @override
  State<MiniMascota> createState() => _MiniMascotaState();
}

class _MiniMascotaState extends State<MiniMascota> {
  /// Tamaño habitual de la burbuja. En cualquier móvil normal manda este
  /// valor: el tope de abajo solo entra en juego en pantallas diminutas.
  /// La caja táctil es deliberadamente algo mayor que la ilustración, pero
  /// no tanto como para comerse los hábitos que quedan debajo.
  static const double _tamanoNominal = 120;

  /// La burbuja no puede pasar del 40% del alto de pantalla. Es una
  /// salvaguarda, no un tamaño: si se llega a aplicar es que la pantalla es
  /// tan baja que 136px ya tapaban media lista.
  static const double _fraccionMaximaAlto = 0.4;

  /// La ilustración deja aire alrededor dentro de la caja de la burbuja
  /// (108 sobre 120). Ese aire ya no es la zona de agarre —ahora agarra la
  /// caja entera, ver el `behavior` de abajo—, sino el sitio por donde se
  /// derrama el halo y el respiro que evita que Nori toque el borde al
  /// rebotar.
  ///
  /// La ilustración conserva prácticamente el tamaño visual anterior, pero
  /// la caja que bloquea los toques de la lista se reduce.
  static const double _proporcionIlustracion = 0.90;

  /// El halo aquí es un apunte, no el foco que es en la pantalla de mascota:
  /// esto flota sobre el contenido de cualquier pantalla de la app.
  static const double _intensidadHalo = 0.55;

  /// Caja del halo. A 0.86 el degradado muere justo en el borde de la burbuja
  /// (el painter pinta a 0.58 del lado que le den), así que la luz no se sale
  /// de la caja que la burbuja declara como suya.
  static const double _proporcionHalo = 0.86;

  String? _estado;
  String? _fase;
  bool _oculta = false;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _inicializar();
    // La mini-mascota vive fuera de la pantalla que provoca el cambio, así
    // que sin esta señal se quedaría con el ánimo del último `_inicializar()`.
    refrescoMascotaNotifier.addListener(_onRefrescoSolicitado);
  }

  @override
  void dispose() {
    refrescoMascotaNotifier.removeListener(_onRefrescoSolicitado);
    super.dispose();
  }

  void _onRefrescoSolicitado() => _inicializar();

  /// Los valores con los que se guardaron las posiciones del formato viejo.
  static const double _margenDerechoAnterior = 132;
  static const double _topAnterior = 0.5;

  double get _tamano {
    final topeAlto = MediaQuery.of(context).size.height * _fraccionMaximaAlto;
    return min(_tamanoNominal, topeAlto);
  }

  /// Convierte una sola vez el `dx`/`dy` guardados con la mitad de abajo y la
  /// franja de 132 a los de ahora, para que Nori siga en el mismo sitio de la
  /// pantalla. Va antes de montar la burbuja, que es quien lee esas claves.
  Future<void> _convertirPosicionGuardada(SharedPreferences prefs) async {
    if (prefs.getBool(MiniMascota.claveFormatoNuevo) ?? false) return;
    final dx = prefs.getDouble('mini_mascota_dx');
    final dy = prefs.getDouble('mini_mascota_dy');
    const margen = 12.0;
    final area = widget.areaSize;
    final tamano = _tamano;

    final recorridoYViejo = max(
      0.0,
      area.height - tamano - margen - (area.height * _topAnterior + margen),
    );
    final recorridoYNuevo = max(0.0, area.height - tamano - 2 * margen);
    final recorridoXViejo = max(
      0.0,
      area.width - tamano - 2 * margen - _margenDerechoAnterior,
    );
    final recorridoXNuevo = max(
      0.0,
      area.width - tamano - 2 * margen - widget.margenDerecho,
    );

    if (dy != null) {
      final topViejo =
          area.height * _topAnterior + margen + dy * recorridoYViejo;
      final nuevo = recorridoYNuevo > 0
          ? (topViejo - margen) / recorridoYNuevo
          : 0.0;
      await prefs.setDouble('mini_mascota_dy', nuevo.clamp(0.0, 1.0));
    }
    if (dx != null) {
      final nuevo = recorridoXNuevo > 0
          ? dx * recorridoXViejo / recorridoXNuevo
          : 0.0;
      await prefs.setDouble('mini_mascota_dx', nuevo.clamp(0.0, 1.0));
    }
    await prefs.setBool(MiniMascota.claveFormatoNuevo, true);
  }

  Future<void> _inicializar() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    await _convertirPosicionGuardada(prefs);
    final oculta = prefs.getBool('mini_mascota_oculta') ?? false;
    String? estado;
    String? fase;
    try {
      final data = await ApiServiceCore.getMascota(widget.usuarioId);
      estado = animoDeMascota(data);
      fase = data['fase'];
      // Para el avatar (T-032): solo con una lectura buena.
      faseMascotaNotifier.value = fase;
    } catch (_) {
      // Si falla, se muestra igualmente con fase y estado por defecto
    }
    if (!mounted) return;
    setState(() {
      _estado = estado;
      _fase = fase;
      _oculta = oculta;
      _cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando || _oculta) return const SizedBox.shrink();

    final tamano = _tamano;

    return BurbujaFlotante(
      storageKey: 'mini_mascota',
      areaSize: widget.areaSize,
      // La burbuja calcula sus límites con este tamaño: si no coincide con el
      // del contenido, la mascota se sale del área por abajo.
      size: tamano,
      // Sin `onTap`: la mini mascota sólo se arrastra. Con las dos cosas, un
      // toque con el mínimo deslizamiento lo ganaba el arrastre y la
      // pulsación se perdía. A la pantalla de la mascota se llega por su
      // pestaña.
      // Toda la altura del área; el margen de 12 de la burbuja la mantiene
      // fuera de la barra de estado y de la de abajo.
      minTopFraction: 0.0,
      margenDerecho: widget.margenDerecho,
      vagabundeo: true,
      // Agarra la caja entera, no solo el trozo que pinta la ilustración. Es
      // la misma caja de `size` con la que la burbuja calcula sus límites: sin
      // esto, el aire de alrededor se movía con ella pero no respondía, y
      // agarrarla exigía acertarle al dibujo.
      behavior: HitTestBehavior.opaque,
      // Sin holgura, a propósito: con el agarre inmediato de la burbuja, la
      // caja de 136 ya basta. Se probó con 60, 30, 18 y 8 por lado y en
      // todos sobraba. Cada píxel de más es un píxel de la tarjeta de
      // debajo que deja de responder al toque.
      holguraTactil: 0,
      // Mientras se arrastra, se ve por dónde puede moverse. Antes el usuario
      // lo descubría a base de soltarla en sitios donde no se quedaba.
      colorZona: tokens(context).primary,
      // Sin círculo, sin sombra y sin superficie: lo único que hay detrás de
      // Nori es la luz de la identidad equipada, floja. La caja sigue
      // midiendo `tamano` porque es la que le hemos declarado a la burbuja.
      child: SizedBox(
        width: tamano,
        height: tamano,
        child: Stack(
          alignment: Alignment.center,
          children: [
            HaloIdentidad(
              tamano: tamano * _proporcionHalo,
              intensidad: _intensidadHalo,
            ),
            // El toque lo gestiona la burbuja (que además arrastra), así que
            // aquí va sin él: dos GestureDetector encajados se pelearían.
            MascotaAnimadaViva(
              fase: _fase,
              estado: _estado,
              tamano: tamano * _proporcionIlustracion,
              vestida: true,
            ),
          ],
        ),
      ),
    );
  }
}
