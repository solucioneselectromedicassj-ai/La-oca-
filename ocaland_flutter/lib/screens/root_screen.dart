import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/identity_service.dart';
import '../theme/app_colors.dart';
import 'lobby_screen.dart';
import 'nickname_screen.dart';
import 'widgets/premio_diario_dialog.dart';

/// Pantalla raíz: intenta restaurar la identidad guardada en el dispositivo
/// (equivalente al `localStorage` del prototipo) antes de decidir si mostrar
/// la pantalla de nombre o ir directo al lobby saludando al usuario.
class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _restaurar());
  }

  Future<void> _restaurar() async {
    final resultado = await IdentityService.restaurarIdentidad();
    if (!mounted) return;
    if (resultado == null) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const NicknameScreen()));
      return;
    }
    if (resultado.premio != null) {
      AudioService.coin();
      await showDialog(
        context: context,
        builder: (_) => PremioDiarioDialog(usuario: resultado.usuario, premio: resultado.premio!),
      );
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => LobbyScreen(usuario: resultado.usuario, offline: resultado.offline)));
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.parchment,
      body: Center(child: CircularProgressIndicator(color: AppColors.violetDark)),
    );
  }
}
