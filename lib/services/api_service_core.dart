import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/usuario.dart';
import 'api_error.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Motor: todo lo que no sabe de dominio — sesión, usuario, preferencias,
/// gamificación, tienda y mascota.
///
/// Las apps del ecosistema ponen encima su propio servicio con los endpoints
/// que sí son suyos (en Norday Hábitos, `ApiServiceHabitos`). Por eso la
/// tubería de peticiones ([enviar], [verificar], [parsear]), [getHeaders],
/// [getToken], [baseUrl] y [cliente] son públicos: son el punto de apoyo de
/// esos servicios de dominio, que viven fuera del paquete.
class ApiServiceCore {
  static const String baseUrl = 'https://api.norday.app/api';

  /// Qué app del ecosistema es esta. Viaja en la cabecera `X-Norday-App` de
  /// los dos catálogos para que el backend filtre lo que es exclusivo de otra
  /// app; lo compartido lo ven todas.
  ///
  /// Cada app lo fija antes de `runApp` si no es la de hábitos:
  /// `ApiServiceCore.appId = 'conocimiento';`
  static String appId = 'habitos';

  /// Cabecera de identificación de app. Solo la llevan los catálogos: el
  /// inventario y los logros de un usuario ya vienen acotados por quién es,
  /// no por desde dónde mira.
  static Map<String, String> get _headersCatalogo => {'X-Norday-App': appId};

  /// Cliente HTTP compartido: reutiliza la conexión TCP+TLS (keep-alive).
  /// Público para que los servicios de dominio de cada app usen la misma
  /// conexión en vez de abrir la suya.
  static final http.Client cliente = http.Client();

  /// Lecturas y escrituras normales.
  static const Duration timeoutNormal = Duration(seconds: 15);

  /// Autenticación: encadena varias llamadas (login + FCM + preferencias) y
  /// es la peor para cortar a medias, así que se le da más margen.
  static const Duration timeoutAuth = Duration(seconds: 30);

  // ── Tuberia comun de errores ───────────────────────────
  //
  // Toda peticion pasa por aqui: es el unico sitio donde se decide que es un
  // fallo de red y que es un fallo del servidor. Las pantallas solo ven
  // ApiException ya clasificada.

  /// Aplica el timeout y traduce los fallos de transporte.
  static Future<http.Response> enviar(
    Future<http.Response> Function() peticion, {
    Duration timeout = timeoutNormal,
  }) async {
    try {
      return await peticion().timeout(timeout);
    } on TimeoutException {
      throw const ApiException(TipoErrorApi.timeout);
    } on http.ClientException catch (e) {
      // IOClient envuelve aqui SocketException: sin red, DNS caido o conexion
      // rechazada. Se captura el tipo de http y no el de dart:io para no
      // romper una futura compilacion web.
      throw ApiException(TipoErrorApi.sinConexion, cuerpo: e.message);
    } catch (e) {
      // Por descarte: lo unico que corre dentro de [peticion] es la llamada
      // HTTP, asi que cualquier otro fallo tambien es "no se pudo hablar con
      // el servidor". Cubre HandshakeException (TLS roto por un antivirus o
      // un proxy corporativo), que IOClient no envuelve y que de otro modo
      // llegaria a la pantalla sin clasificar.
      throw ApiException(TipoErrorApi.sinConexion, cuerpo: e.toString());
    }
  }

  /// Lanza si el código no es uno de los esperados.
  static void verificar(http.Response r, {List<int> ok = const [200]}) {
    if (ok.contains(r.statusCode)) return;
    final tipo = switch (r.statusCode) {
      401 || 403 => TipoErrorApi.noAutorizado,
      >= 500 => TipoErrorApi.servidor,
      _ => TipoErrorApi.peticionInvalida,
    };
    throw ApiException(tipo, codigoEstado: r.statusCode, cuerpo: r.body);
  }

  /// Envuelve el parseo del cuerpo: un 200 con JSON malformado, un campo que
  /// falta o que llega con otro tipo son "respuesta inesperada", no un error
  /// de red ni un crash.
  static T parsear<T>(T Function() parseo) {
    try {
      return parseo();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(TipoErrorApi.respuestaInesperada, cuerpo: e.toString());
    }
  }

  // ── Token ──────────────────────────────────────────────
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<void> saveUsuario(Usuario usuario) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('usuarioId', usuario.usuarioId);
    await prefs.setString('nombre', usuario.nombre);
    await prefs.setString('username', usuario.username);
    await prefs.setString('email', usuario.email);
    await prefs.setString('proveedorAuth', usuario.proveedorAuth);
  }

  // ── Preferencias: idioma y zona horaria ────────────────
  static Future<Map<String, dynamic>> getPreferencias(int usuarioId) async {
    final headers = await getHeaders();
    final response = await enviar(() => cliente.get(
          Uri.parse('$baseUrl/usuarios/$usuarioId/preferencias'),
          headers: headers,
        ));
    verificar(response);
    return parsear(() => jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// Cada campo es opcional: se manda solo el que se quiere cambiar.
  static Future<void> actualizarPreferencias(int usuarioId,
      {String? idioma, String? zonaHoraria}) async {
    final body = <String, String>{};
    if (idioma != null) body['idioma'] = idioma;
    if (zonaHoraria != null) body['zonaHoraria'] = zonaHoraria;
    if (body.isEmpty) return;

    final headers = await getHeaders();
    final response = await enviar(() => cliente.put(
          Uri.parse('$baseUrl/usuarios/$usuarioId/preferencias'),
          headers: headers,
          body: jsonEncode(body),
        ));
    verificar(response);
  }

  static Future<Map<String, dynamic>?> getUsuarioLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return null;
    return {
      'usuarioId': prefs.getInt('usuarioId'),
      'nombre': prefs.getString('nombre'),
      'username': prefs.getString('username'),
      'email': prefs.getString('email'),
      'proveedorAuth': prefs.getString('proveedorAuth') ?? 'LOCAL',
      'token': token,
    };
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // ── Headers ────────────────────────────────────────────
  static Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ── Usuarios ───────────────────────────────────────────
  static Future<Usuario> login(String email, String contrasena) async {
    final response = await enviar(
      () => cliente.post(
        Uri.parse('$baseUrl/usuarios/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'contrasena': contrasena}),
      ),
      timeout: timeoutAuth,
    );
    verificar(response);
    return parsear(() => Usuario.fromJson(jsonDecode(response.body)));
  }

  static Future<void> registro(String nombre, String username,
                                String email, String contrasena) async {
    final response = await enviar(
      () => cliente.post(
        Uri.parse('$baseUrl/usuarios/registro'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre': nombre,
          'username': username,
          'email': email,
          'contrasena': contrasena,
        }),
      ),
      timeout: timeoutAuth,
    );
    verificar(response, ok: const [201]);
  }

  static Future<void> actualizarUsuario(
      int usuarioId, String nombre, String username, String email) async {
    final headers = await getHeaders();
    final response = await enviar(() => cliente.put(
          Uri.parse('$baseUrl/usuarios/$usuarioId'),
          headers: headers,
          body: jsonEncode({
            'nombre': nombre,
            'username': username,
            'email': email,
          }),
        ));
    verificar(response);

    // Actualizar también los datos guardados en local
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nombre', nombre);
    await prefs.setString('username', username);
    await prefs.setString('email', email);
  }

  static Future<void> cambiarContrasena(
      int usuarioId, String contrasenaActual, String contrasenaNueva) async {
    final headers = await getHeaders();
    final response = await enviar(() => cliente.put(
          Uri.parse('$baseUrl/usuarios/$usuarioId/contrasena'),
          headers: headers,
          body: jsonEncode({
            'contrasenaActual': contrasenaActual,
            'contrasenaNueva': contrasenaNueva,
          }),
        ));
    verificar(response);
  }

// ── Recuperación de contraseña ─────────────────────────
  static Future<void> solicitarCodigoRecuperacion(String email) async {
    final response = await enviar(() => cliente.post(
          Uri.parse('$baseUrl/usuarios/recuperar'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email}),
        ));
    verificar(response);
  }

  static Future<void> restablecerContrasena(
      String email, String codigo, String contrasenaNueva) async {
    final response = await enviar(() => cliente.post(
          Uri.parse('$baseUrl/usuarios/restablecer'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email,
            'codigo': codigo,
            'contrasenaNueva': contrasenaNueva,
          }),
        ));
    verificar(response);
  }

  static Future<void> eliminarUsuario(int usuarioId) async {
    final headers = await getHeaders();
    final response = await enviar(() => cliente.delete(
          Uri.parse('$baseUrl/usuarios/$usuarioId'),
          headers: headers,
        ));
    verificar(response);

    // Cuenta eliminada: limpiar toda la sesión local
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<void> registrarInteraccionResena(int usuarioId) async {
    final headers = await getHeaders();
    final response = await enviar(() => cliente.post(
          Uri.parse('$baseUrl/gamificacion/resena/$usuarioId'),
          headers: headers,
        ));
    verificar(response);
  }

  // ── Gamificación ───────────────────────────────────────
  static Future<int> getSaldoPuntos(int usuarioId) async {
    final headers = await getHeaders();
    final response = await enviar(() => cliente.get(
          Uri.parse('$baseUrl/gamificacion/saldo/$usuarioId'),
          headers: headers,
        ));
    verificar(response);
    return parsear(() => jsonDecode(response.body)['saldo'] as int);
  }

  static Future<List<dynamic>> getCatalogoLogros() async {
    final headers = {...await getHeaders(), ..._headersCatalogo};
    final response = await enviar(() => cliente.get(
          Uri.parse('$baseUrl/gamificacion/logros/catalogo'),
          headers: headers,
        ));
    verificar(response);
    return parsear(() => jsonDecode(response.body) as List<dynamic>);
  }

  static Future<List<dynamic>> getLogrosUsuario(int usuarioId) async {
    final headers = await getHeaders();
    final response = await enviar(() => cliente.get(
          Uri.parse('$baseUrl/gamificacion/logros/usuario/$usuarioId'),
          headers: headers,
        ));
    verificar(response);
    return parsear(() => jsonDecode(response.body) as List<dynamic>);
  }

  // ── Tienda ─────────────────────────────────────────────
  static Future<List<dynamic>> getCatalogoProductos() async {
    final headers = {...await getHeaders(), ..._headersCatalogo};
    final response = await enviar(() => cliente.get(
          Uri.parse('$baseUrl/gamificacion/productos/catalogo'),
          headers: headers,
        ));
    verificar(response);
    return parsear(() => jsonDecode(response.body) as List<dynamic>);
  }

  static Future<List<dynamic>> getInventarioProductos(int usuarioId) async {
    final headers = await getHeaders();
    final response = await enviar(() => cliente.get(
          Uri.parse('$baseUrl/gamificacion/productos/usuario/$usuarioId'),
          headers: headers,
        ));
    verificar(response);
    return parsear(() => jsonDecode(response.body) as List<dynamic>);
  }

  static Future<void> comprarProducto(int usuarioId, int productoId) async {
    final headers = await getHeaders();
    final response = await enviar(() => cliente.post(
          Uri.parse('$baseUrl/gamificacion/productos/comprar/$usuarioId/$productoId'),
          headers: headers,
        ));
    verificar(response);
  }

  static Future<void> otorgarProducto(int usuarioId, int productoId) async {
    final headers = await getHeaders();
    final response = await enviar(() => cliente.post(
          Uri.parse('$baseUrl/gamificacion/productos/otorgar/$usuarioId/$productoId'),
          headers: headers,
        ));
    verificar(response);
  }

  static Future<void> equiparProducto(int usuarioId, int productoId) async {
    final headers = await getHeaders();
    final response = await enviar(() => cliente.post(
          Uri.parse('$baseUrl/gamificacion/productos/equipar/$usuarioId/$productoId'),
          headers: headers,
        ));
    verificar(response);
  }

  static Future<void> desequiparProducto(int usuarioId, int productoId) async {
    final headers = await getHeaders();
    final response = await enviar(() => cliente.post(
          Uri.parse('$baseUrl/gamificacion/productos/desequipar/$usuarioId/$productoId'),
          headers: headers,
        ));
    verificar(response);
  }

  static Future<Map<String, dynamic>> usarProducto(int usuarioId, int productoId) async {
    final headers = await getHeaders();
    final response = await enviar(() => cliente.post(
          Uri.parse('$baseUrl/gamificacion/productos/usar/$usuarioId/$productoId'),
          headers: headers,
        ));
    verificar(response);
    return parsear(() {
      final data = jsonDecode(response.body);
      return {
        'codigoConsumido': data['codigoConsumido'],
        'subioNivel': data['subioNivel'] ?? false,
        'nivelNuevo': data['nivelNuevo'] ?? 0,
      };
    });
  }

  // ── Mascota ────────────────────────────────────────────
  static Future<Map<String, dynamic>> getMascota(int usuarioId) async {
    final headers = await getHeaders();
    final response = await enviar(() => cliente.get(
          Uri.parse('$baseUrl/mascota/$usuarioId'),
          headers: headers,
        ));
    verificar(response);
    return parsear(() => jsonDecode(response.body) as Map<String, dynamic>);
  }

  static Future<void> actualizarNombreMascota(int usuarioId, String nombre) async {
    final headers = await getHeaders();
    final response = await enviar(() => cliente.put(
          Uri.parse('$baseUrl/mascota/$usuarioId/nombre'),
          headers: headers,
          body: jsonEncode({'nombre': nombre}),
        ));
    verificar(response);
  }

  // Devuelve true si la cuenta se acaba de crear en este login (para
  // disparar el mini-onboarding), false si ya existía o si se canceló.
  static Future<bool> loginConGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      serverClientId: '1086143132391-vprrrjr7s3u12q544flm2tclllj61ami.apps.googleusercontent.com',
    );

    final GoogleSignInAccount? account = await googleSignIn.signIn();
    if (account == null) return false;

    final GoogleSignInAuthentication auth = await account.authentication;
    final String? idToken = auth.idToken;
    // Google respondio, pero sin token utilizable: no es un fallo de red.
    if (idToken == null) {
      throw const ApiException(TipoErrorApi.respuestaInesperada);
    }

    final response = await enviar(
      () => cliente.post(
        Uri.parse('$baseUrl/usuarios/login-google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
      ),
      timeout: timeoutAuth,
    );
    verificar(response);

    final data = parsear(() => jsonDecode(response.body) as Map<String, dynamic>);
    await saveToken(data['token']);
    await saveUsuario(Usuario.fromJson(data));
    return data['esNuevo'] ?? false;
  }

// ── Notificaciones ─────────────────────────────────────
  static Future<void> actualizarFcmToken(int usuarioId, String fcmToken) async {
    final headers = await getHeaders();
    final response = await enviar(() => cliente.put(
          Uri.parse('$baseUrl/usuarios/$usuarioId/fcm-token'),
          headers: headers,
          body: jsonEncode({'fcmToken': fcmToken}),
        ));
    verificar(response);
  }
}
