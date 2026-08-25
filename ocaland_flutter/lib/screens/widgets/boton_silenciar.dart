import 'package:flutter/material.dart';
import '../../services/audio_service.dart';
import '../../theme/app_colors.dart';

/// Botón fijo para silenciar/reactivar el sonido de la partida en
/// curso — pedido explícito del usuario, no existía ninguna forma de
/// bajarle el volumen al juego sin silenciar el celular entero.
class BotonSilenciar extends StatefulWidget {
  const BotonSilenciar({super.key});

  @override
  State<BotonSilenciar> createState() => _BotonSilenciarState();
}

class _BotonSilenciarState extends State<BotonSilenciar> {
  late bool _activado = AudioService.enabled;

  Future<void> _alternar() async {
    await AudioService.alternarSonido(enJuego: true);
    if (mounted) setState(() => _activado = AudioService.enabled);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: _alternar,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(_activado ? Icons.volume_up : Icons.volume_off, color: AppColors.violetDark, size: 22),
        ),
      ),
    );
  }
}
