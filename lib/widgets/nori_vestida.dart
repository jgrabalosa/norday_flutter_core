import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../l10n/catalogos_core.dart';
import '../l10n/norday_core_localizations.dart';
import '../models/manifiesto_arte.dart';
import '../services/arte_prendas_service.dart';
import '../services/manifiesto_compartido.dart';
import '../theme/mascota_assets.dart';
import '../theme/prendas.dart';
import 'imagen_mascota.dart';

/// Nori con lo que lleva puesto (Nori vestida, N-9): capas sobre el mismo
/// lienzo de 1024, en el orden de [ordenCapasPrenda] — el cuerpo canónico, la
/// prenda de `Cuerpo`, la de `Cabeza` y el brote encima.
///
/// **Sin prendas, exactamente lo de siempre**: el `ImagenMascota` del dibujo
/// original, sin pedir el manifiesto ni ningún fichero. Lo mismo si ninguna de
/// las puestas se puede pintar todavía.
///
/// Una prenda se pinta si su código está en el manifiesto compartido, la fase
/// está en sus `fases`, tiene imagen para la fase y el estado (o la fase) y el
/// fichero ya ha llegado. Mientras se baja, o sin red, no se pinta. `oculta` y
/// `subidaBrote` solo cuentan si la prenda se pinta: una que no llegó no deja
/// a Nori sin brote.
///
/// Los ficheros se piden al cambiar las prendas, el manifiesto, la fase o el
/// estado, y se guardan en el estado: nunca en `build` (la animación la
/// repinta en cada frame).
class NoriVestida extends StatefulWidget {
  /// Fase y estado tal y como los manda el backend.
  final String? fase;
  final String? estado;

  /// Lado al que se pinta, en puntos.
  final double tamano;

  /// Ver [ImagenMascota.margen].
  final double margen;

  /// Para los tests: lo puesto (por defecto [prendasEquipadasNotifier]), el
  /// manifiesto (por defecto [manifiestoArteNotifier]) y de dónde sale el
  /// fichero de una imagen (por defecto `ArtePrendasService().imagen`).
  final ValueListenable<Map<String, String>>? prendas;
  final ValueListenable<ManifiestoArte>? manifiesto;
  final Future<File?> Function(String ruta)? imagen;

  const NoriVestida({
    super.key,
    this.fase,
    this.estado,
    required this.tamano,
    this.margen = 1,
    this.prendas,
    this.manifiesto,
    this.imagen,
  });

  @override
  State<NoriVestida> createState() => _NoriVestidaState();
}

/// Una prenda que se puede pintar ya.
class _Capa {
  final String sitio;
  final String codigo;
  final PrendaArte prenda;
  final File fichero;

  const _Capa(this.sitio, this.codigo, this.prenda, this.fichero);
}

class _NoriVestidaState extends State<NoriVestida> {
  late ValueListenable<Map<String, String>> _prendas;
  late ValueListenable<ManifiestoArte> _manifiesto;

  /// Los ficheros pedidos, por ruta: `null` mientras no llega o si falló.
  final Map<String, File?> _ficheros = {};
  final Set<String> _pedidas = {};
  bool _manifiestoAsegurado = false;

  /// Las capas que se pintan ahora, ya en su orden.
  List<_Capa> _capas = const [];

  @override
  void initState() {
    super.initState();
    _prendas = widget.prendas ?? prendasEquipadasNotifier;
    _manifiesto = widget.manifiesto ?? manifiestoArteNotifier;
    _prendas.addListener(_alCambiar);
    _manifiesto.addListener(_alCambiar);
    _actualizar();
  }

  @override
  void didUpdateWidget(covariant NoriVestida anterior) {
    super.didUpdateWidget(anterior);
    final prendas = widget.prendas ?? prendasEquipadasNotifier;
    final manifiesto = widget.manifiesto ?? manifiestoArteNotifier;
    var cambio =
        anterior.fase != widget.fase || anterior.estado != widget.estado;
    if (!identical(prendas, _prendas)) {
      _prendas.removeListener(_alCambiar);
      _prendas = prendas..addListener(_alCambiar);
      cambio = true;
    }
    if (!identical(manifiesto, _manifiesto)) {
      _manifiesto.removeListener(_alCambiar);
      _manifiesto = manifiesto..addListener(_alCambiar);
      cambio = true;
    }
    if (cambio) _actualizar();
  }

  @override
  void dispose() {
    _prendas.removeListener(_alCambiar);
    _manifiesto.removeListener(_alCambiar);
    super.dispose();
  }

  void _alCambiar() {
    if (!mounted) return;
    setState(_actualizar);
  }

  /// Decide qué se pinta y pide los ficheros que falten. Sin prendas no pide
  /// nada.
  void _actualizar() {
    final puestas = _prendas.value;
    if (puestas.isEmpty) {
      _capas = const [];
      return;
    }
    if (!_manifiestoAsegurado && widget.manifiesto == null) {
      _manifiestoAsegurado = true;
      unawaited(asegurarManifiesto());
    }
    final f = faseYSufijoMascota(fase: widget.fase, estado: widget.estado);
    final manifiesto = _manifiesto.value;
    final capas = <_Capa>[];
    for (final sitio in ordenCapasPrenda) {
      final codigo = puestas[sitio];
      if (codigo == null) continue;
      final prenda = manifiesto.prendas[codigo];
      if (prenda == null || !prenda.fases.contains(f.fase)) continue;
      final ruta = prenda.imagenPara(f.fase, f.sufijo);
      if (ruta == null) continue;
      final fichero = _ficheros[ruta];
      if (fichero != null) {
        capas.add(_Capa(sitio, codigo, prenda, fichero));
      } else {
        _pedir(ruta);
      }
    }
    _capas = capas;
  }

  void _pedir(String ruta) {
    if (!_pedidas.add(ruta)) return;
    final imagen = widget.imagen ?? ArtePrendasService().imagen;
    unawaited(() async {
      File? fichero;
      try {
        fichero = await imagen(ruta);
      } catch (_) {
        fichero = null;
      }
      if (fichero == null) {
        // Sin red o sin servidor: se puede volver a pedir en el próximo
        // cambio (otro manifiesto, otra fase…). No hay bucle: `_actualizar`
        // solo corre ante cambios.
        _pedidas.remove(ruta);
        return;
      }
      if (!mounted) return;
      _ficheros[ruta] = fichero;
      setState(_actualizar);
    }());
  }

  /// «Lleva: gorro de Papá Noel, traje…», con los nombres traducidos. Un
  /// código sin traducción no sale (nunca crudo); sin ninguno, `null`.
  String? _semantica(BuildContext context) {
    final nombres = [
      for (final capa in _capas)
        CatalogosCore.producto(context, capa.codigo, ''),
    ].where((n) => n.isNotEmpty).toList();
    if (nombres.isEmpty) return null;
    return NordayCoreLocalizations.of(context)!.noriLleva(nombres.join(', '));
  }

  @override
  Widget build(BuildContext context) {
    final tamano = widget.tamano;
    if (_capas.isEmpty) {
      return ImagenMascota(
        asset: assetMascota(fase: widget.fase, estado: widget.estado),
        tamano: tamano,
        margen: widget.margen,
      );
    }

    final f = faseYSufijoMascota(fase: widget.fase, estado: widget.estado);
    final ocultaBrote = _capas.any((c) => c.prenda.oculta.contains('brote'));
    final subida = _capas
        .map((c) => c.prenda.subidaBroteEn(f.fase))
        .fold<int>(0, (a, b) => b > a ? b : a);
    final densidad = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1;
    final ancho = ImagenMascota.anchoDescodificado(
      tamano: tamano,
      densidad: densidad,
      margen: widget.margen,
    );

    final pila = SizedBox(
      width: tamano,
      height: tamano,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ImagenMascota(
            asset: assetCuerpoMascota(fase: widget.fase, estado: widget.estado),
            tamano: tamano,
            margen: widget.margen,
          ),
          for (final capa in _capas)
            Image.file(
              capa.fichero,
              key: ValueKey('prenda_${capa.sitio}'),
              width: tamano,
              height: tamano,
              cacheWidth: ancho,
              gaplessPlayback: true,
            ),
          if (!ocultaBrote)
            Transform.translate(
              key: const ValueKey('brote'),
              offset: Offset(0, -subida * tamano / ladoOriginalMascota),
              child: ImagenMascota(
                asset: assetBroteMascota(
                  fase: widget.fase,
                  estado: widget.estado,
                ),
                tamano: tamano,
                margen: widget.margen,
              ),
            ),
        ],
      ),
    );

    final etiqueta = _semantica(context);
    if (etiqueta == null) return pila;
    return Semantics(label: etiqueta, image: true, child: pila);
  }
}
