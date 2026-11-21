# Publicar una versión

Movido del `CLAUDE.md` (Lecciones aprendidas › Publicar una versión).

- **La versión va en dos sitios: la `version:` del `pubspec.yaml` y
  `versionCore` (`lib/version_core.dart`).** Al subir una, la otra también:
  lo vigila `test/version_core_test.dart`. El core la manda en
  `X-Norday-Core` (catálogo de productos y compra) y el backend no da un
  producto con `version_minima_core` mayor (Nori vestida, N-6).
- **Antes de `git tag`, `git --no-pager log -1`.** Se creó y subió `v0.9.0`
  sobre el commit de `v0.8.0` porque se saltaron el merge y el cambio de
  versión. Se arregla con `git tag -d` y `git push origin --delete <tag>` si
  nadie apunta aún a él.
- **Un tag anotado resuelve a su commit, no a sí mismo**:
  `git rev-parse <tag>^{commit}`.
- **`git ls-remote origin <patrón>` no muestra la línea `^{}`** del tag: el
  patrón no casa con ella. Listar con `--tags` para verla.
- **Un cambio aquí no llega solo a las apps**: hay que hacer push y luego
  `flutter pub upgrade norday_flutter_core` en cada una, porque pub cachea
  el commit resuelto. La dependencia va por tag: se mergea y se tagea aquí
  primero, y luego la app apunta al tag nuevo. Una app fijada a un commit
  viejo del core seguirá con el comportamiento viejo aunque aquí esté
  arreglado.
