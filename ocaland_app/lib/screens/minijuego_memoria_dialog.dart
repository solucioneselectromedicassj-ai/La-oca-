import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../game/gema_iconos.dart';
import '../theme/ocaland_theme.dart';

/// Minijuego de Memoria (sección 5): se iluminan 3 gemas en secuencia,
/// hay que repetirla tocando en el mismo orden.
class MinijuegoMemoriaDialog extends StatefulWidget {
  const MinijuegoMemoriaDialog({super.key});

  static Future<bool> mostrar(BuildContext context) async {
    final resultado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const MinijuegoMemoriaDialog(),
    );
    return resultado ?? false;
  }

  @override
  State<MinijuegoMemoriaDialog> createState() => _MinijuegoMemoriaDialogState();
}

enum _Fase { mostrando, esperando, resuelto }

class _MinijuegoMemoriaDialogState extends State<MinijuegoMemoriaDialog> {
  static const _largoSecuencia = 3;

  late final List<int> _secuencia;
  _Fase _fase = _Fase.mostrando;
  int _indiceResaltado = -1;
  int _indiceEsperado = 0;
  bool? _gano;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _secuencia = List.generate(_largoSecuencia, (_) => rng.nextInt(GemaIconos.rutas.length));
    _mostrarSecuencia();
  }

  Future<void> _mostrarSecuencia() async {
    await Future.delayed(const Duration(milliseconds: 500));
    for (final gema in _secuencia) {
      if (!mounted) return;
      setState(() => _indiceResaltado = gema);
      await Future.delayed(const Duration(milliseconds: 550));
      if (!mounted) return;
      setState(() => _indiceResaltado = -1);
      await Future.delayed(const Duration(milliseconds: 200));
    }
    if (!mounted) return;
    setState(() => _fase = _Fase.esperando);
  }

  void _onTapGema(int gema) {
    if (_fase != _Fase.esperando) return;
    if (gema == _secuencia[_indiceEsperado]) {
      _indiceEsperado++;
      if (_indiceEsperado >= _secuencia.length) {
        _resolver(true);
        return;
      }
      setState(() {});
    } else {
      _resolver(false);
    }
  }

  void _resolver(bool gano) {
    if (_fase == _Fase.resuelto) return;
    setState(() {
      _fase = _Fase.resuelto;
      _gano = gano;
    });
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) Navigator.of(context).pop(gano);
    });
  }

  String get _mensaje {
    switch (_fase) {
      case _Fase.mostrando:
        return 'Memorizá el orden...';
      case _Fase.esperando:
        return 'Ahora repetilo';
      case _Fase.resuelto:
        return _gano == true ? '¡Memoria perfecta!' : 'No era ese orden';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Minijuego: Memoria'),
      content: SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_mensaje, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: List.generate(GemaIconos.rutas.length, (i) => _GemaBoton(
                    ruta: GemaIconos.rutas[i],
                    resaltada: _indiceResaltado == i,
                    habilitada: _fase == _Fase.esperando,
                    onTap: () => _onTapGema(i),
                  )),
            ),
          ],
        ),
      ),
    );
  }
}

class _GemaBoton extends StatelessWidget {
  const _GemaBoton({
    required this.ruta,
    required this.resaltada,
    required this.habilitada,
    required this.onTap,
  });

  final String ruta;
  final bool resaltada;
  final bool habilitada;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: habilitada ? onTap : null,
      child: AnimatedScale(
        scale: resaltada ? 1.15 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: resaltada
                ? [
                    BoxShadow(
                      color: OcalandColors.amarillo.withValues(alpha: 0.8),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Opacity(
            opacity: habilitada || resaltada ? 1 : 0.85,
            child: Image.asset(ruta, width: 56, height: 56, cacheWidth: 168),
          ),
        ),
      ),
    );
  }
}
