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

## Versión recomendada (T-061b)

El aviso de Play solo sale si Google ya ofrece la versión en ese móvil y la app
viene de Play. Para el resto, el backend guarda una **versión recomendada** por
app (`versionRecomendada` en `GET /api/version/{appId}`, entero o `null`; sin
la clave, backend viejo, es `null`). No obliga: obligar es la mínima.

`comprobar` mira la recomendada **solo si en esa llamada el aviso de Play no
ha ofrecido nada** (no hay versión en Play, no es Android, no viene de Play,
o falló antes de ofrecer). Nunca salen los dos en la misma
apertura. Con `appId` vacío no pregunta.

- **Corte diario de Play.** Si hoy ya se ofreció o enseñó el aviso de Play
  (`aviso_actualizacion_dia`), `comprobar` lo cuenta como «Play ya ha hablado»:
  ese día tampoco sale la tarjeta, ni se pregunta al backend. Play ya habló de
  esa versión hoy y la tarjeta repetiría el mismo mensaje. Aceptado por
  Quim el 23-nov-2026.
- **Sale si** la instalada es menor que la recomendada y esa recomendada no se
  ha ofrecido ya en este móvil: `SharedPreferences`, clave
  `version_recomendada_ofrecida`, con el número. Se guarda al enseñarla, así
  que «Ahora no» (o tocar fuera) no vuelve hasta que el backend suba otra mayor.
  La sube Quim con un `UPDATE`.
- **La tarjeta** (`TarjetaVersionRecomendada`) va en un diálogo, sin bloquear a
  quien llama: `comprobar` termina al enseñarla. «Actualizar» abre Play por
  `ActualizacionObligatoriaScreen.abrirActualizacion()` (el mismo seam
  `actualizar`). En la app de prueba, la actualización dentro de la app
  falla (no se instaló desde Play) y se abre la ficha de Play de su paquete,
  `com.norday.habitos.prueba`, que no existe. Igual en la pantalla de
  versión obligatoria. Aceptado por Quim el 23-nov-2026: no rompe nada y
  solo la usa él.
- Nunca lanza: un fallo del backend, de la versión instalada o del diálogo se
  deja en el log y no sale nada.

Analytics: `AnalyticsCore.versionRecomendada(paso)` → evento
`version_recomendada`, `paso` = `ofrecida`, `actualizar` o `ahora_no`.

## Cómo está hecha

Una clase estática con el día y la última recomendada ofrecida en preferencias.
`comprobar` llama a `_avisoDePlay` (devuelve si ofreció algo) y, si no, a
`_comprobarRecomendada`. Todo lo que toca el exterior son seams
`@visibleForTesting`: `esAndroid`, `ahora`, `consultar`, `empezarFlexible`,
`completarFlexible` y `estadoInstalacion`; y, de la recomendada,
`VersionMinimaService.pedirVersionRecomendada` y `leerVersionInstalada`, y
`ActualizacionObligatoriaScreen.actualizar` para abrir Play.

## Solo funciona instalada desde Play

La API de Google solo responde a una app instalada desde Play. Con `flutter
run` o un APK suelto, `checkForUpdate` falla y `comprobar` no hace nada.

Para probarlo en un móvil: subir dos builds a una pista de pruebas interna
(la segunda con `versionCode` mayor), instalar la primera desde Play y abrir la
app cuando Play ya ofrezca la segunda (puede tardar). Para repetir el mismo
día hay que borrar la clave `aviso_actualizacion_dia` (borrar datos de la app).
Los tests no necesitan Play: sustituyen los seams.
