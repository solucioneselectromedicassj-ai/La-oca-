import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/ocaland_theme.dart';

/// Minijuego de reflejos (sección 5): esperar a que el botón se ponga
/// verde y tocarlo rápido. Falla si tocás antes de tiempo O si tardás
/// demasiado después de que se puso verde (ventana de menos de 1s).
class MinijuegoReflejosDialog extends StatefulWidget {
  const MinijuegoReflejosDialog({super.key});

  static Future<bool> mostrar(BuildContext context) async {
    final resultado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const MinijuegoReflejosDialog(),
    );
    return resultado ?? false;
  }

  @override
  State<MinijuegoReflejosDialog> createState() => _MinijuegoReflejosDialogState();
}

enum _Estado { esperando, verde, resuelto }

class _MinijuegoReflejosDialogState extends State<MinijuegoReflejosDialog> {
  _Estado _estado = _Estado.esperando;
  bool? _gano;
  Timer? _timerVerde;
  Timer? _timerVentana;

  @override
  void initState() {
    super.initState();
    final demora = 1200 + Random().nextInt(2500); // 1.2s - 3.7s
    _timerVerde = Timer(Duration(milliseconds: demora), () {
      if (!mounted) return;
      setState(() => _estado = _Estado.verde);
      _timerVentana = Timer(const Duration(milliseconds: 900), () {
        if (!mounted || _estado == _Estado.resuelto) return;
        _resolver(false); // tardó demasiado
      });
    });
  }

  @override
  void dispose() {
    _timerVerde?.cancel();
    _timerVentana?.cancel();
    super.dispose();
  }

  void _resolver(bool gano) {
    if (_estado == _Estado.resuelto) return;
    _timerVerde?.cancel();
    _timerVentana?.cancel();
    setState(() {
      _estado = _Estado.resuelto;
      _gano = gano;
    });
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) Navigator.of(context).pop(gano);
    });
  }

  void _onTap() {
    if (_estado == _Estado.esperando) {
      _resolver(false); // tocó antes de tiempo
    } else if (_estado == _Estado.verde) {
      _resolver(true);
    }
  }

  Color get _colorAro {
    switch (_estado) {
      case _Estado.esperando:
        return Colors.grey.shade400;
      case _Estado.verde:
        return OcalandColors.verde;
      case _Estado.resuelto:
        return _gano == true ? OcalandColors.verde : OcalandColors.fucsia;
    }
  }

  String get _mensaje {
    switch (_estado) {
      case _Estado.esperando:
        return 'Esperá a que se ponga verde...';
      case _Estado.verde:
        return '¡Ahora! Tocá ya';
      case _Estado.resuelto:
        return _gano == true ? '¡Reflejos perfectos!' : 'Fallaste';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Minijuego: Reflejos'),
      content: SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_mensaje, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _colorAro, width: 6),
                  boxShadow: [
                    BoxShadow(
                      color: _colorAro.withValues(alpha: 0.6),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Transform.scale(
                    scale: 1.12,
                    child: Image.asset(
                      'assets/minijuegos/orbe_reflejos.png',
                      fit: BoxFit.cover,
                      cacheHeight: 300,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
