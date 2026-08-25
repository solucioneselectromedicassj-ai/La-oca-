import 'dart:math';
import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../services/audio_service.dart';
import '../services/economy_service.dart';
import '../theme/app_colors.dart';
import 'widgets/minijuego_overlay.dart';

/// Actividad de la pestaña Bonus: una tanda abierta de minijuegos
/// (reflejos y memoria, alternados al azar — los mismos de la casilla de
/// minijuego del tablero) donde cada uno superado gana monedas. Es la
/// segunda forma "jugando" de ganar monedas en Bonus, junto a la tanda
/// de cuestionados que gana sellos.
class MinijuegosBonusScreen extends StatefulWidget {
  final Usuario usuario;
  const MinijuegosBonusScreen({super.key, required this.usuario});

  @override
  State<MinijuegosBonusScreen> createState() => _MinijuegosBonusScreenState();
}

class _MinijuegosBonusScreenState extends State<MinijuegosBonusScreen> {
  static const _monedasPorExito = 3;

  late String _tipo;
  int _rondaKey = 0;
  int _jugados = 0;
  int _superados = 0;
  int _monedasGanadasAca = 0;
  late int _monedas;

  @override
  void initState() {
    super.initState();
    _monedas = widget.usuario.monedas;
    _tipo = Random().nextBool() ? 'reflejos' : 'memoria';
  }

  Future<void> _onDone(bool exito) async {
    setState(() {
      _jugados++;
      if (exito) _superados++;
    });

    if (exito) {
      try {
        final nuevoTotal = await EconomyService.agregarMonedas(widget.usuario.id, _monedasPorExito);
        if (!mounted) return;
        AudioService.coin();
        setState(() {
          _monedasGanadasAca += _monedasPorExito;
          if (nuevoTotal != null) _monedas = nuevoTotal;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🪙 ¡+$_monedasPorExito monedas!'), duration: Duration(seconds: 2)),
        );
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo guardar la moneda, probá de nuevo.')));
        }
      }
    } else {
      AudioService.wrong();
    }

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() {
      _rondaKey++;
      _tipo = Random().nextBool() ? 'reflejos' : 'memoria';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('🎮 Minijuegos'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: AppColors.heroGradient),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _stat('Jugados', '$_jugados'),
                    _stat('Superados', '$_superados'),
                    _stat('Ganadas acá', '$_monedasGanadasAca'),
                    _stat('🪙 Total', '$_monedas'),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('Superá cada minijuego para ganar $_monedasPorExito monedas.', style: const TextStyle(color: Colors.white70, fontSize: 12), textAlign: TextAlign.center),
              ),
              Expanded(
                child: MinijuegoOverlay(
                  key: ValueKey(_rondaKey),
                  titulo: _tipo == 'reflejos' ? '⚡ Reflejos' : '🧠 Memoria',
                  tipo: _tipo,
                  onDone: _onDone,
                  scrim: false,
                ),
              ),
            ],
          ),
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
