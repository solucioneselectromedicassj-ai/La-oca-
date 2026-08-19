import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Mini-juego de memoria: se iluminan 3 fichas de colores en secuencia,
/// hay que repetirla tocando en el mismo orden.
class MemoriaWidget extends StatefulWidget {
  final ValueChanged<bool> onDone;
  const MemoriaWidget({super.key, required this.onDone});

  @override
  State<MemoriaWidget> createState() => _MemoriaWidgetState();
}

class _MemoriaWidgetState extends State<MemoriaWidget> {
  static const _colors = [Color(0xFF43D67D), Color(0xFFFF5A7A), Color(0xFF29B6F6), Color(0xFFFFD93D)];
  late final List<int> _sequence = List.generate(3, (_) => Random().nextInt(_colors.length));
  final List<int> _input = [];
  bool _showing = true;
  bool _locked = false;
  int _litIndex = -1;
  String _resultado = 'Mirá la secuencia...';

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () => _showSequence(0));
  }

  Future<void> _showSequence(int idx) async {
    if (idx >= _sequence.length) {
      if (!mounted) return;
      setState(() {
        _showing = false;
        _resultado = 'Ahora repetí la secuencia.';
      });
      return;
    }
    if (!mounted) return;
    setState(() => _litIndex = _sequence[idx]);
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() => _litIndex = -1);
    await Future.delayed(const Duration(milliseconds: 200));
    _showSequence(idx + 1);
  }

  void _tap(int i) {
    if (_showing || _locked) return;
    _input.add(i);
    final step = _input.length - 1;
    if (_sequence[step] != i) {
      setState(() {
        _locked = true;
        _resultado = '❌ Te equivocaste.';
      });
      Future.delayed(const Duration(milliseconds: 1100), () => widget.onDone(false));
      return;
    }
    if (_input.length == _sequence.length) {
      setState(() {
        _locked = true;
        _resultado = '✅ ¡Memoria perfecta!';
      });
      Future.delayed(const Duration(milliseconds: 1100), () => widget.onDone(true));
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Mini-juego de memoria: van a brillar 3 fichas de colores, una por una. Cuando terminen, tocalas en el mismo orden en que brillaron.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.violetDark),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _colors.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () => _tap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: _colors[i].withValues(alpha: _litIndex == i ? 1 : 0.5), borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(_resultado, style: const TextStyle(fontSize: 13, color: Color(0xFF7A6A99))),
      ],
    );
  }
}
