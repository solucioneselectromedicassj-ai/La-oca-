import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Burbuja grande con el aviso de la casilla ("Caíste en la cárcel", etc.)
/// que aparece y se esfuma sola a los pocos segundos — reemplaza el texto
/// chico permanente de antes (pedido del usuario: que se vea como un aviso,
/// no como un renglón más de la pantalla).
class MessageBubble extends StatefulWidget {
  final String mensaje;
  const MessageBubble({super.key, required this.mensaje});

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  Timer? _hideTimer;
  bool _visible = false;
  String _shown = '';

  @override
  void initState() {
    super.initState();
    _mostrar(widget.mensaje);
  }

  @override
  void didUpdateWidget(covariant MessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mensaje != oldWidget.mensaje) _mostrar(widget.mensaje);
  }

  void _mostrar(String msg) {
    if (msg.isEmpty) return;
    _hideTimer?.cancel();
    setState(() {
      _shown = msg;
      _visible = true;
    });
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _visible = false);
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: _visible ? 1 : 0,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.violetDark,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Text(
          _shown,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, height: 1.3),
        ),
      ),
    );
  }
}
