import 'package:flutter/material.dart';
import '../models/trivia_bank.dart';
import '../services/audio_service.dart';
import '../services/sellos_service.dart';
import '../theme/app_colors.dart';
import 'widgets/trivia_overlay.dart';

/// Actividad de la pestaña Bonus: una tanda abierta de Cuestionados (sin
/// límite de tiempo ni de preguntas) donde cada [_preguntasPorSello]
/// respuestas correctas seguidas gana un sello — la forma "jugando" de
/// conseguir sellos, además de la casilla de suerte del tablero y el
/// canje por monedas/video del perfil.
class TandaCuestionadosScreen extends StatefulWidget {
  final String edadBracket;
  final String pais;
  const TandaCuestionadosScreen({super.key, required this.edadBracket, required this.pais});

  @override
  State<TandaCuestionadosScreen> createState() => _TandaCuestionadosScreenState();
}

class _TandaCuestionadosScreenState extends State<TandaCuestionadosScreen> {
  static const _preguntasPorSello = 3;

  late TriviaQuestion _pregunta;
  int _rondaKey = 0;
  int _correctasSeguidas = 0;
  int _respondidas = 0;
  int _sellosGanadosAca = 0;
  int _sellos = 0;

  /// Cola de preguntas ya barajadas: se van sacando de a una para no repetir
  /// hasta agotar todo el banco (en vez de barajar y sacar la primera cada
  /// vez, que podía repetir la misma pregunta seguida).
  final List<TriviaQuestion> _cola = [];

  @override
  void initState() {
    super.initState();
    _elegirPregunta();
    SellosService.obtener().then((s) {
      if (mounted) setState(() => _sellos = s);
    });
  }

  void _elegirPregunta() {
    if (_cola.isEmpty) {
      _cola.addAll(List<TriviaQuestion>.from(TriviaBank.bancoPorPais(widget.pais, widget.edadBracket))..shuffle());
    }
    _pregunta = _cola.removeAt(0);
  }

  Future<void> _responder(int idx) async {
    final acierto = idx == _pregunta.correct;
    if (acierto) {
      AudioService.correct();
    } else {
      AudioService.wrong();
    }
    setState(() {
      _respondidas++;
      _correctasSeguidas = acierto ? _correctasSeguidas + 1 : 0;
    });

    if (acierto && _correctasSeguidas % _preguntasPorSello == 0) {
      final restantes = await SellosService.agregar(1);
      if (!mounted) return;
      AudioService.coin();
      setState(() {
        _sellosGanadosAca++;
        _sellos = restantes;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🎖️ ¡Ganaste un sello!'), duration: Duration(seconds: 2)));
    }

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() {
      _rondaKey++;
      _elegirPregunta();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.violetDark,
      appBar: AppBar(
        backgroundColor: AppColors.violetDark,
        foregroundColor: Colors.white,
        title: const Text('🎯 Tanda de cuestionados'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _stat('Respondidas', '$_respondidas'),
                  _stat('Seguidas', '$_correctasSeguidas'),
                  _stat('Sellos ganados', '$_sellosGanadosAca'),
                  _stat('🎖️ Total', '$_sellos'),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Cada $_preguntasPorSello correctas seguidas ganás un sello.', style: const TextStyle(color: Colors.white70, fontSize: 12), textAlign: TextAlign.center),
            ),
            Expanded(
              child: TriviaOverlay(
                key: ValueKey(_rondaKey),
                titulo: '🎯 Cuestionados',
                pregunta: _pregunta,
                segundos: 0,
                onResponder: _responder,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String valor) {
    return Column(
      children: [
        Text(valor, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
      ],
    );
  }
}
