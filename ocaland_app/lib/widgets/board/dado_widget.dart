import 'dart:math';

import 'package:flutter/material.dart';

import '../../game/dado_iconos.dart';

/// Controlador imperativo: quien tira el dado llama a `rodar(resultado)`
/// y espera a que termine la animación antes de seguir con el turno.
class DadoController {
  Future<void> Function(int resultado)? _animar;

  Future<void> rodar(int resultado) async {
    final animar = _animar;
    if (animar == null) return;
    await animar(resultado);
  }
}

/// Dado animado: cara estática en reposo, ciclo de frames "en movimiento"
/// al tirar, y se asienta en la cara del resultado real.
class DadoWidget extends StatefulWidget {
  const DadoWidget({super.key, required this.controller, this.tamano = 64});

  final DadoController controller;
  final double tamano;

  @override
  State<DadoWidget> createState() => _DadoWidgetState();
}

class _DadoWidgetState extends State<DadoWidget> {
  int _valorMostrado = 1;
  bool _rodando = false;
  int _indiceMovimiento = 0;
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    widget.controller._animar = _animar;
  }

  Future<void> _animar(int resultado) async {
    setState(() {
      _rodando = true;
      _indiceMovimiento = _rng.nextInt(DadoIconos.movimiento.length);
    });
    for (var i = 0; i < 7; i++) {
      await Future.delayed(const Duration(milliseconds: 65));
      if (!mounted) return;
      setState(
        () => _indiceMovimiento = (_indiceMovimiento + 1) % DadoIconos.movimiento.length,
      );
    }
    if (!mounted) return;
    setState(() {
      _rodando = false;
      _valorMostrado = resultado;
    });
  }

  @override
  Widget build(BuildContext context) {
    final asset = _rodando
        ? DadoIconos.movimiento[_indiceMovimiento]
        : DadoIconos.caras[_valorMostrado - 1];
    return Image.asset(
      asset,
      height: widget.tamano,
      cacheHeight: (widget.tamano * 3).round(),
      fit: BoxFit.contain,
    );
  }
}
