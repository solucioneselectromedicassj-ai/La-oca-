import 'dart:math';
import '../utils/palabras_cortas.dart';

const _abecedario = 'ABCDEFGHIJKLMNÑOPQRSTUVWXYZ';

/// Mini-desafío de "la letra que falta" — versión de un solo toque del
/// Ahorcado para los juegos de espera (medidor/chequeo de turno): se
/// tapa una letra de una palabra corta y hay que elegir cuál es, entre 4
/// opciones. Pedido explícito del usuario: variar los juegos de espera
/// en vez de repetir siempre lo mismo.
class AhorcadoEleccionDesafio {
  final String palabra;
  final int indiceOculto;
  final List<String> opciones;
  final String letraCorrecta;

  const AhorcadoEleccionDesafio({required this.palabra, required this.indiceOculto, required this.opciones, required this.letraCorrecta});

  /// La palabra con un guión bajo en la posición oculta, ej. "C_SA".
  String get textoConHueco => palabra.split('').asMap().entries.map((e) => e.key == indiceOculto ? '_' : e.value).join();

  factory AhorcadoEleccionDesafio.aleatoria([Random? random]) {
    final rnd = random ?? Random();
    final palabra = (List<String>.from(palabrasCortas)..shuffle(rnd)).first;
    final indice = rnd.nextInt(palabra.length);
    final correcta = palabra[indice];
    final decoys = <String>{};
    while (decoys.length < 3) {
      final letra = _abecedario[rnd.nextInt(_abecedario.length)];
      if (letra != correcta) decoys.add(letra);
    }
    final opciones = [correcta, ...decoys]..shuffle(rnd);
    return AhorcadoEleccionDesafio(palabra: palabra, indiceOculto: indice, opciones: opciones, letraCorrecta: correcta);
  }
}
