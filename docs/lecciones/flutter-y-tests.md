# Lecciones: Flutter y tests

Movido del `CLAUDE.md` (Lecciones aprendidas › Flutter y tests). Errores que ya
se cometieron una vez. No se vuelven a cometer.

- **En `flutter test` Firebase no está inicializado**: acceder a
  `FirebaseAnalytics.instance` lanza `[core/no-app]`. Sirve para probar que un
  servicio no deja escapar el fallo. Ojo en sentido contrario: un servicio de
  aquí que espere a Firebase sin que la app lo haya inicializado bloquea el
  login de esa app.
- **`MaterialApp` interpola el tema con `AnimatedTheme`** y `TextStyle.lerp` no
  mezcla familias: en tests que cambian de identidad, `pumpAndSettle`, no
  `pump`.
- **El ticker de una animación toma la hora de inicio en su primer tic**: en
  tests de duración, un `pump()` sin duración antes de medir.
- **`containsSemantics` está deprecado desde Flutter 3.40** en favor de
  `isSemantics`, que tiene los mismos parámetros y también sólo comprueba lo
  indicado.
- **Tras editar un ARB, `flutter analyze` no regenera las traducciones**:
  `flutter gen-l10n` antes.
- **El analizador de Dart promociona a no nulo a través de un `bool`
  intermedio.** Si `final bool b = x != null && ...`, dentro de `if (b)` la
  variable `x` ya es no nula: añadir `&& x != null` ahí dispara
  `unnecessary_null_comparison`.
- **Test en rojo antes del arreglo.** Si el test nuevo pasa contra el código
  sin arreglar, no demuestra nada: parar.
- **Para comprobar que algo NO se oye, `find.semantics.byLabel`, no `find.bySemanticsLabel`.** El segundo mira el nodo que guarda el render object, que se queda viejo cuando un `ExcludeSemantics` lo saca del árbol: «encuentra» lo que el lector ya no lee.

- **`clamp(a, b)` lanza `ArgumentError` si `a > b`, y un recorrido calculado
  puede salir negativo o cero.** `BurbujaFlotante` se cerraba al arrastrarla
  en un área baja (11 fallos en Crashlytics): `minY > maxY`, `maxX < margen` y
  una división por `maxY - minY` a cero. Todo recorrido calculado se protege
  (`max(0.0, …)`) antes de usarlo como límite de `clamp`, como divisor o como
  `width`/`height`; y los límites se derivan del recorrido ya protegido
  (`minY + recorridoY`), no de las cifras en bruto. Los tests de layout
  prueban también áreas absurdas (cero, más pequeñas que el widget).

- **Una imagen para compartir lleva una base opaca y un test que lo vigila.**
  `FondoIdentidad` no pinta base (en la app la pone el `Scaffold`): la postal
  de Nori (T-063a) salió transparente, negra en WhatsApp y con las letras de
  Profundidad ilegibles, y los tests seguían en verde. Toda tarjeta que se
  captura con `toImage` empieza con `ColoredBox(color: t.bg)`, como
  `TarjetaCierreDia`, y lleva un test que captura y mira el alfa de las
  esquinas en las tres identidades (`test/tarjeta_nori_test.dart`).
