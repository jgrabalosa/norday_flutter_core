# norday_flutter_core

Motor compartido del ecosistema Norday: red, sesión, temas y tokens de diseño,
gamificación, mascota, onboarding y preferencias.

Nada de lo que hay aquí sabe de un dominio concreto — ni de hábitos, ni de
lecciones. Eso lo pone cada app encima.

## Uso

```yaml
dependencies:
  norday_flutter_core:
    git:
      url: https://github.com/jgrabalosa/norday_flutter_core.git
      ref: main
```

```dart
import 'package:norday_flutter_core/norday_flutter_core.dart';
```

Un solo import: el paquete exporta todo por su fichero barril.

## Lo que hay que enchufar desde la app

```dart
// 1. El navigator del motor, en vez de uno propio.
MaterialApp(
  navigatorKey: nordayNavigatorKey,
  localizationsDelegates: const [
    AppLocalizations.delegate,          // los textos de la app
    NordayCoreLocalizations.delegate,   // los del motor
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
)

// 2. Adónde va el login cuando la sesión ya es buena.
LoginScreen(destinoTrasLogin: (context, mostrarOnboarding) =>
    MiPantallaPrincipal(mostrarOnboarding: mostrarOnboarding))

// 3. Los logros propios, para que LogrosScreen y las celebraciones los
//    traduzcan. Una vez, antes de runApp.
CatalogosCore.registrarLogrosDeDominio(nombres: ..., descripciones: ...);
```

Y tras el login (o tras el splash con sesión guardada), el aspecto que el
usuario lleve puesto según el backend:

```dart
await Equipamiento.cargarDeUsuarioSiSePuede(usuarioId);
```

## Desarrollo

Tras tocar un `.arb`:

```bash
flutter gen-l10n
```

Los ficheros generados se versionan a propósito — `flutter pub get` no ejecuta
`gen-l10n` sobre una dependencia Git.

Ver [CLAUDE.md](CLAUDE.md) para el reparto completo motor/disparadores.
