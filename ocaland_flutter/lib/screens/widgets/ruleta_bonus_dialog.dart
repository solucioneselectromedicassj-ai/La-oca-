import 'package:flutter/material.dart';
import '../../services/audio_service.dart';
import '../../services/economy_service.dart';
import '../../theme/app_colors.dart';

class RuletaBonusDialog extends StatefulWidget {
  final String usuarioId;
  const RuletaBonusDialog({super.key, required this.usuarioId});

  @override
  State<RuletaBonusDialog> createState() => _RuletaBonusDialogState();
}

class _RuletaBonusDialogState extends State<RuletaBonusDialog> {
  bool _girando = false;
  String? _resultado;

  Future<void> _girar() async {
    setState(() => _girando = true);
    AudioService.sorteo();
    try {
      final r = await EconomyService.girarRuletaBonus(widget.usuarioId);
      if (!mounted) return;
      if (r == null || r.yaUsado) {
        setState(() => _resultado = '⏳ Ya usaste tu giro de hoy. Volvé mañana.');
      } else if (r.valor > 1) {
        AudioService.win();
        setState(() => _resultado = '🎉 ¡Conseguiste x${r.valor.toStringAsFixed(r.valor == r.valor.roundToDouble() ? 0 : 1)} monedas por ${r.minutosDuracion} minutos!');
      } else {
        setState(() => _resultado = '😅 Nada esta vez. Probá de nuevo mañana.');
      }
    } catch (_) {
      if (mounted) setState(() => _resultado = 'No pudimos conectar con el servidor.');
    } finally {
      if (mounted) setState(() => _girando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.parchment,
      title: const Text('🎰 Ruleta de bonus'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Girá una vez por día para conseguir un multiplicador de monedas por un rato.', style: TextStyle(fontSize: 12.5)),
          const SizedBox(height: 10),
          if (_resultado != null) Text(_resultado!, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      actions: [
        if (_resultado == null)
          ElevatedButton(
            onPressed: _girando ? null : _girar,
            child: _girando ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Girar'),
          ),
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar')),
      ],
    );
  }
}
