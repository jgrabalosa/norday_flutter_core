import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/manifiesto_arte.dart';
import '../theme/mascota_assets.dart';
import 'imagen_mascota.dart';
import 'nori_vestida.dart';

/// Motor: da vida a la ilustración de la mascota sin assets nuevos, sólo con
/// animación nativa. Tres capas continuas superpuestas —respiración (escala),
/// vaivén (traslación vertical) y balanceo (rotación)— cada una con su propio
/// controlador y su propia duración: si compartieran periodo el conjunto se
/// leería como un único movimiento mecánico en vez de como algo que respira.
///
/// La amplitud y la velocidad de las tres salen del estado, que es lo único
/// de dominio que entra aquí — y "estado de la mascota" es motor, igual que
/// `assetMascota`: este widget no sabe qué es un hábito ni por qué la mascota
/// está como está.
class MascotaAnimadaViva extends StatefulWidget {
  /// Fase y estado tal y como los manda el backend. La ruta se resuelve
  /// dentro con `assetMascota`, que ya garantiza un asset existente para
  /// cualquier combinación, incluida la desconocida.
  final String? fase;
  final String? estado;

  /// Lado del cuadrado donde se pinta la ilustración.
  final double tamano;

  /// Si acepta el toque directo. En falso el widget no instala ningún
  /// `GestureDetector`, para no competir con el de quien lo envuelva
  /// (la burbuja flotante, sin ir más lejos, ya gestiona toque y arrastre).
  final bool permiteToque;

  /// Aviso opcional de que la han tocado, por si quien la usa quiere añadir
  /// háptica o sonido. El widget no decide nada de eso.
  final VoidCallback? onToque;

  /// Aviso de que Nori ha reaccionado (p. ej. al comer): cada aviso lanza el
  /// mismo gesto que un toque. Es una reacción, no un toque del usuario: no
  /// llama a [onToque] ni exige [permiteToque]. Con «reducir movimiento», no
  /// hace nada, como el toque. El valor del aviso no importa; quien avisa
  /// suele usar un contador para que cada aviso sea un cambio.
  final Listenable? reaccion;

  /// Si se pinta con lo que lleva puesto (`NoriVestida`, Nori vestida N-9),
  /// dentro de la misma animación. En falso, el dibujo de siempre: el splash,
  /// el login y el avatar no se visten (decisión 16).
  final bool vestida;

  /// Solo con [vestida]: se pasan tal cual a [NoriVestida]. Con [prendas], Nori
  /// lleva eso y no lo equipado (el login lo usa: ahí puede haber otra cuenta).
  /// Sin ellos, lo de siempre. [manifiesto] e [imagen] son sobre todo para los
  /// tests.
  final ValueListenable<Map<String, String>>? prendas;
  final ValueListenable<ManifiestoArte>? manifiesto;
  final Future<File?> Function(String ruta)? imagen;

  const MascotaAnimadaViva({
    super.key,
    this.fase,
    this.estado,
    required this.tamano,
    this.permiteToque = false,
    this.onToque,
    this.reaccion,
    this.vestida = false,
    this.prendas,
    this.manifiesto,
    this.imagen,
  });

  @override
  State<MascotaAnimadaViva> createState() => _MascotaAnimadaVivaState();
}

/// Cuánto y cómo de rápido se mueve cada capa. Un estado, un perfil.
class _PerfilVida {
  final Duration respiracion;
  final Duration vaiven;
  final Duration balanceo;

  /// Desviación máxima de la escala respecto a 1 (0.04 → 0.96–1.04).
  final double amplitudEscala;

  /// Desplazamiento vertical máximo, en píxeles lógicos.
  final double amplitudY;

  /// Giro máximo, en grados.
  final double amplitudGiro;

  const _PerfilVida({
    required this.respiracion,
    required this.vaiven,
    required this.balanceo,
    required this.amplitudEscala,
    required this.amplitudY,
    required this.amplitudGiro,
  });
}

/// Las tres duraciones de cada perfil son distintas entre sí a propósito.
const _PerfilVida _perfilFeliz = _PerfilVida(
  respiracion: Duration(milliseconds: 1100),
  vaiven: Duration(milliseconds: 1400),
  balanceo: Duration(milliseconds: 1900),
  amplitudEscala: 0.04,
  amplitudY: 5.0,
  amplitudGiro: 2.0,
);

const _PerfilVida _perfilTriste = _PerfilVida(
  respiracion: Duration(milliseconds: 2100),
  vaiven: Duration(milliseconds: 2600),
  balanceo: Duration(milliseconds: 3300),
  amplitudEscala: 0.018,
  amplitudY: 2.0,
  amplitudGiro: 0.8,
);

/// Casi quieta: lo justo para que no parezca una imagen congelada.
const _PerfilVida _perfilDormida = _PerfilVida(
  respiracion: Duration(milliseconds: 3400),
  vaiven: Duration(milliseconds: 4300),
  balanceo: Duration(milliseconds: 5700),
  amplitudEscala: 0.012,
  amplitudY: 1.2,
  amplitudGiro: 0.3,
);

/// Más que feliz: las tres capas más rápidas y más amplias. Provisional
/// hasta que se revisen las animaciones de Nori.
const _PerfilVida _perfilExultante = _PerfilVida(
  respiracion: Duration(milliseconds: 850),
  vaiven: Duration(milliseconds: 1100),
  balanceo: Duration(milliseconds: 1500),
  amplitudEscala: 0.055,
  amplitudY: 7.0,
  amplitudGiro: 3.0,
);

/// Un estado que este cliente aún no conozca cae al perfil sereno, mismo
/// criterio que `assetMascota`: ante la duda, no darla por contenta.
_PerfilVida _perfilDe(String? estado) => switch (estado) {
  'exultante' => _perfilExultante,
  'feliz' => _perfilFeliz,
  'dormida' => _perfilDormida,
  _ => _perfilTriste,
};

/// Lo más que se estira la ilustración: la respiración más amplia de los
/// perfiles (5,5 %) por el squish (18 %), 1,245, redondeado arriba.
const double _margenAnimacion = 1.25;

class _MascotaAnimadaVivaState extends State<MascotaAnimadaViva>
    with TickerProviderStateMixin {
  late final AnimationController _respiracion;
  late final AnimationController _vaiven;
  late final AnimationController _balanceo;

  /// Reacción al toque, independiente de las tres capas de reposo: va de 1
  /// (aplastada) a 0 (en reposo) con rebote elástico, así que en reposo vale
  /// 0 y no deforma nada.
  late final AnimationController _squishController;
  late final Animation<double> _squish;

  /// Última lectura de la preferencia del sistema de reducir animaciones.
  bool _animacionesDesactivadas = false;

  /// El [MascotaAnimadaViva.reaccion] al que estamos suscritos. Se guarda
  /// aparte porque, al cambiar el widget, el nuevo puede no ser el que se dio
  /// de alta: así se da de baja el bueno.
  Listenable? _suscrito;

  _PerfilVida get _perfil => _perfilDe(widget.estado);

  @override
  void initState() {
    super.initState();
    _suscribirReaccion(widget.reaccion);
    final p = _perfil;
    _respiracion = AnimationController(vsync: this, duration: p.respiracion);
    _vaiven = AnimationController(vsync: this, duration: p.vaiven);
    _balanceo = AnimationController(vsync: this, duration: p.balanceo);

    _squishController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
      value: 1.0, // 1 en el controlador = 0 de deformación
    );
    _squish = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _squishController, curve: Curves.elasticOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respetar "reducir movimiento" del sistema: una animación en bucle
    // permanente es justo lo que esa preferencia quiere apagar.
    _animacionesDesactivadas =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _sincronizarBucles();
  }

  @override
  void didUpdateWidget(covariant MascotaAnimadaViva anterior) {
    super.didUpdateWidget(anterior);
    if (anterior.estado != widget.estado) _sincronizarBucles();
    if (anterior.reaccion != widget.reaccion) {
      _suscribirReaccion(widget.reaccion);
    }
  }

  void _suscribirReaccion(Listenable? nuevo) {
    _suscrito?.removeListener(_alReaccionar);
    _suscrito = nuevo;
    _suscrito?.addListener(_alReaccionar);
  }

  /// Deja los tres bucles en marcha con las duraciones del perfil actual, o
  /// parados y en su punto medio (sin deformación) si no toca animar.
  void _sincronizarBucles() {
    final p = _perfil;
    _respiracion.duration = p.respiracion;
    _vaiven.duration = p.vaiven;
    _balanceo.duration = p.balanceo;

    for (final c in [_respiracion, _vaiven, _balanceo]) {
      if (_animacionesDesactivadas) {
        c.stop();
        c.value = 0.5; // centro del recorrido: reposo exacto
      } else {
        c.repeat(reverse: true);
      }
    }
    if (_animacionesDesactivadas) _squishController.value = 1.0;
  }

  @override
  void dispose() {
    _suscrito?.removeListener(_alReaccionar);
    _respiracion.dispose();
    _vaiven.dispose();
    _balanceo.dispose();
    _squishController.dispose();
    super.dispose();
  }

  /// El gesto del toque y el de la reacción: el mismo aplastón, o nada si
  /// Nori no debe moverse.
  void _aplastar() {
    if (!_animacionesDesactivadas) _squishController.forward(from: 0);
  }

  void _alTocar() {
    _aplastar();
    widget.onToque?.call();
  }

  void _alReaccionar() => _aplastar();

  /// De [0,1] a [-1,1] con entrada y salida suaves, que es lo que convierte
  /// un vaivén lineal en algo que parece vivo.
  double _oscilacion(AnimationController c) =>
      Curves.easeInOut.transform(c.value) * 2 - 1;

  @override
  Widget build(BuildContext context) {
    final p = _perfil;
    final imagen = assetMascota(fase: widget.fase, estado: widget.estado);

    final cuerpo = AnimatedBuilder(
      animation: Listenable.merge([_respiracion, _vaiven, _balanceo, _squish]),
      builder: (context, child) {
        final escala = 1 + _oscilacion(_respiracion) * p.amplitudEscala;
        final desplazamientoY = _oscilacion(_vaiven) * p.amplitudY;
        final giro = _oscilacion(_balanceo) * p.amplitudGiro * math.pi / 180;

        // El squish aplasta en Y y ensancha en X (y al rebotar, al revés).
        final squish = _squish.value;
        final escalaX = escala * (1 + squish * 0.18);
        final escalaY = escala * (1 - squish * 0.18);

        return Transform.translate(
          offset: Offset(0, desplazamientoY),
          child: Transform.rotate(
            angle: giro,
            child: Transform(
              // Desde la base: aplastarse contra el suelo se lee como peso,
              // hacerlo desde el centro parece que flota.
              alignment: Alignment.bottomCenter,
              transform: Matrix4.diagonal3Values(escalaX, escalaY, 1),
              child: child,
            ),
          ),
        );
      },
      // Descodificada a su tamaño, con margen para el pico de la animación.
      // Va en el `child`: se construye una vez y la animación solo la
      // transforma. Vestida, igual (NoriVestida busca sus ficheros en su
      // estado, no en cada frame).
      child: widget.vestida
          ? NoriVestida(
              fase: widget.fase,
              estado: widget.estado,
              tamano: widget.tamano,
              margen: _margenAnimacion,
              prendas: widget.prendas,
              manifiesto: widget.manifiesto,
              imagen: widget.imagen,
            )
          : ImagenMascota(
              asset: imagen,
              tamano: widget.tamano,
              margen: _margenAnimacion,
            ),
    );

    if (!widget.permiteToque) return cuerpo;

    return GestureDetector(
      onTap: _alTocar,
      behavior: HitTestBehavior.opaque,
      child: cuerpo,
    );
  }
}
