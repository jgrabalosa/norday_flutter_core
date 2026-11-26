import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/norday_core_localizations.dart';
import '../l10n/catalogos_core.dart';
import '../l10n/mensajes_error.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/precio_tienda.dart';
import '../services/api_error.dart';
import '../services/analytics_service.dart';
import '../services/api_service_core.dart';
import '../services/celebracion_service.dart';
import '../theme/app_theme.dart';
import '../theme/identidad_paleta.dart';
import '../theme/identidades_paleta.dart';
import '../theme/avatares.dart';
import '../theme/equipamiento.dart';
import '../theme/prendas.dart';
import '../widgets/ayuda_campo.dart';
import '../widgets/burbuja_contexto.dart';
import '../widgets/fondo_identidad.dart';
import '../widgets/nori_vestida.dart';
import '../widgets/preview_identidad_tienda.dart';
import '../widgets/superficie_identidad.dart';

class TiendaScreen extends StatefulWidget {
  final int usuarioId;
  const TiendaScreen({super.key, required this.usuarioId});

  /// Seams de test: todo lo que la tienda pide al backend pasa por aquí (y por
  /// los de `Equipamiento` al equipar). En producción, `ApiServiceCore`.
  @visibleForTesting
  static Future<int> Function(int) obtenerSaldo = ApiServiceCore.getSaldoPuntos;

  @visibleForTesting
  static Future<List<dynamic>> Function() obtenerCatalogo =
      ApiServiceCore.getCatalogoProductos;

  @visibleForTesting
  static Future<List<dynamic>> Function(int) obtenerInventario =
      ApiServiceCore.getInventarioProductos;

  @visibleForTesting
  static Future<List<String>> Function(int, int) comprar =
      ApiServiceCore.comprarProducto;

  /// La marca en `SharedPreferences` de la pista de la primera vez. Los tests
  /// la preparan con `SharedPreferences.setMockInitialValues`.
  static const clavePistaVista = 'pista_vista_tienda';

  /// Seam de test: la fecha del móvil, con la que se elige la oferta vigente.
  @visibleForTesting
  static DateTime Function() ahora = DateTime.now;

  @visibleForTesting
  static void reiniciarParaTest() {
    obtenerSaldo = ApiServiceCore.getSaldoPuntos;
    obtenerCatalogo = ApiServiceCore.getCatalogoProductos;
    obtenerInventario = ApiServiceCore.getInventarioProductos;
    comprar = ApiServiceCore.comprarProducto;
    ahora = DateTime.now;
  }

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

  /// La Nori pequeña de cada prenda la lleva puesta ella sola: un notifier
  /// fijo por prenda, para que `NoriVestida` no vuelva a pedir sus ficheros
  /// en cada repintado.
  final Map<String, ValueNotifier<Map<String, String>>> _soloPrenda = {};

  /// La pista de la primera vez está a la vista.
  bool _pistaVisible = false;

  /// Ya se decidió si sale (una sola vez por apertura de la pantalla): las
  /// recargas tras comprar o equipar no vuelven a preguntar.
  bool _pistaDecidida = false;

  @override
  void dispose() {
    for (final n in _soloPrenda.values) {
      n.dispose();
    }
    super.dispose();
  }

  /// Iconografía por categoría, en Lucide como todo el resto de la app. Antes
  /// eran emoji, que los pinta la fuente del sistema: cambian de dibujo, de
  /// color y de peso entre Android, iOS y versión, así que no se pueden alinear
  /// con ninguna identidad ni con el resto de iconos.
  static const iconosCategoria = {
    'Tema': LucideIcons.palette,
    'Protección': LucideIcons.shield,
    'Avatar': LucideIcons.userRound,
    // Sin esta entrada, la comida caía en iconoCategoriaDesconocida y se
    // dibujaba con la caja genérica. La categoría la manda el backend con
    // la C mayúscula: 'Consumible', no 'CONSUMIBLE' (eso es el `tipo`).
    'Consumible': LucideIcons.apple,
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
      final saldo = await TiendaScreen.obtenerSaldo(widget.usuarioId);
      final catalogo = await TiendaScreen.obtenerCatalogo();
      final inventario = await TiendaScreen.obtenerInventario(widget.usuarioId);

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
      await _decidirPista();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _mostrarError(e);
    }
  }

  /// Sale si es la primera vez (no hay marca en `SharedPreferences`), y sólo
  /// con la tienda cargada: con error no se llama. La marca se guarda al
  /// mostrarla, no al cerrarla: si se sale sin tocarla, no se repite.
  Future<void> _decidirPista() async {
    if (_pistaDecidida) return;
    _pistaDecidida = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(TiendaScreen.clavePistaVista) ?? false) return;
      await prefs.setBool(TiendaScreen.clavePistaVista, true);
      if (!mounted) return;
      setState(() => _pistaVisible = true);
      // Sin `await`: `pistaVista` no lanza y la tienda no espera a nadie.
      unawaited(AnalyticsCore.pistaVista('tienda'));
    } catch (e) {
      debugPrint('Tienda: no se pudo decidir la pista: $e');
    }
  }

  Future<void> _comprar(int productoId) async {
    setState(() => _procesando = productoId);
    List<String> logros = const [];
    try {
      logros = await TiendaScreen.comprar(widget.usuarioId, productoId);
      await _cargarDatos();
    } on ApiException catch (e) {
      if (e.codigoEstado == 409) {
        // Fuera de temporada, hay que actualizar la app o ya es tuyo (otro
        // móvil, un doble toque). No es un fallo de red: se dice con un texto
        // propio (el del backend va en un solo idioma) y la tienda se pone al
        // día. Cerca de medianoche el catálogo (UTC) y la compra (zona del
        // usuario) pueden no coincidir.
        if (mounted) {
          _avisar(NordayCoreLocalizations.of(context)!.tiendaCompraRechazada);
        }
        await _cargarDatos();
      } else if (e.codigoEstado == 400) {
        // Saldo insuficiente (el saldo cambió en otro móvil). No se mira el
        // texto del mensaje: se recarga para que el botón pase a «Te faltan N
        // puntos» y se sigue diciendo el error genérico.
        _mostrarError(e);
        await _cargarDatos();
      } else {
        _mostrarError(e);
      }
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

  Future<void> _equipar(
    int productoId,
    String? codigo,
    String categoria,
  ) async {
    setState(() => _procesando = productoId);
    List<String> logros = const [];
    try {
      if (categoria == 'Tema') {
        logros = await Equipamiento.equiparTema(
          widget.usuarioId,
          productoId,
          codigo,
        );
      } else if (categoria == 'Avatar') {
        await Equipamiento.equiparAvatar(widget.usuarioId, productoId, codigo);
      } else if (sitiosPrenda.contains(categoria) && codigo != null) {
        logros = await Equipamiento.equiparPrenda(
          widget.usuarioId,
          productoId,
          codigo,
          categoria,
        );
      }
      await _cargarDatos();
    } catch (e) {
      _mostrarError(e);
    } finally {
      if (mounted) setState(() => _procesando = null);
    }
    // Fuera del try y tras recargar, igual que en _comprar: si falla la
    // recarga, el equipado sí ocurrió y su logro se celebra igual.
    if (mounted) await CelebracionService.mostrar(logros);
  }

  void _avisar(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  void _mostrarError(Object e) {
    if (mounted) {
      MensajesError.enSnackBar(
        context,
        e,
        generico: NordayCoreLocalizations.of(context)!.tiendaError,
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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l.tiendaTitulo),
            AyudaCampo(
              id: 'tienda',
              texto: l.tiendaAyuda,
              etiquetaSemantica: l.tiendaAyudaEtiqueta,
              superindice: true,
            ),
          ],
        ),
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
          const Positioned.fill(child: FondoIdentidad.habitacion()),
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
                          opacidadSuperficie: 0.75,
                          relleno: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Icon(
                                LucideIcons.coins,
                                color: t.points,
                                size: 40,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$_saldo',
                                style: Theme.of(context).textTheme.displaySmall
                                    ?.copyWith(color: t.text),
                              ),
                              Text(
                                l.puntos,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: t.textMuted),
                              ),
                            ],
                          ),
                        ),
                        if (_pistaVisible) ...[
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => setState(() => _pistaVisible = false),
                            child: BurbujaContexto(texto: l.tiendaPista),
                          ),
                        ],
                        ..._seccionNori(l, t),
                        const SizedBox(height: 16),
                        Text(
                          l.tiendaCatalogo,
                          style: Theme.of(
                            context,
                          ).textTheme.headlineSmall?.copyWith(color: t.text),
                        ),
                        const SizedBox(height: 8),
                        for (final producto in _catalogo)
                          if (!esPrenda(producto as Map) &&
                              _precioHoy(producto) != null)
                            _productoCard(l, producto, t),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _productoCard(
    NordayCoreLocalizations l,
    dynamic producto,
    TokensContextuales t,
  ) {
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

    final precioHoy = _precioHoy(producto)!.precio;
    return SuperficieIdentidad(
      // Es un elemento de lista, no el protagonista de la pantalla: radio
      // secundario.
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
                child: Text(
                  CatalogosCore.producto(
                    context,
                    producto['codigo'],
                    producto['nombre'],
                  ),
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: t.text),
                ),
              ),
              if (equipado)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: t.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    l.tiendaEquipado,
                    style: Theme.of(
                      context,
                    ).textTheme.labelMedium?.copyWith(color: t.successText),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            CatalogosCore.productoDescripcion(
              context,
              producto['codigo'],
              producto['descripcion'],
            ),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: t.textMuted),
          ),
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
              // Flexible: con «Te faltan N puntos» el botón es más ancho y el
              // precio cede en vez de desbordar la fila.
              Flexible(
                child: Text(
                  tipo == 'CONSUMIBLE' && cantidad > 0
                      ? l.tiendaPrecioConCantidad(precioHoy, cantidad)
                      : l.tiendaPrecio(precioHoy),
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: t.textMuted),
                ),
              ),
              const SizedBox(width: 8),
              _botonAccion(
                l,
                productoId,
                tipo,
                poseido,
                equipado,
                codigo,
                categoria,
                procesandoEste,
                precioHoy,
              ),
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
      child: Image.asset(
        avatar.asset,
        package: 'norday_flutter_core',
        width: 24,
        height: 24,
      ),
    );
  }

  /// Enseña el tema antes de pagarlo. Las acciones cierran la hoja y delegan
  /// en los mismos métodos de la tarjeta: la hoja no duplica nada del estado
  /// de compra, sólo evita el viaje de vuelta.
  void _abrirPrevisualizacion(
    NordayCoreLocalizations l,
    dynamic producto,
    IdentidadPaleta identidad,
  ) {
    final productoId = producto['productoId'] as int;
    final codigo = producto['codigo'] as String?;
    final categoria = producto['categoria'] as String;
    final info = _inventario[productoId];
    final poseido = info != null;
    final equipado = info?['equipado'] == true;
    final precio = _precioHoy(producto as Map)?.precio ?? 0;
    final faltan = !poseido && precio > 0 ? precio - _saldo : 0;

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
              Text(
                CatalogosCore.producto(context, codigo, producto['nombre']),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
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
                        onPressed: faltan > 0
                            ? null
                            : () {
                                Navigator.pop(hoja);
                                if (poseido) {
                                  _equipar(productoId, codigo, categoria);
                                } else {
                                  _comprar(productoId);
                                }
                              },
                        child: Text(
                          poseido
                              ? l.tiendaEquipar
                              : faltan > 0
                              ? l.tiendaTeFaltan(faltan)
                              : l.tiendaComprar,
                        ),
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

  Widget _botonAccion(
    NordayCoreLocalizations l,
    int productoId,
    String tipo,
    bool poseido,
    bool equipado,
    String? codigo,
    String categoria,
    bool procesando,
    int precio,
  ) {
    if (procesando) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (tipo == 'EQUIPABLE') {
      if (!poseido) {
        return _botonComprar(l, productoId, precio);
      }
      if (equipado) {
        return const SizedBox.shrink();
      }
      return OutlinedButton(
        onPressed: () => _equipar(productoId, codigo, categoria),
        child: Text(l.tiendaEquipar),
      );
    }

    // CONSUMIBLE. Se compra aquí y se gasta en Mascota, que es donde está la
    // mascota a la que alimenta. La cantidad que ya tienes se lee en el
    // precio, no en el botón: el botón siempre hace lo mismo.
    return _botonComprar(l, productoId, precio);
  }

  /// «Comprar», o, si hoy no es gratis y el saldo no llega, un botón
  /// deshabilitado con lo que falta.
  Widget _botonComprar(NordayCoreLocalizations l, int productoId, int precio) {
    final faltan = precio > 0 ? precio - _saldo : 0;
    if (faltan > 0) {
      return ElevatedButton(
        onPressed: null,
        child: Text(l.tiendaTeFaltan(faltan)),
      );
    }
    return ElevatedButton(
      onPressed: () => _comprar(productoId),
      child: Text(l.tiendaComprar),
    );
  }

  /// El precio de hoy, con la fecha del móvil; `null` si hoy no se vende
  /// (todas sus ofertas son de otros días).
  PrecioTienda? _precioHoy(Map producto) =>
      precioEnTienda(producto, TiendaScreen.ahora());

  /// La sección «Nori» (Nori vestida, N-10): las prendas que se venden hoy,
  /// agrupadas por colección en el orden del catálogo, y al final las que no
  /// tienen. Una colección que este cliente no sabe nombrar va sin título,
  /// nunca con el código crudo. Sin prendas a la venta, no sale.
  List<Widget> _seccionNori(NordayCoreLocalizations l, TokensContextuales t) {
    final grupos = <String?, List<Map>>{};
    for (final producto in _catalogo) {
      if (producto is! Map || !esPrenda(producto)) continue;
      if (_precioHoy(producto) == null) continue;
      final coleccion = producto['coleccion'];
      grupos
          .putIfAbsent(coleccion is String ? coleccion : null, () => [])
          .add(producto);
    }
    if (grupos.isEmpty) return const [];
    final sinColeccion = grupos.remove(null);
    final texto = Theme.of(context).textTheme;
    return [
      const SizedBox(height: 16),
      Text(
        l.tiendaSeccionNori,
        style: texto.headlineSmall?.copyWith(color: t.text),
      ),
      for (final MapEntry(key: codigo, value: prendas) in grupos.entries) ...[
        const SizedBox(height: 8),
        if (CatalogosCore.coleccion(context, codigo, '') case final nombre
            when nombre.isNotEmpty) ...[
          Text(nombre, style: texto.titleSmall?.copyWith(color: t.textMuted)),
          const SizedBox(height: 8),
        ],
        for (final p in prendas) _prendaCard(l, p, t),
      ],
      if (sinColeccion != null) ...[
        const SizedBox(height: 8),
        for (final p in sinColeccion) _prendaCard(l, p, t),
      ],
    ];
  }

  ValueNotifier<Map<String, String>> _notifierSolo(
    String sitio,
    String codigo,
  ) => _soloPrenda.putIfAbsent(
    '$sitio|$codigo',
    () => ValueNotifier(Map.unmodifiable({sitio: codigo})),
  );

  /// Una prenda: Nori pequeña que la lleva puesta, el nombre, el precio de hoy
  /// («Gratis», «Hasta el…») o «Tuyo», y los botones «Probar» y comprar o
  /// equipar.
  Widget _prendaCard(
    NordayCoreLocalizations l,
    Map producto,
    TokensContextuales t,
  ) {
    final productoId = producto['productoId'] as int;
    final codigo = producto['codigo'] as String?;
    final sitio = producto['categoria'] as String;
    final nombre = CatalogosCore.producto(
      context,
      codigo,
      producto['nombre'] as String? ?? '',
    );
    final info = _inventario[productoId];
    final poseido = info != null;
    final equipado = info?['equipado'] == true;
    final precio = _precioHoy(producto)!;
    final texto = Theme.of(context).textTheme;

    final String detalle;
    if (poseido) {
      detalle = l.tiendaTuyo;
    } else {
      final cifra = precio.gratis
          ? l.tiendaGratis
          : l.tiendaPrecio(precio.precio);
      final hasta = precio.hasta;
      detalle = hasta == null
          ? cifra
          : '$cifra · ${l.tiendaHastaEl(_fechaCorta(hasta))}';
    }

    return SuperficieIdentidad(
      key: ValueKey('tienda_prenda_$productoId'),
      margen: const EdgeInsets.only(bottom: 8),
      relleno: const EdgeInsets.all(16),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: codigo == null
                ? null
                : NoriVestida(
                    fase: 'CRIA',
                    estado: 'feliz',
                    tamano: 64,
                    prendas: _notifierSolo(sitio, codigo),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nombre, style: texto.titleMedium?.copyWith(color: t.text)),
                const SizedBox(height: 4),
                Text(
                  detalle,
                  style: texto.labelMedium?.copyWith(color: t.textMuted),
                ),
                const SizedBox(height: 8),
                // Wrap: «Te faltan N puntos» es un botón ancho y en una tarjeta
                // estrecha baja de línea en vez de desbordar.
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (codigo != null)
                      TextButton(
                        onPressed: () => _abrirProbar(nombre, sitio, codigo),
                        child: Text(l.tiendaProbar),
                      ),
                    if (equipado)
                      Text(
                        l.tiendaEquipado,
                        style: texto.labelMedium?.copyWith(
                          color: t.successText,
                        ),
                      )
                    else
                      _botonAccion(
                        l,
                        productoId,
                        'EQUIPABLE',
                        poseido,
                        equipado,
                        codigo,
                        sitio,
                        _procesando == productoId,
                        precio.precio,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// La fecha corta en el idioma activo: «6 ene», «Jan 6», «6 de jan.».
  String _fechaCorta(DateTime dia) => DateFormat.MMMd(
    Localizations.localeOf(context).toLanguageTag(),
  ).format(dia);

  /// «Probar» (decisión 13): Nori en grande con la prenda puesta en su sitio y
  /// el resto de lo que lleva. Ni equipa ni compra: no llama al backend (la
  /// imagen de la prenda sí puede bajarse del servidor del arte).
  void _abrirProbar(String nombre, String sitio, String codigo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _HojaProbar(nombre: nombre, sitio: sitio, codigo: codigo),
    );
  }
}

class _HojaProbar extends StatefulWidget {
  final String nombre;
  final String sitio;
  final String codigo;

  const _HojaProbar({
    required this.nombre,
    required this.sitio,
    required this.codigo,
  });

  @override
  State<_HojaProbar> createState() => _HojaProbarState();
}

class _HojaProbarState extends State<_HojaProbar> {
  /// Lo que lleva ahora, con esta prenda en su sitio. Fijo mientras la hoja
  /// está abierta.
  late final ValueNotifier<Map<String, String>> _puesta = ValueNotifier(
    Map.unmodifiable({
      ...prendasEquipadasNotifier.value,
      widget.sitio: widget.codigo,
    }),
  );

  @override
  void dispose() {
    _puesta.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = NordayCoreLocalizations.of(context)!;
    final lado = (MediaQuery.sizeOf(context).width * 0.6).clamp(120.0, 280.0);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.nombre,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Center(
              child: SizedBox(
                width: lado,
                height: lado,
                child: NoriVestida(
                  fase: 'CRIA',
                  estado: 'feliz',
                  tamano: lado,
                  prendas: _puesta,
                ),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l.comunCerrar),
            ),
          ],
        ),
      ),
    );
  }
}
