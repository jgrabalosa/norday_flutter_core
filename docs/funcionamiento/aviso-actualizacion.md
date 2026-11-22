# Aviso de versión nueva (`AvisoActualizacion`)

`lib/services/aviso_actualizacion.dart`, exportado desde el paquete. Avisa de
que hay una versión nueva **sin obligar**: obligar es cosa de la versión mínima
del backend (`VersionMinimaService` → `ActualizacionObligatoriaScreen`, modo
inmediato). Genérico: no sabe de ninguna app; cada app decide cuándo llama a
`AvisoActualizacion.comprobar(context)` (nunca durante el alta ni con otra
tarjeta abierta). Hoy solo lo llama Habits (T-058b).

## Cuándo avisa

1. Fuera de Android: nada.
2. Como mucho **una vez al día** (fecha del móvil, `SharedPreferences`, clave
   `aviso_actualizacion_dia`): si hoy ya se ofreció o se enseñó el aviso, nada.
3. `checkForUpdate()`. Cualquier error (instalada fuera de Play, sin Play, sin
   red): nada. `comprobar` nunca lanza.
4. Si ya hay una descarga terminada (`installStatus == downloaded`, de otro día
   y sin reiniciar): se enseña el aviso directamente.
5. Si hay versión y `flexibleUpdateAllowed`: se guarda el día y se llama a
   `startFlexibleUpdate()`, que enseña el diálogo de Google. Si dice que no,
   nada más hasta otro día. Mientras baja se escucha `installUpdateListener`;
   con `downloaded` sale el aviso, y la escucha se cancela con `downloaded`,
   `failed` o `canceled` (y si el usuario rechaza).

El aviso es un `SnackBar` de 10 s («Hay una versión nueva lista.» /
«Reiniciar»). **`completeFlexibleUpdate()` solo se llama al tocar «Reiniciar»**
(Google instala y reabre la app). Si no se toca, vuelve otro día o Play
actualiza por su cuenta.

Analytics: `AnalyticsCore.avisoActualizacion(paso)` → evento
`aviso_actualizacion`, `paso` = `ofrecida`, `aceptada`, `rechazada`,
`descargada` o `reiniciada`.

## Cómo está hecha

Una clase estática sin estado propio (el estado es el día en preferencias).
Todo lo que toca el exterior son seams `@visibleForTesting`: `esAndroid`,
`ahora`, `consultar`, `empezarFlexible`, `completarFlexible` y
`estadoInstalacion`. `ActualizacionObligatoriaScreen` no se toca: sigue con su
propio seam `actualizar`.

## Solo funciona instalada desde Play

La API de Google solo responde a una app instalada desde Play. Con `flutter
run` o un APK suelto, `checkForUpdate` falla y `comprobar` no hace nada.

Para probarlo en un móvil: subir dos builds a una pista de pruebas interna
(la segunda con `versionCode` mayor), instalar la primera desde Play y abrir la
app cuando Play ya ofrezca la segunda (puede tardar). Para repetir el mismo
día hay que borrar la clave `aviso_actualizacion_dia` (borrar datos de la app).
Los tests no necesitan Play: sustituyen los seams.
