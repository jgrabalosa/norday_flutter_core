/// Motor compartido del ecosistema Norday.
///
/// Todo lo genérico y reutilizable: red, sesión, temas y tokens de diseño,
/// gamificación, mascota, onboarding y preferencias. Nada de aquí sabe de
/// hábitos, lecciones ni de ningún otro dominio — eso lo pone cada app.
library;

export 'navegacion.dart';

// ── Servicios ────────────────────────────────────────────
export 'services/api_service_core.dart';
export 'services/api_error.dart';
export 'services/analytics_service.dart';
export 'services/celebracion_service.dart';
export 'services/sonido_service.dart';
export 'services/idioma_service.dart';
export 'services/zona_service.dart';

// ── Textos ───────────────────────────────────────────────
export 'l10n/norday_core_localizations.dart';
export 'l10n/catalogos_core.dart';
export 'l10n/mensajes_error.dart';
export 'l10n/mensajes_mascota.dart';

// ── Tema ─────────────────────────────────────────────────
export 'theme/app_theme.dart';
export 'theme/identidad_paleta.dart';
export 'theme/identidades_paleta.dart';
export 'theme/avatares.dart';
export 'theme/equipamiento.dart';
export 'theme/mascota_assets.dart';
export 'theme/mascota_refresh.dart';
export 'theme/tono_error.dart';

// ── Modelos ──────────────────────────────────────────────
export 'models/usuario.dart';

// ── Widgets ──────────────────────────────────────────────
export 'widgets/anillo_progreso.dart';
export 'widgets/anillo_identidad.dart';
export 'widgets/animacion_puntos.dart';
export 'widgets/burbuja_contexto.dart';
export 'widgets/burbuja_flotante.dart';
export 'widgets/campo_identidad.dart';
export 'widgets/celebracion_nivel.dart';
export 'widgets/check_circular.dart';
export 'widgets/halo_identidad.dart';
export 'widgets/logo_google.dart';
export 'widgets/mascota_animada_viva.dart';
export 'widgets/mini_mascota.dart';
export 'widgets/nori_marca.dart';
export 'widgets/onboarding_overlay.dart';
export 'widgets/selector_avatar_gratis.dart';
export 'widgets/selector_preferencias.dart';
export 'widgets/skeleton.dart';
export 'widgets/splash_generico.dart';
export 'widgets/superficie_identidad.dart';
export 'widgets/terrario_identidad.dart';
export 'widgets/valoracion_sheet.dart';
export 'widgets/wordmark_identidad.dart';

// ── Pantallas ────────────────────────────────────────────
export 'screens/eleccion_identidad_screen.dart';
export 'screens/login_screen.dart';
export 'screens/recuperacion_screen.dart';
export 'screens/tienda_screen.dart';
export 'screens/mascota_screen.dart';
export 'screens/logros_screen.dart';
export 'screens/coleccion_screen.dart';
export 'screens/perfil_screen.dart';
