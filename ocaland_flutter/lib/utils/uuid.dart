import 'dart:math';

/// Genera un UUID v4 sin depender de un paquete externo — lo suficiente
/// para que el modo solo pueda generar ids localmente (offline) con el
/// mismo formato que espera una columna `uuid` de Postgres.
String uuidV4() {
  final rnd = Random();
  final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
  bytes[6] = (bytes[6] & 0x0F) | 0x40; // versión 4
  bytes[8] = (bytes[8] & 0x3F) | 0x80; // variante RFC 4122

  String hex(int start, int len) => bytes.sublist(start, start + len).map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  return '${hex(0, 4)}-${hex(4, 2)}-${hex(6, 2)}-${hex(8, 2)}-${hex(10, 6)}';
}
