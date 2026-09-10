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
