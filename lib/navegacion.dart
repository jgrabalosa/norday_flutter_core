import 'package:flutter/material.dart';

/// Navigator global del ecosistema.
///
/// Lo necesita el motor para abrir cosas que no cuelgan de ninguna pantalla
/// en concreto — la celebración de un logro, por ejemplo, puede dispararse
/// desde cualquier sitio. Cada app se lo pasa a su `MaterialApp` en vez de
/// declarar el suyo:
///
/// ```dart
/// MaterialApp(navigatorKey: nordayNavigatorKey, ...)
/// ```
final GlobalKey<NavigatorState> nordayNavigatorKey = GlobalKey<NavigatorState>();
