# La sesión de concentración con bloqueo suave

Movido del `CLAUDE.md` (punto de extensión 12). Código:
`services/sesion_concentracion.dart`, `services/motor_sesion.dart` y
`widgets/aro_cuenta_atras.dart`.

12. **La sesión con bloqueo suave** (`services/sesion_concentracion.dart`,
   `services/motor_sesion.dart`, `widgets/aro_cuenta_atras.dart`). El core
   lleva la lógica; la app pone lo que es de plataforma o de dominio:
   - `FuenteReloj` (`Future<int> monotonicoMs()`, `DateTime ahoraUtc()`):
     el monótono es `SystemClock.elapsedRealtime` por un canal nativo de la
     app. Un `Stopwatch` de Dart no sirve: muere con el proceso.
   - `FuentePantalla` (`Future<bool> encendidaYDesbloqueada()`):
     `PowerManager.isInteractive && !KeyguardManager.isKeyguardLocked`.
   - `AvisosSesion` (`avisarGracia`, `cancelarGracia`, `programarFin`,
     `cancelarFin`), idempotentes y sin alarmas exactas. Al salir: aviso de
     gracia (la app lo hace caducar a `quedan`, `timeoutAfter`) y fuera el
     de fin; al volver a tiempo, fuera el de gracia y otra vez el de fin.
     Sin implementación, `AvisosSesionNulos`.

   **Decisión (15-nov-2026): los avisos de la sesión van por `AvisosSesion`,
   que implementa cada app, y no por `NotificacionesService` ni por una
   dependencia del core.** `NotificacionesService` es el permiso y el token
   de push del backend, no notificaciones locales. Y
   `flutter_local_notifications` obliga a activar el desugaring en el Gradle
   de la app aunque no se programe nada («even if they don't use scheduled
   notifications», README de la 23.0.2): en el core rompería el build
   Android de Norday Habits, que no lo tiene. El permiso
   `POST_NOTIFICATIONS` sí se pide con `NotificacionesService`.
   - `datosApp` (`Map` serializable): lo que la app quiera guardar con la
     sesión (a qué va dedicada). El core no lo mira.

   Reglas: gracia de 10 s y mínimo de 10 min (`ReglasSesion`, con los bordes
   dentro); terminar antes del mínimo da `descartada` (no se envía);
   rendirse o volver tarde, `perdida`; minutos = enteros hacia abajo y solo
   si cuenta. Sale de la app solo un `paused` con dos consultas de pantalla
   (al llegar y a los 400 ms) que digan encendida y desbloqueada; `inactive`
   y `hidden` nunca. Tras la primera consulta positiva se guarda una marca
   provisional (`salidaPendienteMonoMs`): si el proceso muere antes de la
   segunda, al recomponer cuenta como salida desde la marca. `detached` con
   la pantalla encendida sale sin esperar a la segunda consulta.
   Bloquear, desbloquear y abrir otra app puede no pasar por `resumed`: en
   `paused` con la sesión corriendo se consulta la pantalla cada 2 s, y la
   app llama a `MotorSesion.avisarDesbloqueo()` desde un receptor nativo de
   `ACTION_USER_PRESENT`. **Limitación:** Android puede congelar o matar la
   app en segundo plano y entonces nada de eso corre; sin servicio en primer
   plano no hay garantía completa. La meta alcanzada dentro de la gracia da `completada`.
   Reinicio del móvil (monótono por debajo del inicio, o el instante de
   arranque desplazado más de 5 min, que también salta con un cambio manual
   de hora con el proceso muerto) → `perdida`. `inactive` cuenta como
   delante para la cuenta atrás. `SesionConcentracion.versionFormato` es la
   1: para cambiar el formato se sube y se añade la migración en `_migrar`,
   sin descartar sesiones acabadas sin enviar. Cada transición se guarda
   en `SharedPreferences` (`sesion_concentracion_actual`); una sesión
   acabada se queda guardada hasta que la app la recoge y llama a
   `MotorSesion.cerrar()`. Una sola sesión a la vez.
