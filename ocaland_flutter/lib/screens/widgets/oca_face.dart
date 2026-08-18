import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/mascota_service.dart';

/// Cara de la Oca según su estado de ánimo actual, con un ciclo de 2
/// cuadros (parpadeo/bostezo) para que se sienta viva incluso quieta.
/// Prioridad de humor: dormida > hambre > aburrida > sueño > feliz.
class OcaFace extends StatefulWidget {
  final EstadoMascota estado;
  final double size;
  const OcaFace({super.key, required this.estado, this.size = 140});

  @override
  State<OcaFace> createState() => _OcaFaceState();
}

class _OcaFaceState extends State<OcaFace> {
  Timer? _timer;
  int _cuadro = 0;

  static const _umbralBajo = 30.0;

  List<String> get _cuadros {
    final e = widget.estado;
    if (e.durmiendo) return const ['oca_durmiendo_1', 'oca_durmiendo_2'];
    if (e.hambre < _umbralBajo) return const ['oca_hambre'];
    if (e.diversion < _umbralBajo) return const ['oca_aburrida'];
    if (e.sueno < _umbralBajo) return const ['oca_sueno_1', 'oca_sueno_2'];
    return const ['oca_feliz', 'oca_feliz_boca_abierta'];
  }

  @override
  void initState() {
    super.initState();
    _iniciarCiclo();
  }

  @override
  void didUpdateWidget(covariant OcaFace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_moodKey(oldWidget.estado) != _moodKey(widget.estado)) {
      _cuadro = 0;
      _iniciarCiclo();
    }
  }

  String _moodKey(EstadoMascota e) {
    if (e.durmiendo) return 'durmiendo';
    if (e.hambre < _umbralBajo) return 'hambre';
    if (e.diversion < _umbralBajo) return 'aburrida';
    if (e.sueno < _umbralBajo) return 'sueno';
    return 'feliz';
  }

  void _iniciarCiclo() {
    _timer?.cancel();
    if (_cuadros.length < 2) return;
    _timer = Timer.periodic(const Duration(milliseconds: 2200), (_) {
      if (mounted) setState(() => _cuadro = (_cuadro + 1) % _cuadros.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cuadros = _cuadros;
    final nombre = cuadros[_cuadro % cuadros.length];
    return Image.asset('assets/mascota/$nombre.png', width: widget.size, height: widget.size);
  }
}
