import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../l10n/norday_core_localizations.dart';
import '../theme/identidades_paleta.dart';
import '../theme/mascota_assets.dart';
import '../theme/progreso_dia.dart';
import 'idioma_service.dart';

/// Los datos que el widget nativo de Nori lee sin abrir la app (T-008).
///
/// El widget no calcula nada —ni el ánimo, ni la frase, ni el color—: lee lo
/// que este servicio deja con `home_widget`, y por eso su Nori es siempre la
/// de la app. El contrato de claves está en
/// `docs/funcionamiento/widget-nori.md`.
///
/// No hace nada hasta que la app llama a [iniciar] (con el nombre del
/// proveedor del widget): `conocimiento_app_mobile` no lo llama nunca y no se
/// entera de que existe. Es estático, como `NotificacionesService`.
///
/// **Nunca lanza.** Cualquier fallo —en `flutter test` no hay plataforma
/// nativa— se traga y se escribe con `debugPrint`: el widget es un extra y no
/// puede tumbar la app ni el cierre de sesión.
class WidgetNori {
  WidgetNori._();

  // ── Claves del contrato ─────────────────────────────────

  static const String claveSesion = 'nori_sesion';
  static const String claveFecha = 'nori_fecha';
  static const String claveFase = 'nori_fase';
  static const String claveNombre = 'nori_nombre';
  static const String claveAnimo = 'nori_animo';
  static const String claveAnimosSiguientes = 'nori_animos_siguientes';
  static const String claveHechos = 'nori_hechos';
  static const String claveTotal = 'nori_total';
  static const String claveAvance = 'nori_avance';
  static const String claveProgresoFecha = 'nori_progreso_fecha';
  static const String claveIdentidad = 'nori_identidad';

  /// Los cuatro ánimos del backend: de cada uno hay un dibujo y una frase.
  static const List<String> _animos = [
    'dormida',
    'feliz',
    'exultante',
    'triste',
  ];

  static const List<String> _clavesColor = [
    'nori_color_fondo',
    'nori_color_superficie',
    'nori_color_acento',
    'nori_color_texto',
    'nori_color_texto_suave',
  ];

  static const List<String> _clavesTexto = [
    'nori_frase_dormida',
    'nori_frase_feliz',
    'nori_frase_exultante',
    'nori_frase_triste',
    'nori_frase_huevo',
    'nori_texto_empieza',
    'nori_texto_sin_sesion',
    'nori_texto_todo_hecho',
    'nori_texto_progreso',
    'nori_texto_progreso_corto',
    'nori_texto_accesible',
  ];

  /// Todas las claves del contrato: lo que se borra al cerrar sesión.
  static final List<String> todasLasClaves = [
    claveSesion,
    claveFecha,
    claveFase,
    claveNombre,
    claveAnimo,
    claveAnimosSiguientes,
    for (final a in _animos) 'nori_asset_$a',
    claveHechos,
    claveTotal,
    claveAvance,
    claveProgresoFecha,
    claveIdentidad,
    ..._clavesColor,
    ..._clavesTexto,
  ];

  // ── Seams de test ───────────────────────────────────────

  /// Guarda una clave en el almacén del widget. Con `null` la borra.
  @visibleForTesting
  static Future<void> Function(String clave, Object? valor) guardarClave =
      _guardarReal;

  /// Pide al sistema que repinte el widget con ese nombre de proveedor.
  @visibleForTesting
  static Future<void> Function(String nombreAndroid) repintar = _repintarReal;

  /// El día de hoy, para decidir qué progreso cuenta.
  @visibleForTesting
  static DateTime Function() ahora = DateTime.now;

  @visibleForTesting
  static void reiniciarParaTest() {
    _detener();
    guardarClave = _guardarReal;
    repintar = _repintarReal;
    ahora = DateTime.now;
    _cola = Future<void>.value();
  }

  /// Lo que queda por escribir. Los tests lo esperan.
  @visibleForTesting
  static Future<void> get pendiente => _cola;

  // ── Estado ──────────────────────────────────────────────

  static String? _nombreAndroid;
  static Future<void> _cola = Future<void>.value();

  /// Si la app ya ha llamado a [iniciar].
  static bool get iniciado => _nombreAndroid != null;

  /// Arranca el servicio: desde aquí escucha el progreso, la identidad y el
  /// idioma, y recibe las lecturas de la mascota. [nombreAndroid] es el nombre
  /// del proveedor del widget, el que se pasa a `updateWidget`.
  ///
  /// Escribe ya la identidad y los textos del idioma actual, que no dependen
  /// de la sesión: así el widget puede pintarse, con su «Inicia sesión», antes
  /// del primer login. Llamarlo otra vez no duplica las escuchas.
  static void iniciar({required String nombreAndroid}) {
    try {
      _detener();
      _nombreAndroid = nombreAndroid;
      progresoDiaNotifier.addListener(_alCambiarProgreso);
      identidadEquipadaNotifier.addListener(_alCambiarIdentidad);
      IdiomaService.localeNotifier.addListener(_alCambiarIdioma);
      _encolar(() => _guardar({..._datosIdentidad(), ..._datosTextos()}));
    } catch (e) {
      debugPrint('WidgetNori.iniciar: $e');
    }
  }

  static void _detener() {
    progresoDiaNotifier.removeListener(_alCambiarProgreso);
    identidadEquipadaNotifier.removeListener(_alCambiarIdentidad);
    IdiomaService.localeNotifier.removeListener(_alCambiarIdioma);
    _nombreAndroid = null;
  }

  /// Lo llama `ApiServiceCore.getMascota` con cada lectura correcta.
  static void alLeerMascota(Map<String, dynamic> data) {
    if (!iniciado) return;
    try {
      _encolar(() => _guardar(_datosMascota(data)));
    } catch (e) {
      debugPrint('WidgetNori.alLeerMascota: $e');
    }
  }

  /// Lo llama `ApiServiceCore._limpiarSesionLocal`: borra todo lo del widget y
  /// deja [claveSesion] en `false`.
  static Future<void> alCerrarSesion() async {
    if (!iniciado) return;
    try {
      await _encolar(
        () => _guardar({
          for (final c in todasLasClaves) c: null,
          claveSesion: false,
        }),
      );
    } catch (e) {
      debugPrint('WidgetNori.alCerrarSesion: $e');
    }
  }

  // ── Escuchas ────────────────────────────────────────────

  static void _alCambiarProgreso() {
    try {
      final datos = _datosProgreso(progresoDiaNotifier.value);
      if (datos == null) return; // otro día de la tira: no cuenta
      _encolar(() => _guardar(datos));
    } catch (e) {
      debugPrint('WidgetNori progreso: $e');
    }
  }

  static void _alCambiarIdentidad() {
    try {
      _encolar(() => _guardar(_datosIdentidad()));
    } catch (e) {
      debugPrint('WidgetNori identidad: $e');
    }
  }

  static void _alCambiarIdioma() {
    try {
      _encolar(() => _guardar(_datosTextos()));
    } catch (e) {
      debugPrint('WidgetNori idioma: $e');
    }
  }

  // ── Qué se guarda ───────────────────────────────────────

  static Map<String, Object?> _datosMascota(Map<String, dynamic> data) {
    final fase = data['fase'] is String ? data['fase'] as String : 'HUEVO';
    // Sin ánimo, el mismo respaldo que `assetMascota`: nunca dar por hecho que
    // Nori está contenta.
    final animo = animoDeMascota(data) ?? 'triste';
    final nombre = data['nombre'];
    final siguientes = data['animosSiguientes'];
    return {
      claveSesion: true,
      claveFecha: _fecha(ahora()),
      claveFase: fase,
      claveNombre: nombre is String ? nombre : '',
      claveAnimo: animo,
      claveAnimosSiguientes: siguientes == null ? '[]' : jsonEncode(siguientes),
      for (final a in _animos)
        'nori_asset_$a': assetMascota(fase: fase, estado: a),
    };
  }

  /// El progreso de hoy, o `null` si [p] es de otro día o no hay día.
  static Map<String, Object?>? _datosProgreso(ProgresoDia p) {
    final f = p.fecha;
    if (f == null || _fecha(f) != _fecha(ahora())) return null;
    return {
      claveHechos: p.hechos,
      claveTotal: p.total,
      claveAvance: p.avance,
      claveProgresoFecha: _fecha(f),
    };
  }

  /// Los colores que la app usa para esos papeles: `bg` el fondo de pantalla,
  /// `surface` las tarjetas, `primary` el acento, `text` y `textMuted` la
  /// letra principal y la secundaria.
  static Map<String, Object?> _datosIdentidad() {
    final id = identidadEquipadaNotifier.value;
    final t = id.tokens;
    return {
      claveIdentidad: id.codigo,
      _clavesColor[0]: t.bg.toARGB32(),
      _clavesColor[1]: t.surface.toARGB32(),
      _clavesColor[2]: t.primary.toARGB32(),
      _clavesColor[3]: t.text.toARGB32(),
      _clavesColor[4]: t.textMuted.toARGB32(),
    };
  }

  /// Frases y textos en el idioma de la app. Sin `BuildContext`: se resuelve
  /// la clase generada directamente por el `Locale` del servicio de idioma.
  ///
  /// Los textos con cifras o frase se guardan con los marcadores `{hechos}`,
  /// `{total}` y `{frase}` sin sustituir: lo que cambia cada día lo rellena el
  /// widget nativo.
  static Map<String, Object?> _datosTextos() {
    final l = lookupNordayCoreLocalizations(IdiomaService.localeNotifier.value);
    return {
      'nori_frase_dormida': l.mascotaAnimoAtencion,
      'nori_frase_feliz': l.mascotaAnimoFeliz,
      'nori_frase_exultante': l.mascotaAnimoExultante,
      'nori_frase_triste': l.mascotaAnimoTriste,
      'nori_frase_huevo': l.mascotaAnimoHuevo,
      'nori_texto_empieza': l.widgetNoriEmpieza,
      'nori_texto_sin_sesion': l.widgetNoriSinSesion,
      'nori_texto_todo_hecho': l.widgetNoriTodoHecho,
      'nori_texto_progreso': l.widgetNoriProgreso('{hechos}', '{total}'),
      'nori_texto_progreso_corto': l.widgetNoriProgresoCorto(
        '{hechos}',
        '{total}',
      ),
      'nori_texto_accesible': l.widgetNoriAccesible(
        '{frase}',
        '{hechos}',
        '{total}',
      ),
    };
  }

  static String _fecha(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  // ── Escritura ───────────────────────────────────────────

  /// Encadena el trabajo para que las escrituras salgan en el orden en que
  /// ocurrieron los cambios. [trabajo] no lanza: se protege igualmente.
  static Future<void> _encolar(Future<void> Function() trabajo) {
    return _cola = _cola.then((_) async {
      try {
        await trabajo();
      } catch (e) {
        debugPrint('WidgetNori: $e');
      }
    });
  }

  /// Guarda cada clave por separado —un fallo no impide las demás— y después
  /// pide un repintado. Con [datos] vacío solo repinta.
  static Future<void> _guardar(Map<String, Object?> datos) async {
    for (final e in datos.entries) {
      try {
        await guardarClave(e.key, e.value);
      } catch (err) {
        debugPrint('WidgetNori: no se pudo guardar ${e.key}: $err');
      }
    }
    final nombre = _nombreAndroid;
    if (nombre == null) return;
    try {
      await repintar(nombre);
    } catch (err) {
      debugPrint('WidgetNori: no se pudo repintar: $err');
    }
  }

  static Future<void> _guardarReal(String clave, Object? valor) async {
    await HomeWidget.saveWidgetData<Object>(clave, valor);
  }

  static Future<void> _repintarReal(String nombreAndroid) async {
    await HomeWidget.updateWidget(androidName: nombreAndroid);
  }
}
