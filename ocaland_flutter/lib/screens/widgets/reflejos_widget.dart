import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Mini-juego de reflejos: hay que tocar el botón apenas se pone verde.
/// Falla si se toca antes de tiempo o si se tarda demasiado (>900ms) una vez
/// que ya está listo.
class ReflejosWidget extends StatefulWidget {
  final ValueChanged<bool> onDone;
  const ReflejosWidget({super.key, required this.onDone});

  @override
  State<ReflejosWidget> createState() => _ReflejosWidgetState();
}

class _ReflejosWidgetState extends State<ReflejosWidget> {
  static const _ventanaMs = 900;
  bool _armado = false;
  bool _resuelto = false;
  DateTime? _listoTs;
  String _resultado = 'Esperá a que se ponga verde y tocá rápido (tenés menos de 1 segundo).';
  Timer? _armTimer;
  Timer? _ventanaTimer;

  @override
  void initState() {
    super.initState();
    final delay = 1000 + Random().nextInt(1800);
    _armTimer = Timer(Duration(milliseconds: delay), () {
      if (!mounted) return;
      setState(() {
        _armado = true;
        _listoTs = DateTime.now();
      });
      _ventanaTimer = Timer(const Duration(milliseconds: _ventanaMs), () {
        if (_resuelto || !mounted) return;
        setState(() {
          _resuelto = true;
          _resultado = '🐢 Muy lento, se te pasó el tiempo.';
        });
        Future.delayed(const Duration(milliseconds: 1100), () => widget.onDone(false));
      });
    });
  }

  void _tap() {
    if (_resuelto) return;
    bool exito;
    if (_armado) {
      _ventanaTimer?.cancel();
      final ms = DateTime.now().difference(_listoTs!).inMilliseconds;
      _resultado = '⚡ ¡${ms}ms! Buen reflejo.';
      exito = true;
    } else {
      _armTimer?.cancel();
      _resultado = '🙈 Tocaste antes de tiempo.';
      exito = false;
    }
    setState(() => _resuelto = true);
    Future.delayed(const Duration(milliseconds: 1100), () => widget.onDone(exito));
  }

  @override
  void dispose() {
    _armTimer?.cancel();
    _ventanaTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Mini-juego de reflejos: tocá el botón apenas se ponga verde.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.violetDark),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _armado ? const Color(0xFF2ECC71) : const Color(0xFF5C7CFA), padding: const EdgeInsets.symmetric(vertical: 22)),
            onPressed: _resuelto ? null : _tap,
            child: Text(_armado ? '¡YA! Tocá' : 'Esperá...', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 8),
        Text(_resultado, style: const TextStyle(fontSize: 13, color: Color(0xFF7A6A99))),
      ],
    );
  }
}
