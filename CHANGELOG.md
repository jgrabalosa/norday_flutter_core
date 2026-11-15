# Changelog

Las versiones anteriores a la 0.55.0 no tienen entrada aquí: su historia
está en `git log`.

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
  - `MotorSesion`, `FuenteReloj`, `FuentePantalla`, `AvisosSesion` y
    `AvisosSesionNulos` (`services/motor_sesion.dart`): ciclo de vida,
    persistencia, recomposición y avisos.
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
- `ApiServiceCore.actualizarFcmToken` manda la cabecera `X-Norday-App` con
  `ApiServiceCore.appId` (sin ella si `appId` está vacío), para que el
  backend guarde un token de avisos por app.

### Compatibilidad

- Ninguna firma pública existente cambia. Sin dependencias nuevas.
