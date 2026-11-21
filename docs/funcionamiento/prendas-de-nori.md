# Las prendas de Nori (Nori vestida)

Movido del `CLAUDE.md` (sección «Equipamiento», subsección «Las prendas de
Nori»). El arte está en `arte-prendas.md` y `nori-canonica.md`.

Lo que lleva puesto Nori sale del mismo inventario, sin campos nuevos en el
backend: los productos equipados cuya `categoria` es un sitio de
`sitiosPrenda` (`theme/prendas.dart`: hoy `Cabeza` y `Cuerpo`; un sitio nuevo
se añade ahí y en `ordenCapasPrenda`, en su lugar de la pila). Se publica en
`prendasEquipadasNotifier`, un mapa de sitio a código de producto que no se
puede modificar desde fuera y que solo avisa si cambia; todas las Nori de la
app lo escuchan, así que cambian a la vez.

- **Equipar y quitar:** `Equipamiento.equiparPrenda(usuarioId, productoId,
  codigo, sitio)` y `desequiparPrenda(usuarioId, productoId, sitio)`. Cambian
  el notifier **solo si el backend contesta bien**; si falla, el error sube y
  no cambia nada. Otra prenda en el mismo sitio sustituye a la anterior (el
  backend deja una equipada por categoría). Un sitio que no existe se rechaza
  sin llamar al backend.
- **Sin red:** copia por usuario (`prendas_equipadas_<usuarioId>`, JSON), que
  se aplica solo si falla la red al arrancar y se corrige al leer el
  inventario. **A diferencia de la identidad, sin copia Nori se queda sin
  prendas**: lo que llevara puesto podría ser de otra cuenta del mismo móvil.
- **Backend antiguo** (sin `categoria`) o un sitio que el core no conoce: no
  cuenta, sin errores. Si un sitio tuviera dos equipadas (no debería, N-5),
  gana la de `usuarioProductoId` más alto.
- Pintarlas en Nori (las capas) es `NoriVestida` (N-9).
- **Dónde se ponen y se compran (N-10):** el vestidor (`VestidorNori`), en la
  pantalla de Nori, debajo del selector de fases, y la sección «Nori» de la
  tienda. **Las prendas no van en Colección** (se filtran antes de agrupar) y
  **el vestidor nunca las busca en el catálogo**: sale del inventario que la
  pantalla ya pide, porque al acabar la temporada la prenda deja de venderse
  pero sigue siendo tuya. La tienda enseña el precio de la oferta de hoy
  (`precioEnTienda`, con la fecha del móvil) y no enseña lo que hoy no se
  vende; «Probar» no llama al backend. Un 409 al comprar se dice con un texto
  propio (`tiendaCompraRechazada`), nunca con el del backend, y recarga.
