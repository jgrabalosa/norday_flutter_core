import 'package:firebase_analytics/firebase_analytics.dart';

/// Motor: los eventos que tiene cualquier app del ecosistema — entrar y
/// darse de alta. Lo que se mide del dominio (hábitos, lecciones...) lo
/// registra cada app con su propio servicio encima de [analytics].
class AnalyticsCore {
  static final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  static Future<void> registro(int usuarioId) async {
    await analytics.setUserId(id: usuarioId.toString());
    await analytics.logEvent(name: 'registro_completado');
  }

  static Future<void> login(int usuarioId) async {
    await analytics.setUserId(id: usuarioId.toString());
    await analytics.logEvent(name: 'login');
  }
}
