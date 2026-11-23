import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Motor: los eventos que tiene cualquier app del ecosistema — entrar y
/// darse de alta. Lo que se mide del dominio (hábitos, lecciones...) lo
/// registra cada app con su propio servicio encima de [analytics].
///
/// Medir nunca puede romper lo que se mide: ningún método de aquí lanza. Si
/// Firebase falla —sin inicializar, sin red, un fallo de plataforma— el evento
/// se pierde y queda una línea en el log. Así quien llama puede hacer `await`
/// dentro de su propio `try` sin que un fallo de Analytics se confunda con un
/// fallo de la acción.
class AnalyticsCore {
  /// Acceder a esto directamente SÍ puede lanzar. Quien lo use fuera de esta
  /// clase tiene que capturar por su cuenta, igual que hacen los métodos de
  /// abajo.
  static final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  /// Lo que de verdad manda un evento a Firebase. Sustituible en tests, donde
  /// Firebase no está inicializado.
  @visibleForTesting
  static Future<void> Function(String nombre, Map<String, Object> parametros)
  enviarEvento = _enviarAFirebase;

  static Future<void> _enviarAFirebase(
    String nombre,
    Map<String, Object> parametros,
  ) => analytics.logEvent(name: nombre, parameters: parametros);

  /// Se abrió la nota de un [AyudaCampo]. [id] identifica la ayuda, en
  /// minúsculas y con guiones bajos (`tienda`, `coleccion`...).
  static Future<void> ayudaAbierta(String id) async {
    try {
      await enviarEvento('ayuda_abierta', {'ayuda': id});
    } catch (e) {
      debugPrint('Analytics: no se registró ayuda_abierta: $e');
    }
  }

  /// Un paso del aviso de versión nueva ([AvisoActualizacion]): [paso] es
  /// `ofrecida`, `aceptada`, `rechazada`, `descargada` o `reiniciada`.
  static Future<void> avisoActualizacion(String paso) async {
    try {
      await enviarEvento('aviso_actualizacion', {'paso': paso});
    } catch (e) {
      debugPrint('Analytics: no se registró aviso_actualizacion: $e');
    }
  }

  /// Un paso de la tarjeta de versión recomendada: [paso] es `ofrecida`,
  /// `actualizar` o `ahora_no`.
  static Future<void> versionRecomendada(String paso) async {
    try {
      await enviarEvento('version_recomendada', {'paso': paso});
    } catch (e) {
      debugPrint('Analytics: no se registró version_recomendada: $e');
    }
  }

  static Future<void> registro(int usuarioId) async {
    try {
      await analytics.setUserId(id: usuarioId.toString());
      await analytics.logEvent(name: 'registro_completado');
    } catch (e) {
      debugPrint('Analytics: no se registró registro_completado: $e');
    }
  }

  static Future<void> login(int usuarioId) async {
    try {
      await analytics.setUserId(id: usuarioId.toString());
      await analytics.logEvent(name: 'login');
    } catch (e) {
      debugPrint('Analytics: no se registró login: $e');
    }
  }
}
