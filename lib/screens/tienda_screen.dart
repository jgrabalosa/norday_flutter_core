import 'package:flutter/material.dart';
import '../l10n/norday_core_localizations.dart';
import '../l10n/catalogos_core.dart';
import '../l10n/mensajes_error.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/api_service_core.dart';
import '../services/celebracion_service.dart';
import '../theme/app_theme.dart';
import '../theme/identidad_paleta.dart';
import '../theme/identidades_paleta.dart';
import '../theme/avatares.dart';
import '../theme/equipamiento.dart';
import '../widgets/fondo_estelar.dart';
import '../widgets/preview_identidad_tienda.dart';
import '../widgets/superficie_identidad.dart';

class TiendaScreen extends StatefulWidget {
  final int usuarioId;
  const TiendaScreen({super.key, required this.usuarioId});

  @override
  State<TiendaScreen> createState() => _TiendaScreenState();
}

class _TiendaScreenState extends State<TiendaScreen> {
  bool _loading = true;
  int _saldo = 0;
  List<dynamic> _catalogo = [];
  // productoId -> {cantidad, equipado}
  Map<int, Map<String, dynamic>> _inventario = {};
  int? _procesando;

  /// Iconografía por categoría, en Lucide como todo el resto de la app. Antes
  /// eran emoji, que los pinta la fuente del sistema: cambian de dibujo, de
  /// color y de peso entre Android, iOS y versión, así que no se pueden alinear
  /// con ninguna identidad ni con el resto de iconos.
  static const iconosCategoria = {
    'Tema': LucideIcons.palette,
    'Protección': LucideIcons.shield,
    'Avatar': LucideIcons.userRound,
  };

  /// Una categoría que este cliente aún no conozca — el catálogo lo manda el
  /// backend y puede crecer sin que la app se entere.
  static const iconoCategoriaDesconocida = LucideIcons.package;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final saldo = await ApiServiceCore.getSaldoPuntos(widget.usuarioId);
      final catalogo = await ApiServiceCore.getCatalogoProductos();
      final inventario = await ApiServiceCore.getInventarioProductos(widget.usuarioId);

      final mapaInventario = <int, Map<String, dynamic>>{};
      for (final up in inventario) {
        final productoId = up['producto']['productoId'] as int;
        mapaInventario[productoId] = {
          'cantidad': up['cantidad'],
          'equipado': up['equipado'],
        };
      }

      if (!mounted) return;
      setState(() {
        _saldo = saldo;
        _catalogo = catalogo;
        _inventario = mapaInventario;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _mostrarError(e);
    }
  }

  Future<void> _comprar(int productoId) async {
    setState(() => _procesando = productoId);
    List<String> logros = const [];
    try {
      logros = await ApiServiceCore.comprarProducto(widget.usuarioId, productoId);
      await _cargarDatos();
    } catch (e) {
      _mostrarError(e);
    } finally {
      if (mounted) setState(() => _procesando = null);
    }
    // Después de recargar, para que al cerrar el diálogo la tienda ya muestre
    // el producto como poseído. Y fuera del try: si falla la recarga, la
    // compra sí ocurrió y su logro se celebra igual.
    if (mounted) await CelebracionService.mostrar(logros);
  }

  Future<void> _equipar(int productoId, String? codigo, String categoria) async {
    setState(() => _procesando = productoId);
    try {
      if (categoria == 'Tema') {
        await Equipamiento.equiparTema(widget.usuarioId, productoId, codigo);
      } else if (categoria == 'Avatar') {
        await Equipamiento.equiparAvatar(widget.usuarioId, productoId, codigo);
      }
      await _cargarDatos();
    } catch (e) {
      _mostrarError(e);
    } finally {
      if (mounted) setState(() => _procesando = null);
    }
  }

  Future<void> _usar(int productoId) async {
    setState(() => _procesando = productoId);
    try {
      await ApiServiceCore.usarProducto(widget.usuarioId, productoId);
      await _cargarDatos();
    } catch (e) {
      _mostrarError(e);
    } finally {
      if (mounted) setState(() => _procesando = null);
    }
  }

  void _mostrarError(Object e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(MensajesError.de(context, e,
              generico: NordayCoreLocalizations.of(context)!.tiendaError)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = tokens(context);
    final l = NordayCoreLocalizations.of(context)!;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(l.tiendaTitulo),
        // Transparente para que la nebulosa verde —centrada contra el borde
        // superior— se vea a través de la barra en vez de quedar tapada.
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Imprescindible: sin esto Material 3 tiñe el AppBar en cuanto hay
        // scroll debajo y vuelve a tapar la nebulosa.
        scrolledUnderElevation: 0,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Nivel 2: esta pantalla se abre ENCIMA del shell, así que tiene
          // cielo pero no constelación —la monta el shell—. El cielo tenue
          // dice «sigues dentro» sin fingir un progreso que aquí no se
          // muestra.
          const Positioned.fill(child: FondoEstelar.tenue()),
          SafeArea(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _cargarDatos,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        SuperficieIdentidad(
                          protagonista: true,
                          relleno: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Icon(LucideIcons.coins, color: t.points, size: 40),
                              const SizedBox(height: 8),
                              Text('$_saldo',
                                  style: Theme.of(context)
                                      .textTheme
                                      .displaySmall
                                      ?.copyWith(color: t.text)),
                              Text(l.puntos,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: t.textMuted)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(l.tiendaCatalogo,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(color: t.text)),
                        const SizedBox(height: 8),
                        ..._catalogo.map((producto) => _productoCard(l, producto, t)),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _productoCard(NordayCoreLocalizations l, dynamic producto, TokensContextuales t) {
    final productoId = producto['productoId'] as int;
    final codigo = producto['codigo'] as String?;
    final tipo = producto['tipo'] as String;
    final categoria = producto['categoria'] as String;
    final icono = iconosCategoria[categoria] ?? iconoCategoriaDesconocida;
    final info = _inventario[productoId];
    final poseido = info != null;
    final equipado = info?['equipado'] == true;
    final cantidad = info?['cantidad'] ?? 0;
    final procesandoEste = _procesando == productoId;
    final identidad = codigo != null ? catalogoIdentidades[codigo] : null;

    return SuperficieIdentidad(
      // Es un elemento de lista, no el protagonista de la pantalla: radio
      // secundario, y en Alba línea fina debajo en vez de caja.
      esFila: true,
      margen: const EdgeInsets.only(bottom: 8),
      relleno: const EdgeInsets.all(16),
      // Sólo los temas se pueden previsualizar: del resto no hay nada que
      // enseñar que no esté ya en la propia tarjeta.
      //
      // El `clipBehavior: Clip.antiAlias` que había aquí ya no hace falta:
      // `SuperficieIdentidad` pasa `customBorder: forma` al InkWell, así que
      // el ripple respeta la figura de la identidad, chaflán incluido.
      onTap: identidad != null
          ? () => _abrirPrevisualizacion(l, producto, identidad)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconoProducto(categoria, codigo, icono),
              const SizedBox(width: 8),
              Expanded(
                child: Text(CatalogosCore.producto(context, producto['codigo'], producto['nombre']),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: t.text)),
              ),
              if (equipado)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: t.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(l.tiendaEquipado,
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(color: t.primary)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
              CatalogosCore.productoDescripcion(
                  context, producto['codigo'], producto['descripcion']),
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: t.textMuted)),
          if (identidad != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                ChipIdentidad(identidad: identidad),
                const Spacer(),
                // Pista de que la tarjeta se puede tocar para verlo.
                Icon(LucideIcons.eye, size: 16, color: t.textMuted),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l.tiendaPrecio(producto['precio'] as int),
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: t.textMuted)),
              _botonAccion(l, productoId, tipo, poseido, equipado, cantidad, codigo, categoria, procesandoEste),
            ],
          ),
        ],
      ),
    );
  }

  /// Los avatares se ven, no se describen: si el código está en el catálogo se
  /// pinta el PNG real. Cualquier otra cosa —incluido un avatar que este
  /// cliente aún no conozca— cae al icono de su categoría.
  Widget _iconoProducto(String categoria, String? codigo, IconData icono) {
    final avatar = categoria == 'Avatar' && codigo != null
        ? catalogoAvatares[codigo]
        : null;
    if (avatar == null) {
      return Icon(icono, size: 24, color: tokens(context).text);
    }
    return CircleAvatar(
      radius: 16,
      backgroundColor: fondoAvatar,
      // El PNG cuadrado no llena el círculo: se deja aire alrededor, igual
      // que en AvatarUsuario.
      child: Image.asset(avatar.asset, package: 'norday_flutter_core', width: 24, height: 24),
    );
  }

  /// Enseña el tema antes de pagarlo. Las acciones cierran la hoja y delegan
  /// en los mismos métodos de la tarjeta: la hoja no duplica nada del estado
  /// de compra, sólo evita el viaje de vuelta.
  void _abrirPrevisualizacion(
      NordayCoreLocalizations l, dynamic producto, IdentidadPaleta identidad) {
    final productoId = producto['productoId'] as int;
    final codigo = producto['codigo'] as String?;
    final categoria = producto['categoria'] as String;
    final info = _inventario[productoId];
    final poseido = info != null;
    final equipado = info?['equipado'] == true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (hoja) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controlador) => SafeArea(
          child: ListView(
            controller: controlador,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              Text(CatalogosCore.producto(context, codigo, producto['nombre']),
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              MaquetaPreviewIdentidad(identidad: identidad),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(hoja),
                      child: Text(l.comunCerrar),
                    ),
                  ),
                  // Ya equipado no hay nada que ofrecer: sólo mirarlo.
                  if (!equipado) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(hoja);
                          if (poseido) {
                            _equipar(productoId, codigo, categoria);
                          } else {
                            _comprar(productoId);
                          }
                        },
                        child: Text(poseido ? l.tiendaEquipar : l.tiendaComprar),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _botonAccion(NordayCoreLocalizations l, int productoId, String tipo, bool poseido, bool equipado,
      int cantidad, String? codigo, String categoria, bool procesando) {
    if (procesando) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (tipo == 'EQUIPABLE') {
      if (!poseido) {
        return ElevatedButton(
          onPressed: () => _comprar(productoId),
          child: Text(l.tiendaComprar),
        );
      }
      if (equipado) {
        return const SizedBox.shrink();
      }
      return OutlinedButton(
        onPressed: () => _equipar(productoId, codigo, categoria),
        child: Text(l.tiendaEquipar),
      );
    }

    // CONSUMIBLE
    if (cantidad > 0) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () => _comprar(productoId),
            child: const Text('+1'),
          ),
          ElevatedButton(
            onPressed: () => _usar(productoId),
            child: Text(l.tiendaUsar(cantidad)),
          ),
        ],
      );
    }
    return ElevatedButton(
      onPressed: () => _comprar(productoId),
      child: Text(l.tiendaComprar),
    );
  }
}