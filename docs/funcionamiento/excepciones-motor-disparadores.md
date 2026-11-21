# Excepciones conocidas a «Motor vs Disparadores»

Movido del `CLAUDE.md`. La regla (ningún widget ni servicio del core conoce
conceptos de dominio) sigue en el `CLAUDE.md`; aquí, lo que hoy se la salta.

**Excepciones conocidas**, que se saltan la regla y están pendientes de
limpiar (comprobadas contra el código el 20-nov-2026, v0.59.1):

- La vista previa de la tienda (`preview_identidad_tienda.dart`) pinta
  una pantalla «Hoy» de mentira con dos tarjetas de hábito y la pestaña
  «Hábitos», con textos del core: `plantillaBeberAgua`,
  `tiendaPreviewHabito2` y `tiendaPreviewNavHabitos` (más `navHoy` y
  `tiendaPreviewNavPerfil`, que son neutros). La ve cualquier app que abra la
  tienda o la elección de identidad. Limpiarla es rediseñar la maqueta, no
  cambiar textos: queda para cuando una segunda app la enseñe.
- `logroDescPrimerosPasos` («Completa tu primer hábito») es la descripción
  de un logro genérico del core, y `CatalogosCore` da prioridad a la del core
  sobre la que registre la app.
- `prodDescEscudoRacha` habla de hábitos, pero el producto está retirado
  (24-ago-2026) y el backend no lo manda.

Ya no son excepciones: `ApiServiceCore.appId` vale `''` por defecto (sin
app, no se manda `X-Norday-App`; cada app lo fija antes de `runApp`), y
`constelacionPara`/`nombreConstelacion` reciben un `total` neutro. Nombre,
lema del login, actualización obligatoria y borrado de cuenta salen de
`TextosApp` desde v0.55.0.
