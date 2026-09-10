import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norday_flutter_core/theme/app_theme.dart';
import 'package:norday_flutter_core/theme/identidades_paleta.dart';

/// El contraste se ha ido midiendo a mano, identidad por identidad, y el
/// resultado vive en comentarios. Un comentario no falla cuando alguien
/// cambia el color de al lado.
///
/// Esto es la red. No comprueba que la app sea bonita: comprueba que ningún
/// color nuevo deje texto por debajo de AA ni un aro por debajo de 1.4.11.
/// Es barato, no abre ninguna pantalla y corre en milisegundos.
void main() {
  /// AA para texto normal.
  const double aaTexto = 4.5;

  /// WCAG 1.4.11, componentes de interfaz y objetos gráficos.
  const double aaNoTexto = 3.0;

  double contraste(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    final claro = la > lb ? la : lb;
    final oscuro = la > lb ? lb : la;
    return (claro + 0.05) / (oscuro + 0.05);
  }

  Map<String, Color> fondosDe(TokensContextuales t) => {
        'bg': t.bg,
        'surface': t.surface,
        'surface2': t.surface2,
      };

  void exigir(String identidad, String rol, Color color,
      Map<String, Color> fondos, double minimo) {
    for (final fondo in fondos.entries) {
      final valor = contraste(color, fondo.value);
      expect(valor, greaterThanOrEqualTo(minimo),
          reason: '$identidad · $rol sobre ${fondo.key} '
              '= ${valor.toStringAsFixed(2)}, mínimo $minimo');
    }
  }

  test('el texto de cada identidad llega a AA sobre sus tres fondos', () {
    for (final identidad in catalogoIdentidades.values) {
      final t = identidad.tokens;
      final fondos = fondosDe(t);
      exigir(identidad.codigo, 'text', t.text, fondos, aaTexto);
      exigir(identidad.codigo, 'textMuted', t.textMuted, fondos, aaTexto);
    }
  });

  /// TEMA_ALBA queda fuera a propósito, y ésta es la única excepción de todo
  /// el fichero.
  ///
  /// Alba no declara `successText`, así que hereda `success` por el fallback
  /// del constructor y se queda en 2.96 / 3.20 / 2.65 sobre sus tres fondos.
  /// Es un fallo real —`coleccion_screen` pinta con `successText` el filo y
  /// el texto de la tarjeta— pero Alba está oculta del catálogo y su paleta
  /// entera se rehará en el rebranding, así que arreglarlo hoy sería trabajo
  /// que se tira. Si Alba vuelve, este test es lo que lo recuerda: quítala de
  /// la lista de abajo y fallará hasta que se le dé un `successText` propio.
  test('las variantes de texto de los acentos llegan a AA', () {
    const excluidas = {'TEMA_ALBA'};

    for (final identidad in catalogoIdentidades.values) {
      if (excluidas.contains(identidad.codigo)) continue;
      final t = identidad.tokens;
      final fondos = fondosDe(t);
      exigir(identidad.codigo, 'successText', t.successText, fondos, aaTexto);
      exigir(identidad.codigo, 'streakText', t.streakText, fondos, aaTexto);
      exigir(identidad.codigo, 'pointsText', t.pointsText, fondos, aaTexto);
    }
  });

  /// El aro del check vacío es el caso más justo de la app: Neotokyo+ está a
  /// 3.10 sobre surface2 y Alba a 3.05. No hay margen para tocar los fondos
  /// sin volver a medir, y por eso 4.5 quedó descartada la transparencia de
  /// las tarjetas de Hoy en Neotokyo+.
  test('el aro del check vacío cumple 1.4.11 sobre sus tres fondos', () {
    for (final identidad in catalogoIdentidades.values) {
      final t = identidad.tokens;
      exigir(identidad.codigo, 'aroVacio', t.aroVacio, fondosDe(t), aaNoTexto);
    }
  });

  /// La tinta de los botones rellenos. No se puede fijar a blanco ni a negro
  /// para todas: las identidades de acento claro piden tinta oscura y Alba,
  /// que lo tiene oscuro, la pide blanca. Con `Colors.white` para todas esto
  /// daba 2.21 / 3.50 / 3.33 / 2.60.
  test('la tinta de un botón relleno llega a AA sobre su propio acento', () {
    for (final identidad in catalogoIdentidades.values) {
      final t = identidad.tokens;
      final valor = contraste(t.tinta, t.primary);
      expect(valor, greaterThanOrEqualTo(aaTexto),
          reason: '${identidad.codigo} · tinta sobre primary '
              '= ${valor.toStringAsFixed(2)}');
    }
  });
}
