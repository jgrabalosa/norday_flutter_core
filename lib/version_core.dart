/// La versión de este paquete, la misma que la `version:` del `pubspec.yaml`
/// (Nori vestida, N-6).
///
/// El core la manda al backend en `X-Norday-Core` (catálogo de productos y
/// compra), y el backend no le da un producto que este core no sabe pintar
/// (`version_minima_core`). Por eso es la versión del core y no la de cada
/// app: quien pinta las prendas es el core.
///
/// **Al subir la versión del `pubspec.yaml`, esta también**: lo vigila
/// `test/version_core_test.dart`.
const String versionCore = '0.56.0';
