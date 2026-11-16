# Changelog

Las versiones anteriores a la 0.55.0 no tienen entrada aquí: su historia
está en `git log`.

## Sin publicar

### Nuevo

- **Nori canónica** (Nori vestida, N-1 y N-2): `assets/mascota/canonica/`,
  los 12 dibujos de Nori separados en cuerpo y brote, con su geometría
  (`docs/funcionamiento/nori-canonica.md`), y `tool/nori_canonica/`, el
  script que los separa y la hoja de revisión del arte. No se declaran aún
  en el `pubspec.yaml`: las apps no cambian.
- **`ImagenMascota`** (`widgets/imagen_mascota.dart`) y
  `ladoOriginalMascota`: una ilustración de Nori descodificada a
  `tamaño × densidad × margen` píxeles, nunca más de 1024 (Nori vestida,
  N-3).

### Cambia

- `MascotaAnimadaViva` (y con ella `MiniMascota`, `NoriMarca` y la pantalla
  de Nori), el selector de fases de `MascotaScreen` y `AvatarUsuario` sin
  avatar ya no descodifican el PNG de 1024 × 1024 entero (4 MB por imagen):
  lo piden a su tamaño en pantalla. `MascotaAnimadaViva` deja un margen de
  1,25 para el estirón de la respiración y el squish.

## 0.55.0 — 15-nov-2026

### Nuevo

- **`TextosApp`** (`l10n/textos_app.dart`): cada app registra en `main()` su
  nombre, el lema del login, el texto de la actualización obligatoria y el de
  borrado de cuenta (`TextosApp.registrar(...)`). Lo que no registre cae en
  un texto neutro del core.
- **Sesión de concentración con bloqueo suave**:
  - `SesionConcentracion`, `EstadoSesion`, `MotivoPerdida`, `ReglasSesion`
    y `generarClave()` (`services/sesion_concentracion.dart`): la máquina de
    estados pura.
  - `SesionConcentracion.versionFormato` (1), `marcarSalidaPendiente`,
    `quitarSalidaPendiente` y `salidaPendienteMonoMs`.
  - `MotorSesion`, `FuenteReloj`, `FuentePantalla`, `AvisosSesion` y
    `AvisosSesionNulos` (`services/motor_sesion.dart`): ciclo de vida,
    persistencia, recomposición y avisos. `MotorSesion.avisarDesbloqueo()`
    (la app lo llama desde un receptor de `ACTION_USER_PRESENT`) y el
    parámetro `intervaloVigilancia` (2 s): en `paused` con la sesión
    corriendo se consulta la pantalla periódicamente. Sin servicio en primer
    plano no hay garantía completa: Android puede congelar la app.
  - `AroCuentaAtras` (`widgets/aro_cuenta_atras.dart`).
  - Textos: `sesionAvisoSalir`, `sesionAvisoGraciaTitulo`,
    `sesionAvisoGraciaCuerpo`, `sesionAvisoFinTitulo`, `sesionAvisoFinCuerpo`
    y `aroCuentaAtrasEtiqueta` (es, en, pt).

### Cambia

- `appTitulo`, `loginTagline`, `actualizacionTexto` y `perfilEliminarCuerpo`
  pasan a ser la caída neutra («Norday» y frases sin dominio). Las claves
  siguen existiendo. **Una app que no registre sus textos con `TextosApp`
  verá los neutros**: Norday Habits tiene que registrarlos al subir a esta
  versión.
- **`appTitulo` vale ahora «Norday», no «Norday Habits».** Quien lo lea
  directamente —por ejemplo, `onGenerateTitle` del `MaterialApp`, como hace
  hoy Norday Habits— verá «Norday» en el título de la tarea (Recientes)
  hasta que use su propio texto.
- `ApiServiceCore.actualizarFcmToken` manda la cabecera `X-Norday-App` con
  `ApiServiceCore.appId` (sin ella si `appId` está vacío), para que el
  backend guarde un token de avisos por app.

### Arreglado

- **`VersionMinimaService.vigilarAlVolver()` ya no comprueba en el arranque.**
  Escuchaba `onResume`, que en un arranque en frío de Android también salta
  (de ningún estado directamente a `resumed`): era una segunda petición
  además de la del splash y, con el proceso lanzado en segundo plano,
  fallaba por red. Ahora se ignora la primera llegada a primer plano, salvo
  que la app ya estuviera en `resumed` al empezar a vigilar. Volver del
  segundo plano y volver de `inactive` (cortina de notificaciones, diálogo
  del sistema) siguen comprobando. No se usa `onRestart` porque solo salta
  en `paused` → `hidden` y perdería las vueltas desde `inactive`.
- El log `Versión mínima: no se pudo comprobar` incluye el `cuerpo` de la
  `ApiException` (la causa real: DNS, TLS, el cuerpo de un 5xx).
  `ApiException.toString()` no cambia: lo que no se captura acaba en
  Crashlytics y no debe llevar cuerpos.
- `VersionMinimaService.reiniciarParaTest()` (`@visibleForTesting`), para
  los tests del ciclo de vida.

### Reglas de la sesión que conviene saber

- **Reinicio:** al recomponer, una sesión activa se da por perdida
  (`MotivoPerdida.reinicio`) si el reloj monótono está por debajo del
  inicio o si el instante de arranque del móvil (hora de pared menos
  monótono) se ha desplazado más de 5 minutos
  (`ReglasSesion.toleranciaArranque`). Eso incluye **cambiar la hora a mano
  más de 5 minutos con el proceso muerto** durante una sesión.
- Una marca provisional de salida (proceso muerto entre las dos consultas
  de pantalla) cuenta como salida al recomponer.

### Compatibilidad

- Ninguna firma pública existente cambia. Sin dependencias nuevas.
