import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../l10n/norday_core_localizations.dart';
import '../services/idioma_service.dart';
import '../services/sonido_service.dart';
import '../services/zona_service.dart';
import '../theme/app_theme.dart';
import 'superficie_identidad.dart';

/// Dos selectores independientes: idioma y zona horaria.
///
/// Van juntos en la misma tarjeta porque se configuran a la vez, pero no
/// están acoplados: cambiar uno no toca el otro. Un brasileño y un portugués
/// hablan lo mismo y están a cuatro horas.
///
/// Motor: no conoce ningún concepto de hábitos.
class SelectorPreferencias extends StatefulWidget {
  final int usuarioId;
  const SelectorPreferencias({super.key, required this.usuarioId});

  @override
  State<SelectorPreferencias> createState() => _SelectorPreferenciasState();
}

class _SelectorPreferenciasState extends State<SelectorPreferencias> {
  String _zona = ZonaService.porDefecto;
  bool _sonidoActivado = SonidoService.activado;

  @override
  void initState() {
    super.initState();
    _cargarZona();
    _cargarSonido();
  }

  Future<void> _cargarSonido() async {
    await SonidoService.cargarPreferencia();
    if (!mounted) return;
    setState(() => _sonidoActivado = SonidoService.activado);
  }

  Future<void> _cambiarSonido(bool valor) async {
    setState(() => _sonidoActivado = valor);
    await SonidoService.establecerActivado(valor);
    if (mounted) {
      _avisar(NordayCoreLocalizations.of(context)!.preferenciasGuardadas);
    }
  }

  Future<void> _cargarZona() async {
    final guardada = await ZonaService.obtenerGuardada();
    if (!mounted) return;
    setState(() {
      _zona = guardada;
    });
  }

  Future<void> _cambiarIdioma(String codigo) async {
    await IdiomaService.cambiar(codigo, usuarioId: widget.usuarioId);
    if (mounted) {
      _avisar(NordayCoreLocalizations.of(context)!.preferenciasGuardadas);
    }
  }

  Future<void> _cambiarZona(String zona) async {
    await ZonaService.cambiar(zona, usuarioId: widget.usuarioId);
    if (!mounted) return;
    setState(() {
      _zona = zona;
    });
    _avisar(NordayCoreLocalizations.of(context)!.preferenciasGuardadas);
  }

  void _avisar(String mensaje) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  String _nombreIdioma(NordayCoreLocalizations l, String codigo) =>
      switch (codigo) {
        'en' => l.idiomaEn,
        'pt' => l.idiomaPt,
        _ => l.idiomaEs,
      };

  @override
  Widget build(BuildContext context) {
    final t = tokens(context);
    final l = NordayCoreLocalizations.of(context)!;

    return SuperficieIdentidad(
      margen: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.preferencias,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: t.text),
          ),
          Text(
            l.preferenciasSubtitulo,
            style: TextStyle(color: t.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 16),

          _filaPreferencia(
            t,
            icono: LucideIcons.languages,
            etiqueta: l.idioma,
            control: ValueListenableBuilder<Locale>(
              valueListenable: IdiomaService.localeNotifier,
              builder: (context, locale, _) => _marcoControl(
                t,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: locale.languageCode,
                    isExpanded: true,
                    isDense: true,
                    icon: Icon(
                      LucideIcons.chevronDown,
                      size: 16,
                      color: t.textMuted,
                    ),
                    items: IdiomaService.soportados
                        .map(
                          (codigo) => DropdownMenuItem<String>(
                            value: codigo,
                            child: Text(
                              _nombreIdioma(l, codigo),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (codigo) {
                      if (codigo != null) _cambiarIdioma(codigo);
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _filaPreferencia(
            t,
            icono: LucideIcons.clock,
            etiqueta: l.zonaHoraria,
            control: _marcoControl(
              t,
              child: InkWell(
                onTap: _abrirSelectorZona,
                borderRadius: BorderRadius.circular(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _zona.replaceAll('_', ' / '),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: t.text),
                      ),
                    ),
                    Icon(LucideIcons.chevronDown, size: 16, color: t.textMuted),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _filaPreferencia(
            t,
            icono: LucideIcons.volume2,
            etiqueta: l.sonido,
            control: SizedBox(
              height: 40,
              width: 56,
              child: Switch.adaptive(
                value: _sonidoActivado,
                onChanged: _cambiarSonido,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filaPreferencia(
    TokensContextuales t, {
    required IconData icono,
    required String etiqueta,
    required Widget control,
  }) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          Icon(icono, size: 18, color: t.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              etiqueta,
              style: TextStyle(color: t.text, fontWeight: FontWeight.w600),
            ),
          ),
          control,
        ],
      ),
    );
  }

  Widget _marcoControl(TokensContextuales t, {required Widget child}) {
    return SizedBox(
      width: 190,
      height: 40,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: t.textMuted.withValues(alpha: 0.55)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: child,
        ),
      ),
    );
  }

  Future<void> _abrirSelectorZona() async {
    final elegida = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ListaZonas(zonaActual: _zona),
    );
    if (elegida != null) await _cambiarZona(elegida);
  }
}

/// Lista de zonas con buscador. La detectada aparece primero.
class _ListaZonas extends StatefulWidget {
  final String zonaActual;
  const _ListaZonas({required this.zonaActual});

  @override
  State<_ListaZonas> createState() => _ListaZonasState();
}

class _ListaZonasState extends State<_ListaZonas> {
  String _filtro = '';

  /// Las zonas que cubren a los usuarios previsibles. No es la lista IANA
  /// entera a propósito: son ~600 y la mayoría son alias históricos.
  static const List<String> _zonas = [
    'Europe/Madrid',
    'Europe/Lisbon',
    'Europe/London',
    'Europe/Paris',
    'Europe/Berlin',
    'Europe/Rome',
    'Europe/Amsterdam',
    'Europe/Dublin',
    'Europe/Moscow',
    'Atlantic/Canary',
    'America/Sao_Paulo',
    'America/Argentina/Buenos_Aires',
    'America/Santiago',
    'America/Bogota',
    'America/Lima',
    'America/Mexico_City',
    'America/New_York',
    'America/Chicago',
    'America/Denver',
    'America/Los_Angeles',
    'America/Toronto',
    'Africa/Casablanca',
    'Africa/Lagos',
    'Africa/Johannesburg',
    'Africa/Cairo',
    'Asia/Jerusalem',
    'Asia/Dubai',
    'Asia/Kolkata',
    'Asia/Bangkok',
    'Asia/Shanghai',
    'Asia/Tokyo',
    'Asia/Seoul',
    'Asia/Manila',
    'Australia/Perth',
    'Australia/Sydney',
    'Pacific/Auckland',
  ];

  @override
  Widget build(BuildContext context) {
    final t = tokens(context);
    final l = NordayCoreLocalizations.of(context)!;
    final detectada = ZonaService.detectarDelDispositivo();

    final ordenadas = [
      if (_zonas.contains(detectada)) detectada,
      ..._zonas.where((z) => z != detectada),
    ];
    final visibles = ordenadas
        .where((z) => z.toLowerCase().contains(_filtro.toLowerCase()))
        .toList();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l.cambiarZona,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: t.text),
            ),
            const SizedBox(height: 12),
            TextField(
              autofocus: false,
              decoration: InputDecoration(
                hintText: l.buscarZona,
                prefixIcon: const Icon(LucideIcons.search, size: 18),
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _filtro = v),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.45,
              child: visibles.isEmpty
                  ? Center(
                      child: Text(
                        l.sinResultados,
                        style: TextStyle(color: t.textMuted),
                      ),
                    )
                  : ListView.builder(
                      itemCount: visibles.length,
                      itemBuilder: (context, i) {
                        final zona = visibles[i];
                        return ListTile(
                          title: Text(zona.replaceAll('_', ' ')),
                          subtitle: zona == detectada
                              ? Text(
                                  l.zonaDetectada,
                                  style: TextStyle(
                                    color: t.primary,
                                    fontSize: 11,
                                  ),
                                )
                              : null,
                          trailing: zona == widget.zonaActual
                              ? Icon(
                                  LucideIcons.check,
                                  color: t.primary,
                                  size: 18,
                                )
                              : null,
                          onTap: () => Navigator.pop(context, zona),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
