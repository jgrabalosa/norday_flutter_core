# El check vivo (T-018, experimento)

De vez en cuando, algo da una vuelta al aro de un `CheckCircular` sin hacer,
sacado del mundo de cada identidad. Es un experimento visual: si no convence,
se quita sin dejar rastro.

Código: `lib/widgets/check_vivo.dart` (coordinador y dibujos) y los ganchos de
`lib/widgets/check_circular.dart`. Tests: `test/check_vivo_test.dart`.

## Quién da la vuelta

Solo un `CheckCircular` **sin hacer y tocable** (`onTap` no nulo), con el
movimiento permitido (`MediaQuery.disableAnimations` a `false`) y con
`CheckCircular.vivo` a `true`. Si deja de cumplirlo (pasa a hecho, se quita
del árbol, cambia `onTap` a nulo) se da de baja y su vuelta se corta; si
vuelve a cumplirlo (deshacer) se apunta otra vez.

## Los turnos

`CoordinadorCheckVivo` es estático, como los notifiers del core. Da un turno
cada **4 s**: **uno cada vez**, de arriba abajo y vuelta a empezar. «De arriba
abajo» se decide al dar cada turno, por la posición global en pantalla (`dy` y,
a igualdad, `dx`), no por orden de registro: así vale con listas que se
desplazan o se reordenan. Cada turno va al primero que queda por debajo del
último servido; si ya no está o era el último, al primero.

El temporizador nace con el primer registrado y se cancela con el último: sin
checks no hay nada en marcha.

## La vuelta

1 s (`duracionVueltaCheck`, siempre menos que el turno: nunca hay dos a la
vez), empieza arriba y va en sentido horario por la
figura del check (círculo en Profundidad y Dulce, cuadrado achaflanado en
Neotokyo+), con el mismo radio que el aro: no sale del área del check ni mueve
la fila. Tocar el check durante la vuelta la corta y empieza el pop y el trazo
de siempre.

## Medidas (de Quim, 23-nov)

Al principio de `check_vivo.dart`, para retocarlas cambiando un número:
`factorGrosorVivo = 1.5` (todo lo que sale del `grosor` en las tres
identidades), `alfaEstelaProfundidad = 1.0` (antes 0,7), `alfaHaloNeotokyo =
0.9` (antes 0,6) y `alfaTrazoDulce = 1.0` (antes 0,75). El halo de Profundidad
sigue al 0,55; su radio y su `blur` crecen con el grosor.

Y `colorCuerpoCohete = Color(0xFFFFF8E7)` (de Quim, 25-nov): el cuerpo del
cohete de Profundidad, casi blanco como una estrella fugaz. El `streak` es el
mismo amarillo que el aro sin hacer (`aroCheck`) y amarillo sobre amarillo no
se veía; el brillo y la estela siguen en el amarillo. Si en el móvil no
convence, se cambia ese valor.

## Dónde va el dibujo de cada identidad

`_VueltaPainter.paint` (en `check_circular.dart`) tiene un `switch` sobre
`FormaIdentidad`; cada rama llama a una función que recibe la figura (con
inicio arriba, sentido horario), el progreso 0-1, el color (`streak`) y el
grosor del aro.

- **Profundidad** — `pintarVueltaProfundidad`: un cohete de cuerpo casi
  blanco (`colorCuerpoCohete`) del tamaño del aro, orientado hacia donde
  avanza, con estela y brillo suave en el amarillo de la identidad (`streak`).
- **Neotokyo+** — `pintarVueltaNeotokyo`: un destello de neón, como un letrero
  que se enciende. Un tramo de luz de un cuarto del aro, en el cian de la
  identidad (`streak`), con halo difuso, tubo y núcleo claro. Se enciende al
  salir y se apaga al llegar.
- **Dulce** — `pintarVueltaDulce`: una punta de lápiz que repasa el aro. Un
  trazo `pintarTrazoLapiz` en el `primaryTrazo` de la identidad (el rosa) se va dibujando desde arriba
  durante el 85 % de la vuelta y se borra suave en el resto. **Sin brillo**
  (no hay resplandor en Dulce) y nada de flores ni jardín.

## Apagarlo

`CheckCircular.vivo = false`: el check se pinta y se comporta como antes. No
es un ajuste del usuario. Es una variable estática (no `const`) para poder
conmutarla en los tests.
