import 'package:flutter/material.dart';
import '../l10n/norday_core_localizations.dart';
import '../l10n/mensajes_error.dart';
import '../services/api_error.dart';
import '../services/api_service_core.dart';
import '../theme/identidad_paleta.dart';
import '../theme/identidades_paleta.dart';
import '../widgets/preview_identidad_tienda.dart';

/// Una identidad del catálogo emparejada con el productoId que le asignó el
/// backend. Los productoId son autogenerados por la base de datos y cambian
/// entre instalaciones — el único identificador estable es el código, así que
/// el emparejamiento se hace aquí, no se cablea.
class _ItemIdentidad {
  final IdentidadPaleta identidad;
  final int productoId;
  const _ItemIdentidad(this.identidad, this.productoId);
}

/// Elección de identidad en el onboarding: el usuario ya está registrado y
/// tiene que salir con una identidad equipada, así que esta pantalla no
/// tiene salida (sin AppBar, sin retroceso). Un 409 al elegir no es un
/// error — significa que la red de seguridad del backend ya le dio una — y
/// se trata igual que el éxito: atraparlo en un error irresoluble sería peor.
class EleccionIdentidadScreen extends StatefulWidget {
  final int usuarioId;

  /// Se llama tras elegir con éxito. La app decide a dónde ir.
  final VoidCallback alElegir;

  const EleccionIdentidadScreen({
    super.key,
    required this.usuarioId,
    required this.alElegir,
  });

  @override
  State<EleccionIdentidadScreen> createState() => _EleccionIdentidadScreenState();
}

class _EleccionIdentidadScreenState extends State<EleccionIdentidadScreen> {
  // Profundidad primero por ser la identidad base de la app.
  static const _codigosIdentidad = [
    'TEMA_PROFUNDIDAD',
    'TEMA_NEOTOKYO_PLUS',
    'TEMA_ALBA',
    'TEMA_DULCE',
  ];

  final PageController _controlador = PageController(viewportFraction: 0.84);
  int _paginaActual = 0;

  bool _cargandoCatalogo = true;
  Object? _fallocatalogo;
  List<_ItemIdentidad> _items = [];

  bool _enviando = false;
  String? _errorEleccion;

  @override
  void initState() {
    super.initState();
    _cargarCatalogo();
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  /// El productoId no está en catalogoIdentidades a propósito (ver
  /// identidad_paleta.dart: "nada de ids cableados en el cliente"), así que
  /// hace falta pedir el catálogo real y cruzar por código, igual que hace
  /// tienda_screen.dart en sentido inverso.
  Future<void> _cargarCatalogo() async {
    setState(() {
      _cargandoCatalogo = true;
      _fallocatalogo = null;
    });

    try {
      final catalogo = await ApiServiceCore.getCatalogoProductos();
      final porCodigo = <String, dynamic>{};
      for (final producto in catalogo) {
        final codigo = producto['codigo'] as String?;
        if (codigo != null) porCodigo[codigo] = producto;
      }

      final items = <_ItemIdentidad>[];
      for (final codigo in _codigosIdentidad) {
        final producto = porCodigo[codigo];
        final identidad = catalogoIdentidades[codigo];
        if (producto == null || identidad == null) continue;
        if (producto['activo'] != true) continue;
        items.add(_ItemIdentidad(identidad, producto['productoId'] as int));
      }

      if (!mounted) return;
      setState(() {
        _items = items;
        _cargandoCatalogo = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargandoCatalogo = false;
        _fallocatalogo = e;
      });
    }
  }

  Future<void> _elegir(NordayCoreLocalizations l) async {
    setState(() {
      _enviando = true;
      _errorEleccion = null;
    });

    final productoId = _items[_paginaActual].productoId;
    try {
      await ApiServiceCore.elegirIdentidad(widget.usuarioId, productoId);
      if (!mounted) return;
      widget.alElegir();
    } on ApiException catch (e) {
      if (e.codigoEstado == 409) {
        // Ya tiene una identidad (red de seguridad del backend): seguir
        // como si hubiera elegido, no dejar al usuario atascado aquí.
        widget.alElegir();
        return;
      }
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _errorEleccion = MensajesError.de(context, e, generico: l.identidadErrorGenerico);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _errorEleccion = MensajesError.de(context, e, generico: l.identidadErrorGenerico);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = NordayCoreLocalizations.of(context)!;
    final huboFallo = _fallocatalogo != null || (!_cargandoCatalogo && _items.isEmpty);

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: _cargandoCatalogo
              ? const Center(child: CircularProgressIndicator())
              : huboFallo
                  ? _vistaErrorCatalogo(l)
                  : _vistaCarrusel(l),
        ),
      ),
    );
  }

  Widget _vistaErrorCatalogo(NordayCoreLocalizations l) {
    final fallo = _fallocatalogo;
    final texto = fallo != null
        ? MensajesError.de(context, fallo, generico: l.identidadErrorCatalogo)
        : l.identidadErrorCatalogo;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(texto, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargarCatalogo,
              child: Text(l.reintentar),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vistaCarrusel(NordayCoreLocalizations l) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          Text(
            l.identidadTitulo,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            l.identidadSubtitulo,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: PageView.builder(
              controller: _controlador,
              physics: _enviando ? const NeverScrollableScrollPhysics() : null,
              itemCount: _items.length,
              onPageChanged: (pagina) => setState(() => _paginaActual = pagina),
              itemBuilder: (context, indice) {
                final id = _items[indice].identidad;
                return Semantics(
                  label: '${l.identidadTitulo}: ${id.nombre}',
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    child: Column(
                      children: [
                        Expanded(child: MaquetaPreviewIdentidad(identidad: id)),
                        const SizedBox(height: 12),
                        Text(
                          id.nombre,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < _items.length; i++)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _paginaActual
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Semantics(
            label: '${l.identidadElegir}: ${_items[_paginaActual].identidad.nombre}',
            button: true,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _enviando ? null : () => _elegir(l),
                child: _enviando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l.identidadElegir),
              ),
            ),
          ),
          if (_errorEleccion != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorEleccion!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }
}
