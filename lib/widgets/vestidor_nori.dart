import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../l10n/catalogos_core.dart';
import '../l10n/mensajes_error.dart';
import '../l10n/mensajes_mascota.dart';
import '../l10n/norday_core_localizations.dart';
import '../models/manifiesto_arte.dart';
import '../services/celebracion_service.dart';
import '../services/manifiesto_compartido.dart';
import '../theme/app_theme.dart';
import '../theme/equipamiento.dart';
import '../theme/mascota_assets.dart';
import '../theme/prendas.dart';
import 'superficie_identidad.dart';

/// El vestidor de Nori (Nori vestida, N-10): una fila por sitio de
/// [sitiosPrenda] con «Nada» y las prendas de ese sitio que el usuario tiene.
///
/// **Sale del inventario, nunca del catálogo**: al acabar la temporada la
/// prenda deja de venderse, pero sigue siendo tuya y se sigue pudiendo poner
/// y quitar. La pantalla de Nori le pasa el inventario que ya pide para la
/// comida, sin otra petición. Sin ninguna prenda, no pinta nada.
///
/// Lo puesto sale de [prendasEquipadasNotifier]; tocar una prenda la pone
/// (`Equipamiento.equiparPrenda`) y «Nada» quita la del sitio. El notifier solo
/// cambia si el backend contesta bien, así que todas las Nori cambian a la vez
/// y, si falla, no cambia nada y se avisa.
class VestidorNori extends StatefulWidget {
  final int usuarioId;

  /// Las entradas de `ApiServiceCore.getInventarioProductos`, tal cual.
  final List<dynamic> inventario;

  /// La fase que se ve ahora, tal y como la manda el backend (`CRIA`…): una
  /// prenda que no se ve en ella avisa de cuándo se verá.
  final String? fase;

  /// Para los tests: lo puesto (por defecto [prendasEquipadasNotifier]) y el
  /// manifiesto (por defecto [manifiestoArteNotifier]).
  final ValueListenable<Map<String, String>>? prendas;
  final ValueListenable<ManifiestoArte>? manifiesto;

  const VestidorNori({
    super.key,
    required this.usuarioId,
    required this.inventario,
    this.fase,
    this.prendas,
    this.manifiesto,
  });

  @override
  State<VestidorNori> createState() => _VestidorNoriState();
}

/// Una prenda del inventario.
class _Prenda {
  final int productoId;
  final String codigo;
  final String nombre;

  const _Prenda(this.productoId, this.codigo, this.nombre);
}

class _VestidorNoriState extends State<VestidorNori> {
  /// El sitio que se está cambiando: mientras, sus opciones no se tocan.
  String? _cambiando;

  /// Las prendas del inventario por sitio, en el orden de [sitiosPrenda].
  Map<String, List<_Prenda>> get _porSitio {
    final mapa = <String, List<_Prenda>>{};
    for (final entrada in widget.inventario) {
      if (entrada is! Map) continue;
      final p = entrada['producto'];
      if (p is! Map) continue;
      final sitio = p['categoria'];
      final codigo = p['codigo'];
      final id = p['productoId'];
      if (sitio is! String || !sitiosPrenda.contains(sitio)) continue;
      if (codigo is! String || id is! int) continue;
      mapa
          .putIfAbsent(sitio, () => [])
          .add(_Prenda(id, codigo, p['nombre'] is String ? p['nombre'] : ''));
    }
    return {
      for (final sitio in sitiosPrenda)
        if (mapa[sitio] != null) sitio: mapa[sitio]!,
    };
  }

  Future<void> _poner(String sitio, _Prenda prenda) async {
    if (_cambiando != null) return;
    setState(() => _cambiando = sitio);
    var logros = const <String>[];
    try {
      logros = await Equipamiento.equiparPrenda(
        widget.usuarioId,
        prenda.productoId,
        prenda.codigo,
        sitio,
      );
    } catch (e) {
      _avisar(e);
    } finally {
      if (mounted) setState(() => _cambiando = null);
    }
    if (mounted) await CelebracionService.mostrar(logros);
  }

  Future<void> _quitar(String sitio, List<_Prenda> delSitio) async {
    if (_cambiando != null) return;
    final puesta = (widget.prendas ?? prendasEquipadasNotifier).value[sitio];
    if (puesta == null) return;
    final prenda = delSitio.where((p) => p.codigo == puesta).firstOrNull;
    // Puesta pero no en el inventario: no hay producto que quitar. Lo pondrá
    // en su sitio la próxima lectura del inventario.
    if (prenda == null) return;
    setState(() => _cambiando = sitio);
    try {
      await Equipamiento.desequiparPrenda(
        widget.usuarioId,
        prenda.productoId,
        sitio,
      );
    } catch (e) {
      _avisar(e);
    } finally {
      if (mounted) setState(() => _cambiando = null);
    }
  }

  void _avisar(Object e) {
    if (!mounted) return;
    MensajesError.enSnackBar(
      context,
      e,
      generico: NordayCoreLocalizations.of(context)!.tiendaError,
    );
  }

  /// «Se verá cuando Nori sea cría», o `null` si se ve en la fase de ahora o
  /// el manifiesto no la conoce (sin manifiesto no se puede saber).
  String? _seVeraCuando(
    NordayCoreLocalizations l,
    ManifiestoArte manifiesto,
    String codigo,
  ) {
    final arte = manifiesto.prendas[codigo];
    if (arte == null || arte.fases.isEmpty) return null;
    final ahora = faseYSufijoMascota(fase: widget.fase).fase;
    if (arte.fases.contains(ahora)) return null;
    const orden = ['huevo', 'cria', 'adulto'];
    final primera = orden.where(arte.fases.contains).firstOrNull;
    if (primera == null) return null;
    final nombre = MensajesMascota.fase(l, primera.toUpperCase());
    return l.vestidorSeVeraCuando(nombre.toLowerCase());
  }

  String _nombreSitio(NordayCoreLocalizations l, String sitio) =>
      switch (sitio) {
        'Cabeza' => l.mascotaSitioCabeza,
        'Cuerpo' => l.mascotaSitioCuerpo,
        _ => sitio,
      };

  @override
  Widget build(BuildContext context) {
    final porSitio = _porSitio;
    if (porSitio.isEmpty) return const SizedBox.shrink();

    final prendas = widget.prendas ?? prendasEquipadasNotifier;
    final manifiesto = widget.manifiesto ?? manifiestoArteNotifier;
    final l = NordayCoreLocalizations.of(context)!;
    final t = tokens(context);
    final texto = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: ListenableBuilder(
        listenable: Listenable.merge([prendas, manifiesto]),
        builder: (context, _) {
          final puestas = prendas.value;
          return SuperficieIdentidad(
            relleno: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.vestidorTitulo,
                  style: texto.titleMedium?.copyWith(color: t.text),
                ),
                for (final MapEntry(key: sitio, value: delSitio)
                    in porSitio.entries) ...[
                  const SizedBox(height: 12),
                  Text(
                    _nombreSitio(l, sitio),
                    style: texto.labelLarge?.copyWith(color: t.textMuted),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _opcion(
                        context,
                        clave: ValueKey('vestidor_${sitio}_nada'),
                        nombre: l.vestidorNada,
                        puesta: puestas[sitio] == null,
                        activa: _cambiando == null,
                        alTocar: () => _quitar(sitio, delSitio),
                      ),
                      for (final prenda in delSitio)
                        _opcion(
                          context,
                          clave: ValueKey('vestidor_${prenda.codigo}'),
                          nombre: CatalogosCore.producto(
                            context,
                            prenda.codigo,
                            prenda.nombre,
                          ),
                          aviso: _seVeraCuando(
                            l,
                            manifiesto.value,
                            prenda.codigo,
                          ),
                          puesta: puestas[sitio] == prenda.codigo,
                          activa: _cambiando == null,
                          alTocar: () => _poner(sitio, prenda),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  /// Una opción: «Nada» o una prenda. La puesta lleva el filo encendido y no
  /// hace nada al tocarla.
  Widget _opcion(
    BuildContext context, {
    required Key clave,
    required String nombre,
    String? aviso,
    required bool puesta,
    required bool activa,
    required VoidCallback alTocar,
  }) {
    final t = tokens(context);
    final texto = Theme.of(context).textTheme;
    return Semantics(
      key: clave,
      button: true,
      selected: puesta,
      child: SuperficieIdentidad(
        relleno: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        filo: puesta ? BorderSide(color: t.primaryTrazo, width: 2) : null,
        filoNeon: puesta ? FiloNeon.encendido : FiloNeon.fijo,
        onTap: puesta || !activa ? null : alTocar,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(nombre, style: texto.bodyMedium?.copyWith(color: t.text)),
            if (aviso != null)
              Text(aviso, style: texto.bodySmall?.copyWith(color: t.textMuted)),
          ],
        ),
      ),
    );
  }
}
