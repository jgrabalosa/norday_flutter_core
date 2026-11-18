# El arte de las prendas de Nori: manifiesto y caché

El arte de las prendas **no va dentro del core**: se descarga del servidor, en
WebP, y se guarda en disco para siempre. Un manifiesto JSON dice, por prenda,
cómo se pinta. Esto es el modelo y el servicio (T-021); ninguna pantalla lo usa
todavía (lo usarán N-9, N-10 y N-11).

- Modelo: `lib/models/manifiesto_arte.dart` (`ManifiestoArte`, `PrendaArte`).
- Servicio: `lib/services/arte_prendas_service.dart` (`ArtePrendasService`).
- Tests: `test/arte_prendas_test.dart`.

## El manifiesto

Se sirve en `<servidor>/arte/manifiesto-v1.json`. `<servidor>` es
`ApiServiceCore.baseUrl` sin el `/api` final.

```json
{
  "version": 1,
  "nieve": { "desde": "2026-12-01", "hasta": "2027-01-06" },
  "prendas": {
    "PRENDA_GORRO_LANA": {
      "sitio": "cabeza",
      "fases": ["huevo", "cria", "adulto"],
      "oculta": [],
      "subidaBrote": { "huevo": 76, "cria": 24, "adulto": 58 },
      "imagenes": {
        "huevo": "prendas/gorro_lana_huevo.62733313.webp",
        "cria": "prendas/gorro_lana_cria.28e8ce75.webp",
        "adulto": "prendas/gorro_lana_adulto.75dc2a70.webp"
      }
    },
    "PRENDA_BUFANDA": {
      "sitio": "cuerpo",
      "fases": ["huevo", "cria", "adulto"],
      "oculta": [],
      "imagenes": {
        "huevo": "prendas/bufanda_huevo.0a1b2c3d.webp",
        "cria": "prendas/bufanda_cria.1a2b3c4d.webp",
        "adulto": "prendas/bufanda_adulto.2a3b4c5d.webp",
        "cria_dormido": "prendas/bufanda_cria_dormido.3a4b5c6d.webp"
      }
    }
  }
}
```

- La clave de cada prenda es el **código del producto** del backend.
- `sitio`: `"cabeza"` o `"cuerpo"`, en minúscula, como en
  `hoja_revision.py`. Ojo: `sitiosPrenda` (`theme/prendas.dart`) usa la
  `categoria` del backend, con mayúscula inicial (`Cabeza`, `Cuerpo`). No son
  la misma cadena: quien use el manifiesto junto a `sitiosPrenda` (N-9, N-10,
  N-11) debe convertir entre ambas formas, o no encontrará ninguna prenda.
- `subidaBrote` es opcional: píxeles del lienzo de 1024, por fase. Si falta una
  fase, 0 (`PrendaArte.subidaBroteEn`).
- `oculta`: capas de Nori que la prenda tapa. Hoy solo puede traer `"brote"`.
- `imagenes`: claves `<fase>` o `<fase>_<estado>`. Las rutas son relativas a
  `<servidor>/arte/` y **llevan la huella en el nombre**: si una imagen cambia,
  cambia el nombre. Por eso la caché nunca caduca. Es lo mismo que el
  `prenda.json` de la hoja de revisión (`tool/nori_canonica/hoja_revision.py`).
- `PrendaArte.imagenPara(fase, estado)` busca primero `<fase>_<estado>`, luego
  `<fase>`, y si no hay ninguna, `null`.

## Qué hace la app sin red o con algo que no entiende

`ArtePrendasService.cargarManifiesto()` **nunca lanza**:

1. Si la respuesta es 200, el JSON es válido y `version` es 1, lo guarda como
   «último bueno» y lo devuelve.
2. Si no hay red, la respuesta no es 200, el JSON está roto o la `version` no
   es 1 (un manifiesto de un formato futuro), devuelve el último bueno.
3. Si nunca bajó ninguno, `ManifiestoArte.vacio`: sin prendas ni nieve. Nori se
   queda sin prendas, y no se rompe nada.

Un manifiesto que no se entiende no pisa el último bueno.

El último bueno se guarda en `SharedPreferences` bajo
`arte_manifiesto_ultimo_bueno`, con el JSON tal cual llegó (se vuelve a
validar al leerlo).

## La caché de imágenes

`ArtePrendasService.imagen(ruta)`:

- Carpeta: `getApplicationSupportDirectory()/arte` (la de soporte de la app, no
  la de caché del sistema, que Android puede vaciar). La ruta del manifiesto se
  respeta como subcarpetas (`arte/prendas/gorro_lana_cria.28e8ce75.webp`).
- Si el fichero ya está, se devuelve **sin pedir nada a la red**.
- Si no, se descarga de `<servidor>/arte/<ruta>` y se guarda. Solo vale un 200
  con cuerpo; si falla, `null`.
- **Nunca queda un fichero a medias**: se escribe a `<nombre>.part` y se
  renombra al nombre final, que dentro de una carpeta es atómico. Si algo falla
  se borra el `.part`. Así, que exista el fichero con su nombre significa que
  está entero.
- **Una sola descarga por imagen a la vez**: todas las Nori de la app cambian
  a la vez, así que la primera vez que sale una prenda varias piden la misma
  imagen. Quien la pide mientras ya se está bajando espera a esa descarga,
  aunque use otro `ArtePrendasService`. Antes, la segunda petición recibía
  `null`.
- Para siempre: no hay caducidad ni limpieza. Las imágenes viejas (huella
  antigua) quedan huérfanas; son pocas y pequeñas.
- La ruta se valida porque el manifiesto viene de fuera: si trae `..`, empieza
  por `/` o tiene caracteres fuera de `[a-z0-9_./-]`, `null` sin pedir nada.

## La nieve

`nieve.desde` y `nieve.hasta` (`AAAA-MM-DD`, ambas incluidas) se comparan con
la **fecha del móvil** (`ManifiestoArte.nieveActiva(hoy)`, solo la fecha, sin
hora). La nieve es **solo visual**: no cambia nada del backend ni de la
gamificación, y quien cambie la hora del móvil verá nieve cuando no toca.
Sin `nieve` en el manifiesto, nunca hay.

**El manifiesto, uno para toda la app (T-027):** la nieve y las prendas leen
el mismo, `manifiestoArteNotifier` (`services/manifiesto_compartido.dart`),
que empieza en el vacío. Dos funciones lo piden, y las dos comparten la
petición en marcha (diez Nori a la vez, una sola petición):

- `recargarManifiesto()` lo pide otra vez. Lo llama la pantalla de Nori
  (`MascotaScreen`) en `_cargarDatos`: al montarse, cada vez que su pestaña
  vuelve a estar activa y al tirar para recargar, **aparte, sin esperarlo**
  (la petición tiene hasta 15 s y `_cargarDatos` no puede tardar más por
  ella).
- `asegurarManifiesto()` lo pide solo si nunca se ha pedido en este proceso.
  Lo llama cada `NoriVestida` **con prendas puestas** al montarse (la mini
  Nori de Hoy, que es la primera que se ve). Sin prendas no se pide nada.

Hasta que llega, el vacío: sin nieve ni prendas. En `_escenario` decide con la fecha del móvil en cada `build`
(`nieveActiva(DateTime.now())`, escuchando el notifier), así que el 7-ene la nieve se va sola al
repintar o al volver a la pestaña, sin temporizador de medianoche.

`TerrarioIdentidad` **solo recibe el `bool`** (`nieve`): no llama a la red ni
lee el manifiesto. Con nieve pinta un manto quieto sobre el suelo, con el
estilo de cada forma (en Dulce, a lápiz) y copos que caen por encima de la
escena: un solo controlador y un solo pintor para todos, que se paran con
«reducir animaciones» (la nieve quieta se queda). Sin nieve, el terrario es
el de siempre, sin la capa ni el controlador en el árbol.
