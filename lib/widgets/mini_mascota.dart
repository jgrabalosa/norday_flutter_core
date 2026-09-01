import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service_core.dart';
import '../screens/mascota_screen.dart';
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
  /// El valor por defecto es el de la lista de Hoy: 44 del `CheckCircular`,
  /// 6 de aire y 16 de relleno de la fila, redondeado a 72. Una pantalla con
  /// otra maquetación pasa el suyo.
  ///
  /// Sin esto, Nori acaba encima de un aro —está encerrada en la mitad
  /// inferior, que es justo la lista—, y como su caja es opaca al hit test se
  /// come el toque: el hábito no se marca y no hay forma de saber por qué.
  final double margenDerecho;

  const MiniMascota({
    super.key,
    required this.usuarioId,
    required this.areaSize,
    this.margenDerecho = 72,
  });

  @override
  State<MiniMascota> createState() => _MiniMascotaState();
}

class _MiniMascotaState extends State<MiniMascota> {
  /// Tamaño habitual de la burbuja. En cualquier móvil normal manda este
  /// valor: el tope de abajo solo entra en juego en pantallas diminutas.
  static const double _tamanoNominal = 136;

  /// La burbuja no puede pasar del 40% del alto de pantalla. Es una
  /// salvaguarda, no un tamaño: si se llega a aplicar es que la pantalla es
  /// tan baja que 136px ya tapaban media lista.
  static const double _fraccionMaximaAlto = 0.4;

  /// La ilustración deja aire alrededor dentro de la caja de la burbuja
  /// (109 sobre 136). Ese aire ya no es la zona de agarre —ahora agarra la
  /// caja entera, ver el `behavior` de abajo—, sino el sitio por donde se
  /// derrama el halo y el respiro que evita que Nori toque el borde al
  /// rebotar.
  ///
  /// Subió de 0.75 a 0.80 al crecer la caja: mantiene los ~13px de aire por
  /// lado que tenía a 105 y deja que todo el crecimiento se lo lleve la
  /// ilustración, que es de lo que iba el cambio.
  static const double _proporcionIlustracion = 0.80;

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
  bool _rebotando = false;

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

  Future<void> _inicializar() async {
    final prefs = await SharedPreferences.getInstance();
    final oculta = prefs.getBool('mini_mascota_oculta') ?? false;
    String? estado;
    String? fase;
    try {
      final data = await ApiServiceCore.getMascota(widget.usuarioId);
      estado = data['estado'];
      fase = data['fase'];
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

  void _onTap() {
    setState(() => _rebotando = true);
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _rebotando = false);
    });
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MascotaScreen(usuarioId: widget.usuarioId)),
    ).then((_) => _inicializar()); // al volver, refresca el estado (pudo alimentarla)
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando || _oculta) return const SizedBox.shrink();

    final topeAlto =
        MediaQuery.of(context).size.height * _fraccionMaximaAlto;
    final tamano = min(_tamanoNominal, topeAlto);

    return BurbujaFlotante(
      storageKey: 'mini_mascota',
      areaSize: widget.areaSize,
      // La burbuja calcula sus límites con este tamaño: si no coincide con el
      // del contenido, la mascota se sale del área por abajo.
      size: tamano,
      onTap: _onTap,
      minTopFraction: 0.5,
      margenDerecho: widget.margenDerecho,
      vagabundeo: true,
      // Agarra la caja entera, no solo el trozo que pinta la ilustración. Es
      // la misma caja de `size` con la que la burbuja calcula sus límites: sin
      // esto, el aire de alrededor se movía con ella pero no respondía, y
      // agarrarla exigía acertarle al dibujo.
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _rebotando ? 1.2 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}