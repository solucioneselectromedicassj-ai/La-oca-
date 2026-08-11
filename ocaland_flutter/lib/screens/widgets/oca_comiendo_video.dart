import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Animación cortita de la Oca comiendo (video generado, sin audio propio
/// para no pisarse con la música/efectos del juego) — se muestra como
/// premio al darle de comer en `MascotaScreen`. Se reproduce una sola vez
/// y avisa cuando termina; también se puede saltear tocándola.
class OcaComiendoVideo extends StatefulWidget {
  final VoidCallback onTerminado;
  const OcaComiendoVideo({super.key, required this.onTerminado});

  @override
  State<OcaComiendoVideo> createState() => _OcaComiendoVideoState();
}

class _OcaComiendoVideoState extends State<OcaComiendoVideo> {
  late final VideoPlayerController _controller;
  bool _avisado = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/mascota/oca_comiendo.mp4')
      ..setVolume(0)
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {});
        _controller.play();
      });
    _controller.addListener(_chequearFin);
  }

  void _chequearFin() {
    if (_avisado) return;
    final v = _controller.value;
    if (v.isInitialized && !v.isPlaying && v.position >= v.duration && v.duration > Duration.zero) {
      _avisado = true;
      widget.onTerminado();
    }
  }

  void _saltear() {
    if (_avisado) return;
    _avisado = true;
    widget.onTerminado();
  }

  @override
  void dispose() {
    _controller.removeListener(_chequearFin);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _saltear,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: _controller.value.isInitialized
              ? VideoPlayer(_controller)
              : Container(color: Colors.black12, child: const Center(child: CircularProgressIndicator())),
        ),
      ),
    );
  }
}
