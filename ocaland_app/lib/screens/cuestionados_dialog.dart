import 'dart:async';

import 'package:flutter/material.dart';

import '../game/cuestionados/pregunta.dart';
import '../theme/ocaland_theme.dart';

/// Modal de Cuestionados: pregunta + timer + opciones (sección 4).
/// Devuelve `true` si acertó, `false` si falló o se agotó el tiempo.
class CuestionadosDialog extends StatefulWidget {
  const CuestionadosDialog({
    super.key,
    required this.pregunta,
    required this.tituloCasilla,
    this.segundos = 15,
  });

  final Pregunta pregunta;
  final String tituloCasilla;
  final int segundos;

  static Future<bool> mostrar(
    BuildContext context, {
    required Pregunta pregunta,
    required String tituloCasilla,
    int segundos = 15,
  }) async {
    final resultado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CuestionadosDialog(
        pregunta: pregunta,
        tituloCasilla: tituloCasilla,
        segundos: segundos,
      ),
    );
    return resultado ?? false;
  }

  @override
  State<CuestionadosDialog> createState() => _CuestionadosDialogState();
}

class _CuestionadosDialogState extends State<CuestionadosDialog> {
  late int _restante = widget.segundos;
  int? _seleccion;
  bool _resuelto = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_resuelto) return;
      setState(() => _restante--);
      if (_restante <= 0) {
        _timer?.cancel();
        _responder(null);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _responder(int? indice) {
    if (_resuelto) return;
    final acerto = indice != null && indice == widget.pregunta.indiceCorrecta;
    setState(() {
      _seleccion = indice;
      _resuelto = true;
    });
    _timer?.cancel();
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) Navigator.of(context).pop(acerto);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text('Cuestionados · ${widget.tituloCasilla}')),
          Text(
            '⏱ $_restante',
            style: TextStyle(
              color: _restante <= 5 ? Colors.red : null,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.pregunta.texto,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < widget.pregunta.opciones.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _OpcionButton(
                  texto: widget.pregunta.opciones[i],
                  estado: _estadoDe(i),
                  onTap: _resuelto ? null : () => _responder(i),
                ),
              ),
          ],
        ),
      ),
    );
  }

  _EstadoOpcion _estadoDe(int indice) {
    if (!_resuelto) return _EstadoOpcion.normal;
    if (indice == widget.pregunta.indiceCorrecta) return _EstadoOpcion.correcta;
    if (indice == _seleccion) return _EstadoOpcion.incorrectaSeleccionada;
    return _EstadoOpcion.deshabilitada;
  }
}

enum _EstadoOpcion { normal, correcta, incorrectaSeleccionada, deshabilitada }

class _OpcionButton extends StatelessWidget {
  const _OpcionButton({
    required this.texto,
    required this.estado,
    required this.onTap,
  });

  final String texto;
  final _EstadoOpcion estado;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Color? background;
    Color foreground = Colors.black87;
    switch (estado) {
      case _EstadoOpcion.normal:
        background = OcalandColors.fondo;
        break;
      case _EstadoOpcion.correcta:
        background = OcalandColors.verde;
        foreground = Colors.white;
        break;
      case _EstadoOpcion.incorrectaSeleccionada:
        background = OcalandColors.fucsia;
        foreground = Colors.white;
        break;
      case _EstadoOpcion.deshabilitada:
        background = Colors.grey.shade200;
        foreground = Colors.grey;
        break;
    }
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        alignment: Alignment.centerLeft,
        elevation: 0,
      ),
      child: Text(texto),
    );
  }
}
